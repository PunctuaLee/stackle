#!/bin/sh
# Builds www/index.html (the app the phones load) from stackle.html (the single-file game).
set -e
cd "$(dirname "$0")/.."
mkdir -p www
{
cat <<'HEAD'
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover, user-scalable=no">
<meta name="theme-color" content="#141226">
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
<meta name="apple-mobile-web-app-title" content="Stackle">
<link rel="manifest" href="manifest.webmanifest">
<link rel="apple-touch-icon" href="icon-192.png">
<link rel="icon" href="icon-192.png">
<style>html,body{height:100%}body{margin:0}[hidden]{display:none!important}</style>
</head>
<body>
HEAD
# online config (Supabase url + anon key). Empty values keep the leaderboard hidden.
if [ -f config.json ]; then
  printf '<script>window.STACKLE_CONFIG=%s;</script>\n' "$(tr -d '\n' < config.json)"
fi
# the game file starts with <title> and a claude-only meta; keep the title, drop that meta
sed '/claude:viewport-fit-sides/d' stackle.html
cat <<'TAIL'
<script>
// register the offline cache when served over https (PWA); skipped inside the native app shell
if ('serviceWorker' in navigator && location.protocol === 'https:') {
  navigator.serviceWorker.register('sw.js').catch(function(){});
}
</script>
</body>
</html>
TAIL
} > www/index.html
cp assets/icon-192.png assets/icon-512.png www/ 2>/dev/null || true
cp assets/manifest.webmanifest www/
# stamp the service worker so every deploy replaces the old cache
BUILD="$(date -u +%Y%m%d%H%M%S)-$(git rev-parse --short HEAD 2>/dev/null || echo dev)"
sed "s/__BUILD__/$BUILD/" assets/sw.js > www/sw.js
echo "built www/index.html"
