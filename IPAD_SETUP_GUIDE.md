# 📲 iPad 验证指南 — kuCar

无需 Mac、无需 Apple Developer 账号、无需等待审核。

---

## ⚠️ 先确认 iPadOS 版本

**必须 iPadOS 17.0+**

检查方法：设置 → 通用 → 关于本机 → 软件版本

如果低于 17.0，先更新系统。

---

## 🔧 如果 Swift Playgrounds 崩溃

已准备 **3 个版本**，按顺序尝试：

| 版本 | 文件夹 | 说明 |
|------|--------|------|
| **A（首选）** | `kuCarPlayground-root.swiftpm` | 最兼容格式 — 所有文件在根目录 |
| **B（备选）** | `kuCarPlayground-flat.swiftpm` | 扁平 Sources/ 结构 |
| **C（原始）** | `kuCarPlayground.swiftpm` | 已修复后的原始版本 |

### 诊断步骤

**先测试最小版本确认 Playgrounds 本身正常：**

1. 先把 `TestPlayground.swiftpm` 传到 iPad
2. 在 Swift Playgrounds 中打开
3. 如果正常 → 显示绿色勾 + iOS 版本号 → Playgrounds 可用
4. 如果也崩溃 → iPadOS 版本太低，或 Swift Playgrounds 需重装

**然后按顺序试 A → B → C：**
- 哪个不崩溃就用哪个，内容完全一样

---

## 方法 1：iCloud 传输（推荐）

### 在 Windows 上
1. 浏览器打开 [iCloud.com](https://www.icloud.com)，登录
2. 进入 **iCloud Drive**
3. 把 `kuCarPlayground-root.swiftpm` 文件夹（或备选版本）拖入

### 在 iPad 上
1. 打开 **文件** App → iCloud Drive
2. 找到这个文件夹 → **长按** → **共享** → **Swift Playgrounds**
3. 点击右上角 ▶️ 运行

---

## 方法 2：AirDrop / 微信 / QQ

1. Windows 上把文件夹**压缩为 .zip**
2. 发到 iPad（微信文件传输 / QQ / 邮件）
3. iPad 上解压
4. Swift Playgrounds → 右上角「...」→ 导入 → 选择文件夹
5. 点击 ▶️ 运行

---

## 崩溃原因已修复

原版 `kuCarPlayground.swiftpm` 有以下问题，已全部修复：

| 问题 | 修复 |
|------|------|
| `teamIdentifier: ""` 空字符串导致解析失败 | 已移除该参数 |
| `capabilities` 字符串不兼容 | 已移除 |
| 嵌套子目录（App/Views/Models/Services）可能不被识别 | 创建了根目录扁平版 |
| `path: "Sources"` 某些版本不支持 | 根目录版用 `path: "."` |

---

## 运行后你能看到

```
🏠 首页
  ├─ 快速体验 → 示例轿车 → AI识别模拟 → 改色编辑器
  ├─ SUV体验 → 示例SUV → AI识别模拟 → 改色编辑器
  └─ 从相册选择 → 相册 → AI识别模拟 → 改色编辑器

🎨 改色编辑器
  ├─ 19种颜色预设 + 3种材质切换 + 强度调节
  └─ 实时渲染 → 导出/保存

🔧 轮毂编辑器 → 8种轮毂 → 导出

📤 导出 → 保存到相册 / 系统分享
```

---

## 与正式版区别

| 功能 | iPad Demo | 正式版 |
|------|-----------|--------|
| 运行环境 | Swift Playgrounds | Xcode 编译 |
| AI分割 | 模拟（整车） | CoreML DeepLabV3 像素级 |
| 渲染 | Core Image | Core Image + Metal PBR |
| 分面板着色 | ❌ | ✅ 12个面板独立 |
| 轮毂叠加 | UI 就绪 | ✅ 透视合成 |
| 材质 | 3种 | 8种 |
