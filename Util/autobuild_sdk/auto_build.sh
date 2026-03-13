#!/bin/bash

# ==================================
# Multi-Profile Auto Build Script (Dynamic Function Mode)
# ==================================

# --- Color Definitions ---
YELLOW='\e[1;33m'
RED='\e[1;31m'
GREEN='\e[1;32m'
NC='\e[0m' # No Color

# --- 1. Usage Function ---
show_usage() {
    echo -e "${YELLOW}Usage:${NC}"
    echo -e "  $0 <auto_build_config> [options]"
    echo ""
    echo -e "${YELLOW}Options:${NC}"
    echo -e "  --dry-run        Show commands without executing them."
    echo -e "  --verbose        Show real-time compilation output (Sequential build)."
    echo -e "  --j-nproc        Use all CPU cores for compilation (default is -j1)."
    echo -e "  --help, -h       Show this help message."
    echo ""
    echo -e "${YELLOW}Configuration File Variables (Required):${NC}"
    echo -e "  ${GREEN}SOURCE_CODE_DIR${NC} Path to the source code (e.g., \"workspace/releases/wrt_prpl410\")"
    echo -e "  ${GREEN}XML_NAME${NC}        XML file path (e.g., \"releases/wrt_prpl410.xml\")"
    echo -e "  ${GREEN}PROFILES${NC}        Comma-separated profiles (e.g., \"profile1, profile2\")"
    echo -e "  ${GREEN}BUILD_ROOT_DIR${NC}  Root folder for build outputs. (Must exist before running)"
    echo ""
    echo -e "${YELLOW}Configuration File Variables (Optional):${NC}"
    echo -e "  ${GREEN}DOWNLOAD_DIR${NC}    Path to shared 'dl' folder to symlink (e.g., \"/Yocto/dl\")"
    echo ""
    echo -e "${YELLOW}Example Config (.conf):${NC}"
    echo -e "  SOURCE_CODE_DIR=\"/path/to/sdk/folder\""
    echo -e "  XML_NAME=\"releases/wrt_prpl410.xml\""
    echo -e "  PROFILES=\"Board_A, Board_B\""
    echo -e "  BUILD_ROOT_DIR=\"/path/to/build/folder\""
    exit 1
}

# --- 2. Argument & Option Pre-check ---
DRY_RUN=false
VERBOSE=false
USE_NPROC=false

ARGS=()
for arg in "$@"; do
    case $arg in
        --dry-run) DRY_RUN=true ;;
        --verbose) VERBOSE=true ;;
        --j-nproc) USE_NPROC=true ;;
        --help|-h) show_usage ;;
        *) ARGS+=("$arg") ;;
    esac
done

if [ "${#ARGS[@]}" -lt 1 ]; then
    show_usage
fi

CONFIG_FILE="${ARGS[0]}"

# --- 3. Load Configuration ---
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}Error: Configuration file '$CONFIG_FILE' not found.${NC}"
    exit 1
fi

source "$CONFIG_FILE"

# Validate Mandatory Fields
if [ -z "$SOURCE_CODE_DIR" ] || [ -z "$XML_NAME" ] || [ -z "$PROFILES" ] || [ -z "$BUILD_ROOT_DIR" ]; then
    echo -e "${RED}Error: Missing required fields in $CONFIG_FILE.${NC}"
    echo -e "${YELLOW}Please check --help for required variables.${NC}"
    exit 1
fi

eval EXPANDED_BUILD_ROOT="$BUILD_ROOT_DIR"

# --- 4. Mockable Execution Function ---
run_cmd() {
    local cmd="$*"
    local current_ts=$(date +'%H:%M:%S')

    # Log to file (if not dry run and log path is defined)
    if [ "$DRY_RUN" = false ] && [ -n "$CURRENT_CMD_LOG" ]; then
        echo "[$current_ts] $cmd" >> "$CURRENT_CMD_LOG"
    fi

    # Display to console (Mandatory for both Normal and Dry-run)
    if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}[$current_ts][DRY-RUN] Executing: $cmd${NC}"
    else
        echo -e "${YELLOW}[$current_ts] Executing: $cmd${NC}"
        eval "$cmd"
    fi
}

# --- 5. Build Function for releases-wrt_prpl410_xml ---
build_single_profile_releases-wrt_prpl410_xml() {
    local profile_name=$1
    local source_root=$2
    local xml_full_path=$3
    local ts=$4
    local dl_folder=$5
    local j_count=$6

    local xml_dir_path=$(echo "$xml_full_path" | sed 's|.xml$||')
    local build_dir="${ABS_BUILD_ROOT}/${xml_dir_path}/${ts}/${profile_name}"

    local log_file="${build_dir}/build_${profile_name}_${ts}.log"
    local cmd_log="${build_dir}/cmd_history_${profile_name}.log"
    local START_TIME=$SECONDS
    
    if [ "$DRY_RUN" = false ]; then
        export CURRENT_CMD_LOG="$cmd_log"
        mkdir -p "$build_dir"
        echo "--- Command History for $profile_name ---" > "$cmd_log"
    else
        unset CURRENT_CMD_LOG
    fi

    echo -e "\n${YELLOW}--- Processing Profile: $profile_name ---${NC}"
    echo -e "${YELLOW}Build Directory: $build_dir${NC}"
    
    local out_target="/dev/null"
    [ "$VERBOSE" = true ] && out_target="/dev/stdout"

    # Step 1: Directory Preparation
    if [ -d "$build_dir" ]; then
        run_cmd "rm -rf $build_dir 2>/dev/null"
    fi
    run_cmd "cp -rf $source_root $build_dir 2>/dev/null"

    [ "$DRY_RUN" = false ] && set -e

    # Step 2: Environment Setup
    run_cmd "cd $build_dir/prplos-prplware-v4.1.0"
    eval REAL_DL_PATH="$dl_folder"
    if [ -n "$REAL_DL_PATH" ]; then
      run_cmd "rm -f $build_dir/prplos-prplware-v4.1.0/dl"
      run_cmd "ln -s $REAL_DL_PATH $build_dir/prplos-prplware-v4.1.0/dl"
    fi
    run_cmd "cd $build_dir"
    
    run_cmd "./setup_openwrt.sh $profile_name > $log_file 2>&1"
    
    run_cmd "cd $build_dir/prplos-prplware-v4.1.0"
    run_cmd "make defconfig >> $log_file 2>&1"
    run_cmd "yes 'x' | make kernel_menuconfig >> $log_file 2>&1"

    # Step 3: Compilation
    if [ "$VERBOSE" = true ]; then
        run_cmd "make -j$j_count V=s 2>&1 | tee -a $log_file"
    else
        run_cmd "make -j$j_count V=s >> $log_file 2>&1"
    fi

    local EXIT_CODE=$?
    if [ "$DRY_RUN" = false ]; then
        local ELAPSED=$(( SECONDS - START_TIME ))
        local DURATION_MSG="$(($ELAPSED / 60))m $(($ELAPSED % 60))s"
        if [ $EXIT_CODE -eq 0 ]; then
            echo -e "[$profile_name] ${GREEN}SUCCESS.${NC} ($DURATION_MSG)"
        else
            echo -e "[$profile_name] ${RED}FAILED.${NC} ($DURATION_MSG)"
            echo -e "  Log: $log_file"
        fi
    fi
    [ "$DRY_RUN" = false ] && set +e
}

# --- 6. Main Loop & Function Dispatcher ---
TIMESTAMP=$(date +"%y%m%d%H%M")
TOP_DIR=$(pwd)

# Resolve Paths
if [[ "$SOURCE_CODE_DIR" == /* || "$SOURCE_CODE_DIR" == ~* ]]; then
    eval ABS_SOURCE_CODE_DIR="$SOURCE_CODE_DIR"
else
    ABS_SOURCE_CODE_DIR="${TOP_DIR}/${SOURCE_CODE_DIR}"
fi
SOURCE_ROOT="$ABS_SOURCE_CODE_DIR"

if [[ "$EXPANDED_BUILD_ROOT" == /* ]]; then
    ABS_BUILD_ROOT="$EXPANDED_BUILD_ROOT"
else
    ABS_BUILD_ROOT="${TOP_DIR}/${EXPANDED_BUILD_ROOT}"
fi

# Mandatory Check
if [ ! -d "$ABS_BUILD_ROOT" ]; then
    echo -e "${RED}Error: BUILD_ROOT_DIR '$ABS_BUILD_ROOT' does not exist.${NC}"
    echo -e "${YELLOW}Please create the directory manually before running.${NC}"
    exit 1
fi

J_VAL=1
[ "$USE_NPROC" = true ] && J_VAL=$(nproc)

# Function dispatch
FUNC_SUFFIX=$(echo "$XML_NAME" | sed 's|/|-|g' | sed 's|\.|_|g')
TARGET_FUNC="build_single_profile_${FUNC_SUFFIX}"

if ! declare -f "$TARGET_FUNC" > /dev/null; then
    echo -e "${RED}Error: Build function '$TARGET_FUNC' not defined for XML: $XML_NAME${NC}"
    exit 1
fi

IFS=',' read -ra PROFILE_ARRAY <<< "$PROFILES"

# Display Config Settings
echo -e "\n${GREEN}====================================${NC}"
echo -e "${YELLOW}Config File:     $CONFIG_FILE${NC}"
echo -e "${YELLOW}Source Code Dir: $ABS_SOURCE_CODE_DIR${NC}"
echo -e "${YELLOW}XML Name:        $XML_NAME${NC}"
echo -e "${YELLOW}Build Root:      $ABS_BUILD_ROOT${NC}"
echo -e "${YELLOW}Build Mode:      -j$J_VAL${NC}"
echo -e "${YELLOW}Timestamp:       $TIMESTAMP${NC}"
[ "$VERBOSE" = true ] && echo -e "${YELLOW}Verbose Mode:    ON${NC}"
[ "$DRY_RUN" = true ] && echo -e "${YELLOW}!!! DRY-RUN MODE ENABLED !!!${NC}"
echo -e "${GREEN}------------------------------------${NC}"
echo -e "${YELLOW}Target Profiles:${NC}"
for p in "${PROFILE_ARRAY[@]}"; do
    echo -e "  - $(echo "$p" | xargs)"
done
echo -e "${GREEN}====================================${NC}"

# Execution Loop
for profile in "${PROFILE_ARRAY[@]}"; do
    profile_trimmed=$(echo "$profile" | xargs)
    if [ "$DRY_RUN" = true ]; then
        $TARGET_FUNC "$profile_trimmed" "$SOURCE_ROOT" "$XML_NAME" "$TIMESTAMP" "$DOWNLOAD_DIR" "$J_VAL"
    else
        $TARGET_FUNC "$profile_trimmed" "$SOURCE_ROOT" "$XML_NAME" "$TIMESTAMP" "$DOWNLOAD_DIR" "$J_VAL" &
        sleep 1
    fi
done

[ "$DRY_RUN" = false ] && [ "$VERBOSE" = false ] && wait
echo -e "\n${GREEN}--- All Tasks Finished ---${NC}"
