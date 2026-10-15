# lens-spark-site

The one-page download site for the LensSpark beta.

- `site/` is the page (plain HTML, no external requests).
- `k8s/` deploys it: httpd serving a small volume, a Route, and a Let's Encrypt certificate.
  Argo CD pulls `k8s/` through a gate file in the cluster's GitOps repo.
- The APK is never committed. `publish.sh` copies the page and a signed APK onto the volume.

## New release

1. Build and sign the APK in the app repo.
2. Update the version, file name and SHA-256 in `site/index.html`, and commit.
3. `./publish.sh path/to/app-release.apk <version>`
