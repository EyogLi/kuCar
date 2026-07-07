# 📱 不上架 App Store 自己使用 — 完整指南

两种方案：AltStore（免费即时） + Apple Developer（稳定长期）

---

## 方案 A：AltStore 免费旁加载（现在就能用）

### 原理
```
你的 Apple ID（免费）→ AltStore 签名 IPA → 安装到 iPhone
                                        ↓
                              同 WiFi 下每隔 7 天自动续签
```

### 你需要
- Windows PC ✅ 已有
- iPhone/iPad ✅ 已有
- Apple ID（免费，不需要开发者账号）
- USB 数据线（首次安装需要）

### 第一步：在 Windows 上安装 AltServer

1. 下载 AltServer for Windows：[altstore.io](https://altstore.io)
2. 安装并运行 AltServer
3. 用 USB 连接 iPhone/iPad
4. 开启「信任此电脑」（iPhone 上弹出的提示）
5. 系统托盘 AltServer 图标 → Install AltStore → 选择你的 iPhone
6. 输入 Apple ID 和密码
7. AltStore 会出现在 iPhone 主屏幕

> ⚠️ 如果签名失败：Apple ID 可能没开两步验证，先去 appleid.apple.com 开通

### 第二步：用 Codemagic 编译 IPA

1. 把 kuCar 代码推送到 GitHub
```bash
cd d:/kuCar
git remote add origin https://github.com/YOUR_USER/kuCar.git
git push -u origin main
```

2. 打开 [codemagic.io](https://codemagic.io) → 免费注册 → 连接 GitHub
3. 选择 kuCar 仓库 → Codemagic 自动检测 `codemagic.yaml`
4. **手动触发一次编译**（点 "Start new build"）
5. 编译完成后 → 下载 **kuCar.ipa** 文件

### 第三步：安装到 iPhone

**方式 1：AltStore 直接安装**
1. 把 kuCar.ipa 发送到 iPhone（AirDrop / 微信 / 邮件）
2. iPhone 上打开文件 → 分享 → AltStore
3. AltStore 自动签名并安装
4. 首次打开：设置 → 通用 → VPN与设备管理 → 信任证书

**方式 2：AltServer 无线安装**
1. PC 和 iPhone 连同一个 WiFi
2. 运行 AltServer（系统托盘图标）
3. iPhone 打开 AltStore → My Apps → + → 浏览 → 选择 IPA

### 维护
- **每 7 天**：确保 PC 和 iPhone 在同一个 WiFi，AltServer 自动续签
- **如果忘了**：重新用 AltServer 签一次即可，数据不会丢失

### 限制
| 限制项 | 说明 |
|--------|------|
| 最多 3 个 App | 含 AltStore 自身，所以还能装 2 个 |
| 7 天签名 | 同 WiFi 下自动续签，否则需手动 |
| 10 个 App ID/周 | Apple 限制，正常使用不会触及 |
| 部分权限 | 推送通知不可用，iCloud 部分功能受限 |

---

## 方案 B：Apple Developer 账号（稳定长期）

当你确认 App 满意后，注册开发者账号获得更好的体验：

### 开通 ($99/年 ≈ ¥720)

1. [developer.apple.com](https://developer.apple.com) → 注册
2. 选 **Apple Developer Program** → 个人
3. 交费 + 验证身份（用 iPhone 双因素认证）

### 自动编译 + TestFlight 分发

注册后，你会拥有：
- App Store Connect API Key
- Team ID
- 证书自动管理

把 API Key 配置到 Codemagic 环境变量，之后每次 `git push`：
```
git push → Codemagic 编译(5分钟) → 自动上传 TestFlight → iPhone 收到通知 → 一键安装
```

### 对比

| | AltStore | Apple Developer + TestFlight |
|---|---|---|
| 费用 | 免费 | $99/年 |
| 安装方式 | AltServer 签名 | TestFlight App |
| 有效期 | 7 天（可续） | 90 天（可续） |
| 设备数 | 1 台 | 最多 100 台 |
| 推送通知 | ❌ | ✅ |
| App Store 分发 | ❌ | ✅ |
| 更新 | 手动下载 IPA | 自动推送 |
| 是否需要 Mac | ❌ | ❌（Codemagic 代编译） |

---

## 快速命令参考

```bash
# 推送代码触发编译
git add .
git commit -m "your message"
git push origin main

# Codemagic 编译完成后
# → 浏览器打开 https://codemagic.io → 下载 kuCar.ipa

# 更新 AltStore 签名 (到期前)
# → iPhone 打开 AltStore → My Apps → Refresh All
```

## 进阶：AltStore 自动续签

AltServer 运行在 Windows 后台时，只要：
1. PC 开着
2. iPhone 和 PC 同 WiFi
3. AltServer 在系统托盘运行

就会在到期前自动续签，不需要手动操作。把 AltServer 设为开机启动即可。
