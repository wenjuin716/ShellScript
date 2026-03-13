#!/bin/bash

# ==========================================================
# 使用說明:
# ./check_commits.sh --since "2026-03-11 00:00:00" [--keyword "DEBUG"] [--project "name"]
#
# 參數說明:
# --since   : (必要) 格式 "YYYY-MM-DD HH:MM:SS"
# --keyword : (選填) 搜尋內容關鍵字，忽略大小寫
# --project : (選填) 指定專案名稱 (對應 XML 中的 name)
# ==========================================================

# 1. 初始化變數
SINCE_TIME=""
KEYWORD=""
TARGET_PROJECTS=""

# 2. 解析參數
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --since) SINCE_TIME="$2"; shift ;;
        --keyword) KEYWORD="$2"; shift ;;
        --project) TARGET_PROJECTS="$2"; shift ;;
        *) echo "未知參數: $1"; exit 1 ;;
    esac
    shift
done

# 3. 必要參數檢查
if [ -z "$SINCE_TIME" ]; then
    echo "=========================================================="
    echo "用法說明 (Usage Examples):"
    echo "=========================================================="
    echo "1. 基本用法：列出所有專案在特定時間後的 Commit"
    echo "   $0 --since \"2026-03-11 00:00:00\""
    echo ""
    echo "2. 特定專案清單：列出指定專案（不篩選關鍵字）的 Commit"
    echo "   $0 --since \"2026-03-11 00:00:00\" --project \"rtk_openwrt pon/oam\""
    echo ""
    echo "3. 關鍵字搜尋：搜尋所有專案內容中包含 'limit' 的修改"
    echo "   $0 --since \"2026-03-11 00:00:00\" --keyword \"limit\""
    echo ""
    echo "4. 精確搜尋：在指定專案中搜尋特定關鍵字並顯示 Diff"
    echo "   $0 --since \"2026-03-11 00:00:00\" --keyword \"limit\" --project \"rtk_openwrt pon/oam\""
    echo ""
    echo "5. 輸出至檔案："
    echo "   $0 --since \"2026-03-11 00:00:00\" --keyword \"limit\" > report.log"
    echo "=========================================================="
    exit 1
fi

echo "----------------------------------------------------------"
echo "起始時間   : $SINCE_TIME"
echo "關鍵字     : ${KEYWORD:- (無，僅列出所有 Commit)}"
echo "指定專案   : ${TARGET_PROJECTS:- (所有專案)}"
echo "----------------------------------------------------------"

# 4. 執行 Repo Forall
# repo 會自動解析包含在 wrt_2410.xml 內部的 wrt.xml 專案
repo forall $TARGET_PROJECTS -c '
    # 取得 Commit 列表
    COMMITS=$(git rev-list --since="'"$SINCE_TIME"'" HEAD)
    
    if [ ! -z "$COMMITS" ]; then
        MATCHED_CONTENT=""
        
        for rev in $COMMITS; do
            # 取得基礎資訊與 Change-Id
            INFO=$(git log -1 --pretty=format:"%h | %ai | %s | %(trailers:key=Change-Id,valueonly=true)" $rev)
            
            if [ -z "'"$KEYWORD"'" ]; then
                # 模式 A: 純清單
                MATCHED_CONTENT="${MATCHED_CONTENT}\n$INFO"
            else
                # 模式 B: 搜尋內容 (忽略大小寫 -i)
                if git show $rev | grep -qi "'"$KEYWORD"'"; then
                    DIFF_SNIPPET=$(git show $rev | grep -i -C 2 "'"$KEYWORD"'")
                    MATCHED_CONTENT="${MATCHED_CONTENT}\n$INFO\n--- Diff Snippet ---\n$DIFF_SNIPPET\n--------------------"
                fi
            fi
        done

        # 輸出該專案結果
        if [ ! -z "$MATCHED_CONTENT" ]; then
            echo "=========================================================="
            echo "Project: $REPO_PROJECT ($REPO_PATH)"
            echo "=========================================================="
            echo -e "$MATCHED_CONTENT"
            echo -e ""
        fi
    fi
'
