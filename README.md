# iOS 视频底层技术学习项目

## 🎯 项目简介

这是一个系统化学习iOS视频底层技术的项目，从Core Media/Core Video最底层API到高级视频应用，分为5个层次，共20+个详细示例。

## 📱 运行项目

1. 打开 `AudioVideo.xcodeproj`
2. 选择模拟器或真机
3. 运行项目
4. 在主界面选择想要学习的知识点

## 📚 学习体系

### Layer 1: Core Media & Core Video (最底层)
视频系统的核心数据结构

- ✅ **CMSampleBuffer 详解** - 视频帧容器的完整解析
- ✅ **CVPixelBuffer 操作** - 直接操作像素数据（灰度、反色、亮度调整）
- ✅ **CMTime 时间系统** - 精确时间表示和计算
- ✅ **像素格式详解** - RGB、YUV、BGRA等格式对比

### Layer 2: 原始数据采集与处理
AVFoundation底层采集

- ✅ **AVCaptureVideoDataOutput** - 实时获取原始视频帧（完整实现，带性能监控）
- ✅ **AVAssetReader 逐帧读取** - 从视频文件精确读取每一帧（完整实现）
- ⏳ **AVAssetWriter 逐帧写入** - 将帧写入视频文件（占位）
- ⏳ **相机深度控制** - 手动对焦、曝光、白平衡（占位）

### Layer 3: 编解码与格式转换
VideoToolbox硬件编解码

- ⏳ **H.264/H.265 硬编码** - VideoToolbox编码器（占位）
- ⏳ **H.264/H.265 硬解码** - VideoToolbox解码器（占位）
- ⏳ **格式转换与转码** - 分辨率、码率转换（占位）
- ⏳ **AVAssetExportSession** - 高层导出API（占位）

### Layer 4: Metal 渲染与自定义滤镜
GPU加速视频处理

- ⏳ **Metal 视频渲染管线** - Metal基础（占位）
- ⏳ **自定义 Metal 滤镜** - 着色器编程（占位）
- ⏳ **Core Image + Metal** - 结合使用（占位）
- ⏳ **GPU 性能优化** - MPS和优化技巧（占位）

### Layer 5: 高级视频应用
实际应用效果

- ⏳ **实时美颜算法** - 磨皮、美白、瘦脸（占位）
- ⏳ **绿幕抠图** - Chroma Key实现（占位）
- ⏳ **多轨道视频合成** - AVComposition（占位）
- ⏳ **视频水印与字幕** - 自定义合成器（占位）
- ⏳ **实时视频直播** - RTMP/HLS（占位）

## 📖 详细学习指南

### 核心文档

1. **[VIDEO_LEARNING_GUIDE.md](./VIDEO_LEARNING_GUIDE.md)** - 完整学习指南
   - 每个知识点的详细讲解
   - 核心API使用说明
   - 代码示例和最佳实践

2. **[YUV_VS_RGB_EXPLAINED.md](./YUV_VS_RGB_EXPLAINED.md)** - YUV颜色空间深度解析
   - 为什么YUV更接近人眼感知？
   - YUV vs RGB详细对比
   - 色度降采样原理
   - 在iOS中的实际应用

2.1 **[PIXEL_FORMAT_MEMORY_CALCULATION.md](./PIXEL_FORMAT_MEMORY_CALCULATION.md)** - 像素格式内存计算
   - YUV 4:2:0 为什么是1.5字节/像素？
   - 1920×1080 = 3MB 详细计算
   - 不同格式内存对比
   - iOS中的验证代码

3. **[THREADING_GUIDE.md](./THREADING_GUIDE.md)** - 线程管理最佳实践
   - AVFoundation线程安全
   - UIKit线程规则
   - 常见问题和解决方案

4. **[QUICKSTART.md](./QUICKSTART.md)** - 5分钟快速上手

## 🔑 核心特色

### 1. 完整的实现示例

已实现的示例都包含：
- 完整的UI界面
- 详细的代码注释
- 实时信息展示
- 性能监控
- 错误处理

例如 `CMSampleBufferViewController`:
- 实时采集视频帧
- 详细解析每一帧的结构
- 显示时间戳、格式、像素信息
- 展示CMSampleBuffer的各个组成部分

### 2. 渐进式学习

从最底层的数据结构开始：
```
CMSampleBuffer (数据容器)
    ↓
CVPixelBuffer (像素数据)
    ↓
AVCaptureVideoDataOutput (实时采集)
    ↓
AVAssetReader/Writer (文件读写)
    ↓
VideoToolbox (编解码)
    ↓
Metal (GPU处理)
    ↓
高级应用
```

### 3. 实用的代码示例

所有代码都可以直接运行，例如：

**CVPixelBuffer直接操作**:
```swift
// 锁定像素缓冲区
CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)

// 获取基地址
let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)

// 逐像素处理
for y in 0..<height {
    for x in 0..<width {
        let offset = y * bytesPerRow + x * 4
        let ptr = baseAddress.advanced(by: offset).assumingMemoryBound(to: UInt8.self)
        
        // 处理BGRA像素
        let b = ptr[0]
        let g = ptr[1]
        let r = ptr[2]
        let a = ptr[3]
        
        // 灰度转换
        let gray = UInt8(0.114 * Float(b) + 0.587 * Float(g) + 0.299 * Float(r))
        ptr[0] = gray
        ptr[1] = gray
        ptr[2] = gray
    }
}

CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
```

## 🚀 已实现功能

### CMSampleBuffer详解
- ✅ 实时相机采集
- ✅ 完整的CMSampleBuffer结构解析
- ✅ 时间信息（PTS、Duration）
- ✅ 格式描述（分辨率、编码格式）
- ✅ 像素缓冲区信息
- ✅ 附件信息展示

### CVPixelBuffer操作
- ✅ 灰度转换算法
- ✅ 反色效果
- ✅ 亮度调整
- ✅ 像素读取和显示
- ✅ 实时预览

### CMTime时间系统
- ✅ CMTime结构详解
- ✅ 时间运算示例
- ✅ CMTimeRange使用
- ✅ 视频播放时间监控
- ✅ 时间码格式化

### AVCaptureVideoDataOutput
- ✅ 实时视频帧采集
- ✅ 帧率控制（15/30/60fps）
- ✅ 像素格式切换（BGRA/YUV）
- ✅ 性能监控（FPS、丢帧统计）
- ✅ 实时预览

### AVAssetReader
- ✅ 从相册选择视频
- ✅ 逐帧读取
- ✅ 手动前进/自动播放
- ✅ 进度条控制
- ✅ 详细的帧信息展示

## 💡 适合人群

- iOS视频开发初学者
- 需要深入理解底层原理的开发者
- 想要实现自定义视频处理的工程师
- 准备做视频相关面试的求职者

## 📝 学习建议

1. **按层次学习**：从Layer 1开始，逐层深入
2. **动手实践**：运行每个示例，观察效果
3. **阅读代码**：仔细阅读源码和注释
4. **修改实验**：尝试修改参数，理解影响
5. **查阅文档**：配合Apple官方文档学习

## 🔗 参考资源

- [AVFoundation Programming Guide](https://developer.apple.com/library/archive/documentation/AudioVideo/Conceptual/AVFoundationPG/)
- [Core Media Framework Reference](https://developer.apple.com/documentation/coremedia)
- [Core Video Programming Guide](https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/CoreVideo/)
- [VideoToolbox Framework](https://developer.apple.com/documentation/videotoolbox)
- [Metal Programming Guide](https://developer.apple.com/metal/)

## 🛠 技术栈

- Swift 5.9+
- iOS 18.0+
- AVFoundation
- Core Media
- Core Video
- VideoToolbox (待实现)
- Metal (待实现)
- Core Image

## 📊 项目进度

- ✅ 项目架构设计
- ✅ Layer 1: 完整实现（4个示例）
- ✅ Layer 2: 部分实现（2个完整示例 + 2个占位）
- ⏳ Layer 3: 占位实现（待完善）
- ⏳ Layer 4: 占位实现（待完善）
- ⏳ Layer 5: 占位实现（待完善）
- ✅ 详细学习文档

## 📄 License

MIT License

## 👨‍💻 贡献

欢迎提Issue和PR，一起完善这个学习项目！

## 🙏 致谢

感谢Apple提供强大的视频处理框架，感谢所有为iOS视频技术做出贡献的开发者！

---

⭐️ 如果这个项目对你有帮助，请给个Star！
