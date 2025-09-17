# Tape Manager Advanced / 磁带管理工具高级版

---

## 中文版

### 简介
这是一个用 Bash 写的磁带备份管理工具，带图形化菜单（TUI）、进度条、加密和压缩功能，适合 Linux 系统下管理磁带。

### 功能
- **备份 & 恢复**
  - 支持完整备份和增量备份
  - 可覆盖整个磁带或追加到磁带
  - 支持压缩（gzip、bzip2、xz）
  - 支持加密（GPG 或 OpenSSL）

- **多卷管理**
  - 支持切换多卷磁带
  - 查看卷状态
  - 自动提示插入下一卷磁带

- **磁带操作**
  - 回卷、弹出、擦除磁带
  - 写文件标记
  - 查看磁带状态

- **语言**
  - 中文 / 英文

- **用户体验**
  - 菜单式操作，不用记命令
  - 进度条显示备份/恢复状态
  - 退出时可自动回卷磁带

- **依赖检查**
  - 会检查缺少的工具，并提示是否安装

### 安装
```bash
git clone https://github.com/你的用户名/tape-manager-advanced.git
cd tape-manager-advanced
chmod +x tape_manager_advanced.sh
```

### 使用
```bash
./tape_manager_advanced.sh
```
菜单中可选择：
- 备份到磁带
- 从磁带恢复
- 查看磁带内容
- 验证备份
- 磁带操作（回卷、弹出、擦除）
- 配置（设备、压缩、加密、语言等）
- 多卷管理

**提示：**
- 覆盖磁带会清空内容，需要输入六位数字确认。
- 加密请确保密钥文件路径正确。
- 自动回卷可以在退出时把磁带回到初始位置。

### 配置文件
默认路径：
```
~/.tape_manager.conf
```
示例：
```ini
TAPE_DEVICE="/dev/nst0"
WORK_DIR="$HOME/tape_temp"
COMPRESSION="gzip"
ENCRYPTION="none"
ENCRYPT_KEY=""
BACKUP_TYPE="full"
BACKUP_MODE="append"
LANGUAGE="en"
AUTO_REWIND_ON_EXIT="true"
```

### 许可
MIT License

### 反馈
有问题或建议请在 GitHub 提 Issue。

---

## English Version

### Overview
Tape Manager Advanced is a Bash-based tape backup tool with a TUI (text-based menu), progress bars, encryption, and compression. Works on Linux.

### Features
- **Backup & Restore**
  - Full or incremental backup
  - Overwrite tape or append to tape
  - Compression: gzip, bzip2, xz
  - Encryption: GPG or OpenSSL

- **Multi-volume Management**
  - Switch between tape volumes
  - Check volume status
  - Auto prompt for next tape

- **Tape Operations**
  - Rewind, eject, erase tape
  - Write filemarks
  - Check tape status

- **Language**
  - English / Chinese

- **User Experience**
  - Menu-driven, no need to memorize commands
  - Progress bar for backup/restore
  - Auto rewind on exit

- **Dependency Check**
  - Checks for missing tools and prompts installation

### Installation
```bash
git clone https://github.com/your-username/tape-manager-advanced.git
cd tape-manager-advanced
chmod +x tape_manager_advanced.sh
```

### Usage
```bash
./tape_manager_advanced.sh
```
Menu options:
- Backup to tape
- Restore from tape
- List tape contents
- Verify backup
- Tape operations (rewind, eject, erase)
- Configuration (device, compression, encryption, language)
- Multi-volume management

**Tips:**
- Overwriting tape will erase all data, requires 6-digit confirmation.
- Make sure encryption key path is correct if using encryption.
- Auto rewind will rewind tape on exit.

### Configuration File
Default location:
```
~/.tape_manager.conf
```
Example:
```ini
TAPE_DEVICE="/dev/nst0"
WORK_DIR="$HOME/tape_temp"
COMPRESSION="gzip"
ENCRYPTION="none"
ENCRYPT_KEY=""
BACKUP_TYPE="full"
BACKUP_MODE="append"
LANGUAGE="en"
AUTO_REWIND_ON_EXIT="true"
```

### License
MIT License

### Feedback
Open an issue on GitHub for problems or suggestions.
