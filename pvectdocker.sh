#!/bin/bash

#############################################
# PVE 9 CT 容器 Docker 一键配置脚本
# 功能：解决 LXC 容器中 Docker 无法正常运行的问题
# 作者：自动生成
# 版本：1.0
#############################################

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查是否为 root 用户
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "请使用 root 权限运行此脚本"
        exit 1
    fi
}

# 显示欢迎信息
show_welcome() {
    clear
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  PVE 9 CT 容器 Docker 配置工具${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo "此脚本将帮助您配置 LXC 容器以支持 Docker"
    echo ""
}

# 检测运行环境
detect_environment() {
    log_info "检测运行环境..."
    
    # 检查是否在 LXC 容器中
    if [ -f /proc/1/environ ] && grep -q container=lxc /proc/1/environ; then
        ENV_TYPE="lxc"
        log_success "检测到 LXC 容器环境"
    else
        ENV_TYPE="pve_host"
        log_success "检测到 PVE 宿主机环境"
    fi
    
    # 获取系统信息
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_NAME=$NAME
        OS_VERSION=$VERSION_ID
        log_info "操作系统: $OS_NAME $OS_VERSION"
    fi
}

# 列出所有虚拟机和容器
list_vms_and_cts() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  当前系统中的虚拟机和容器${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    # 列出所有容器
    echo -e "${GREEN}LXC 容器:${NC}"
    if pct list &>/dev/null; then
        pct list | awk 'NR>1 {printf "  [%s] %s (状态: %s)\n", $1, $3, $2}'
    else
        echo "  未找到容器"
    fi
    
    echo ""
    
    # 列出所有虚拟机
    echo -e "${GREEN}KVM 虚拟机:${NC}"
    if qm list &>/dev/null; then
        qm list | awk 'NR>1 {printf "  [%s] %s (状态: %s)\n", $1, $2, $3}'
    else
        echo "  未找到虚拟机"
    fi
    
    echo ""
}

# 获取 CT 容器 ID
get_ct_id() {
    list_vms_and_cts
    
    echo -e "${YELLOW}请输入要配置的 CT 容器 ID:${NC}"
    read -p "CT ID: " CT_ID
    
    if [ -z "$CT_ID" ]; then
        log_error "容器 ID 不能为空"
        exit 1
    fi
    
    # 验证容器是否存在
    if ! pct status $CT_ID &>/dev/null; then
        log_error "容器 $CT_ID 不存在"
        exit 1
    fi
    
    # 获取容器名称
    CT_NAME=$(pct config $CT_ID | grep "^hostname:" | awk '{print $2}')
    if [ -z "$CT_NAME" ]; then
        CT_NAME="未命名"
    fi
    
    log_success "容器 $CT_ID ($CT_NAME) 已找到"
}

# 备份容器配置
backup_config() {
    local config_file="/etc/pve/lxc/${CT_ID}.conf"
    local backup_file="/etc/pve/lxc/${CT_ID}.conf.backup.$(date +%Y%m%d_%H%M%S)"
    
    log_info "备份容器配置文件..."
    cp "$config_file" "$backup_file"
    log_success "配置已备份到: $backup_file"
}

# 配置 PVE 宿主机上的容器
configure_pve_host() {
    log_info "开始配置 PVE 宿主机上的容器 $CT_ID..."
    
    local config_file="/etc/pve/lxc/${CT_ID}.conf"
    
    # 询问是否配置为特权容器
    echo ""
    echo -e "${YELLOW}容器权限配置:${NC}"
    echo "1) 特权容器 (推荐，Docker 完全兼容)"
    echo "2) 非特权容器 (更安全，但可能有限制)"
    read -p "请选择 (1-2，默认 1): " privilege_choice
    
    if [ -z "$privilege_choice" ]; then
        privilege_choice="1"
    fi
    
    if [ "$privilege_choice" = "1" ]; then
        USE_PRIVILEGED=true
        log_info "将配置为特权容器"
    else
        USE_PRIVILEGED=false
        log_info "将配置为非特权容器"
    fi
    
    # 检查容器是否正在运行
    if pct status $CT_ID | grep -q "running"; then
        echo ""
        log_warning "容器 $CT_ID 正在运行"
        read -p "是否停止容器以进行配置? (y/n): " stop_ct
        if [ "$stop_ct" = "y" ] || [ "$stop_ct" = "Y" ]; then
            log_info "停止容器..."
            pct stop $CT_ID
            sleep 3
        else
            log_error "容器必须停止才能修改配置"
            exit 1
        fi
    fi
    
    # 添加必要的配置
    log_info "添加 Docker 所需的配置..."
    
    # 检查并添加配置项
    add_config_if_missing() {
        local key=$1
        local value=$2
        if ! grep -q "^${key}:" "$config_file"; then
            echo "${key}: ${value}" >> "$config_file"
            log_success "已添加: ${key}: ${value}"
        else
            log_info "配置项已存在: ${key}"
        fi
    }
    
    # 更新或添加配置项
    update_or_add_config() {
        local key=$1
        local value=$2
        if grep -q "^${key}:" "$config_file"; then
            sed -i "s|^${key}:.*|${key}: ${value}|" "$config_file"
            log_success "已更新: ${key}: ${value}"
        else
            echo "${key}: ${value}" >> "$config_file"
            log_success "已添加: ${key}: ${value}"
        fi
    }
    
    # 配置特权容器
    if [ "$USE_PRIVILEGED" = true ]; then
        log_info "配置特权容器模式..."
        update_or_add_config "unprivileged" "0"
    else
        log_info "配置非特权容器模式..."
        update_or_add_config "unprivileged" "1"
    fi
    
    # 关键配置项
    add_config_if_missing "features" "nesting=1"
    
    # 如果 features 行存在但没有 nesting，则更新
    if grep -q "^features:" "$config_file" && ! grep -q "nesting=1" "$config_file"; then
        sed -i 's/^features:.*/&,nesting=1/' "$config_file"
        log_success "已更新 features 添加 nesting=1"
    fi
    
    # 添加 lxc.apparmor.profile
    if ! grep -q "^lxc.apparmor.profile" "$config_file"; then
        echo "lxc.apparmor.profile: unconfined" >> "$config_file"
        log_success "已添加: lxc.apparmor.profile: unconfined"
    fi
    
    # 添加 lxc.cgroup2.devices.allow
    if ! grep -q "^lxc.cgroup2.devices.allow" "$config_file"; then
        echo "lxc.cgroup2.devices.allow: a" >> "$config_file"
        log_success "已添加: lxc.cgroup2.devices.allow: a"
    fi
    
    # 添加 lxc.cap.drop (移除限制)
    if ! grep -q "^lxc.cap.drop" "$config_file"; then
        echo "lxc.cap.drop:" >> "$config_file"
        log_success "已添加: lxc.cap.drop: (空值，移除限制)"
    fi
    
    # 添加 lxc.mount.auto
    if ! grep -q "^lxc.mount.auto" "$config_file"; then
        echo "lxc.mount.auto: proc:rw sys:rw" >> "$config_file"
        log_success "已添加: lxc.mount.auto: proc:rw sys:rw"
    fi
    
    log_success "PVE 宿主机配置完成"
    
    # 询问是否启动容器
    echo ""
    read -p "是否现在启动容器? (y/n): " start_ct
    if [ "$start_ct" = "y" ] || [ "$start_ct" = "Y" ]; then
        log_info "启动容器 $CT_ID..."
        pct start $CT_ID
        sleep 5
        log_success "容器已启动"
    fi
}

# 在容器内配置 Docker 环境
configure_container_docker() {
    log_info "开始在容器内配置 Docker 环境..."
    
    echo ""
    echo -e "${YELLOW}请选择操作:${NC}"
    echo "1) 安装 Docker"
    echo "2) 仅配置已安装的 Docker"
    echo "3) 跳过容器内配置"
    read -p "请选择 (1-3): " choice
    
    case $choice in
        1)
            install_docker_in_container
            configure_docker_daemon
            ;;
        2)
            configure_docker_daemon
            ;;
        3)
            log_info "跳过容器内配置"
            return
            ;;
        *)
            log_error "无效选择"
            exit 1
            ;;
    esac
}

# 在容器内安装 Docker
install_docker_in_container() {
    log_info "准备安装 Docker..."
    
    # 检测容器内的操作系统
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case $ID in
            ubuntu|debian)
                install_docker_debian
                ;;
            centos|rhel|rocky|almalinux)
                install_docker_rhel
                ;;
            *)
                log_error "不支持的操作系统: $ID"
                exit 1
                ;;
        esac
    fi
}

# Debian/Ubuntu 系统安装 Docker
install_docker_debian() {
    log_info "在 Debian/Ubuntu 系统上安装 Docker..."
    
    # 更新包索引
    apt-get update
    
    # 安装依赖
    apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
    
    # 添加 Docker 官方 GPG key
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/$ID/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    
    # 添加 Docker 仓库
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$ID \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # 安装 Docker
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    log_success "Docker 安装完成"
}

# RHEL/CentOS 系统安装 Docker
install_docker_rhel() {
    log_info "在 RHEL/CentOS 系统上安装 Docker..."
    
    # 安装依赖
    yum install -y yum-utils
    
    # 添加 Docker 仓库
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    
    # 安装 Docker
    yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    log_success "Docker 安装完成"
}

# 配置 Docker daemon
configure_docker_daemon() {
    log_info "配置 Docker daemon..."
    
    # 创建 Docker 配置目录
    mkdir -p /etc/docker
    
    # 创建或更新 daemon.json
    cat > /etc/docker/daemon.json <<EOF
{
  "storage-driver": "overlay2",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF
    
    log_success "Docker daemon 配置完成"
    
    # 启动 Docker 服务
    log_info "启动 Docker 服务..."
    systemctl enable docker
    systemctl start docker
    
    # 验证 Docker 是否正常运行
    if docker --version &>/dev/null; then
        log_success "Docker 服务已启动"
        docker --version
    else
        log_error "Docker 启动失败"
        exit 1
    fi
}

# 测试 Docker 功能
test_docker() {
    log_info "测试 Docker 功能..."
    
    echo ""
    read -p "是否运行 Docker 测试? (y/n): " run_test
    if [ "$run_test" = "y" ] || [ "$run_test" = "Y" ]; then
        log_info "运行 hello-world 容器..."
        if docker run --rm hello-world; then
            log_success "Docker 测试成功!"
        else
            log_error "Docker 测试失败"
            return 1
        fi
    fi
}

# 显示配置摘要
show_summary() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  配置完成摘要${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    if [ -n "$CT_ID" ]; then
        echo "容器 ID: $CT_ID"
        if [ -n "$CT_NAME" ]; then
            echo "容器名称: $CT_NAME"
        fi
        if [ -n "$USE_PRIVILEGED" ]; then
            if [ "$USE_PRIVILEGED" = true ]; then
                echo "容器类型: 特权容器"
            else
                echo "容器类型: 非特权容器"
            fi
        fi
        echo "配置备份: /etc/pve/lxc/${CT_ID}.conf.backup.*"
    fi
    echo ""
    echo "已添加的关键配置:"
    if [ "$USE_PRIVILEGED" = true ]; then
        echo "  - unprivileged: 0 (特权容器)"
    fi
    echo "  - features: nesting=1"
    echo "  - lxc.apparmor.profile: unconfined"
    echo "  - lxc.cgroup2.devices.allow: a"
    echo "  - lxc.cap.drop: (空)"
    echo "  - lxc.mount.auto: proc:rw sys:rw"
    echo ""
    echo -e "${YELLOW}注意事项:${NC}"
    echo "1. 如果 Docker 仍有问题，请尝试重启容器"
    if [ "$USE_PRIVILEGED" = true ]; then
        echo "2. 特权容器具有更高权限，请注意安全"
    else
        echo "2. 非特权容器某些 Docker 功能可能受限"
    fi
    echo "3. 建议定期更新 Docker 到最新版本"
    echo ""
}

# 主函数
main() {
    check_root
    show_welcome
    detect_environment
    
    if [ "$ENV_TYPE" = "pve_host" ]; then
        # 在 PVE 宿主机上运行
        get_ct_id
        backup_config
        configure_pve_host
        
        echo ""
        log_info "PVE 宿主机配置完成"
        echo ""
        echo -e "${YELLOW}下一步:${NC}"
        echo "1. 进入容器: pct enter $CT_ID"
        echo "2. 在容器内运行此脚本进行 Docker 配置"
        echo "   或手动安装和配置 Docker"
        
    elif [ "$ENV_TYPE" = "lxc" ]; then
        # 在 LXC 容器内运行
        configure_container_docker
        test_docker
        
        echo ""
        log_success "容器内 Docker 配置完成"
        
    fi
    
    show_summary
    
    echo ""
    log_success "所有配置已完成!"
}

# 运行主函数
main
