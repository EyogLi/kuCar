# App Store 审核说明 (App Store Review Notes)

## 应用基本信息

- **App Name**: kuCar
- **Version**: 1.0.0
- **Category**: 生活方式 (Lifestyle)
- **Age Rating**: 4+
- **Minimum OS**: iOS 17.0
- **Languages**: 简体中文, English

## AI 功能声明 (Guideline 5.1.2)

**所有AI处理均在设备端完成，无需联网。**

This app uses on-device CoreML models for car body segmentation and wheel detection.  
All image processing is performed locally on the device via:

1. **CoreML** — DeepLabV3 semantic segmentation model (bundled with app)
2. **Vision Framework** — Image analysis request dispatching
3. **Core Image + Metal** — Color rendering and wheel compositing
4. **Neural Engine** — Hardware-accelerated inference

**No user photos are uploaded to any server. No internet connection is required for core functionality.**

## 隐私说明

- 相机访问：仅用于拍摄车辆照片
- 相册访问：仅用于加载已有照片和保存编辑结果
- 无数据收集：不收集、不分享、不上传任何用户数据
- 无第三方分析SDK

## AI生成内容标注

导出的图片会在以下位置添加 AI 标签：
1. 可选的可见水印 "kuCar AI" (用户可在导出设置中关闭)
2. EXIF 元数据标签 "Created with kuCar AI"
3. App 内部 UI 显示 "AI增强" 标识

## 内容审核机制

使用 Vision Framework 的 `VNDetectHumanRectanglesRequest` 检测不当内容，如检测到则阻止处理并提示用户。

## Apple Intelligence 兼容性

kuCar 兼容 iOS 18+ 的 Apple Intelligence 功能，但核心功能不依赖任何 Apple Intelligence 服务。

## TestFlight 测试说明

- 测试重点：CoreML分割精度、改色渲染效果、导出质量
- 推荐测试环境：iPhone 14 及以上机型（Neural Engine 优化）
- 已知限制：
  - 极度倾斜角度的车辆照片分割精度可能降低
  - 内置车型库参考照片需用户从网上下载（避免版权问题）
