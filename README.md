# PVE 9 CT 容器 Docker 配置工具

## 简介

这是一个交互式脚本，用于解决 Proxmox VE 9 中 LXC 容器无法正常运行 Docker 的问题。

## 问题背景

在 PVE 的 LXC 容器中直接运行 Docker 会遇到以下常见问题：

1. **权限不足**: 容器默认的安全限制阻止 Docker 运行
2. **Nesting 未启用**: Docker 需要嵌套虚拟化支持
3. **AppArmor 限制**: 安全配置文件限制了容器的操作
4. **设备访问受限**: Docker 需要访问某些设备节点
5. **挂载权限问题**: Docker 需要特定的挂载权限

## 功能特性

- ✅ 自动检测运行环境（PVE 宿主机或 LXC 容器）
- ✅ 交互式配置流程，简单易用
- ✅ 自动备份容器配置文件
- ✅ 支持 Debian/Ubuntu 和 RHEL/CentOS 系统
- ✅ 可选择安装 Docker 或仅配置现有 Docker
- ✅ 包含 Docker 功能测试
- ✅ 详细的日志输出和错误处理

## 使用方法

### 方法一：两步配置（推荐）



脚本会提示您输入容器 ID，然后自动配置容器的必要参数。

#### 步骤 2: 在容器内配置 Docker

```bash
# 进入容器
pct enter <容器ID>

# 上传脚本到容器（或从宿主机复制）
# 在容器内运行脚本
chmod +x pve-ct-docker-setup.sh
./pve-ct-docker-setup.sh
```

选择安装 Docker 或配置现有 Docker。

### 方法二：手动配置

如果您更喜欢手动配置，可以参考以下步骤：

#### 在 PVE 宿主机上

编辑容器配置文件 `/etc/pve/lxc/<CTID>.conf`，添加以下内容：

```conf
# 启用嵌套虚拟化
features: nesting=1

# 禁用 AppArmor 限制
lxc.apparmor.profile: unconfined

# 允许所有设备访问
lxc.cgroup2.devices.allow: a

# 移除能力限制
lxc.cap.drop:

# 允许挂载
lxc.mount.auto: proc:rw sys:rw
```

重启容器使配置生效：

```bash
pct stop <CTID>
pct start <CTID>
```

#### 在容器内

安装 Docker（以 Ubuntu/Debian 为例）：

```bash
# 更新包索引
apt-get update

# 安装依赖
apt-get install -y ca-certificates curl gnupg lsb-release

# 添加 Docker GPG key
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# 添加 Docker 仓库
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# 安装 Docker
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 启动 Docker
systemctl enable docker
systemctl start docker

# 测试 Docker
docker run hello-world
```

## 配置说明

### 关键配置项解释

| 配置项 | 说明 | 作用 |
|--------|------|------|
| `features: nesting=1` | 启用嵌套虚拟化 | 允许容器内运行容器（Docker） |
| `lxc.apparmor.profile: unconfined` | 禁用 AppArmor | 移除安全限制，允许 Docker 操作 |
| `lxc.cgroup2.devices.allow: a` | 允许所有设备 | Docker 需要访问设备节点 |
| `lxc.cap.drop:` | 移除能力限制 | 给予容器更多权限 |
| `lxc.mount.auto: proc:rw sys:rw` | 挂载权限 | 允许读写 proc 和 sys 文件系统 |

### 安全注意事项

⚠️ **警告**: 这些配置会降低容器的安全隔离性。建议：

1. 仅在受信任的环境中使用
2. 不要在生产环境的多租户场景中使用
3. 定期更新系统和 Docker
4. 使用防火墙限制容器网络访问
5. 考虑使用专用的虚拟机而非容器运行 Docker

## 故障排除

### Docker 无法启动

```bash
# 检查 Docker 服务状态
systemctl status docker

# 查看 Docker 日志
journalctl -u docker -n 50

# 检查内核模块
lsmod | grep overlay
lsmod | grep br_netfilter
```

### 权限错误

如果遇到权限错误，确认：

1. 容器配置已正确添加
2. 容器已重启
3. 在 PVE 宿主机上检查配置文件：
   ```bash
   cat /etc/pve/lxc/<CTID>.conf
   ```

### 网络问题

如果 Docker 容器网络不通：

```bash
# 加载必要的内核模块
modprobe overlay
modprobe br_netfilter

# 配置系统参数
cat > /etc/sysctl.d/99-docker.conf <<EOF
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

sysctl --system
```

### 存储驱动问题

如果遇到存储驱动错误：

```bash
# 编辑 /etc/docker/daemon.json
{
  "storage-driver": "overlay2"
}

# 重启 Docker
systemctl restart docker
```

## 验证安装

运行以下命令验证 Docker 是否正常工作：

```bash
# 检查 Docker 版本
docker --version

# 检查 Docker 信息
docker info

# 运行测试容器
docker run --rm hello-world

# 运行一个简单的 Web 服务器测试
docker run -d -p 8080:80 nginx
curl http://localhost:8080
docker stop $(docker ps -q)
```

## 性能优化建议

1. **使用 ZFS 存储**: 如果 PVE 使用 ZFS，容器也应使用 ZFS 数据集
2. **限制日志大小**: 在 daemon.json 中配置日志轮转
3. **使用 overlay2**: 确保使用 overlay2 存储驱动
4. **资源限制**: 在容器配置中设置合理的 CPU 和内存限制

```conf
# 在 /etc/pve/lxc/<CTID>.conf 中
cores: 4
memory: 4096
swap: 2048
```

## 备份和恢复

脚本会自动备份配置文件到：
```
/etc/pve/lxc/<CTID>.conf.backup.<时间戳>
```

如需恢复：
```bash
cp /etc/pve/lxc/<CTID>.conf.backup.<时间戳> /etc/pve/lxc/<CTID>.conf
pct stop <CTID>
pct start <CTID>
```

## 支持的系统

### PVE 版本
- Proxmox VE 9.x

### 容器操作系统
- Ubuntu 20.04/22.04/24.04
- Debian 11/12
- CentOS 8/9
- Rocky Linux 8/9
- AlmaLinux 8/9

## 常见问题 (FAQ)

**Q: 为什么不推荐在 LXC 容器中运行 Docker？**

A: LXC 容器本身就是容器技术，在容器中运行 Docker（容器套容器）会增加复杂性和安全风险。推荐使用 KVM 虚拟机运行 Docker。但在某些场景下（如开发测试），LXC 容器运行 Docker 是可行的。

**Q: 配置后 Docker 仍然无法运行怎么办？**

A: 
1. 检查容器是否已重启
2. 查看 Docker 日志：`journalctl -u docker`
3. 确认所有配置项都已添加
4. 尝试使用特权容器（不推荐）

**Q: 是否可以使用特权容器？**

A: 可以，但不推荐。特权容器会给予容器几乎与宿主机相同的权限，存在严重的安全风险。本脚本提供的配置已足够 Docker 运行。

**Q: 如何卸载？**

A: 
1. 在容器内卸载 Docker：`apt-get purge docker-ce docker-ce-cli containerd.io`
2. 恢复容器配置备份
3. 重启容器

## 更新日志

### v1.0 (2024)
- 初始版本
- 支持 PVE 9
- 支持主流 Linux 发行版
- 交互式配置流程

## 许可证

MIT License

## 贡献

欢迎提交问题和改进建议！

## 相关资源

- [Proxmox VE 官方文档](https://pve.proxmox.com/wiki/Main_Page)
- [Docker 官方文档](https://docs.docker.com/)
- [LXC 容器文档](https://linuxcontainers.org/lxc/documentation/)
