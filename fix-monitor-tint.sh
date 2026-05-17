#!/usr/bin/env bash
#
# Fix warm tint on Xiaomi G Pro 27i after wake/connect by briefly toggling the
# DDC color preset. Equivalent to the OSD "Eco -> Standard" trick. Routed
# through BetterDisplay's HTTP integration because direct DDC via m1ddc is
# unreliable on this monitor (BetterDisplay discussion #3652).
#
# Requires BetterDisplay running with HTTP integration enabled on port 55777.
#
# @raycast.schemaVersion 1
# @raycast.title Fix Monitor Tint
# @raycast.mode silent
# @raycast.packageName Display
# @raycast.icon 🖥️
# @raycast.description Clear post-wake warm tint on Xiaomi G Pro 27i

set -u

BD_HOST="localhost:55777"
ID="nameLike=Mi"

bd_set() {
  curl -fsS --max-time 3 \
    "http://${BD_HOST}/set?${ID}&ddc&vcp=selectColorPreset&value=$1" \
    >/dev/null 2>&1 || true
}

bd_set 6
sleep 1.2
bd_set 5
