#!/bin/bash
# tape_manager_advanced.sh - Advanced TUI for tape storage management with progress bars and auto-rewind option

# 配置部分
TAPE_DEVICE="/dev/nst0"
WORK_DIR="$HOME/tape_temp"
CONFIG_FILE="$HOME/.tape_manager.conf"
SNAPSHOT_FILE="$WORK_DIR/snapshot.db"
ENCRYPT_KEY=""
LANGUAGE="en"  # 默认语言: en/zh
BACKUP_COUNTER_FILE="$WORK_DIR/backup_counter.txt"
AUTO_REWIND_ON_EXIT="true"  # 退出时自动回卷磁带
BACKUP_MODE="append"  # 默认备份模式: append/overwrite

# 初始化配置
init_config() {
    echo "正在初始化配置..."
    
    # 加载配置文件
    if [ -f "$CONFIG_FILE" ]; then
        echo "加载现有配置文件: $CONFIG_FILE"
        source "$CONFIG_FILE"
    else
        echo "创建默认配置文件: $CONFIG_FILE"
        # 创建默认配置
        cat > "$CONFIG_FILE" <<-EOF
# Tape Manager Configuration
TAPE_DEVICE="/dev/nst0"
WORK_DIR="$HOME/tape_temp"
COMPRESSION="gzip"
ENCRYPTION="none"
ENCRYPT_KEY=""
BACKUP_TYPE="full"
BACKUP_MODE="append"
LANGUAGE="en"
AUTO_REWIND_ON_EXIT="true"
EOF
        if [ $? -eq 0 ]; then
            echo "默认配置文件创建成功"
            source "$CONFIG_FILE"
        else
            echo "错误: 无法创建配置文件"
            exit 1
        fi
    fi
    
    # 创建必要目录
    echo "创建工作目录: $WORK_DIR"
    mkdir -p "$WORK_DIR" || { echo "错误: 无法创建主工作目录"; exit 1; }
    mkdir -p "$WORK_DIR/extracted" || { echo "错误: 无法创建提取目录"; exit 1; }
    mkdir -p "$WORK_DIR/backups" || { echo "错误: 无法创建备份目录"; exit 1; }
    
    # 初始化备份计数器
    if [ ! -f "$BACKUP_COUNTER_FILE" ]; then
        echo "0" > "$BACKUP_COUNTER_FILE" || { echo "错误: 无法创建备份计数器文件"; exit 1; }
    fi
    
    # 加载语言文件
    echo "加载语言文件..."
    load_language
    
    echo "配置初始化完成"
}

# 加载语言资源
load_language() {
    declare -gA msg
    
    if [ "$LANGUAGE" = "zh" ]; then
        # 中文翻译
        msg=(
            # 通用
            ["title"]="磁带存储管理器"
            ["exit"]="退出"
            ["back"]="返回"
            ["ok"]="确定"
            ["cancel"]="取消"
            ["error"]="错误"
            ["success"]="成功"
            ["warning"]="警告"
            
            # 主菜单
            ["main_menu"]="选择操作:"
            ["backup"]="备份到磁带"
            ["restore"]="从磁带恢复"
            ["list"]="列出磁带内容"
            ["verify"]="验证备份"
            ["tape_ops"]="磁带操作"
            ["config"]="配置"
            ["multi_volume"]="多卷管理"
            ["language"]="语言设置"
            
            # 备份
            ["select_backup"]="选择要备份的目录"
            ["backup_success"]="备份成功完成!"
            ["backup_failed"]="备份失败，请检查日志"
            ["backup_mode"]="选择备份模式:"
            ["overwrite_tape"]="覆盖整个磁带"
            ["append_tape"]="追加到磁带"
            ["position_error"]="磁带定位错误，无法追加备份"
            ["backup_count"]="当前备份序号: %d"
            ["backup_progress"]="备份进度"
            ["restore_progress"]="恢复进度"
            
            # 恢复
            ["restore_success"]="文件已恢复到 %s"
            ["restore_failed"]="恢复失败，请检查日志"
            ["select_backup_to_restore"]="选择要恢复的备份"
            ["no_backups_found"]="未找到备份"
            
            # 磁带操作
            ["rewind"]="回卷磁带"
            ["eject"]="弹出磁带"
            ["erase"]="擦除磁带"
            ["status"]="磁带状态"
            ["load"]="加载磁带"
            ["rewind_success"]="磁带已回卷"
            ["eject_success"]="磁带已弹出，可安全移除"
            ["erase_warning"]="这将擦除磁带上的所有数据!\n确定要继续吗?"
            ["erase_success"]="磁带已成功擦除"
            ["filemark"]="写入文件标记"
            ["auto_rewind"]="退出时自动回卷: %s"
            
            # 配置
            ["config_title"]="配置"
            ["tape_device"]="磁带设备: %s"
            ["compression"]="压缩: %s"
            ["encryption"]="加密: %s"
            ["set_key"]="设置加密密钥"
            ["backup_type"]="备份类型: %s"
            ["save_config"]="保存配置"
            ["config_saved"]="配置已保存!"
            ["auto_rewind_option"]="退出时自动回卷"
            
            # 多卷管理
            ["volume_status"]="卷状态"
            ["change_volume"]="更换卷"
            ["insert_tape"]="请插入磁带并按确定"
            ["insert_next"]="请插入下一卷磁带并按确定"
            
            # 语言设置
            ["current_lang"]="当前语言: %s"
            ["set_english"]="英语"
            ["set_chinese"]="中文"
            
            # 其他
            ["file_not_found"]="错误: 文件/目录未找到!"
            ["operation_cancelled"]="操作已取消"
            ["deps_missing"]="缺少依赖: %s"
            ["install_prompt"]="是否尝试自动安装这些依赖?"
            ["install_success"]="依赖安装成功!"
            ["install_failed"]="依赖安装失败，请手动安装"
            ["distro_not_supported"]="不支持的操作系统: %s"
            ["pv_missing"]="警告: 'pv' 命令未安装，无法显示进度条"
            ["auto_rewind_enabled"]="启用"
            ["auto_rewind_disabled"]="禁用"
        )
    else
        # 英文默认
        msg=(
            # Common
            ["title"]="Tape Storage Manager"
            ["exit"]="Exit"
            ["back"]="Back"
            ["ok"]="OK"
            ["cancel"]="Cancel"
            ["error"]="Error"
            ["success"]="Success"
            ["warning"]="Warning"
            
            # Main menu
            ["main_menu"]="Choose an operation:"
            ["backup"]="Backup to Tape"
            ["restore"]="Restore from Tape"
            ["list"]="List Tape Contents"
            ["verify"]="Verify Backup"
            ["tape_ops"]="Tape Operations"
            ["config"]="Configuration"
            ["multi_volume"]="Multi-volume Management"
            ["language"]="Language Settings"
            
            # Backup
            ["select_backup"]="Select Directory to Backup"
            ["backup_success"]="Backup completed successfully!"
            ["backup_failed"]="Backup failed. Check logs"
            ["backup_mode"]="Select backup mode:"
            ["overwrite_tape"]="Overwrite entire tape"
            ["append_tape"]="Append to tape"
            ["position_error"]="Tape positioning error, cannot append"
            ["backup_count"]="Current backup number: %d"
            ["backup_progress"]="Backup Progress"
            ["restore_progress"]="Restore Progress"
            
            # Restore
            ["restore_success"]="Files restored to %s"
            ["restore_failed"]="Restore failed. Check logs"
            ["select_backup_to_restore"]="Select backup to restore"
            ["no_backups_found"]="No backups found"
            
            # Tape operations
            ["rewind"]="Rewind Tape"
            ["eject"]="Eject Tape"
            ["erase"]="Erase Tape"
            ["status"]="Tape Status"
            ["load"]="Load Tape"
            ["rewind_success"]="Tape rewound"
            ["eject_success"]="Tape ejected. Safe to remove"
            ["erase_warning"]="This will ERASE ALL DATA on the tape!\nAre you sure?"
            ["erase_success"]="Tape erased successfully"
            ["filemark"]="Write filemark"
            ["auto_rewind"]="Auto rewind on exit: %s"
            
            # Configuration
            ["config_title"]="Configuration"
            ["tape_device"]="Tape Device: %s"
            ["compression"]="Compression: %s"
            ["encryption"]="Encryption: %s"
            ["set_key"]="Set Encryption Key"
            ["backup_type"]="Backup Type: %s"
            ["save_config"]="Save Configuration"
            ["config_saved"]="Configuration saved!"
            ["auto_rewind_option"]="Auto rewind on exit"
            
            # Multi-volume
            ["volume_status"]="Volume Status"
            ["change_volume"]="Change Volume"
            ["insert_tape"]="Please insert tape and press OK"
            ["insert_next"]="Please insert next tape and press OK"
            
            # Language
            ["current_lang"]="Current Language: %s"
            ["set_english"]="English"
            ["set_chinese"]="Chinese"
            
            # Other
            ["file_not_found"]="Error: File/directory not found!"
            ["operation_cancelled"]="Operation cancelled"
            ["deps_missing"]="Missing dependencies: %s"
            ["install_prompt"]="Attempt to install these dependencies automatically?"
            ["install_success"]="Dependencies installed successfully!"
            ["install_failed"]="Failed to install dependencies. Please install manually."
            ["distro_not_supported"]="Unsupported operating system: %s"
            ["pv_missing"]="Warning: 'pv' command not installed, progress bar disabled"
            ["auto_rewind_enabled"]="Enabled"
            ["auto_rewind_disabled"]="Disabled"
        )
    fi
}

# 翻译函数
tr() {
    local key=$1
    shift
    if [ -n "${msg[$key]}" ]; then
        printf "${msg[$key]}" "$@"
    else
        printf "$key" "$@"  # 回退到键名
    fi
}

# 检测操作系统类型
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_VERSION=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
        OS_VERSION=$(lsb_release -sr)
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        OS=$DISTRIB_ID
        OS_VERSION=$DISTRIB_RELEASE
    elif [ -f /etc/debian_version ]; then
        OS=debian
        OS_VERSION=$(cat /etc/debian_version)
    elif [ -f /etc/redhat-release ]; then
        OS=$(awk '{print $1}' /etc/redhat-release)
        OS_VERSION=$(awk '{print $3}' /etc/redhat-release)
    else
        OS=$(uname -s)
        OS_VERSION=$(uname -r)
    fi
    
    echo "$OS"
}

# 安装依赖
install_dependencies() {
    local os_type=$1
    local missing_deps=("${!2}")
    local install_cmd=""
    local sudo_cmd=""
    
    # 检查是否有sudo权限
    if command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
        sudo_cmd="sudo "
    elif [ "$(id -u)" -eq 0 ]; then
        sudo_cmd=""
    else
        echo "错误: 需要root权限或sudo权限来安装依赖"
        return 1
    fi
    
    case $os_type in
        ubuntu|debian)
            install_cmd="${sudo_cmd}apt-get update && ${sudo_cmd}apt-get install -y"
            ;;
        centos|rhel|fedora)
            if [ "$os_type" = "centos" ] || [ "$os_type" = "rhel" ]; then
                # 检查是否已安装EPEL仓库
                if ! rpm -qa | grep -q epel-release; then
                    install_cmd="${sudo_cmd}yum install -y epel-release && "
                fi
            fi
            install_cmd+="${sudo_cmd}yum install -y"
            ;;
        *)
            echo "不支持的操作系统: $os_type"
            return 1
            ;;
    esac
    
    # 添加依赖包名
    for dep in "${missing_deps[@]}"; do
        case $dep in
            mt-st) 
                install_cmd+=" mt-st"
                ;;
            mtx)
                install_cmd+=" mtx"
                ;;
            gpg|gnupg)
                install_cmd+=" gnupg"
                ;;
            openssl)
                install_cmd+=" openssl"
                ;;
            pv)
                install_cmd+=" pv"
                ;;
            coreutils)
                install_cmd+=" coreutils"
                ;;
            gawk)
                install_cmd+=" gawk"
                ;;
            grep)
                install_cmd+=" grep"
                ;;
            bash)
                install_cmd+=" bash"
                ;;
            dialog)
                install_cmd+=" dialog"
                ;;
            tar)
                install_cmd+=" tar"
                ;;
            gzip)
                install_cmd+=" gzip"
                ;;
            bzip2)
                install_cmd+=" bzip2"
                ;;
            xz)
                install_cmd+=" xz-utils"
                ;;
            *)
                install_cmd+=" $dep"
                ;;
        esac
    done
    
    echo "执行安装命令: $install_cmd"
    
    # 执行安装命令
    eval "$install_cmd"
    local result=$?
    
    if [ $result -eq 0 ]; then
        echo "依赖安装成功"
    else
        echo "依赖安装失败，退出码: $result"
    fi
    
    return $result
}

# 检查依赖
check_dependencies() {
    local missing=()
    local os_type=$(detect_os)
    
    echo "检测到操作系统: $os_type"
    
    # 基本依赖 - 必需
    command -v dialog >/dev/null 2>&1 || missing+=("dialog")
    command -v mt >/dev/null 2>&1 || missing+=("mt-st")
    command -v tar >/dev/null 2>&1 || missing+=("tar")
    command -v bash >/dev/null 2>&1 || missing+=("bash")
    command -v stat >/dev/null 2>&1 || missing+=("coreutils")
    command -v mkdir >/dev/null 2>&1 || missing+=("coreutils")
    command -v rm >/dev/null 2>&1 || missing+=("coreutils")
    command -v cat >/dev/null 2>&1 || missing+=("coreutils")
    command -v printf >/dev/null 2>&1 || missing+=("coreutils")
    command -v awk >/dev/null 2>&1 || missing+=("gawk")
    command -v grep >/dev/null 2>&1 || missing+=("grep")
    command -v shuf >/dev/null 2>&1 || missing+=("coreutils")
    
    # 压缩工具 - 根据配置检查
    case "$COMPRESSION" in
        gzip) command -v gzip >/dev/null 2>&1 || missing+=("gzip") ;;
        bzip2) command -v bzip2 >/dev/null 2>&1 || missing+=("bzip2") ;;
        xz) command -v xz >/dev/null 2>&1 || missing+=("xz") ;;
    esac
    
    # 加密工具 - 根据配置检查
    if [ "$ENCRYPTION" != "none" ]; then
        case "$ENCRYPTION" in
            gpg) command -v gpg >/dev/null 2>&1 || missing+=("gnupg") ;;
            openssl) command -v openssl >/dev/null 2>&1 || missing+=("openssl") ;;
        esac
    fi
    
    # 多卷支持 - 可选但推荐
    command -v mtx >/dev/null 2>&1 || missing+=("mtx")
    
    # 进度条工具 - 可选但推荐
    command -v pv >/dev/null 2>&1 || missing+=("pv")
    
    echo "缺少的依赖: ${missing[*]}"
    
    if [ ${#missing[@]} -gt 0 ]; then
        # 检查是否有dialog可用，如果没有则使用echo
        if command -v dialog >/dev/null 2>&1; then
            # 显示缺少的依赖
            dialog --msgbox "$(printf "$(tr deps_missing)" "${missing[*]}")" 10 60
            
            # 询问是否安装
            dialog --yesno "$(tr install_prompt)" 8 50
            local install_choice=$?
        else
            # 没有dialog时使用echo
            echo "缺少依赖: ${missing[*]}"
            echo "是否尝试自动安装这些依赖? (y/n)"
            read -r install_choice
            if [ "$install_choice" = "y" ] || [ "$install_choice" = "Y" ]; then
                install_choice=0
            else
                install_choice=1
            fi
        fi
        
        if [ $install_choice -eq 0 ]; then
            # 尝试安装依赖
            echo "正在安装依赖..."
            if install_dependencies "$os_type" missing[@]; then
                if command -v dialog >/dev/null 2>&1; then
                    dialog --msgbox "$(tr install_success)" 8 40
                else
                    echo "依赖安装成功!"
                fi
                return 0
            else
                if command -v dialog >/dev/null 2>&1; then
                    dialog --msgbox "$(tr install_failed)" 10 60
                else
                    echo "依赖安装失败，请手动安装"
                fi
                exit 1
            fi
        else
            echo "用户选择不安装依赖，退出程序"
            exit 1
        fi
    else
        echo "所有依赖检查通过"
    fi
}

# 磁带操作函数
rewind_tape() {
    mt -f "$TAPE_DEVICE" rewind
}

eject_tape() {
    mt -f "$TAPE_DEVICE" eject
}

erase_tape() {
    dialog --yesno "$(tr erase_warning)" 8 50
    if [ $? -eq 0 ]; then
        mt -f "$TAPE_DEVICE" erase
        dialog --msgbox "$(tr erase_success)" 8 40
    fi
}

tape_status() {
    mt -f "$TAPE_DEVICE" status > "$WORK_DIR/status.txt"
    dialog --title "$(tr status)" --textbox "$WORK_DIR/status.txt" 20 80
}

# 定位到磁带末尾
position_to_eod() {
    mt -f "$TAPE_DEVICE" eod
    return $?
}

# 写入文件标记
write_filemark() {
    mt -f "$TAPE_DEVICE" weof 1
}

# 多卷管理
load_tape() {
    dialog --msgbox "$(tr insert_tape)" 8 40
    rewind_tape
}

change_tape() {
    dialog --msgbox "$(tr insert_next)" 8 40
    rewind_tape
}

# 压缩处理
compress_cmd() {
    case "$COMPRESSION" in
        gzip) echo "gzip -c" ;;
        bzip2) echo "bzip2 -c" ;;
        xz) echo "xz -c" ;;
        *) echo "cat" ;;
    esac
}

decompress_cmd() {
    case "$COMPRESSION" in
        gzip) echo "gzip -dc" ;;
        bzip2) echo "bzip2 -dc" ;;
        xz) echo "xz -dc" ;;
        *) echo "cat" ;;
    esac
}

# 加密处理
encrypt_cmd() {
    case "$ENCRYPTION" in
        gpg) echo "gpg --batch --symmetric --passphrase-file $ENCRYPT_KEY -c 2>/dev/null" ;;
        openssl) echo "openssl enc -aes-256-cbc -pass file:$ENCRYPT_KEY -pbkdf2" ;;
        *) echo "cat" ;;
    esac
}

decrypt_cmd() {
    case "$ENCRYPTION" in
        gpg) echo "gpg --batch --passphrase-file $ENCRYPT_KEY -d 2>/dev/null" ;;
        openssl) echo "openssl enc -d -aes-256-cbc -pass file:$ENCRYPT_KEY -pbkdf2" ;;
        *) echo "cat" ;;
    esac
}

# 获取下一个备份编号
get_next_backup_number() {
    local count=$(<"$BACKUP_COUNTER_FILE")
    echo $((count + 1))
}

# 更新备份计数器
update_backup_counter() {
    local count=$(<"$BACKUP_COUNTER_FILE")
    echo $((count + 1)) > "$BACKUP_COUNTER_FILE"
}

# 显示进度条
show_progress() {
    local title="$1"
    local message="$2"
    local size="$3"
    local cmd="$4"
    
    # 检查pv是否可用
    if command -v pv >/dev/null 2>&1; then
        # 使用pv显示进度条
        if [ -n "$size" ]; then
            # 有文件大小时使用精确进度条
            eval "$cmd" | pv -s "$size" -N "$message" 2>&1 | while IFS= read -r line; do
                echo "XXX"
                echo "$line"
                echo "XXX"
            done | dialog --gauge "$title" 10 70 0
        else
            # 没有文件大小时使用不确定进度条
            eval "$cmd" | pv -petr -N "$message" 2>&1 | while IFS= read -r line; do
                echo "XXX"
                echo "$line"
                echo "XXX"
            done | dialog --gauge "$title" 10 70 0
        fi
    else
        # 没有pv时显示静态消息和简单进度
        dialog --infobox "$message\n\n正在处理，请稍候..." 8 50 &
        local dialog_pid=$!
        eval "$cmd"
        local result=$?
        kill $dialog_pid 2>/dev/null
        return $result
    fi
}

# 简化的进度显示函数
show_simple_progress() {
    local title="$1"
    local message="$2"
    local cmd="$3"
    
    # 显示进度对话框
    dialog --infobox "$message\n\n正在处理，请稍候..." 8 50 &
    local dialog_pid=$!
    
    # 执行命令
    eval "$cmd"
    local result=$?
    
    # 关闭进度对话框
    kill $dialog_pid 2>/dev/null
    wait $dialog_pid 2>/dev/null
    
    return $result
}

# 备份函数（支持覆盖/追加模式）
perform_backup() {
    local backup_dir=$1
    local backup_number=$(get_next_backup_number)
    local backup_file="$WORK_DIR/backups/backup_${backup_number}_$(date +%Y%m%d_%H%M%S).tar"
    
    if [ ! -f "$backup_dir" ] && [ ! -d "$backup_dir" ]; then
        dialog --msgbox "$(tr file_not_found)" 8 40
        return 1
    fi
    
    # 显示当前备份编号
    dialog --msgbox "$(printf "$(tr backup_count)" "$backup_number")" 8 40
    
    # 询问备份模式，默认选择追加模式
    backup_mode=$(dialog --default-item 2 --menu "$(tr backup_mode)" 12 40 2 \
                        1 "$(tr overwrite_tape)" \
                        2 "$(tr append_tape)" \
                        3>&1 1>&2 2>&3)
    
    [ $? -ne 0 ] && return  # 用户取消
    
    case $backup_mode in
        1)  # 覆盖模式 - 需要六位数字确认
            # 生成六位随机数字
            confirm_code=$(shuf -i 100000-999999 -n 1)
            dialog --msgbox "警告：这将覆盖整个磁带上的所有数据！\n\n请输入以下六位数字确认：$confirm_code" 10 60
            
            # 要求用户输入确认码
            user_input=$(dialog --inputbox "请输入确认码 ($confirm_code):" 8 40 3>&1 1>&2 2>&3)
            
            if [ $? -ne 0 ] || [ "$user_input" != "$confirm_code" ]; then
                dialog --msgbox "确认码不匹配，操作已取消" 8 40
                return 1
            fi
            
            rewind_tape
            ;;
        2)  # 追加模式
            if ! position_to_eod; then
                dialog --msgbox "$(tr position_error)" 8 60
                return 1
            fi
            ;;
        *)  # 取消
            return
            ;;
    esac
    
    # 创建备份
    tar -c -f "$backup_file" --listed-incremental="$SNAPSHOT_FILE" "$backup_dir" 2>"$WORK_DIR/backup_log.txt"
    
    # 压缩和加密
    $(compress_cmd) < "$backup_file" | $(encrypt_cmd) > "$backup_file.enc"
    rm "$backup_file"
    
    # 获取文件大小用于进度条
    local file_size=$(stat -c %s "$backup_file.enc")
    
    # 写入磁带（带进度条）
    if command -v pv >/dev/null 2>&1; then
        # 使用pv显示进度
        pv -s "$file_size" -N "正在写入磁带..." "$backup_file.enc" > "$TAPE_DEVICE"
    else
        # 没有pv时使用简单进度显示
        show_simple_progress "$(tr backup_progress)" "正在写入磁带..." "cat '$backup_file.enc' > '$TAPE_DEVICE'"
    fi
    
    # 写入文件标记（分隔备份）
    write_filemark
    
    # 更新备份计数器
    update_backup_counter
    
    # 清理
    rm "$backup_file.enc"
    
    if [ $? -eq 0 ]; then
        dialog --msgbox "$(tr backup_success)" 8 40
    else
        dialog --msgbox "$(tr backup_failed)" 8 40
    fi
}

# 列出磁带内容
list_tape_contents() {
    rewind_tape
    $(decrypt_cmd) < "$TAPE_DEVICE" | $(decompress_cmd) | tar -tv > "$WORK_DIR/tape_contents.txt"
    dialog --title "$(tr list)" --textbox "$WORK_DIR/tape_contents.txt" 25 80
}

# 列出所有备份
list_backups() {
    rewind_tape
    local backup_list="$WORK_DIR/backup_list.txt"
    local count=0
    
    echo "Available backups:" > "$backup_list"
    echo "------------------" >> "$backup_list"
    
    while true; do
        count=$((count + 1))
        # 尝试读取备份
        $(decrypt_cmd) < "$TAPE_DEVICE" | $(decompress_cmd) | tar -tv > "$WORK_DIR/backup_$count.txt" 2>/dev/null
        
        # 检查是否成功读取
        if [ $? -ne 0 ] || [ ! -s "$WORK_DIR/backup_$count.txt" ]; then
            rm -f "$WORK_DIR/backup_$count.txt"
            break
        fi
        
        # 获取备份日期
        local backup_date=$(head -1 "$WORK_DIR/backup_$count.txt" | awk '{print $4, $5}')
        
        # 添加到备份列表
        echo "$count. Backup $count - $backup_date" >> "$backup_list"
        echo "   Files: $(wc -l < "$WORK_DIR/backup_$count.txt")" >> "$backup_list"
        
        # 跳过文件标记
        mt -f "$TAPE_DEVICE" fsf 1
    done
    
    if [ $count -eq 1 ]; then
        dialog --msgbox "$(tr no_backups_found)" 8 40
        return 1
    fi
    
    dialog --title "$(tr select_backup_to_restore)" --textbox "$backup_list" 25 80
    return $count
}

# 恢复特定备份
restore_backup() {
    local backup_num=$1
    
    rewind_tape
    
    # 定位到指定备份
    if [ $backup_num -gt 1 ]; then
        mt -f "$TAPE_DEVICE" fsf $((backup_num - 1))
    fi
    
    # 创建目标目录
    mkdir -p "$WORK_DIR/extracted/backup_$backup_num"
    
    # 恢复备份（带进度条）
    if command -v pv >/dev/null 2>&1; then
        # 使用pv显示进度
        $(decrypt_cmd) < "$TAPE_DEVICE" | $(decompress_cmd) | pv -petr -N "正在恢复备份 $backup_num..." | tar -xv -C "$WORK_DIR/extracted/backup_$backup_num" 2>"$WORK_DIR/restore_log.txt"
    else
        # 没有pv时使用简单进度显示
        show_simple_progress "$(tr restore_progress)" "正在恢复备份 $backup_num..." \
            "$(decrypt_cmd) < '$TAPE_DEVICE' | $(decompress_cmd) | tar -xv -C '$WORK_DIR/extracted/backup_$backup_num' 2>'$WORK_DIR/restore_log.txt'"
    fi
    
    if [ $? -eq 0 ]; then
        dialog --msgbox "$(printf "$(tr restore_success)" "$WORK_DIR/extracted/backup_$backup_num")" 8 60
    else
        dialog --msgbox "$(tr restore_failed)" 10 60
    fi
}

# 恢复函数
restore_from_tape() {
    # 列出所有备份
    list_backups
    local backup_count=$?
    
    if [ $backup_count -eq 0 ]; then
        return
    fi
    
    # 选择要恢复的备份
    backup_choice=$(dialog --inputbox "$(tr select_backup_to_restore) (1-$backup_count):" 8 40 3>&1 1>&2 2>&3)
    
    if [ $? -ne 0 ] || [ -z "$backup_choice" ]; then
        dialog --msgbox "$(tr operation_cancelled)" 8 40
        return
    fi
    
    if ! [[ "$backup_choice" =~ ^[0-9]+$ ]] || [ "$backup_choice" -lt 1 ] || [ "$backup_choice" -gt $backup_count ]; then
        dialog --msgbox "Invalid backup number!" 8 40
        return
    fi
    
    # 恢复指定备份
    restore_backup "$backup_choice"
}

# 验证备份
verify_backup() {
    rewind_tape
    $(decrypt_cmd) < "$TAPE_DEVICE" | $(decompress_cmd) | tar -d -f - > "$WORK_DIR/verify_diff.txt"
    
    if [ -s "$WORK_DIR/verify_diff.txt" ]; then
        dialog --title "$(tr verify)" --textbox "$WORK_DIR/verify_diff.txt" 25 80
    else
        dialog --msgbox "$(tr backup_success)" 8 60
    fi
}

# 配置菜单
config_menu() {
    while true; do
        choice=$(dialog --title "$(tr config_title)" \
                        --menu "$(tr config_title):" 15 50 9 \
                        1 "磁带设备: $TAPE_DEVICE" \
                        2 "当前语言: $LANGUAGE" \
                        3 "备份类型: $BACKUP_TYPE" \
                        4 "压缩: $COMPRESSION" \
                        5 "加密: $ENCRYPTION" \
                        6 "$(tr set_key)" \
                        7 "退出时自动回卷: $(if [ "$AUTO_REWIND_ON_EXIT" = "true" ]; then tr auto_rewind_enabled; else tr auto_rewind_disabled; fi)" \
                        8 "$(tr save_config)" \
                        9 "$(tr back)" \
                        3>&1 1>&2 2>&3)
        
        [ $? -ne 0 ] && break
        
        case $choice in
            1)  # 设置磁带设备
                new_dev=$(dialog --inputbox "Enter tape device path:" 8 40 "$TAPE_DEVICE" 3>&1 1>&2 2>&3)
                [ $? -eq 0 ] && TAPE_DEVICE="$new_dev"
                ;;
            2)  # 语言设置
                lang_menu
                ;;
            3)  # 设置备份类型
                type_choice=$(dialog --menu "$(tr backup_type):" 15 30 3 \
                                    1 "完全备份" 2 "增量备份" 3>&1 1>&2 2>&3)
                case $type_choice in
                    1) BACKUP_TYPE="full" ;;
                    2) BACKUP_TYPE="incremental" ;;
                esac
                ;;
            4)  # 设置压缩
                comp_choice=$(dialog --menu "$(tr compression):" 15 30 5 \
                                    1 "无压缩" 2 "gzip" 3 "bzip2" 4 "xz" 3>&1 1>&2 2>&3)
                case $comp_choice in
                    1) COMPRESSION="none" ;;
                    2) COMPRESSION="gzip" ;;
                    3) COMPRESSION="bzip2" ;;
                    4) COMPRESSION="xz" ;;
                esac
                ;;
            5)  # 设置加密
                enc_choice=$(dialog --menu "$(tr encryption):" 15 30 4 \
                                   1 "无加密" 2 "GPG" 3 "OpenSSL" 3>&1 1>&2 2>&3)
                case $enc_choice in
                    1) ENCRYPTION="none" ;;
                    2) ENCRYPTION="gpg" ;;
                    3) ENCRYPTION="openssl" ;;
                esac
                ;;
            6)  # 设置加密密钥
                key_path=$(dialog --fselect "$HOME/" 15 60 3>&1 1>&2 2>&3)
                [ $? -eq 0 ] && ENCRYPT_KEY="$key_path"
                ;;
            7)  # 设置自动回卷选项
                rewind_choice=$(dialog --menu "$(tr auto_rewind_option):" 15 30 2 \
                                    1 "$(tr auto_rewind_enabled)" \
                                    2 "$(tr auto_rewind_disabled)" \
                                    3>&1 1>&2 2>&3)
                case $rewind_choice in
                    1) AUTO_REWIND_ON_EXIT="true" ;;
                    2) AUTO_REWIND_ON_EXIT="false" ;;
                esac
                ;;
            8)  # 保存配置
                save_config
                dialog --msgbox "$(tr config_saved)" 8 40
                ;;
            9)  # 返回主菜单
                break
                ;;
        esac
    done
}

# 语言设置菜单
lang_menu() {
    while true; do
        choice=$(dialog --title "$(tr language)" \
                        --menu "$(printf "$(tr current_lang)" "$LANGUAGE"):" 10 40 3 \
                        1 "English" \
                        2 "中文" \
                        3 "$(tr back)" \
                        3>&1 1>&2 2>&3)
        
        [ $? -ne 0 ] && break
        
        case $choice in
            1)  # 英语
                LANGUAGE="en"
                load_language
                save_config
                break
                ;;
            2)  # 中文
                LANGUAGE="zh"
                load_language
                save_config
                break
                ;;
            3)  # 返回
                break
                ;;
        esac
    done
}

# 保存配置
save_config() {
    cat > "$CONFIG_FILE" <<-EOF
# Tape Manager Configuration
TAPE_DEVICE="$TAPE_DEVICE"
WORK_DIR="$WORK_DIR"
COMPRESSION="$COMPRESSION"
ENCRYPTION="$ENCRYPTION"
ENCRYPT_KEY="$ENCRYPT_KEY"
BACKUP_TYPE="$BACKUP_TYPE"
BACKUP_MODE="$BACKUP_MODE"
LANGUAGE="$LANGUAGE"
AUTO_REWIND_ON_EXIT="$AUTO_REWIND_ON_EXIT"
EOF
}

# 磁带操作子菜单
tape_ops_menu() {
    while true; do
        choice=$(dialog --title "$(tr tape_ops)" \
                        --menu "$(tr tape_ops):" 15 50 8 \
                        1 "$(tr rewind)" \
                        2 "$(tr eject)" \
                        3 "$(tr erase)" \
                        4 "$(tr status)" \
                        5 "$(tr load)" \
                        6 "$(tr filemark)" \
                        7 "$(tr back)" \
                        3>&1 1>&2 2>&3)
        
        [ $? -ne 0 ] && break
        
        case $choice in
            1) 
                rewind_tape
                dialog --msgbox "$(tr rewind_success)" 8 40 
                ;;
            2) 
                eject_tape
                dialog --msgbox "$(tr eject_success)" 8 40 
                ;;
            3) 
                erase_tape
                ;;
            4) 
                tape_status
                ;;
            5) 
                load_tape
                ;;
            6)
                write_filemark
                dialog --msgbox "Filemark written successfully" 8 40
                ;;
            7) 
                break
                ;;
        esac
    done
}

# 多卷管理菜单
multi_volume_menu() {
    while true; do
        choice=$(dialog --title "$(tr multi_volume)" \
                        --menu "$(tr multi_volume):" 15 50 5 \
                        1 "$(tr volume_status)" \
                        2 "$(tr change_volume)" \
                        3 "$(tr load)" \
                        4 "$(tr back)" \
                        3>&1 1>&2 2>&3)
        
        [ $? -ne 0 ] && break
        
        case $choice in
            1) 
                mtx -f "$TAPE_DEVICE" status > "$WORK_DIR/volume_status.txt"
                dialog --title "$(tr volume_status)" --textbox "$WORK_DIR/volume_status.txt" 20 80
                ;;
            2) 
                change_tape
                ;;
            3) 
                load_tape
                ;;
            4) 
                break
                ;;
        esac
    done
}

# 主菜单
main_menu() {
    while true; do
        choice=$(dialog --title "$(tr title)" \
                        --menu "$(tr main_menu)" 18 60 9 \
                        1 "$(tr backup)" \
                        2 "$(tr restore)" \
                        3 "$(tr list)" \
                        4 "$(tr verify)" \
                        5 "$(tr tape_ops)" \
                        6 "$(tr config)" \
                        7 "$(tr multi_volume)" \
                        8 "$(tr exit)" \
                        3>&1 1>&2 2>&3)
        
        [ $? -ne 0 ] && break
        
        case $choice in
            1)  # 备份
                backup_dir=$(dialog --title "$(tr select_backup)" \
                                    --fselect "$HOME/" 15 60 3>&1 1>&2 2>&3)
                [ $? -eq 0 ] && perform_backup "$backup_dir"
                ;;
            2)  # 恢复
                restore_from_tape
                ;;
            3)  # 列出内容
                list_backups
                ;;
            4)  # 验证
                verify_backup
                ;;
            5)  # 磁带操作
                tape_ops_menu
                ;;
            6)  # 配置
                config_menu
                ;;
            7)  # 多卷管理
                multi_volume_menu
                ;;
            8)  # 退出
                break
                ;;
        esac
    done
}

# 清理函数
cleanup() {
    # 退出时自动回卷磁带
    if [ "$AUTO_REWIND_ON_EXIT" = "true" ]; then
        rewind_tape
    fi
    
    rm -rf "$WORK_DIR"
    clear  # 退出时清屏
}

# 主程序
trap cleanup EXIT

# 添加调试信息
echo "=== 磁带存储管理器启动 ==="
echo "脚本路径: $0"
echo "当前用户: $(whoami)"
echo "当前目录: $(pwd)"
echo "Bash版本: $BASH_VERSION"

# 首先检查依赖
echo "=== 开始检查依赖 ==="
check_dependencies

# 然后初始化配置和主菜单
echo "=== 初始化配置 ==="
init_config

echo "=== 启动主菜单 ==="
main_menu