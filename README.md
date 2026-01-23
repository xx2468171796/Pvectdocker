# PVE 9 CT 瀹瑰櫒 Docker 閰嶇疆宸ュ叿

## 绠€浠?
杩欐槸涓€涓氦浜掑紡鑴氭湰锛岀敤浜庤В鍐?Proxmox VE 9 涓?LXC 瀹瑰櫒鏃犳硶姝ｅ父杩愯 Docker 鐨勯棶棰樸€?
## 闂鑳屾櫙

鍦?PVE 鐨?LXC 瀹瑰櫒涓洿鎺ヨ繍琛?Docker 浼氶亣鍒颁互涓嬪父瑙侀棶棰橈細

1. **鏉冮檺涓嶈冻**: 瀹瑰櫒榛樿鐨勫畨鍏ㄩ檺鍒堕樆姝?Docker 杩愯
2. **Nesting 鏈惎鐢?*: Docker 闇€瑕佸祵濂楄櫄鎷熷寲鏀寔
3. **AppArmor 闄愬埗**: 瀹夊叏閰嶇疆鏂囦欢闄愬埗浜嗗鍣ㄧ殑鎿嶄綔
4. **璁惧璁块棶鍙楅檺**: Docker 闇€瑕佽闂煇浜涜澶囪妭鐐?5. **鎸傝浇鏉冮檺闂**: Docker 闇€瑕佺壒瀹氱殑鎸傝浇鏉冮檺

## 鍔熻兘鐗规€?
- 鉁?鑷姩妫€娴嬭繍琛岀幆澧冿紙PVE 瀹夸富鏈烘垨 LXC 瀹瑰櫒锛?- 鉁?浜や簰寮忛厤缃祦绋嬶紝绠€鍗曟槗鐢?- 鉁?鑷姩澶囦唤瀹瑰櫒閰嶇疆鏂囦欢
- 鉁?鏀寔 Debian/Ubuntu 鍜?RHEL/CentOS 绯荤粺
- 鉁?鍙€夋嫨瀹夎 Docker 鎴栦粎閰嶇疆鐜版湁 Docker
- 鉁?鍖呭惈 Docker 鍔熻兘娴嬭瘯
- 鉁?璇︾粏鐨勬棩蹇楄緭鍑哄拰閿欒澶勭悊

## 浣跨敤鏂规硶

### 鏂规硶涓€锛氫袱姝ラ厤缃紙鎺ㄨ崘锛?


鑴氭湰浼氭彁绀烘偍杈撳叆瀹瑰櫒 ID锛岀劧鍚庤嚜鍔ㄩ厤缃鍣ㄧ殑蹇呰鍙傛暟銆?
#### 姝ラ 2: 鍦ㄥ鍣ㄥ唴閰嶇疆 Docker

```bash
bash <(curl -Ls https://raw.githubusercontent.com/xx2468171796/Pvectdocker/main/pvectdocker.sh)
```

閫夋嫨瀹夎 Docker 鎴栭厤缃幇鏈?Docker銆?
### 鏂规硶浜岋細鎵嬪姩閰嶇疆

濡傛灉鎮ㄦ洿鍠滄鎵嬪姩閰嶇疆锛屽彲浠ュ弬鑰冧互涓嬫楠わ細

#### 鍦?PVE 瀹夸富鏈轰笂

缂栬緫瀹瑰櫒閰嶇疆鏂囦欢 `/etc/pve/lxc/<CTID>.conf`锛屾坊鍔犱互涓嬪唴瀹癸細

```conf
# 鍚敤宓屽铏氭嫙鍖?features: nesting=1

# 绂佺敤 AppArmor 闄愬埗
lxc.apparmor.profile: unconfined

# 鍏佽鎵€鏈夎澶囪闂?lxc.cgroup2.devices.allow: a

# 绉婚櫎鑳藉姏闄愬埗
lxc.cap.drop:

# 鍏佽鎸傝浇
lxc.mount.auto: proc:rw sys:rw
```

閲嶅惎瀹瑰櫒浣块厤缃敓鏁堬細

```bash
pct stop <CTID>
pct start <CTID>
```

#### 鍦ㄥ鍣ㄥ唴

瀹夎 Docker锛堜互 Ubuntu/Debian 涓轰緥锛夛細

```bash
# 鏇存柊鍖呯储寮?apt-get update

# 瀹夎渚濊禆
apt-get install -y ca-certificates curl gnupg lsb-release

# 娣诲姞 Docker GPG key
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# 娣诲姞 Docker 浠撳簱
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# 瀹夎 Docker
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 鍚姩 Docker
systemctl enable docker
systemctl start docker

# 娴嬭瘯 Docker
docker run hello-world
```

## 閰嶇疆璇存槑

### 鍏抽敭閰嶇疆椤硅В閲?
| 閰嶇疆椤?| 璇存槑 | 浣滅敤 |
|--------|------|------|
| `features: nesting=1` | 鍚敤宓屽铏氭嫙鍖?| 鍏佽瀹瑰櫒鍐呰繍琛屽鍣紙Docker锛?|
| `lxc.apparmor.profile: unconfined` | 绂佺敤 AppArmor | 绉婚櫎瀹夊叏闄愬埗锛屽厑璁?Docker 鎿嶄綔 |
| `lxc.cgroup2.devices.allow: a` | 鍏佽鎵€鏈夎澶?| Docker 闇€瑕佽闂澶囪妭鐐?|
| `lxc.cap.drop:` | 绉婚櫎鑳藉姏闄愬埗 | 缁欎簣瀹瑰櫒鏇村鏉冮檺 |
| `lxc.mount.auto: proc:rw sys:rw` | 鎸傝浇鏉冮檺 | 鍏佽璇诲啓 proc 鍜?sys 鏂囦欢绯荤粺 |

### 瀹夊叏娉ㄦ剰浜嬮」

鈿狅笍 **璀﹀憡**: 杩欎簺閰嶇疆浼氶檷浣庡鍣ㄧ殑瀹夊叏闅旂鎬с€傚缓璁細

1. 浠呭湪鍙椾俊浠荤殑鐜涓娇鐢?2. 涓嶈鍦ㄧ敓浜х幆澧冪殑澶氱鎴峰満鏅腑浣跨敤
3. 瀹氭湡鏇存柊绯荤粺鍜?Docker
4. 浣跨敤闃茬伀澧欓檺鍒跺鍣ㄧ綉缁滆闂?5. 鑰冭檻浣跨敤涓撶敤鐨勮櫄鎷熸満鑰岄潪瀹瑰櫒杩愯 Docker

## 鏁呴殰鎺掗櫎

### Docker 鏃犳硶鍚姩

```bash
# 妫€鏌?Docker 鏈嶅姟鐘舵€?systemctl status docker

# 鏌ョ湅 Docker 鏃ュ織
journalctl -u docker -n 50

# 妫€鏌ュ唴鏍告ā鍧?lsmod | grep overlay
lsmod | grep br_netfilter
```

### 鏉冮檺閿欒

濡傛灉閬囧埌鏉冮檺閿欒锛岀‘璁わ細

1. 瀹瑰櫒閰嶇疆宸叉纭坊鍔?2. 瀹瑰櫒宸查噸鍚?3. 鍦?PVE 瀹夸富鏈轰笂妫€鏌ラ厤缃枃浠讹細
   ```bash
   cat /etc/pve/lxc/<CTID>.conf
   ```

### 缃戠粶闂

濡傛灉 Docker 瀹瑰櫒缃戠粶涓嶉€氾細

```bash
# 鍔犺浇蹇呰鐨勫唴鏍告ā鍧?modprobe overlay
modprobe br_netfilter

# 閰嶇疆绯荤粺鍙傛暟
cat > /etc/sysctl.d/99-docker.conf <<EOF
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

sysctl --system
```

### 瀛樺偍椹卞姩闂

濡傛灉閬囧埌瀛樺偍椹卞姩閿欒锛?
```bash
# 缂栬緫 /etc/docker/daemon.json
{
  "storage-driver": "overlay2"
}

# 閲嶅惎 Docker
systemctl restart docker
```

## 楠岃瘉瀹夎

杩愯浠ヤ笅鍛戒护楠岃瘉 Docker 鏄惁姝ｅ父宸ヤ綔锛?
```bash
# 妫€鏌?Docker 鐗堟湰
docker --version

# 妫€鏌?Docker 淇℃伅
docker info

# 杩愯娴嬭瘯瀹瑰櫒
docker run --rm hello-world

# 杩愯涓€涓畝鍗曠殑 Web 鏈嶅姟鍣ㄦ祴璇?docker run -d -p 8080:80 nginx
curl http://localhost:8080
docker stop $(docker ps -q)
```

## 鎬ц兘浼樺寲寤鸿

1. **浣跨敤 ZFS 瀛樺偍**: 濡傛灉 PVE 浣跨敤 ZFS锛屽鍣ㄤ篃搴斾娇鐢?ZFS 鏁版嵁闆?2. **闄愬埗鏃ュ織澶у皬**: 鍦?daemon.json 涓厤缃棩蹇楄疆杞?3. **浣跨敤 overlay2**: 纭繚浣跨敤 overlay2 瀛樺偍椹卞姩
4. **璧勬簮闄愬埗**: 鍦ㄥ鍣ㄩ厤缃腑璁剧疆鍚堢悊鐨?CPU 鍜屽唴瀛橀檺鍒?
```conf
# 鍦?/etc/pve/lxc/<CTID>.conf 涓?cores: 4
memory: 4096
swap: 2048
```

## 澶囦唤鍜屾仮澶?
鑴氭湰浼氳嚜鍔ㄥ浠介厤缃枃浠跺埌锛?```
/etc/pve/lxc/<CTID>.conf.backup.<鏃堕棿鎴?
```

濡傞渶鎭㈠锛?```bash
cp /etc/pve/lxc/<CTID>.conf.backup.<鏃堕棿鎴? /etc/pve/lxc/<CTID>.conf
pct stop <CTID>
pct start <CTID>
```

## 鏀寔鐨勭郴缁?
### PVE 鐗堟湰
- Proxmox VE 9.x

### 瀹瑰櫒鎿嶄綔绯荤粺
- Ubuntu 20.04/22.04/24.04
- Debian 11/12
- CentOS 8/9
- Rocky Linux 8/9
- AlmaLinux 8/9

## 甯歌闂 (FAQ)

**Q: 涓轰粈涔堜笉鎺ㄨ崘鍦?LXC 瀹瑰櫒涓繍琛?Docker锛?*

A: LXC 瀹瑰櫒鏈韩灏辨槸瀹瑰櫒鎶€鏈紝鍦ㄥ鍣ㄤ腑杩愯 Docker锛堝鍣ㄥ瀹瑰櫒锛変細澧炲姞澶嶆潅鎬у拰瀹夊叏椋庨櫓銆傛帹鑽愪娇鐢?KVM 铏氭嫙鏈鸿繍琛?Docker銆備絾鍦ㄦ煇浜涘満鏅笅锛堝寮€鍙戞祴璇曪級锛孡XC 瀹瑰櫒杩愯 Docker 鏄彲琛岀殑銆?
**Q: 閰嶇疆鍚?Docker 浠嶇劧鏃犳硶杩愯鎬庝箞鍔烇紵**

A: 
1. 妫€鏌ュ鍣ㄦ槸鍚﹀凡閲嶅惎
2. 鏌ョ湅 Docker 鏃ュ織锛歚journalctl -u docker`
3. 纭鎵€鏈夐厤缃」閮藉凡娣诲姞
4. 灏濊瘯浣跨敤鐗规潈瀹瑰櫒锛堜笉鎺ㄨ崘锛?
**Q: 鏄惁鍙互浣跨敤鐗规潈瀹瑰櫒锛?*

A: 鍙互锛屼絾涓嶆帹鑽愩€傜壒鏉冨鍣ㄤ細缁欎簣瀹瑰櫒鍑犱箮涓庡涓绘満鐩稿悓鐨勬潈闄愶紝瀛樺湪涓ラ噸鐨勫畨鍏ㄩ闄┿€傛湰鑴氭湰鎻愪緵鐨勯厤缃凡瓒冲 Docker 杩愯銆?
**Q: 濡備綍鍗歌浇锛?*

A: 
1. 鍦ㄥ鍣ㄥ唴鍗歌浇 Docker锛歚apt-get purge docker-ce docker-ce-cli containerd.io`
2. 鎭㈠瀹瑰櫒閰嶇疆澶囦唤
3. 閲嶅惎瀹瑰櫒

## 鏇存柊鏃ュ織

### v1.0 (2024)
- 鍒濆鐗堟湰
- 鏀寔 PVE 9
- 鏀寔涓绘祦 Linux 鍙戣鐗?- 浜や簰寮忛厤缃祦绋?
## 璁稿彲璇?
MIT License

## 璐＄尞

娆㈣繋鎻愪氦闂鍜屾敼杩涘缓璁紒

## 鐩稿叧璧勬簮

- [Proxmox VE 瀹樻柟鏂囨。](https://pve.proxmox.com/wiki/Main_Page)
- [Docker 瀹樻柟鏂囨。](https://docs.docker.com/)
- [LXC 瀹瑰櫒鏂囨。](https://linuxcontainers.org/lxc/documentation/)

---

## 支持作者 / 打赏

如果这个项目对你有帮助，欢迎支持作者继续维护更新（不强制，量力而行）。

![赞赏码](donate_qr.png)

### USDT (TRC20)

- 地址：`TNp2BLnqrsgGPjrABQwvTq6cWyT8iRKk3D`
- 网络：TRC20

![USDT TRC20 QR](usdt_trc20_qr.jpg)

## Support / Donate

If this project helps you, consider supporting the author (optional).

![Donate QR](donate_qr.png)

### USDT (TRC20)

- Address: `TNp2BLnqrsgGPjrABQwvTq6cWyT8iRKk3D`
- Network: TRC20

![USDT TRC20 QR](usdt_trc20_qr.jpg)
