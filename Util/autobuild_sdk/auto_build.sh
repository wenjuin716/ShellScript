#!/bin/bash

# ==============================================================
# Multi-Profile Auto Build Script (Direct Script Integration Mode)
# ==============================================================

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
    echo -e "  --ts-dir         Include timestamp folder in the build path."
    echo -e "  --help, -h       Show this help message."
    echo ""
    echo -e "${YELLOW}Configuration File Variables (Required):${NC}"
    echo -e "  ${GREEN}SOURCE_CODE_DIR${NC} Path to the source code (e.g., \"workspace/releases/wrt_prpl410\")"
    echo -e "  ${GREEN}XML_NAME${NC}        XML file path (e.g., \"releases/wrt_prpl410.xml\")"
    echo -e "  ${GREEN}PROFILES${NC}        Comma-separated profiles (e.g., \"profile1, profile2\")"
    echo -e "  ${GREEN}BUILD_ROOT_DIR${NC}  Root folder for build outputs. (Must exist before running)"
    echo ""
    echo -e "${YELLOW}Configuration File Variables (Optional):${NC}"
    echo -e "  ${GREEN}DOWNLOAD_DIR${NC}    Path to shared 'dl' folder to symlink (e.g., \"/Yocto/dl\",\"~/downloads\")"
    echo -e "  ${GREEN}FEED_TARBALL${NC}    Filename or path of the feeds tarball to extract"
    exit 1
}

# --- 2. Argument & Option Pre-check ---
export DRY_RUN=false
export VERBOSE=false
export USE_TS_IN_DIR=false
USE_NPROC=false

ARGS=()
for arg in "$@"; do
    case $arg in
        --dry-run) export DRY_RUN=true ;;
        --verbose) export VERBOSE=true ;;
        --j-nproc) USE_NPROC=true ;;
        --ts-dir) export USE_TS_IN_DIR=true ;;
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

# --- 4. Helper Functions ---
run_cmd() {
    local cmd="$*"
    local current_ts=$(date +'%H:%M:%S')

    if [ "$DRY_RUN" = false ] && [ -n "$CURRENT_CMD_LOG" ]; then
        echo "[$current_ts] $cmd" >> "$CURRENT_CMD_LOG"
    fi

    if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}[$current_ts][DRY-RUN] Executing: $cmd${NC}"
    else
        echo -e "${YELLOW}[$current_ts] Executing: $cmd${NC}"
        eval "$cmd"
    fi
}

get_build_dir() {
    local xml_full_path=$1
    local ts=$2
    local profile_name=$3

    local xml_dir_path=$(echo "$xml_full_path" | sed 's|.xml$||')
    if [ "$USE_TS_IN_DIR" = true ]; then
        echo "${ABS_BUILD_ROOT}/${xml_dir_path}/${ts}/${profile_name}"
    else
        echo "${ABS_BUILD_ROOT}/${xml_dir_path}/${profile_name}"
    fi
}

get_elapsed_time() {
    local start_time=$1
    local end_time=$2
    local elapsed=$(( end_time - start_time ))
    echo "$((elapsed / 60))m $((elapsed % 60))s"
}

checkout_new_sdk() {
    local source_root=$1
    local build_dir=$2

    if [ -d "$build_dir" ]; then
        run_cmd "rm -rf $build_dir 2>/dev/null"
    fi

    local parent_dir=$(dirname "$build_dir")
    if [ ! -d "$parent_dir" ]; then
        run_cmd "mkdir -p $parent_dir"
    fi

    run_cmd "cp -rf $source_root $build_dir 2>/dev/null"
}

collect_data() {
    local profile_name=$1
    local build_dir=$2
    :
}

release_resource() {
    local profile_name=$1
    local build_dir=$2
    :
}

# ==============================================================
# --- 5. Main Pipeline Orchestrator ---
# ==============================================================
run_build_pipeline() {
    local profile_name=$1
    local ts=$2
    local build_dir=$(get_build_dir "$XML_NAME" "$ts" "$profile_name")
    
    local log_file="${build_dir}/build_${profile_name}.log"
    local cmd_log="${build_dir}/cmd_history_${profile_name}.log"
    local START_TIME=$SECONDS
    local step_start
    local step_end

    echo -e "\n${YELLOW}--- Processing Profile: $profile_name ---${NC}"
    echo -e "${YELLOW}Build Directory: $build_dir${NC}"

    # Step 1: Checkout
    echo -e "\n${YELLOW}--- Step 1: Checkout new SDK ($profile_name) ---${NC}"
    step_start=$SECONDS
    checkout_new_sdk "$SOURCE_ROOT" "$build_dir"
    step_end=$SECONDS
    echo -e "${GREEN}Step 1 Duration: $(get_elapsed_time $step_start $step_end)${NC}"

    [ "$DRY_RUN" = false ] && set -e

    if [ "$DRY_RUN" = false ]; then
        export CURRENT_CMD_LOG="$cmd_log"
        echo "--- Command History for $profile_name ---" > "$cmd_log"
    else
        unset CURRENT_CMD_LOG
    fi

    # Step 2: SDK Preparation
    echo -e "\n${YELLOW}--- Step 2: SDK Preparation ($profile_name) ---${NC}"
    step_start=$SECONDS
    run_cmd "cd $build_dir"
    run_cmd "repo start ${ts} --all"

    # Specific preparation for OpenWrt based platforms (extract feed tarball if provided)
    if [[ "$TARGET_SCRIPT" != *"usdk"* ]]; then
        local sdk_ver=""
        [[ "$XML_NAME" == *"prpl410"* ]] && sdk_ver="prplos-prplware-v4.1.0"
        [[ "$XML_NAME" == *"2410"* ]] && sdk_ver="openwrt-24.10.4"

        if [ -n "$sdk_ver" ] && [ -n "$ABS_FEED_TARBALL" ]; then
            if [ -f "$ABS_FEED_TARBALL" ]; then
                run_cmd "cd $build_dir/$sdk_ver"
                run_cmd "tar jxvf $ABS_FEED_TARBALL >> $log_file 2>&1"
                run_cmd "cd $build_dir"
            else
                echo -e "${YELLOW}[Warning] FEED_TARBALL ($ABS_FEED_TARBALL) not found.${NC}"
            fi
        fi
    fi
    step_end=$SECONDS
    echo -e "${GREEN}Step 2 Duration: $(get_elapsed_time $step_start $step_end)${NC}"

    # Step 3: Compilation (Delegated to external scripts)
    # Notice: We pass $build_dir as the <source_root> argument to the external script
    bash "$TARGET_SCRIPT" "$build_dir" "$profile_name" "$DOWNLOAD_DIR" "$J_VAL"
    local EXIT_CODE=$?

    # Step 4: Data Collection
    echo -e "\n${YELLOW}--- Step 4: Data Collection ($profile_name) ---${NC}"
    step_start=$SECONDS
    collect_data "$profile_name" "$build_dir"
    step_end=$SECONDS
    echo -e "${GREEN}Step 4 Duration: $(get_elapsed_time $step_start $step_end)${NC}"

    # Step 5: Release Resource
    echo -e "\n${YELLOW}--- Step 5: Release Resource ($profile_name) ---${NC}"
    step_start=$SECONDS
    release_resource "$profile_name" "$build_dir"
    step_end=$SECONDS
    echo -e "${GREEN}Step 5 Duration: $(get_elapsed_time $step_start $step_end)${NC}"

    if [ "$DRY_RUN" = false ]; then
        local ELAPSED=$(( SECONDS - START_TIME ))
        local DURATION_MSG="$(($ELAPSED / 60))m $(($ELAPSED % 60))s"
        if [ $EXIT_CODE -eq 0 ]; then
            echo -e "[$profile_name] ${GREEN}SUCCESS.${NC} (Total: $DURATION_MSG)"
        else
            echo -e "[$profile_name] ${RED}FAILED.${NC} (Total: $DURATION_MSG)"
            echo -e "  Log: $log_file"
        fi
    fi
    [ "$DRY_RUN" = false ] && set +e
}


# ==============================================================
# --- 6. Main Setup & Script Dispatch ---
# ==============================================================
TIMESTAMP=$(date +"%y%m%d%H%M%S")
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

# Resolve FEED_TARBALL to absolute path
if [ -n "$FEED_TARBALL" ]; then
    if [[ "$FEED_TARBALL" == /* || "$FEED_TARBALL" == ~* ]]; then
        eval ABS_FEED_TARBALL="$FEED_TARBALL"
    else
        ABS_FEED_TARBALL="${TOP_DIR}/${FEED_TARBALL}"
    fi
    export ABS_FEED_TARBALL
fi

# Mandatory Check
if [ ! -d "$ABS_BUILD_ROOT" ]; then
    echo -e "${RED}Error: BUILD_ROOT_DIR '$ABS_BUILD_ROOT' does not exist.${NC}"
    exit 1
fi

J_VAL=1
[ "$USE_NPROC" = true ] && J_VAL=$(nproc)

# --- Target Script Detection Logic ---
if [[ "$XML_NAME" == *"usdk"* ]]; then
    TARGET_SCRIPT="$(dirname "$0")/build_usdk_series.sh"
else
    FUNC_SUFFIX=$(echo "$XML_NAME" | sed 's|/|-|g' | sed 's|\.|_|g')
    TARGET_SCRIPT="$(dirname "$0")/build_${FUNC_SUFFIX}.sh"
    
    # Fallback to check if the script is named without "_xml"
    if [ ! -f "$TARGET_SCRIPT" ]; then
        FUNC_SUFFIX_NO_XML=$(echo "$FUNC_SUFFIX" | sed 's|_xml$||')
        TARGET_SCRIPT="$(dirname "$0")/build_${FUNC_SUFFIX_NO_XML}.sh"
    fi
fi

if [ ! -f "$TARGET_SCRIPT" ]; then
    echo -e "${RED}Error: Target build script '$TARGET_SCRIPT' not found for XML: $XML_NAME${NC}"
    exit 1
fi

IFS=',' read -ra PROFILE_ARRAY <<< "$PROFILES"

# Display Config Settings
echo -e "\n${GREEN}====================================${NC}"
echo -e "${YELLOW}Config File:     $CONFIG_FILE${NC}"
echo -e "${YELLOW}Source Code Dir: $ABS_SOURCE_CODE_DIR${NC}"
echo -e "${YELLOW}XML Name:        $XML_NAME${NC}"
echo -e "${YELLOW}Target Script:   $TARGET_SCRIPT${NC}"
echo -e "${YELLOW}Build Root:      $ABS_BUILD_ROOT${NC}"
echo -e "${YELLOW}Build Mode:      -j$J_VAL${NC}"
if [ -n "$ABS_FEED_TARBALL" ]; then
    echo -e "${YELLOW}Feed Tarball:    $ABS_FEED_TARBALL${NC}"
fi
echo -e "${YELLOW}Timestamp:       $TIMESTAMP${NC}"
[ "$USE_TS_IN_DIR" = true ] && echo -e "${YELLOW}Use TS in Dir:   ON${NC}"
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
        run_build_pipeline "$profile_trimmed" "$TIMESTAMP"
    else
        run_build_pipeline "$profile_trimmed" "$TIMESTAMP" &
        sleep 1
    fi
done

[ "$DRY_RUN" = false ] && [ "$VERBOSE" = false ] && wait
echo -e "\n${GREEN}--- All Tasks Finished ---${NC}"
