#!/bin/sh
# Copy the page and a signed LensSpark APK onto the site's volume.
# Usage: ./publish.sh path/to/app-release.apk 0.9.0-beta.1
# Check the version and SHA-256 in site/index.html match before running.
set -eu
apk=$1 version=$2
cd "$(dirname "$0")"
pod=$(oc -n lens-spark get pod -l app=httpd -o jsonpath='{.items[0].metadata.name}')
oc -n lens-spark cp site/. "$pod:/var/www/html/"
oc -n lens-spark cp "$apk" "$pod:/var/www/html/LensSpark-$version.apk"
echo "Published LensSpark-$version.apk: $(shasum -a 256 "$apk" | cut -d' ' -f1)"
