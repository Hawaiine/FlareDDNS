# ☁️ FlareDDNS

> 🚀 **Cloudflare 测速优选 IP，全自动 DDNS — 从此告别慢速 CDN！**

[![GitHub](https://img.shields.io/badge/Powered%20by-CloudflareST-blue?style=flat-square)](https://github.com/XIU2/CloudflareSpeedTest)
[![Shell](https://img.shields.io/badge/Shell-Bash-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

---

## 📖 FlareDDNS 是什么？

**FlareDDNS** 将 [CloudflareSpeedTest](https://github.com/XIU2/CloudflareSpeedTest) 与 Cloudflare DNS API 结合，一键实现：

1. 🔬 **自动测速** — 扫描数千个 Cloudflare IP，找到延迟最低、速度最快的节点
2. 🎯 **自动绑定** — 将最优 IP 按优先级分配到你的多个域名
3. 🔄 **持续优选** — 配合定时任务，自动切换最佳线路

适用场景：科学上网 🛡️ · 网站加速 ⚡ · 视频流媒体优化 📺 · 跨国业务加速 🌍

---

## ✨ 核心亮点

| 特性 | 说明 |
|------|------|
| 🔑 **API Token 认证** | 用 Cloudflare API Token 替代已废弃的 Global Key，精细权限更安全 |
| 📦 **无限域名** | 数组配置，支持任意数量域名，不再被 5 个限制 |
| 🤖 **Record ID 自动获取** | 只填域名，脚本自动查 ID，零手工操作 |
| 🛡️ **全链路校验** | API 认证、记录查找、测速结果 — 每步都有错误提示 |
| 🔒 **防并发锁** | 自动检测重复运行，防止测速冲突 |
| 🎨 **彩色日志** | ✅ ❌ ⚠️ 一目了然 |
| 🔧 **配置脚本分离** | 改配置不动脚本，升级无痛 |
| 🧹 **自动清理** | 执行完自动删除临时文件 |

---

## 📋 环境要求

- 🐧 **Linux / macOS / WSL** 系统
- 🖥️ **Bash 4.0+**
- 🐍 **Python 3**（解析 JSON，多数系统自带）
- 🌐 **curl**

---

## 🚀 5 分钟上手

### 1️⃣ 下载 CloudflareST

从 [XIU2/CloudflareSpeedTest Releases](https://github.com/XIU2/CloudflareSpeedTest/releases) 下载最新版，解压后将 `cfst` 放入 `scripts/` 目录。

### 2️⃣ 创建 API Token（代替 Global Key）

进入 [Cloudflare API Tokens](https://dash.cloudflare.com/profile/api-tokens)：

1. **Create Token** → 选择 **Edit zone DNS** 模板
2. 权限设置：

| 权限 | 级别 |
|------|------|
| `Zone` → `Zone` | `Read` |
| `Zone` → `DNS` | `Edit` |

3. 作用域选择你的域名
4. 🔑 **立即复制 Token**（关闭页面就看不到了！）

> 💡 **为啥不用 Global Key？**
>
> | 对比项 | API Token ✅ | Global Key ❌ |
> |--------|------------|-------------|
> | 权限 | 仅 DNS 编辑 | 整个账号完全控制 |
> | 安全 | 可撤销、可限 IP | 泄露=号没了 |
> | 现状 | ✅ Cloudflare 推荐 | ⛔ 已废弃 |

### 3️⃣ 获取 Zone ID

Cloudflare Dashboard → 你的域名 → 右侧概览底部 → **区域 ID**

### 4️⃣ 配置 & 运行

```bash
cd scripts/
cp config.example.conf config.conf
chmod 600 config.conf            # 防止 Token 被其他用户读取
vim config.conf                  # 填入 Token、Zone ID、域名列表
bash flare_ddns.sh
```

> ⚠️ **安全提醒：** `config.conf` 含有 API Token，已被 `.gitignore` 保护。
> 执行 `git status` 前确认它不在待提交列表里！

### 5️⃣ 定时任务（自动优选）

```bash
crontab -e

# 每天凌晨 3 点更新
0 3 * * * cd /path/to/scripts/ && bash flare_ddns.sh >> flare_ddns.log 2>&1

# 或每 6 小时
0 */6 * * * cd /path/to/scripts/ && bash flare_ddns.sh >> flare_ddns.log 2>&1
```

---

## ⚙️ 配置参考

```bash
# ──────── 必填 ────────
CF_API_TOKEN="你的_API_TOKEN"         # Cloudflare API Token
CF_ZONE_ID="你的_区域ID"              # Zone ID
RECORD_NAMES=(                        # 域名数组（最快IP→第一个）
    "cdn1.yourdomain.com"
    "cdn2.yourdomain.com"
)

# ──────── 可选 ────────
CFST_ARGS="-p 0"                      # CloudflareST 参数（别写 -o，脚本会加）
DNS_TTL=60                            # TTL 秒 (60=自动)
DNS_PROXIED=false                     # 是否开启 CDN 代理 (orange cloud)
                                      # ⚠️ 开启后客户端走 Anycast 而非优选 IP
```

### ⚠️ 关键注意事项

- **不要在 `CFST_ARGS` 里写 `-o`** — 脚本会自动追加输出路径 `-o result.csv`
- **`DNS_PROXIED=true` 时** TTL 会被 Cloudflare 强制设为 auto(60)，且客户端走 Anycast 网络而非你测速选出的源站 IP，「优选 IP」提速效果会大打折扣

### CloudflareST 常用参数

| 参数 | 作用 | 默认 |
|------|------|------|
| `-n` | 测速线程数 | 200 |
| `-t` | 延迟测试次数 | 4 |
| `-dn` | 延迟结果数 | 10 |
| `-tl` | 延迟上限 (ms) | 300 |
| `-sl` | 速度下限 (MB/s) | 50 |
| `-p` | 显示结果数 (0=全部) | 10 |
| `-f` | 自定义 IP 列表 | 内置 |

📖 [完整文档](https://github.com/XIU2/CloudflareSpeedTest)

---

## 📊 运行效果

```bash
$ bash flare_ddns.sh

🔍 正在获取 DNS 记录列表...
  ✅ cdn1.yourdomain.com → ID: abc123...
  ✅ cdn2.yourdomain.com → ID: def456...

🚀 正在运行 CloudflareSpeedTest 测速...
  # CloudflareST 正在测速中...

📡 正在更新 DNS 记录...
  [1/2] 更新 cdn1.yourdomain.com → 104.16.xxx.xxx
    ✔  更新成功
  [2/2] 更新 cdn2.yourdomain.com → 104.17.xxx.xxx
    ✔  更新成功

🎉 完成！共更新 2/2 条 DNS 记录
```

---

## 📁 项目结构

```
FlareDDNS/
├── .gitignore                 # 🔒 忽略 config.conf、cfst、*.log
├── README.md                  # 📖 说明文档
└── scripts/
    ├── flare_ddns.sh          # 🔧 主脚本
    ├── config.example.conf    # 📝 配置模板（复制为 config.conf）
    ├── config.conf            # ⚙️ 你的配置（已在 .gitignore 中）
    └── cfst                   # 🏃 CloudflareST 工具
```

---

## 🔄 相比旧版有哪些改进？

| 项目 | 🗑️ 旧版 | 🆕 FlareDDNS |
|------|---------|-------------|
| 🔑 认证 | Global API Key + Email | API Token (Bearer) |
| 📦 域名数 | 固定 5 个，重复代码 | 数组，任意数量 |
| 🆔 Record ID | 手动查了填 | 自动获取 |
| 🛡️ 容错 | 失败无感知 | 每步校验+提示 |
| 🔐 防并发 | 无 | flock 锁 |
| 🚫 隔离性 | 输出路径不可控 | -o 强制绑定到脚本目录 |
| 🔒 安全 | — | .gitignore 防 Token 泄露 |
| 🎨 输出 | 白底黑字 | 彩色日志 |
| ⚙️ 配置 | 硬编码在脚本里 | 独立配置文件 |
| 📋 验证 | 无 | 配置完整性检查 |

---

## ❓ 常见问题

<details>
<summary><strong>Q: 报 "API 认证失败"？</strong></summary>

1. 检查 `config.conf` 中 Token 是否正确
2. 确认 Token 有 `Zone:Zone:Read` + `Zone:DNS:Edit` 权限
3. 确认 Token 作用域包含你要更新的域名
4. 去 [API Tokens 页面](https://dash.cloudflare.com/profile/api-tokens) 验证
</details>

<details>
<summary><strong>Q: 测速结果不理想？</strong></summary>

- 加大线程 `-n 500`，降低延迟上限 `-tl 200`
- 自定义 IP 段：`-f my_ip.txt`
- 参考 [XIU2 Wiki](https://github.com/XIU2/CloudflareSpeedTest/wiki)
</details>

<details>
<summary><strong>Q: 还需要手动查 Record ID 吗？</strong></summary>

**不用了** 🎉 新版脚本通过 API 自动获取所有 A 记录的 Name → ID 映射，你只需在 `RECORD_NAMES` 数组里填域名即可。
</details>

<details>
<summary><strong>Q: 不小心把带着 Token 的 config.conf 提交了怎么办？</strong></summary>

1. **立即在 Cloudflare 后台撤销该 Token**
2. 创建新 Token
3. 在仓库中执行 `git rm --cached scripts/config.conf` 解除追踪
4. 确认 `.gitignore` 已包含 `config.conf`
5. 后续操作参考 [GitHub 官方文档 — 从仓库中移除敏感数据](https://docs.github.com/zh/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository)
</details>

<details>
<summary><strong>Q: DNS_PROXIED=true 有什么影响？</strong></summary>

开启 CDN 代理（橙色云）后：
- TTL 被 Cloudflare 强制设为 auto(60)，`DNS_TTL` 设置失效
- 客户端访问走 Cloudflare Anycast 网络，而非你测速选出的具体源站 IP
- 「优选 IP 提速」效果基本失效，建议保持 `false`
</details>

---

## 🙏 致谢

- [XIU2/CloudflareSpeedTest](https://github.com/XIU2/CloudflareSpeedTest) — 优秀的 Cloudflare IP 测速工具

---

## 📄 License

[MIT](LICENSE) © 2024 Hawaiine