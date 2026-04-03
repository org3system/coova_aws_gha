#!/usr/bin/env bash
# Runs inside the ECS Fargate container.
# Required environment variables:
#   S3_BUCKET   - destination bucket for built RPMs
#   S3_PREFIX   - optional key prefix (default: "rpms")
set -euo pipefail

S3_BUCKET="${S3_BUCKET:?S3_BUCKET env var is required}"
S3_PREFIX="${S3_PREFIX:-rpms}"

TOPDIR=/root/rpmbuild
SPEC="$TOPDIR/SPECS/coova-chilli.spec"

echo "==> Downloading source tarball"
wget --tries=3 -q \
    -O "$TOPDIR/SOURCES/coova-chilli-1.8.tar.gz" \
    "https://codeload.github.com/coova/coova-chilli/tar.gz/refs/tags/1.8"

echo "==> Installing build dependencies via yum-builddep"
yum-builddep -y "$SPEC"

echo "==> Building SRPM"
rpmbuild -bs "$SPEC"

echo "==> Building binary RPM"
rpmbuild -ba "$SPEC"

echo "==> Build complete. Listing RPMs:"
find "$TOPDIR/RPMS" "$TOPDIR/SRPMS" -type f \( -name '*.rpm' -o -name '*.src.rpm' \) -print

echo "==> Uploading RPMs to s3://${S3_BUCKET}/${S3_PREFIX}/"
find "$TOPDIR/RPMS" "$TOPDIR/SRPMS" -type f \( -name '*.rpm' -o -name '*.src.rpm' \) | while read -r rpm; do
    aws s3 cp "$rpm" "s3://${S3_BUCKET}/${S3_PREFIX}/$(basename "$rpm")"
done

echo "==> All RPMs uploaded successfully."
