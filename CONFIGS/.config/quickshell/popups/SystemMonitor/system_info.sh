#!/usr/bin/env bash
# =============================================================================
# System Monitor Data Fetcher – with disk model and per‑minute disk updates
# Usage:
#   system_info.sh cpu|gpu|memory|disk|apps          → single JSON to stdout
#   system_info.sh --daemon [output_file]            → continuous loop (1s)
# =============================================================================

set -o pipefail

# -----------------------------------------------------------------------------
# JSON string escaping – only what JSON requires
# -----------------------------------------------------------------------------
json_escape() {
    printf "%s" "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/\n/\\n/g' -e 's/\r/\\r/g' -e 's/\t/\\t/g'
}

# -----------------------------------------------------------------------------
# Safe integer extraction
# -----------------------------------------------------------------------------
int_val() { echo "${1:-0}" | grep -oE '[0-9]+' | head -1; }

# -----------------------------------------------------------------------------
# Fallback for nproc
# -----------------------------------------------------------------------------
get_nproc() {
    nproc 2>/dev/null || grep -c ^processor /proc/cpuinfo
}

# -----------------------------------------------------------------------------
# CPU – full data including per‑core usage
# -----------------------------------------------------------------------------
get_cpu() {
    # ---- Overall usage (0.2s sample) ----
    read -r cpu user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat
    prev_total=$((user + nice + system + idle + iowait + irq + softirq + steal))
    prev_used=$((user + nice + system + irq + softirq + steal))
    sleep 0.2
    read -r cpu user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat
    total=$((user + nice + system + idle + iowait + irq + softirq + steal))
    used=$((user + nice + system + irq + softirq + steal))
    diff_total=$((total - prev_total))
    diff_used=$((used - prev_used))
    pct=0
    [ "$diff_total" -gt 0 ] && pct=$((diff_used * 100 / diff_total))

    # ---- Per‑core usage (array) ----
    per_core_arr=()
    if [ -f /proc/stat ]; then
        while read -r line; do
            [[ "$line" =~ ^cpu[0-9]+ ]] || continue
            set -- $line
            local cpu_id=$1
            local user=$2 nice=$3 system=$4 idle=$5 iowait=$6 irq=$7 softirq=$8 steal=$9
            local total=$((user + nice + system + idle + iowait + irq + softirq + steal))
            local used=$((user + nice + system + irq + softirq + steal))
            local prev_total_key="prev_total_${cpu_id}"
            local prev_used_key="prev_used_${cpu_id}"
            local prev_total_val=${!prev_total_key:-0}
            local prev_used_val=${!prev_used_key:-0}
            eval "${prev_total_key}=$total"
            eval "${prev_used_key}=$used"
            local diff_total=$((total - prev_total_val))
            local diff_used=$((used - prev_used_val))
            local core_pct=0
            if [ "$diff_total" -gt 0 ]; then
                core_pct=$((diff_used * 100 / diff_total))
            fi
            per_core_arr+=("$core_pct")
        done < /proc/stat
    fi
    per_core_json="["
    for i in "${!per_core_arr[@]}"; do
        [ "$i" -gt 0 ] && per_core_json+=","
        per_core_json+="${per_core_arr[$i]}"
    done
    per_core_json+="]"

    # ---- Temperature ----
    temp=0
    if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
        temp=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null)
        temp=$((temp / 1000))
    elif command -v sensors &>/dev/null; then
        temp=$(sensors 2>/dev/null | awk '/^Package id 0:/{print $4; exit}' | tr -d '+°C')
        [ -z "$temp" ] && temp=$(sensors 2>/dev/null | awk '/^Core 0:/{print $3; exit}' | tr -d '+°C')
    fi
    [ -z "$temp" ] && temp=0

    # ---- Frequency ----
    freq=0
    if [ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq ]; then
        freq=$(awk '{printf "%.1f", $1/1000000}' /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq)
    else
        freq=$(awk -F': ' '/cpu MHz/{printf "%.1f", $2/1000; exit}' /proc/cpuinfo)
    fi
    [ -z "$freq" ] && freq=0

    # ---- Cores ----
    cores=$(get_nproc)

    # ---- Model ----
    model=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2- | xargs)
    [ -z "$model" ] && model="Unknown CPU"
    model_esc=$(json_escape "$model")

    # ---- L2 / L3 cache ----
    l2=$(lscpu 2>/dev/null | awk '/^L2 cache:/{print $3, $4}' | xargs)
    l3=$(lscpu 2>/dev/null | awk '/^L3 cache:/{print $3, $4}' | xargs)
    [ -z "$l2" ] && l2="-"
    [ -z "$l3" ] && l3="-"
    l2_esc=$(json_escape "$l2")
    l3_esc=$(json_escape "$l3")

    # ---- Governor ----
    governor="unknown"
    [ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ] && governor=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)
    governor_esc=$(json_escape "$governor")

    # ---- Processes ----
    processes=$(ps aux --no-headers 2>/dev/null | wc -l)

    echo "{\"usage\":$pct,\"temp\":$temp,\"freq\":$freq,\"cores\":$cores,\"model\":\"$model_esc\",\"l2\":\"$l2_esc\",\"l3\":\"$l3_esc\",\"governor\":\"$governor_esc\",\"processes\":$processes,\"per_core\":$per_core_json}"
}

# -----------------------------------------------------------------------------
# GPU – Intel / AMD / NVIDIA
# -----------------------------------------------------------------------------
get_gpu() {
    usage=0
    temp=0
    freq=0
    model="Unknown GPU"
    vram=0
    vram_total=0
    driver=""
    pcie=""

    if command -v nvidia-smi &>/dev/null; then
        usage=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -1)
        temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -1)
        freq=$(nvidia-smi --query-gpu=clocks.sm --format=csv,noheader,nounits 2>/dev/null | head -1)
        model=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1)
        vram=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits 2>/dev/null | head -1)
        vram_total=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null | head -1)
        driver=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -1)
        pcie=$(nvidia-smi --query-gpu=pcie.link.gen.current --format=csv,noheader 2>/dev/null | head -1)
    else
        for card in /sys/class/drm/card[0-9]*; do
            [ -d "$card/device" ] || continue
            if [ -f "$card/device/vendor" ]; then
                vendor=$(cat "$card/device/vendor" 2>/dev/null)
                case "$vendor" in
                    0x8086) model="Intel GPU"; driver="i915" ;;
                    0x1002) model="AMD GPU"; driver="amdgpu" ;;
                    0x10de) model="NVIDIA GPU"; driver="nvidia" ;;
                esac
            fi
            # Temperature
            if [ -f "$card/device/hwmon/hwmon0/temp1_input" ]; then
                temp=$(cat "$card/device/hwmon/hwmon0/temp1_input" 2>/dev/null)
                temp=$((temp / 1000))
            fi
            # Intel frequency & usage
            if [[ "$model" == "Intel GPU" ]]; then
                if [ -f "$card/gt/gt0/rps_act_freq_mhz" ]; then
                    freq=$(cat "$card/gt/gt0/rps_act_freq_mhz" 2>/dev/null)
                fi
                if [ -d "$card/engine" ]; then
                    total_busy=0; count=0
                    for eng in "$card"/engine/*/busy; do
                        [ -f "$eng" ] && total_busy=$((total_busy + $(cat "$eng"))) && count=$((count+1))
                    done
                    [ $count -gt 0 ] && usage=$((total_busy / count / 10000))
                    [ "$usage" -gt 100 ] && usage=100
                fi
                if [ "$usage" -eq 0 ] && [ -f "$card/gt/gt0/rps_max_freq_mhz" ]; then
                    maxf=$(cat "$card/gt/gt0/rps_max_freq_mhz")
                    [ -n "$maxf" ] && [ "$maxf" -gt 0 ] && usage=$((freq * 100 / maxf))
                fi
            fi
            # AMD specific
            if [[ "$model" == "AMD GPU" ]]; then
                [ -f "$card/device/gpu_busy_percent" ] && usage=$(cat "$card/device/gpu_busy_percent")
                [ -f "$card/device/mem_info_vram_used" ] && vram=$(($(cat "$card/device/mem_info_vram_used") / 1048576))
                [ -f "$card/device/mem_info_vram_total" ] && vram_total=$(($(cat "$card/device/mem_info_vram_total") / 1048576))
            fi
            [ "$model" != "Unknown GPU" ] && break
        done
    fi
    [ -z "$usage" ] && usage=0
    [ -z "$temp" ] && temp=0
    [ -z "$freq" ] && freq=0
    [ -z "$vram" ] && vram=0
    [ -z "$vram_total" ] && vram_total=0
    [ -z "$driver" ] && driver=""
    [ -z "$pcie" ] && pcie=""

    model_esc=$(json_escape "$model")
    driver_esc=$(json_escape "$driver")
    pcie_esc=$(json_escape "$pcie")

    echo "{\"usage\":$usage,\"temp\":$temp,\"freq\":$freq,\"model\":\"$model_esc\",\"vram\":$vram,\"vram_total\":$vram_total,\"driver\":\"$driver_esc\",\"pcie\":\"$pcie_esc\"}"
}

# -----------------------------------------------------------------------------
# Memory
# -----------------------------------------------------------------------------
get_memory() {
    LC_ALL=C awk '
        /MemTotal/ {total=$2}
        /MemAvailable/ {avail=$2}
        /^Cached/ {cached=$2}
        /^Buffers/ {buffers=$2}
        /SwapTotal/ {swap_total=$2}
        /SwapFree/ {swap_free=$2}
        END {
            used = total - avail
            pct = (used * 100) / total
            total_gb = total / 1048576
            used_gb = used / 1048576
            avail_gb = avail / 1048576
            cached_gb = cached / 1048576
            buffers_gb = buffers / 1048576
            swap_used = swap_total - swap_free
            swap_pct = (swap_total > 0) ? (swap_used * 100) / swap_total : 0
            swap_total_gb = swap_total / 1048576
            swap_used_gb = swap_used / 1048576
            printf("{\"usage\":%d,\"total\":\"%.1fG\",\"used\":\"%.1fG\",\"available\":\"%.1fG\",\"cached\":\"%.1fG\",\"buffers\":\"%.1fG\",\"swap_total\":\"%.1fG\",\"swap_used\":\"%.1fG\",\"swap_pct\":%d}",
                   pct, total_gb, used_gb, avail_gb, cached_gb, buffers_gb, swap_total_gb, swap_used_gb, swap_pct)
        }' /proc/meminfo
}

# -----------------------------------------------------------------------------
# Disk – all partitions with disk model (cached per physical disk)
# -----------------------------------------------------------------------------
# Global associative array to cache disk models (populated on first use)
declare -A DISK_MODEL_CACHE

get_disk_model() {
    local disk_base="$1"
    if [[ -z "${DISK_MODEL_CACHE[$disk_base]}" ]]; then
        local model=$(lsblk -dno MODEL "/dev/$disk_base" 2>/dev/null | head -1 | xargs)
        [ -z "$model" ] && model="$disk_base"
        DISK_MODEL_CACHE[$disk_base]=$(json_escape "$model")
    fi
    echo "${DISK_MODEL_CACHE[$disk_base]}"
}

get_disk() {
    local first=true
    echo "["
    LC_ALL=C df -kT 2>/dev/null | grep -E '^(/dev/|//)' | while IFS= read -r line; do
        set -- $line
        fs="$1"
        fstype="$2"
        total="$3"
        used="$4"
        free="$5"
        pct=$(echo "$6" | tr -d '%')
        mount="$7"

        # Skip pseudo filesystems
        case "$fstype" in
            tmpfs|devtmpfs|squashfs|overlay|ramfs|proc|sysfs|debugfs|tracefs|fusectl|configfs|bpf|cgroup|cgroup2|pstore|securityfs|binfmt_misc|autofs|nfsd|rpc_pipefs|hugetlbfs|mqueue)
                continue ;;
        esac

        [ "$total" -eq 0 ] && continue

        total_gb=$(awk "BEGIN {printf \"%.1f\", $total/1048576}")
        used_gb=$(awk "BEGIN {printf \"%.1f\", $used/1048576}")
        free_gb=$(awk "BEGIN {printf \"%.1f\", $free/1048576}")

        mount_esc=$(json_escape "$mount")
        fstype_esc=$(json_escape "$fstype")
        fs_esc=$(json_escape "$fs")

        # Extract base disk name (e.g., sda from /dev/sda2)
        disk_base=$(echo "$fs" | sed -E 's|/dev/([a-z]+)[0-9]*$|\1|')
        disk_model=$(get_disk_model "$disk_base")

        if [ "$first" = true ]; then
            first=false
        else
            printf ","
        fi
        printf '{"mount":"%s","usage":%d,"total":"%sG","used":"%sG","free":"%sG","fs":"%s","type":"%s","diskModel":"%s"}' \
            "$mount_esc" "$pct" "$total_gb" "$used_gb" "$free_gb" "$fs_esc" "$fstype_esc" "$disk_model"
    done
    echo "]"
}

# -----------------------------------------------------------------------------
# Apps – optional (not used in daemon, but kept for completeness)
# -----------------------------------------------------------------------------
get_apps() {
    ps -e -o %cpu,%mem,args --sort=-%cpu | head -11 | tail -10 | awk '
        {
            cpu = $1
            mem = $2
            $1 = ""; $2 = "";
            cmd = substr($0, 3)
            split(cmd, words, " ")
            base = words[1]
            gsub(/.*\//, "", base)
            gsub(/"/, "\\\"", base)
            printf "{\"name\":\"%s\",\"cpu\":%s,\"mem\":%s},", base, cpu, mem
        }' | sed 's/,$//' | { printf "["; cat; printf "]"; }
}

# -----------------------------------------------------------------------------
# Main dispatcher
# -----------------------------------------------------------------------------
case "$1" in
    cpu) get_cpu ;;
    gpu) get_gpu ;;
    memory) get_memory ;;
    disk) get_disk ;;
    apps) get_apps ;;
    all)
        echo "{"
        echo "\"cpu\":$(get_cpu),"
        echo "\"gpu\":$(get_gpu),"
        echo "\"memory\":$(get_memory),"
        echo "\"disk\":$(get_disk)"
        echo "}"
        ;;
    --daemon)
        OUTPUT="${2:-$(dirname "$0")/system_info.json}"
        echo "Daemon writing to $OUTPUT (PID $$)" >&2
        trap 'rm -f "$OUTPUT"; exit 0' INT TERM
        counter=0
        # Pre‑declare disk_data variable
        disk_data=""
        while true; do
            cpu_data=$(get_cpu)
            gpu_data=$(get_gpu)
            mem_data=$(get_memory)
            # Update disk only once per minute (60 iterations)
            if [ $((counter % 60)) -eq 0 ]; then
                disk_data=$(get_disk)
            fi
            {
                echo "{"
                echo "\"cpu\": $cpu_data,"
                echo "\"gpu\": $gpu_data,"
                echo "\"memory\": $mem_data,"
                echo "\"disk\": $disk_data"
                echo "}"
            } > "$OUTPUT"
            counter=$((counter + 1))
            sleep 1
        done
        ;;
    *)
        echo "Usage: $0 {cpu|gpu|memory|disk|apps|all|--daemon [file]}"
        exit 1
        ;;
esac