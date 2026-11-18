#!/bin/zsh
set -e
cd "$(dirname "$0")/auto_mob"
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
if [[ ! -f .env ]]; then
  print "Configura auto_mob/.env seguendo .env.example prima di avviare."
  read '?Premi Invio per chiudere.'
  exit 1
fi
device="39330E47-F013-47D5-B9B2-413D0BF00902"
if ! xcrun simctl list devices booted | grep -q "$device"; then
  xcrun simctl boot "$device"
fi
open -a /Applications/Xcode.app/Contents/Applications/DeviceHub.app
xcrun simctl bootstatus "$device" -b
flutter run -d "$device" --dart-define-from-file=.env "$@"
