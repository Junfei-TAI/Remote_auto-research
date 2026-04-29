#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  ./scripts/install.sh <codex|openclaw|claude-code> [--mode symlink|copy] [--target-dir PATH]

Examples:
  ./scripts/install.sh codex --mode symlink
  ./scripts/install.sh openclaw --mode symlink
  ./scripts/install.sh claude-code --mode copy
USAGE
}

if [ $# -lt 1 ]; then
  usage
  exit 1
fi

TARGET="$1"
shift || true
MODE="symlink"
CUSTOM_TARGET_DIR=""

while [ $# -gt 0 ]; do
  case "$1" in
    --mode)
      MODE="$2"
      shift 2
      ;;
    --target-dir)
      CUSTOM_TARGET_DIR="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ "$MODE" != "symlink" && "$MODE" != "copy" ]]; then
  echo "--mode must be symlink or copy" >&2
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

install_path() {
  local src="$1"
  local dst="$2"

  rm -rf "$dst"
  if [ "$MODE" = "symlink" ]; then
    ln -s "$src" "$dst"
  else
    cp -R "$src" "$dst"
  fi
}

case "$TARGET" in
  codex)
    SRC_ROOT="$REPO_ROOT/skills"
    TARGET_DIR="${CUSTOM_TARGET_DIR:-$HOME/.codex/skills}"
    mkdir -p "$TARGET_DIR"
    for skill_dir in "$SRC_ROOT"/*; do
      [ -d "$skill_dir" ] || continue
      install_path "$skill_dir" "$TARGET_DIR/$(basename "$skill_dir")"
    done
    echo "Installed Codex skills to: $TARGET_DIR"
    ;;
  openclaw)
    SRC_ROOT="$REPO_ROOT/skills"
    TARGET_DIR="${CUSTOM_TARGET_DIR:-$HOME/.agents/skills}"
    mkdir -p "$TARGET_DIR"
    for skill_dir in "$SRC_ROOT"/*; do
      [ -d "$skill_dir" ] || continue
      install_path "$skill_dir" "$TARGET_DIR/$(basename "$skill_dir")"
    done
    echo "Installed OpenClaw/AgentSkills-compatible skills to: $TARGET_DIR"
    ;;
  claude-code)
    SRC_ROOT="$REPO_ROOT/adapters/claude-code/agents"
    TARGET_DIR="${CUSTOM_TARGET_DIR:-$HOME/.claude/agents}"
    mkdir -p "$TARGET_DIR"
    for agent_file in "$SRC_ROOT"/*.md; do
      [ -f "$agent_file" ] || continue
      install_path "$agent_file" "$TARGET_DIR/$(basename "$agent_file")"
    done
    echo "Installed Claude Code agent files to: $TARGET_DIR"
    ;;
  *)
    echo "Unsupported target: $TARGET" >&2
    usage
    exit 1
    ;;
esac
