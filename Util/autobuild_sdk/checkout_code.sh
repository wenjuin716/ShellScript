#!/bin/bash

# ==================================
# Repo Sync Script
# Goal: Prepare workspace and sync source code
# ==================================

# --- Default Configuration ---
GIT_ROOT_DIR_ORIG="~/workspace"
DRY_RUN=false

# Colors for output
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# --- Options Lists ---
url_options=(
    "ssh://cn2sd5.rtkbf.com:29418/rlxlinux/manifest"
    "Quit"
)

file_options=(
    "releases/usdk_v2_2_0.xml"
    "releases/usdk_v2_2_0_FTTR.xml"
    "releases/usdk_v2_2_0_FTTR_release.xml"
    "releases/usdk_v2_2_0_CMCC_NSB_20250606.xml"
    "releases/wrt_prpl410.xml"
    "releases/wrt_2410.xml"
    "Quit"
)

# --------------------------------
## 1. Help Function
# --------------------------------
show_help() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help            Show this help message and exit."
    echo "  -d, --dir DIR_PATH    Specify the root directory for Git workspace."
    echo "                        Default: ~/workspace"
    echo "  -n, --dry-run         Show commands that would be executed without running them."
    echo ""
    echo "Available Manifest URLs:"
    for url in "${url_options[@]}"; do
        [[ "$url" != "Quit" ]] && echo "  - $url"
    done
    echo ""
    echo "Available Manifest Files:"
    for file in "${file_options[@]}"; do
        [[ "$file" != "Quit" ]] && echo "  - $file"
    done
    echo ""
    exit 0
}

# --------------------------------
## 2. Parse Arguments
# --------------------------------
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help) show_help ;;
        -d|--dir) GIT_ROOT_DIR_ORIG="$2"; shift ;;
        -n|--dry-run) DRY_RUN=true ;;
        *) echo "Unknown parameter passed: $1"; show_help ;;
    esac
    shift
done

eval GIT_ROOT_DIR="$GIT_ROOT_DIR_ORIG"

# --------------------------------
## 3. Helper Functions
# --------------------------------
run_cmd() {
    local cmd="$*"

    if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}[DRY-RUN] Executing: $cmd${NC}"
    else
        # 使用 eval 確保 cd 指令能正確改變主腳本的工作目錄
        eval "$cmd"
    fi
}

# --------------------------------
## 4. Menu Logic (Mandatory Selection)
# --------------------------------
echo "--- Repo Sync Interactive Mode ---"
[[ "$DRY_RUN" = true ]] && echo -e "${YELLOW}!!! DRY RUN MODE ENABLED !!!${NC}"
echo "Root Directory: $GIT_ROOT_DIR"
echo "Log File:       $CURRENT_CMD_LOG"
echo "--------------------------------"

# Step 1: Select MANIFEST_URL
echo "Please select a Manifest URL:"
select url_opt in "${url_options[@]}"; do
    case $url_opt in
        "Quit") exit 0 ;;
        "") echo "Invalid option." ;;
        *) MANIFEST_URL=$url_opt; break ;;
    esac
done

echo "--------------------------------"

# Step 2: Select MANIFEST_FILE
echo "Please select a Manifest File Path:"
select file_opt in "${file_options[@]}"; do
    case $file_opt in
        "Quit") exit 0 ;;
        "") echo "Invalid option." ;;
        *) MANIFEST_FILE=$file_opt; break ;;
    esac
done

# Determine target directory
TARGET_DIR_NAME=${MANIFEST_FILE%.xml}
LOCAL_WORKSPACE="$GIT_ROOT_DIR/$TARGET_DIR_NAME"

# --------------------------------
## 5. Directory Preparation & Backup Logic
# --------------------------------
if [ ! -d "$GIT_ROOT_DIR" ]; then 
    run_cmd mkdir -p "$GIT_ROOT_DIR" 
fi

if [ -d "$LOCAL_WORKSPACE" ]; then
    echo "Warning: '$LOCAL_WORKSPACE' already exists."
    actions=("Move to backup (Default)" "Remove existing directory" "Keep and continue" "Abort")
    
    echo "Please choose an action for the existing directory:"
    select action in "${actions[@]}"; do
        case $REPLY in
            1|"") 
                BACKUP_PATH="${LOCAL_WORKSPACE}_backup_$(date +%Y%m%d_%H%M%S)"
                echo "Backing up to $BACKUP_PATH..."
                run_cmd mv "$LOCAL_WORKSPACE" "$BACKUP_PATH"
                run_cmd mkdir -p "$LOCAL_WORKSPACE"
                break ;;
            2) 
                echo "Removing $LOCAL_WORKSPACE..."
                run_cmd rm -rf "$LOCAL_WORKSPACE"
                run_cmd mkdir -p "$LOCAL_WORKSPACE"
                break ;;
            3) 
                echo "Continuing with current directory."
                break ;;
            4) 
                exit 0 ;;
            *) 
                echo "Invalid selection." ;;
        esac
    done
else
    run_cmd mkdir -p "$LOCAL_WORKSPACE"
fi

# --------------------------------
## 6. Repo Initialization & Sync
# --------------------------------
echo "--- Initializing & Syncing Repo ---"
echo "URL:  $MANIFEST_URL"
echo "File: $MANIFEST_FILE"
echo "Dir:  $LOCAL_WORKSPACE"
echo "--------------------------------"

# 使用引號包裹指令，確保 eval 解析正確
run_cmd "cd \"$LOCAL_WORKSPACE\"" || exit 1
run_cmd "repo init -u $MANIFEST_URL -m $MANIFEST_FILE"
run_cmd "repo sync -j1"

if [ "$DRY_RUN" = false ]; then
# 檢查 Repo 指令執行狀態
if [ $? -eq 0 ]; then
    echo "--------------------------------"
    echo "Success: Source code synced at $LOCAL_WORKSPACE"
    echo "You can run to trigger auto build procedure: auto_build.sh -h"
else
    echo "--------------------------------"
    echo "Error: Repo sync failed."
    exit 1
fi
fi
