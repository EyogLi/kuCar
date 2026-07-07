# kuCar — AI汽车改色 & 轮毂模拟 App

基于 CoreML AI 的 iOS 原生应用，支持对任意车型进行改色膜模拟和轮毂更换效果预览。

## 核心功能

- 🎨 **AI车身分割** — DeepLabV3 语义分割自动识别车身面板
- 🖌️ **改色膜模拟** — 支持光泽/哑光/缎面/金属/镀铬5种材质，40+颜色预设
- 🔧 **轮毂更换** — 20+轮毂样式，透视变换叠加，支持全轮更换
- 📸 **任意车型** — 拍照或从相册上传，AI自动识别
- 🚗 **内置车型库** — 10款热门车型免拍照直接使用
- 💾 **本地处理** — 所有AI推理在设备端完成，照片不上传服务器

## 技术栈

| 技术 | 用途 |
|------|------|
| SwiftUI | UI框架 |
| CoreML + Vision | AI车身分割 |
| Core Image + Metal | 改色渲染引擎 |
| SwiftData | 本地持久化 |
| AVFoundation | 相机集成 |

## 项目结构

```
kuCar/
├── App/                    # 应用入口、DI容器、导航
├── Core/
│   ├── Protocols/          # 服务协议定义
│   ├── Storage/            # SwiftData持久化
│   ├── Utilities/          # 工具类
│   ├── Extensions/         # 扩展
│   └── DesignSystem/       # 设计系统
├── Features/
│   ├── Home/               # 首页
│   ├── CameraImport/       # 照片导入
│   ├── CarSegmentation/    # AI分割服务
│   ├── ColorEditor/        # 改色编辑器
│   ├── WheelEditor/        # 轮毂编辑器
│   ├── Export/             # 导出分享
│   └── ProjectBrowser/     # 方案管理
└── Resources/
    ├── CoreMLModels/       # ML模型
    ├── CarDatabase/        # 内置车型数据库
    ├── WheelAssets/        # 轮毂素材
    └── MetalShaders/       # Metal着色器
```

## 系统要求

- iOS 17.0+
- Xcode 15.4+
- Swift 5.9+

## 快速开始

1. 在 Xcode 中创建新 iOS App 项目（SwiftUI + SwiftData）
2. 将 `kuCar/` 下的所有源文件添加到项目
3. 添加 Framework 依赖：CoreML, Vision, CoreImage, Metal, MetalKit
4. 下载 [DeepLabV3 CoreML Model](https://developer.apple.com/machine-learning/models/) 并放入 `Resources/CoreMLModels/`
5. 编译运行到 iPhone (iOS 17+)

详细设置说明见 [kuCar.xcodeproj/project.pbxproj.md](kuCar.xcodeproj/project.pbxproj.md)

## App Store 合规

- ✅ 所有AI处理在设备端完成（CoreML Neural Engine）
- ✅ 无用户数据上传
- ✅ 隐私清单 (PrivacyInfo.xcprivacy)
- ✅ AI生成内容标签
- ✅ 最小年龄限制

## 开发阶段

| Phase | 内容 | 状态 |
|-------|------|------|
| Phase 1 | MVP：整车改色 + 3种材质 + 导出 | 🚧 开发中 |
| Phase 2 | 分面板着色 + SAM细化 + 更多材质 | 📅 计划中 |
| Phase 3 | 轮毂更换 + WheelDetector训练 | 📅 计划中 |
| Phase 4 | 扩充车型库 + App Store上架 | 📅 计划中 |

## License

All rights reserved. © 2026 kuCar
