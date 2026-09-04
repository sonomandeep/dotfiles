#!/usr/bin/env bash
# Link the tracked Pi configuration into Pi's standard global resource directory.

set -Eeuo pipefail

fail() {
  printf 'pi config installer: %s\n' "$*" >&2
  exit 1
}

script_dir() {
  local source="${BASH_SOURCE[0]}"
  local directory

  while [[ -L "$source" ]]; do
    directory="$(cd -P "$(dirname "$source")" && pwd)" || return 1
    source="$(readlink "$source")" || return 1
    [[ "$source" == /* ]] || source="$directory/$source"
  done

  cd -P "$(dirname "$source")" && pwd
}

CONFIG_DIR="$(script_dir)" || fail "could not determine the installer directory"
AGENT_DIR="${HOME:?HOME must be set}/.pi/agent"

backup_target() {
  local target="$1"
  local timestamp backup suffix=1

  timestamp="$(date +%Y%m%d%H%M%S)" || fail "could not create a backup timestamp"
  backup="${target}.bak.${timestamp}"
  while [[ -e "$backup" || -L "$backup" ]]; do
    backup="${target}.bak.${timestamp}.${suffix}"
    ((suffix += 1))
  done

  mv "$target" "$backup" || fail "could not back up $target to $backup"
  printf 'Backed up: %s -> %s\n' "$target" "$backup"
}

link_resource() {
  local name="$1"
  local source="$CONFIG_DIR/$name"
  local target="$AGENT_DIR/$name"

  [[ -e "$source" ]] || fail "required tracked resource is missing: $source"

  if [[ -L "$target" ]] && [[ "$target" -ef "$source" ]]; then
    printf 'Already linked: %s -> %s\n' "$target" "$source"
    return
  fi

  if [[ -e "$target" || -L "$target" ]]; then
    backup_target "$target"
  fi

  ln -s "$source" "$target" || fail "could not link $target to $source"
  printf 'Linked: %s -> %s\n' "$target" "$source"
}

command -v pi >/dev/null 2>&1 || fail "pi must be installed and available on PATH"

mkdir -p "$AGENT_DIR" || fail "could not create $AGENT_DIR"
link_resource AGENTS.md
link_resource settings.json

printf 'Reconciling Pi packages declared in %s...\n' "$CONFIG_DIR/settings.json"
pi update --extensions || fail "could not reconcile Pi packages"
