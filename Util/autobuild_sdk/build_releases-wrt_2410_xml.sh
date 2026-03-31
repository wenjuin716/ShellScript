#!/bin/bash

# --- Color Definitions ---
YELLOW='\e[1;33m'
GREEN='\e[1;32m'
NC='\e[0m'

# --- 1. Usage Function ---
show_usage() {
    echo -e "${YELLOW}Usage:${NC}"
    echo -e "  $0 <source_root> <profile_name> [dl_folder] [j_count]"
    echo ""
    echo -e "${YELLOW}Description:${NC}"
    echo -e "  This script executes Step 3: SDK Compilation specifically for wrt_2410 (openwrt-24.10.4)."
    echo -e "  It serves as a wrapper and delegates the actual build process to build_openwrt.sh."
    echo ""
    echo -e "${YELLOW}Arguments:${NC}"
    echo -e "  ${GREEN}<source_root>${NC}  (Required) Path to the prepared SDK directory"
    echo -e "  ${GREEN}<profile_name>${NC} (Required) Target profile (e.g., Board_A)"
    echo -e "  ${GREEN}[dl_folder]${NC}    (Optional) Path to the shared dl folder"
    echo -e "  ${GREEN}[j_count]${NC}      (Optional) Number of CPU cores for compilation (default: 1)"
    exit 1
}

# --- 2. Argument Check ---
if [ "$1" = "--help" ] || [ "$1" = "-h" ] || [ "$#" -lt 2 ]; then
    show_usage
fi

# --- 3. Delegate to Generic Engine ---
# Define the specific SDK version for wrt_2410
export SDK_VER_NAME="openwrt-24.10.4"

# Delegate all arguments to the generic OpenWrt build engine
bash "$(dirname "$0")/build_openwrt.sh" "$@"
