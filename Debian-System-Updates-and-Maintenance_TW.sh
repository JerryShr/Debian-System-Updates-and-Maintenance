#!/bin/bash

# 檢查是否為root用戶
if [ "$(id -u)" -ne 0 ]; then
    echo "請使用 sudo 執行此腳本"
    exit 1
fi

# 定義彩色輸出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # 重置顏色

# 函數：顯示步驟標題
print_step() {
    echo -e "\n${YELLOW}[步驟 $1] $2${NC}"
    echo "--------------------------------"
}

# 函數：執行命令並檢查狀態
run_command() {
    echo -e "執行命令: ${GREEN}$1${NC}"
    eval "$1"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ 操作成功${NC}\n"
        return 0
    else
        echo -e "${RED}✗ 操作失敗${NC}\n"
        return 1
    fi
}

# ======================
# 第一部分：系統更新流程
# ======================
print_step "01" "更新軟件包清單 (同步倉庫資訊)"
run_command "apt update"

print_step "02" "升級可更新軟件包"
run_command "apt upgrade -y"

print_step "03" "完整系統升級 (處理依賴變更)"
run_command "apt full-upgrade -y"
run_command "apt dist-upgrade -y"

# 顯示內核更新信息
CURRENT_KERNEL=$(uname -r)
echo -e "\n當前運行內核版本: ${GREEN}${CURRENT_KERNEL}${NC}"
echo -e "更新後請重啟系統使新內核生效"

# ======================
# 第二部分：清理系統冗餘
# ======================
print_step "01" "清理無用依賴包"
run_command "apt autoremove -y"

print_step "02" "移除軟件包緩存"
run_command "apt clean"

print_step "03" "清除殘留配置文件"
# 安全處理空列表情況
CONFIG_LIST=$(dpkg -l | awk '/^rc/{print $2}')
if [ -n "$CONFIG_LIST" ]; then
    run_command "dpkg --purge $CONFIG_LIST"
else
    echo -e "${GREEN}✓ 沒有殘留配置文件需要清理${NC}"
fi

# ======================
# 第三部分：更新系統文檔
# ======================
print_step "01" "安裝文檔工具"
# 安裝必要的文檔工具包
run_command "apt install man-db info install-info -y"

print_step "02" "更新 man 手冊頁"
# 使用絕對路徑執行命令
run_command "/usr/bin/mandb"

print_step "03" "更新 info 文檔"
# 替代方案：使用 install-info 命令更新文檔
run_command "find /usr/share/info -name '*.info.gz' -exec install-info --dir-file=/usr/share/info/dir {} \;"

# ======================
# 完成提示
# ======================
echo -e "\n${GREEN}系統更新與維護已完成！${NC}"
echo -e "建議執行 ${YELLOW}重啟系統${NC} 以應用所有更新"
echo -e "請執行: ${GREEN}sudo reboot${NC}"