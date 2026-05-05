#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage:
  POGO_DIM=2 ./run_pogo.sh [case_dir]
  POGO_DIM=3 ./run_pogo.sh [case_dir]

Defaults:
  case_dir: current directory
  POGO_DIM: 2

2D command pair:
  pogoBlock <file.pogo-inp>
  pogoSolve <file.pogo-inp>

3D command pair:
  pogoBlockGreedy3d <file.pogo-inp>
  pogoSolve3d <file.pogo-inp>
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

case_dir="${1:-.}"
POGO_DIM="${POGO_DIM:-2}"

case "$POGO_DIM" in
  2)
    block_cmd="${POGO_BLOCK_CMD:-pogoBlock}"
    solve_cmd="${POGO_SOLVE_CMD:-pogoSolve}"
    ;;
  3)
    block_cmd="${POGO_BLOCK_CMD:-pogoBlockGreedy3d}"
    solve_cmd="${POGO_SOLVE_CMD:-pogoSolve3d}"
    ;;
  *)
    echo "Unsupported POGO_DIM=$POGO_DIM. Use 2 or 3." >&2
    usage
    exit 2
    ;;
esac

command -v "$block_cmd" >/dev/null || { echo "Block command not found: $block_cmd" >&2; exit 127; }
command -v "$solve_cmd" >/dev/null || { echo "Solve command not found: $solve_cmd" >&2; exit 127; }

cd "$case_dir"
shopt -s globstar nullglob
files=(**/*.pogo-inp)
if (( ${#files[@]} == 0 )); then
  echo "No .pogo-inp files found in $(pwd)."
  exit 0
fi

echo "POGO_DIM=$POGO_DIM"
echo "Block command: $block_cmd"
echo "Solve command: $solve_cmd"

for f in "${files[@]}"; do
  echo "[$(date -Is)] $block_cmd $f"
  "$block_cmd" "$f"
  echo "[$(date -Is)] $solve_cmd $f"
  "$solve_cmd" "$f"
  echo "[$(date -Is)] completed $f"
done

echo "All POGO inputs processed."
