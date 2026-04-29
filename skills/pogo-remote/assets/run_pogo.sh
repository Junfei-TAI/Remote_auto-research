#!/usr/bin/env bash
set -euo pipefail

shopt -s globstar nullglob

files=(**/*.pogo-inp)
if [ ${#files[@]} -eq 0 ]; then
  echo "No .pogo-inp files found."
  exit 0
fi

for f in "${files[@]}"; do
  echo "Running pogoBlockGreedy3d on: $f"
  pogoBlockGreedy3d "$f"
  echo "Running pogoSolve3d on: $f"
  pogoSolve3d "$f"
done

echo "All POGO inputs processed."
