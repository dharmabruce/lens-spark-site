#!/bin/sh
# Count APK downloads and page views from the site's persistent access log.
# Usage: ./stats.sh [YYYY-MM]   (default: every month on the volume)
# Visitors are salted hashes (see k8s/httpd-accesslog.yaml); this prints counts only.
set -eu
month=${1:-*}
oc -n lens-spark exec deploy/httpd -- sh -c "cat /var/log/lens-spark/access-$month.log" |
awk -F'"' '
  tolower($4) ~ /bot|crawl|spider|slurp|preview|^curl|^wget/ { next }
  {
    split($1, a, " "); id = a[1]; day = substr(a[2], 1, 10)
    split($2, r, " "); path = r[2]; sub(/\?.*/, "", path)
    split($3, s, " "); status = s[1]
  }
  path ~ /\.apk$/ && status == 200 {
    apk = path; sub(/^\//, "", apk)
    dl[apk]++; if (!((apk, id) in dlu)) { dlu[apk, id]; users[apk]++ }
    if (!(id in anydl)) { anydl[id]; alldl++ }
  }
  path ~ /\.apk$/ && status == 206 { partial++ }
  (path == "/" || path == "/index.html") && status == 200 {
    views[day]++; if (!((day, id) in vu)) { vu[day, id]; vis[day]++ }
    if (!(id in anyv)) { anyv[id]; allv++ }
  }
  END {
    print "APK downloads (complete)          downloads  people"
    for (k in dl) printf "  %-32s %9d %7d\n", k, dl[k], users[k]
    printf "  %-32s %9s %7d\n", "any version", "", alldl
    if (partial) printf "  (plus %d partial/resumed requests)\n", partial
    print ""
    print "Page views              views  visitors"
    for (d in views) printf "  %-20s %7d %9d\n", d, views[d], vis[d]
    printf "  %-20s %7s %9d\n", "all days (unique)", "", allv
  }' | {
  # Sort the per-version and per-day rows; keep headers and totals in place.
  awk '/^  [0-9L]/ { body = body $0 "\n"; next } { if (body != "") { printf "%s", body | "sort"; close("sort"); body = "" } print }'
}
