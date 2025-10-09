# 快速开始

## 🚀 5分钟上手

### 1. 打开项目

```bash
cd /Users/tangyumeng/Documents/ios-learn/AudioVideo2
open AudioVideo.xcodeproj
```

### 2. 运行应用

1. 选择目标设备：模拟器或真机
2. 点击运行按钮（⌘R）
3. 等待编译完成

### 3. 开始学习

应用启动后，你会看到分层的学习目录：

```
Layer 1: Core Media & Core Video
├── CMSampleBuffer 详解
├── CVPixelBuffer 操作
├── CMTime 时间系统
└── 像素格式详解

Layer 2: 原始数据采集与处理
├── AVCaptureVideoDataOutput
├── AVAssetReader 逐帧读取
├── AVAssetWriter 逐帧写入
└── 相机深度控制

Layer 3: 编解码与格式转换
...

Layer 4: Metal 渲染与自定义滤镜
...

Layer 5: 高级视频应用
...
```

## 🎓 推荐学习路径

### 第一天：理解数据结构

**上午：CMSampleBuffer**
1. 点击 "CMSampleBuffer 详解"
2. 点击 "开始采集" 按钮
3. 观察实时显示的帧信息：
   - 时间戳（PTS）
   - 格式描述
   - 像素缓冲区信息
   - 附件数据

**下午：CVPixelBuffer**
1. 点击 "CVPixelBuffer 操作"
2. 选择不同的处理模式：
   - 灰度转换
   - 反色效果
   - 亮度调整
   - 像素读取
3. 对比原始画面和处理后画面
4. 查看像素数据详情

### 第二天：时间系统

**上午：CMTime**
1. 点击 "CMTime 时间系统"
2. 阅读 CMTime 的结构说明
3. 查看代码示例
4. 播放视频，观察实时时间信息

**下午：像素格式**
1. 点击 "像素格式详解"
2. 学习各种像素格式的区别：
   - BGRA vs YUV
   - 内存占用对比
   - 适用场景
3. 查看格式转换代码示例

### 第三天：实时采集

**上午：VideoDataOutput**
1. 点击 "AVCaptureVideoDataOutput"
2. 选择不同的帧率（15/30/60fps）
3. 切换像素格式（BGRA/YUV）
4. 观察性能指标：
   - 实际FPS
   - 丢帧统计
   - 数据大小

**下午：AssetReader**
1. 点击 "AVAssetReader 逐帧读取"
2. 从相册选择一个视频
3. 点击 "下一帧" 手动查看每一帧
4. 使用 "自动播放" 连续读取
5. 拖动进度条跳转

### 第四天及以后

继续探索Layer 3、4、5的内容（部分功能待实现）

## 📝 学习技巧

### 1. 阅读源码

每个示例都有详细注释，建议打开源文件：

```
AudioVideo/ViewControllers/
├── Layer1_CoreMedia/
│   ├── CMSampleBufferViewController.swift    ← 详细注释
│   ├── CVPixelBufferViewController.swift
│   ├── CMTimeViewController.swift
│   └── PixelFormatViewController.swift
├── Layer2_RawCapture/
│   ├── VideoDataOutputViewController.swift
│   └── AssetReaderViewController.swift
...
```

### 2. 修改实验

尝试修改代码参数：

**示例1：修改帧率**
```swift
// 在VideoDataOutputViewController.swift中
camera.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 60)  // 改为60fps
```

**示例2：修改像素格式**
```swift
videoOutput?.videoSettings = [
    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange  // 改为YUV
]
```

### 3. 调试技巧

在关键位置添加断点：

```swift
func captureOutput(_ output: AVCaptureOutput,
                  didOutput sampleBuffer: CMSampleBuffer,
                  from connection: AVCaptureConnection) {
    // 在这里添加断点，查看 sampleBuffer 的内容
    let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
    // 检查 pixelBuffer 的详细信息
}
```

### 4. 使用Instruments

- Time Profiler：分析性能瓶颈
- Allocations：查看内存使用
- Core Animation：检查帧率

## ⚠️ 常见问题

### Q1: 相机权限请求

首次运行需要允许相机权限，如果拒绝了：
1. 打开 设置 > 隐私与安全性 > 相机
2. 找到 AudioVideo 并开启

### Q2: 模拟器没有相机

使用模拟器时，相机采集示例可能无法正常工作，建议：
- 使用真机测试
- 或查看代码了解原理

### Q3: 视频选择器没有视频

在 AssetReader 示例中，如果相册没有视频：
1. 先用系统相机录制一段视频
2. 或使用 AirDrop 从其他设备传输视频

### Q4: 编译错误

如果遇到编译错误：
1. 确保 Xcode 版本 >= 15.0
2. 确保 iOS 部署目标 >= 18.0
3. Clean Build Folder（⇧⌘K）
4. 重新编译

## 📚 进阶学习

### 阅读完整文档

查看 [`VIDEO_LEARNING_GUIDE.md`](./VIDEO_LEARNING_GUIDE.md) 获取：
- 详细的API说明
- 代码示例
- 最佳实践
- 性能优化建议

### 参考示例代码

核心代码位置：

**CMSampleBuffer解析**
```
AudioVideo/ViewControllers/Layer1_CoreMedia/CMSampleBufferViewController.swift
第 252-336 行：analyzeSampleBuffer 函数
```

**像素直接操作**
```
AudioVideo/ViewControllers/Layer1_CoreMedia/CVPixelBufferViewController.swift
第 218-283 行：convertToGrayscale 函数
```

**实时采集配置**
```
AudioVideo/ViewControllers/Layer2_RawCapture/VideoDataOutputViewController.swift
第 195-260 行：setupCaptureSession 函数
```

## 🎯 学习目标

完成所有Layer 1和Layer 2的示例后，你应该能够：

- ✅ 理解 CMSampleBuffer 的结构和作用
- ✅ 直接访问和修改像素数据
- ✅ 使用 CMTime 进行精确时间计算
- ✅ 了解各种像素格式的区别
- ✅ 实时采集视频帧并进行处理
- ✅ 从视频文件逐帧读取数据

## 💡 下一步

1. **完成Layer 1和2的学习**
2. **自己实现一个简单的滤镜**
3. **研究Layer 3-5的占位代码**
4. **参考官方文档实现更多功能**

## 🔗 有用的链接

- [项目主README](./README.md)
- [详细学习指南](./VIDEO_LEARNING_GUIDE.md)
- [Apple AVFoundation 文档](https://developer.apple.com/av-foundation/)
- [Core Media 文档](https://developer.apple.com/documentation/coremedia)

---

开始你的iOS视频开发之旅吧！🚀
