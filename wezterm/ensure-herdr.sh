#!/bin/sh
set -eu

if command -v herdr >/dev/null 2>&1; then
  exit 0
fi

curl -fsSL https://herdr.dev/install.sh | sh
