#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
scratch_dir=$(mktemp -d "${TMPDIR:-/tmp}/lyric-fever-checks.XXXXXX")
trap 'rm -rf "$scratch_dir"' EXIT
xcrun swiftc -swift-version 5 -parse-as-library -module-cache-path "$scratch_dir/cache" \
  Tests/LRCLIBProviderChecks.swift \
  LyricFever/Models/LyricLine.swift \
  LyricFever/LyricProvider/LyricProvider.swift \
  LyricFever/LyricProvider/SongResult.swift \
  LyricFever/LyricProvider/LRCLIB/LRCLIBLyrics.swift \
  LyricFever/LyricProvider/LRCLIB/LRCLIBExtensions.swift \
  LyricFever/LyricProvider/LRCLIB/LRCLIBLyricProvider.swift \
  -o "$scratch_dir/checks"
"$scratch_dir/checks"
