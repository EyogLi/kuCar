# 🖥️ Windows 开发指南 — kuCar

本指南教你如何在 Windows 电脑上开发 iOS 应用，通过 CI/CD 云端编译，在 iPhone/iPad 上测试。

---

## 开发流程全览

```
┌─────────────────────────────────────────────────────────────┐
│  你在 Windows 上写代码                                        │
│  ↓  git push                                                │
│  云端 Mac (Codemagic/GitHub Actions) 自动编译                │
│  ↓  自动上传                                                │
│  TestFlight → 你的 iPhone/iPad 安装测试                      │
│  ↓  审核通过                                                │
│  App Store 上架 🎉                                          │
└─────────────────────────────────────────────────────────────┘
```

---

## 第一步：准备 Apple 开发者账号

### 1.1 注册 Apple Developer
1. 访问 [developer.apple.com](https://developer.apple.com)
2. 注册 Apple ID（如果没有）
3. 加入 Apple Developer Program：
   - **个人账号**：$99/年（约 ¥720）
   - 需要双因素认证设备（你的 iPhone 即可）

### 1.2 创建 App ID
1. 登录 [App Store Connect](https://appstoreconnect.apple.com)
2. 进入「证书、标识符和描述文件」
3. 创建新的 App ID：
   - Bundle ID: `com.kucar.app`
   - 启用功能：无特殊需求

### 1.3 创建 App Store Connect 应用记录
1. App Store Connect → 我的 App → +
2. 平台：iOS
3. 名称：kuCar
4. Bundle ID：选择上面创建的
5. SKU：`com.kucar.app`

---

## 第二步：配置 Codemagic（推荐）

Codemagic 是专门为移动端 CI/CD 设计的云服务，**免费 500 分钟/月**（够编译 10-15 次）。

### 2.1 注册 Codemagic
1. 访问 [codemagic.io](https://codemagic.io)
2. 用 GitHub/GitLab 账号注册
3. 连接你的代码仓库

### 2.2 配置 Apple 签名
1. Codemagic → Teams → 你的 Team → Integrations
2. 连接 **App Store Connect API**
3. 在 App Store Connect 生成 API Key：
   - 用户和访问 → 密钥 → App Store Connect API
   - 下载 `.p8` 文件
4. 在 Codemagic 填入：
   - `APP_STORE_CONNECT_KEY_ID`
   - `APP_STORE_CONNECT_ISSUER_ID`
   - `APP_STORE_CONNECT_API_KEY` (`.p8` 文件内容)

### 2.3 配置环境变量
Codemagic → 你的 App → Environment Variables：
```
APP_STORE_CONNECT_KEY_ID = "你的KeyID"
APP_STORE_CONNECT_ISSUER_ID = "你的IssuerID"
APP_STORE_CONNECT_API_KEY = "@file:api_key.p8"
```

### 2.4 触发首次编译
1. 推送代码到 GitHub
2. Codemagic 会自动检测 `codemagic.yaml`
3. 开始编译 → 成功后自动上传 TestFlight
4. 在 iPhone/iPad 上打开 TestFlight App 安装测试

---

## 第三步：替代方案 — GitHub Actions

### 3.1 使用条件
- 公共仓库：**免费**（macOS runner 包含在免费额度中）
- 私有仓库：需要 GitHub Teams 或付费计划

### 3.2 配置
已创建 `.github/workflows/ios-build.yml`，无需额外配置。
- Push 到 `main` 分支 → 自动编译 Release + 生成 IPA
- Push 到 `develop` → 编译 Debug（仅验证代码）

> ⚠️ GitHub Actions 不支持自动上传 TestFlight，需手动或搭配 `fastlane`。

---

## 第四步：在 iPhone/iPad 上测试

### 4.1 安装 TestFlight
1. 在 iPhone/iPad 上打开 App Store
2. 搜索并安装 **TestFlight**

### 4.2 接受测试邀请
1. Codemagic 编译成功后 → 在 App Store Connect 添加测试员
2. 你的 iPhone/iPad 会收到 TestFlight 邀请邮件
3. 点击「在 TestFlight 中查看」→ 安装 kuCar

### 4.3 内部测试 vs 外部测试

| | 内部测试 | 外部测试 (TestFlight) |
|---|---|---|
| 人数 | 最多 100 人 | 最多 10,000 人 |
| 审核 | 无需审核 | 首次需 Beta 审核（1-2天） |
| 更新 | 即时 | 需重新审核 |
| 适用 | 开发阶段快速迭代 | 发布前大规模测试 |

---

## 第五步：日常开发工作流

### 5.1 在 Windows 上写代码

推荐编辑器：
- **VS Code** + Swift 扩展（免费）
- **JetBrains AppCode**（付费，但已停止更新）

VS Code 推荐扩展：
```
- Swift Language (sswg.swift-lang)
- SwiftFormat
- GitLens
```

### 5.2 本地验证（可选）
在 Windows 上编译 Swift 代码验证语法：
```bash
# 安装 Swift for Windows
# 下载：https://www.swift.org/download/
# 注意：只能编译检查，不能生成 iOS 二进制
swiftc -parse kuCar/**/*.swift
```

### 5.3 推送 → 云端编译 → 测试

```bash
# 1. 写代码...
git add .
git commit -m "feat: 添加新颜色预设"

# 2. 推送到 GitHub
git push origin develop

# 3. Codemagic 自动检测 push → 编译 Debug
# (约 5-10 分钟)

# 4. 合并到 main → 触发 Release 编译 → TestFlight
git checkout main
git merge develop
git push origin main

# 5. 打开 iPhone TestFlight → 安装新版本 → 测试
```

---

## 常见问题

### Q: 没有 Mac 能提交 App Store 吗？
**可以**。Codemagic 的云端 Mac 负责所有编译、签名、上传工作。

### Q: 编译需要多长时间？
首次约 10-15 分钟（安装 XcodeGen + 依赖），后续约 5-8 分钟。

### Q: 免费额度够用吗？
- Codemagic 免费档：500 分钟/月 ≈ 每月 10-15 次编译
- GitHub Actions：公共仓库 macOS 免费 6 小时/月

### Q: 代码签名怎么处理？
Codemagic 自动管理签名。无需本地生成证书。

### Q: 如何调试崩溃？
- 在 Xcode (云端编译) 中，崩溃日志会自动上传
- 你在 App Store Connect → 崩溃报告 中查看
- iPhone 设置 → 隐私 → 分析与改进 → 分析数据 中也能找到

---

## 快速命令参考

```bash
# 初始化项目
cd d:/kuCar
git remote add origin https://github.com/YOUR_USER/kuCar.git
git add .
git commit -m "Initial commit: kuCar MVP"
git push -u origin main

# 触发 Release 编译（→ TestFlight）
git tag v1.0.0-beta.1
git push --tags

# 查看 CI 状态
# 打开 https://codemagic.io → 你的 App → Builds

# 本地编辑
code .   # 用 VS Code 打开
```
