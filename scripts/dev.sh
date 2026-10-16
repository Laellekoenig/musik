#!/bin/zsh
# Builds and launches Musik, then rebuilds and relaunches it whenever a file in Musik/ changes.
# The app's stdout/stderr (print, fatalError) shows up in this terminal. Ctrl-C quits both.

set -u
cd "${0:A:h}/.."

# xcodebuild needs full Xcode, not the Command Line Tools.
if [[ -z "${DEVELOPER_DIR:-}" && "$(xcode-select -p)" == *CommandLineTools* ]]; then
    export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi

APP=build/Build/Products/Debug/Musik.app
BIN="$PWD/$APP/Contents/MacOS/Musik"
STAMP=build/.dev-stamp
mkdir -p build

stop_app() { pkill -f "$BIN" 2>/dev/null; while pgrep -f "$BIN" >/dev/null; do sleep 0.1; done; }
trap 'stop_app; exit 0' INT TERM

build_and_run() {
    touch "$STAMP"
    print -P "%F{blue}▸ Building…%f"
    local start=$SECONDS
    if xcodebuild -project Musik.xcodeproj -scheme Musik -configuration Debug \
        -derivedDataPath build -destination "platform=macOS,arch=$(uname -m)" -quiet build 2>&1 \
        | awk 'length < 500 && !/outside of the allowed root paths|IDERunDestination|Failed frontend command|produced no further output/' \
        ; [[ ${pipestatus[1]} -eq 0 ]]; then
        print -P "%F{green}✔ Built in $((SECONDS - start))s, relaunching%f"
        stop_app
        "$BIN" &
        sleep 0.5
        open "$APP" # brings the new window to the front
    else
        print -P "%F{red}✘ Build failed, keeping the previous build running%f"
    fi
}

build_and_run
print -P "%F{8}Watching Musik/ for changes…%f"
while true; do
    sleep 0.5
    if [[ -n "$(find Musik -type f -newer "$STAMP" -not -name .DS_Store -print -quit)" ]]; then
        sleep 0.2 # let multi-file saves settle
        build_and_run
    fi
done
