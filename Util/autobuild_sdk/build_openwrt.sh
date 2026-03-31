#!/bin/bash

# ==============================================================
# Generic OpenWrt Build Script (Step 3 Only)
# ==============================================================

# --- Color Definitions ---
YELLOW='\e[1;33m'
RED='\e[1;31m'
GREEN='\e[1;32m'
NC='\e[0m'

# --- 1. Usage & Verification ---
show_usage() {
    echo -e "${YELLOW}Usage:${NC}"
    echo -e "  SDK_VER_NAME=\"<version>\" $0 <source_root> <profile_name> [dl_folder] [j_count]"
    echo ""
    echo -e "${YELLOW}Description:${NC}"
    echo -e "  This is a generic OpenWrt compilation engine (Step 3 Only)."
    echo -e "  It MUST be called with the SDK_VER_NAME environment variable set."
    echo ""
    echo -e "${YELLOW}Arguments:${NC}"
    echo -e "  ${GREEN}<source_root>${NC}  (Required) Path to the prepared SDK directory"
    echo -e "  ${GREEN}<profile_name>${NC} (Required) Target profile (e.g., Board_A)"
    echo -e "  ${GREEN}[dl_folder]${NC}    (Optional) Kept for interface consistency"
    echo -e "  ${GREEN}[j_count]${NC}      (Optional) Number of CPU cores for compilation (default: 1)"
    exit 1
}

if [ "$1" = "--help" ] || [ "$1" = "-h" ] || [ "$#" -lt 2 ]; then
    show_usage
fi

if [ -z "$SDK_VER_NAME" ]; then
    echo -e "${RED}Error: SDK_VER_NAME environment variable is required but not set.${NC}"
    exit 1
fi

# --- 2. Arguments & Path Resolution ---
source_root=$1
profile_name=$2
dl_folder=${3:-""}
j_count=${4:-1}

if [ ! -d "$source_root" ]; then
    echo -e "${RED}Error: Source directory '$source_root' not found.${NC}"
    exit 1
fi
build_dir=$(cd "$source_root" && pwd)

# --- 3. Global Variables ---
log_file="${build_dir}/build_${profile_name}.log"
cmd_log="${build_dir}/cmd_history_${profile_name}.log"

export DRY_RUN=${DRY_RUN:-false}
export VERBOSE=${VERBOSE:-false}

# --- 4. Helper Functions ---
run_cmd() {
    local cmd="$*"
    local current_ts=$(date +'%H:%M:%S')

    if [ "$DRY_RUN" = false ]; then
        echo "[$current_ts] $cmd" >> "$cmd_log"
    fi

    if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}[$current_ts][DRY-RUN] Executing: $cmd${NC}"
    else
        echo -e "${YELLOW}[$current_ts] Executing: $cmd${NC}"
        eval "$cmd"
    fi
}

get_elapsed_time() {
    local start_time=$1
    local end_time=$2
    local elapsed=$(( end_time - start_time ))
    echo "$((elapsed / 60))m $((elapsed % 60))s"
}

# --- 5. Main Execution ---
START_TIME=$SECONDS

echo -e "\n${YELLOW}--- Processing Profile: $profile_name ---${NC}"
echo -e "${YELLOW}Build Directory: $build_dir${NC}"
echo -e "${YELLOW}Target SDK Ver:  $SDK_VER_NAME${NC}"

[ "$DRY_RUN" = false ] && set -e

if [ "$DRY_RUN" = false ]; then
    echo "--- Command History for $profile_name ---" >> "$cmd_log"
fi

# Step 3: SDK Compilation
echo -e "\n${YELLOW}--- Step 3: SDK Compilation ($profile_name) ---${NC}"
step_start=$SECONDS

run_cmd "cd $build_dir"
run_cmd "./setup_openwrt.sh $profile_name > $log_file 2>&1"

run_cmd "cd $build_dir/${SDK_VER_NAME}"

# Process dl_folder symlink if provided
if [ -n "$dl_folder" ]; then
    run_cmd "rm -rf $build_dir/${SDK_VER_NAME}/dl"
    run_cmd "ln -s $dl_folder $build_dir/${SDK_VER_NAME}/dl"
fi

run_cmd "yes 'x' | make menuconfig >> $log_file 2>&1"
run_cmd "yes 'x' | make kernel_menuconfig >> $log_file 2>&1"

if [ "$VERBOSE" = true ]; then
    run_cmd "make -j$j_count V=s 2>&1 | tee -a $log_file"
else
    run_cmd "make -j$j_count V=s >> $log_file 2>&1"
fi
EXIT_CODE=$?

step_end=$SECONDS
echo -e "${GREEN}Step 3 Duration ($profile_name): $(get_elapsed_time $step_start $step_end)${NC}"

if [ "$DRY_RUN" = false ]; then
    ELAPSED=$(( SECONDS - START_TIME ))
    DURATION_MSG="$(($ELAPSED / 60))m $(($ELAPSED % 60))s"
    if [ $EXIT_CODE -eq 0 ]; then
        echo -e "[$profile_name] ${GREEN}SUCCESS.${NC} (Compilation Time: $DURATION_MSG)"
    else
        echo -e "[$profile_name] ${RED}FAILED.${NC} (Compilation Time: $DURATION_MSG)"
        echo -e "  Log: $log_file"
    fi
fi

[ "$DRY_RUN" = false ] && set +e
exit $EXIT_CODE
