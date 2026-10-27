#!/usr/bin/env bash
set -e

echo "=== [F08] Starting RTL-to-GDSII Flow via LibreLane/OpenLane ==="
export PDK_ROOT=${PDK_ROOT:-$HOME/.volare}

# Kiểm tra xem file cấu hình đã tồn tại chưa
if [ ! -f "04_IMPLEMENTATION/scripts/config_librelane.json" ]; then
    echo "Error: config_librelane.json not found!"
    exit 1
fi

echo "=== Running LibreLane Flow ==="
python3 -m librelane 04_IMPLEMENTATION/scripts/config_librelane.json

echo "=== RTL-to-GDSII Flow Completed Successfully! ==="
