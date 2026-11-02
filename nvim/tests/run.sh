#!/bin/bash
# Run without touching the user's Neovim data, config, state, or cache.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEMP="$(mktemp -d "${TMPDIR:-/tmp}/nvim-config-test.XXXXXX")"
trap 'rm -rf -- "$TEMP"' EXIT
mkdir -p "$TEMP/config"
cp -R "$ROOT" "$TEMP/config/nvim"
export XDG_CONFIG_HOME="$TEMP/config" XDG_DATA_HOME="$TEMP/data"
export XDG_STATE_HOME="$TEMP/state" XDG_CACHE_HOME="$TEMP/cache"
export NVIM_APPNAME=nvim NVIM_TEST_SCRIPT="$ROOT/tests/smoke.lua"
"${NVIM_BIN:-nvim}" --headless \
  '+lua local ok, err = pcall(dofile, vim.env.NVIM_TEST_SCRIPT); if not ok then print(err); vim.cmd("cquit 1") end' \
  '+qa!'
