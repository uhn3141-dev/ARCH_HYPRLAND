#!/usr/bin/env bash

IPC_DIR="/tmp/quickshell_ipc"
mkdir -p "$IPC_DIR"

# Write a new IPC file with timestamp
write_ipc() {
    local file="$IPC_DIR/msg_$(date +%s%N)"
    echo "$1" > "$file"
    echo "[popup_manager] IPC: $1 -> $file" >&2
}

case "$1" in
    --toggle)
        write_ipc "toggle:$2"
    ;;
    --close-all|--kill-all)
        write_ipc "close:all"
    ;;
    *)
        echo "Usage: $0 --toggle <id> | --close-all"
        exit 1
    ;;
esac