# iOS 视频技术底层学习指南

这是一个系统化的iOS视频技术学习项目，从最底层的Core Media API到高级的视频应用，逐层深入。

## 📚 学习路线图

### Layer 1: Core Media & Core Video (最底层)

这一层讲解iOS视频系统的核心数据结构，是理解所有上层API的基础。

#### 1.1 CMSampleBuffer 详解
**文件**: `CMSampleBufferViewController.swift`

**核心知识点**:
- CMSampleBuffer是什么？为什么需要它？
- 组成部分：CVImageBuffer、CMTime、CMFormatDescription、Attachments
- 实时采集并分析每一帧的结构
- 如何读取和解析各个组成部分

**关键API**:
```swift
// 获取时间戳
let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

// 获取像素数据
let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)

// 获取格式描述
let formatDesc = CMSampleBufferGetFormatDescription(sampleBuffer)

// 获取附件信息
let attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: false)
```

**实践项目**:
- 打开摄像头，实时显示每一帧的详细信息
- 理解PTS（Presentation Time Stamp）的作用
- 查看metadata和EXIF信息

---

#### 1.2 CVPixelBuffer 操作
**文件**: `CVPixelBufferViewController.swift`

**核心知识点**:
- CVPixelBuffer内存结构
- 如何直接访问和修改像素数据
- 像素格式（BGRA、YUV等）的内存布局
- CVPixelBuffer的锁定和解锁机制
- 零拷贝技术（IOSurface）

**关键API**:
```swift
// 锁定像素缓冲区
CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)

// 获取基地址
let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)

// 逐像素处理
let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
for y in 0..<height {
    for x in 0..<width {
        let offset = y * bytesPerRow + x * 4
        let ptr = baseAddress.advanced(by: offset).assumingMemoryBound(to: UInt8.self)
        // 访问 BGRA 值
        let b = ptr[0]
        let g = ptr[1]
        let r = ptr[2]
        let a = ptr[3]
    }
}

// 解锁
CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
```

**实践项目**:
- 实现灰度转换
- 实现反色效果
- 实现亮度调整
- 读取并显示像素值

---

#### 1.3 CMTime 时间系统
**文件**: `CMTimeViewController.swift`

**核心知识点**:
- 为什么不用Double？有理数表示的优势
- CMTime结构：value、timescale、flags、epoch
- CMTime的运算：加减乘除
- CMTimeRange的概念和使用
- 特殊值：zero、invalid、infinity

**关键API**:
```swift
// 创建CMTime
let time1 = CMTime(value: 1, timescale: 30)  // 30fps中的1帧
let time2 = CMTime(seconds: 1.5, preferredTimescale: 600)

// CMTime运算
let sum = CMTimeAdd(time1, time2)
let diff = CMTimeSubtract(time1, time2)
let scaled = CMTimeMultiply(time1, multiplier: 2)

// CMTimeRange
let range = CMTimeRange(start: start, duration: duration)
let contains = range.containsTime(time)
```

**实践项目**:
- 播放视频，实时显示CMTime信息
- 计算视频进度百分比
- 实现精确的时间定位
- 理解timescale对精度的影响

---

#### 1.4 像素格式详解
**文件**: `PixelFormatViewController.swift`

**核心知识点**:
- RGB vs YUV：为什么视频用YUV？
- 主要格式对比：
  - BGRA (32bit): 最常用，每像素4字节
  - 420YpCbCr8BiPlanarVideoRange (NV12): 视频编码标准
  - 420YpCbCr8Planar (YUV420p): 三平面格式
- 色度采样：4:4:4、4:2:2、4:2:0的区别
- FourCC代码的含义
- 内存占用对比

**格式对比表**:

| 格式 | FourCC | 字节/像素 | 1080p内存 | 适用场景 |
|-----|--------|----------|----------|---------|
| BGRA | 'BGRA' | 4 | 8MB | 屏幕显示、图像处理 |
| RGBA | 'RGBA' | 4 | 8MB | OpenGL、Metal |
| NV12 | '420v' | 1.5 | 3MB | H.264/H.265编码 |
| YUV420p | 'y420' | 1.5 | 3MB | 视频处理、滤镜 |

**颜色空间转换**:
```swift
// RGB → Grayscale
gray = 0.299*R + 0.587*G + 0.114*B

// RGB → YUV
Y = 0.299*R + 0.587*G + 0.114*B
U = -0.147*R - 0.289*G + 0.436*B
V = 0.615*R - 0.515*G - 0.100*B
```

---

### Layer 2: AVFoundation 原始数据采集与处理

这一层讲解如何使用AVFoundation获取和处理原始视频帧数据。

#### 2.1 AVCaptureVideoDataOutput
**文件**: `VideoDataOutputViewController.swift`

**核心知识点**:
- 实时视频帧采集的标准方法
- videoSettings配置详解
- 帧率控制：minFrameDuration vs maxFrameDuration
- 性能优化：alwaysDiscardsLateVideoFrames
- 代理队列的选择和配置
- 丢帧处理机制

**完整配置示例**:
```swift
// 创建session
let captureSession = AVCaptureSession()
captureSession.sessionPreset = .vga640x480

// 添加相机输入
let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
let input = try AVCaptureDeviceInput(device: camera)
captureSession.addInput(input)

// 配置帧率
try camera.lockForConfiguration()
camera.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 30)
camera.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: 30)
camera.unlockForConfiguration()

// 创建VideoDataOutput
let videoOutput = AVCaptureVideoDataOutput()
videoOutput.videoSettings = [
    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
]
videoOutput.alwaysDiscardsLateVideoFrames = true

// 设置代理
let queue = DispatchQueue(label: "videoQueue", qos: .userInitiated)
videoOutput.setSampleBufferDelegate(self, queue: queue)

captureSession.addOutput(videoOutput)
captureSession.startRunning()
```

**回调实现**:
```swift
func captureOutput(_ output: AVCaptureOutput,
                  didOutput sampleBuffer: CMSampleBuffer,
                  from connection: AVCaptureConnection) {
    // 每一帧都会回调到这里
    // 在这里进行实时处理：滤镜、识别、编码等
}

func captureOutput(_ output: AVCaptureOutput,
                  didDrop sampleBuffer: CMSampleBuffer,
                  from connection: AVCaptureConnection) {
    // 当处理不过来时，会丢帧并回调这里
    print("Dropped frame")
}
```

**性能指标监控**:
- 实际FPS计算
- 丢帧统计
- 处理延迟
- 内存使用

---

#### 2.2 AVAssetReader 逐帧读取
**文件**: `AssetReaderViewController.swift`

**核心知识点**:
- 从视频文件逐帧读取的标准方法
- AVAssetReader vs AVPlayer的区别
- AVAssetReaderTrackOutput配置
- 时间范围读取（CMTimeRange）
- 状态管理和错误处理

**使用流程**:
```swift
// 1. 创建AVAsset
let asset = AVAsset(url: videoURL)

// 2. 创建AVAssetReader
let assetReader = try AVAssetReader(asset: asset)

// 3. 获取视频轨道
let videoTrack = asset.tracks(withMediaType: .video).first!

// 4. 创建TrackOutput
let outputSettings: [String: Any] = [
    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
]
let trackOutput = AVAssetReaderTrackOutput(track: videoTrack, 
                                           outputSettings: outputSettings)

// 5. 添加output到reader
assetReader.add(trackOutput)

// 6. 开始读取
assetReader.startReading()

// 7. 循环读取每一帧
while let sampleBuffer = trackOutput.copyNextSampleBuffer() {
    // 处理这一帧
    processSampleBuffer(sampleBuffer)
}

// 8. 检查状态
if assetReader.status == .completed {
    print("读取完成")
}
```

**高级用法**:
```swift
// 只读取特定时间范围
let startTime = CMTime(seconds: 10, preferredTimescale: 600)
let duration = CMTime(seconds: 5, preferredTimescale: 600)
trackOutput.timeRange = CMTimeRange(start: startTime, duration: duration)

// 性能优化
trackOutput.alwaysCopiesSampleData = false
```

**适用场景**:
- 视频分析（场景检测、内容理解）
- 帧级别的精确编辑
- 自定义视频转码器
- 提取关键帧
- 生成缩略图序列

---

#### 2.3 AVAssetWriter 逐帧写入
**文件**: `AssetWriterViewController.swift`（待实现）

**核心知识点**:
- 将CMSampleBuffer写入视频文件
- AVAssetWriter vs AVAssetExportSession
- 视频编码参数配置
- 音视频同步写入
- 实时编码性能优化

**基本使用**:
```swift
// 1. 创建AVAssetWriter
let writer = try AVAssetWriter(url: outputURL, fileType: .mov)

// 2. 配置视频输入
let videoSettings: [String: Any] = [
    AVVideoCodecKey: AVVideoCodecType.h264,
    AVVideoWidthKey: 1920,
    AVVideoHeightKey: 1080,
    AVVideoCompressionPropertiesKey: [
        AVVideoAverageBitRateKey: 6000000,
        AVVideoMaxKeyFrameIntervalKey: 30,
        AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
    ]
]

let writerInput = AVAssetWriterInput(mediaType: .video, 
                                    outputSettings: videoSettings)
writerInput.expectsMediaDataInRealTime = true // 实时编码

// 3. 创建PixelBufferAdaptor
let sourcePixelBufferAttributes: [String: Any] = [
    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
    kCVPixelBufferWidthKey as String: 1920,
    kCVPixelBufferHeightKey as String: 1080
]

let adaptor = AVAssetWriterInputPixelBufferAdaptor(
    assetWriterInput: writerInput,
    sourcePixelBufferAttributes: sourcePixelBufferAttributes
)

// 4. 添加input
writer.add(writerInput)

// 5. 开始写入
writer.startWriting()
writer.startSession(atSourceTime: .zero)

// 6. 逐帧追加
var frameCount = 0
while let pixelBuffer = getNextFrame() {
    let presentationTime = CMTime(value: Int64(frameCount), timescale: 30)
    
    while !writerInput.isReadyForMoreMediaData {
        Thread.sleep(forTimeInterval: 0.01) // 等待准备好
    }
    
    adaptor.append(pixelBuffer, withPresentationTime: presentationTime)
    frameCount += 1
}

// 7. 完成写入
writerInput.markAsFinished()
writer.finishWriting {
    if writer.status == .completed {
        print("写入完成")
    }
}
```

---

#### 2.4 相机深度控制
**文件**: `CameraControlViewController.swift`（待实现）

**核心知识点**:
- 手动对焦、曝光、白平衡
- ISO和快门速度控制
- 锁定焦点和曝光
- 自定义曝光补偿
- 平滑对焦动画

**手动控制示例**:
```swift
let device = AVCaptureDevice.default(for: .video)!

try? device.lockForConfiguration()

// 手动对焦
if device.isFocusModeSupported(.continuousAutoFocus) {
    device.focusMode = .continuousAutoFocus
}

// 指定点对焦
if device.isFocusPointOfInterestSupported {
    device.focusPointOfInterest = CGPoint(x: 0.5, y: 0.5)
    device.focusMode = .autoFocus
}

// 手动曝光
if device.isExposureModeSupported(.custom) {
    device.setExposureModeCustom(duration: CMTime(value: 1, timescale: 1000),
                                 iso: 400,
                                 completionHandler: nil)
}

// 白平衡
if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
    device.whiteBalanceMode = .continuousAutoWhiteBalance
}

// 手动白平衡
let gains = AVCaptureDevice.WhiteBalanceGains(redGain: 1.5, greenGain: 1.0, blueGain: 1.2)
device.setWhiteBalanceModeLocked(with: gains, completionHandler: nil)

device.unlockForConfiguration()
```

---

### Layer 3: 视频编解码与格式转换

这一层深入视频编解码的底层实现。

#### 3.1 H.264/H.265 硬编码
**文件**: `VideoEncoderViewController.swift`（待实现）

**核心知识点**:
- VideoToolbox硬件编码器
- H.264 vs H.265性能对比
- 编码参数详解：GOP、BitRate、Profile
- NAL Unit结构
- 实时编码优化

**VideoToolbox编码**:
```swift
import VideoToolbox

// 创建编码会话
var encoderSession: VTCompressionSession?

let status = VTCompressionSessionCreate(
    allocator: kCFAllocatorDefault,
    width: 1920,
    height: 1080,
    codecType: kCMVideoCodecType_H264,
    encoderSpecification: nil,
    imageBufferAttributes: nil,
    compressedDataAllocator: nil,
    outputCallback: encodingOutputCallback,
    refcon: Unmanaged.passUnretained(self).toOpaque(),
    compressionSessionOut: &encoderSession
)

// 配置编码参数
VTSessionSetProperty(encoderSession!,
                    key: kVTCompressionPropertyKey_RealTime,
                    value: kCFBooleanTrue)

VTSessionSetProperty(encoderSession!,
                    key: kVTCompressionPropertyKey_ProfileLevel,
                    value: kVTProfileLevel_H264_High_AutoLevel)

VTSessionSetProperty(encoderSession!,
                    key: kVTCompressionPropertyKey_AverageBitRate,
                    value: 6000000 as CFNumber)

VTSessionSetProperty(encoderSession!,
                    key: kVTCompressionPropertyKey_MaxKeyFrameInterval,
                    value: 30 as CFNumber)

// 准备编码
VTCompressionSessionPrepareToEncodeFrames(encoderSession!)

// 编码一帧
VTCompressionSessionEncodeFrame(
    encoderSession!,
    imageBuffer: pixelBuffer,
    presentationTimeStamp: presentationTime,
    duration: .invalid,
    frameProperties: nil,
    sourceFrameRefcon: nil,
    infoFlagsOut: nil
)

// 编码回调
let encodingOutputCallback: VTCompressionOutputCallback = {
    (outputCallbackRefCon, sourceFrameRefCon, status, infoFlags, sampleBuffer) in
    
    guard let sampleBuffer = sampleBuffer, status == noErr else { return }
    
    // 获取编码后的数据
    // 这里的sampleBuffer包含编码后的H.264/H.265数据
}
```

---

#### 3.2 H.264/H.265 硬解码
**文件**: `VideoDecoderViewController.swift`（待实现）

**核心知识点**:
- VideoToolbox硬件解码器
- 从H.264/H.265数据解码为CVPixelBuffer
- NAL Unit解析
- SPS/PPS处理
- 解码延迟优化

**VideoToolbox解码**:
```swift
// 创建解码会话
var decoderSession: VTDecompressionSession?

let status = VTDecompressionSessionCreate(
    allocator: kCFAllocatorDefault,
    formatDescription: formatDescription,
    decoderSpecification: nil,
    imageBufferAttributes: pixelBufferAttributes as CFDictionary,
    outputCallback: &callback,
    decompressionSessionOut: &decoderSession
)

// 解码一帧
VTDecompressionSessionDecodeFrame(
    decoderSession!,
    sampleBuffer: encodedSampleBuffer,
    flags: [],
    frameRefcon: nil,
    infoFlagsOut: nil
)

// 解码回调
let callback: VTDecompressionOutputCallback = {
    (decompressionOutputRefCon, sourceFrameRefCon, status, infoFlags, imageBuffer, presentationTimeStamp, presentationDuration) in
    
    guard let pixelBuffer = imageBuffer, status == noErr else { return }
    
    // pixelBuffer就是解码后的原始像素数据
    // 可以直接显示或进一步处理
}
```

---

### Layer 4: Metal 视频渲染与自定义滤镜

这一层使用GPU进行高性能视频处理。

#### 4.1 Metal 视频渲染管线
**文件**: `MetalBasicsViewController.swift`（待实现）

**核心知识点**:
- Metal基础概念：Device、CommandQueue、Pipeline
- 纹理（Texture）创建和管理
- 顶点着色器和片段着色器
- CVPixelBuffer → Metal Texture
- 渲染到屏幕或离屏渲染

**Metal渲染流程**:
```swift
// 1. 创建Metal设备
let device = MTLCreateSystemDefaultDevice()!

// 2. 创建命令队列
let commandQueue = device.makeCommandQueue()!

// 3. 从CVPixelBuffer创建纹理
let textureCache = try! CVMetalTextureCacheCreate(
    kCFAllocatorDefault,
    nil,
    device,
    nil,
    &cache
)

var cvMetalTexture: CVMetalTexture?
CVMetalTextureCacheCreateTextureFromImage(
    kCFAllocatorDefault,
    textureCache,
    pixelBuffer,
    nil,
    .bgra8Unorm,
    width, height, 0,
    &cvMetalTexture
)

let texture = CVMetalTextureGetTexture(cvMetalTexture!)!

// 4. 创建渲染管线
let library = device.makeDefaultLibrary()!
let vertexFunction = library.makeFunction(name: "vertexShader")!
let fragmentFunction = library.makeFunction(name: "fragmentShader")!

let pipelineDescriptor = MTLRenderPipelineDescriptor()
pipelineDescriptor.vertexFunction = vertexFunction
pipelineDescriptor.fragmentFunction = fragmentFunction
pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

let pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)

// 5. 渲染
let commandBuffer = commandQueue.makeCommandBuffer()!
let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!

renderEncoder.setRenderPipelineState(pipelineState)
renderEncoder.setFragmentTexture(texture, index: 0)
renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
renderEncoder.endEncoding()

commandBuffer.present(drawable)
commandBuffer.commit()
```

---

### Layer 5: 高级视频应用

这一层实现实际的视频应用效果。

#### 5.1 实时美颜算法
**文件**: `BeautyFilterViewController.swift`（待实现）

**核心算法**:
- 磨皮：双边滤波
- 美白：RGB通道调整
- 瘦脸：局部变形算法
- 大眼：区域放大
- 锐化：USM算法

#### 5.2 绿幕抠图 (Chroma Key)
**文件**: `ChromaKeyViewController.swift`（待实现）

**核心算法**:
- HSV色彩空间
- 颜色距离计算
- 边缘羽化
- 背景替换

---

## 🔧 技术栈总结

```
┌─────────────────────────────────────────┐
│        高级应用                           │
│    (美颜、绿幕、直播...)                   │
└─────────────────────────────────────────┘
                  ↑
┌─────────────────────────────────────────┐
│        Metal / Core Image                │
│    (GPU渲染、自定义滤镜)                   │
└─────────────────────────────────────────┘
                  ↑
┌─────────────────────────────────────────┐
│        VideoToolbox                      │
│    (硬件编解码、格式转换)                   │
└─────────────────────────────────────────┘
                  ↑
┌─────────────────────────────────────────┐
│        AVFoundation                      │
│    (采集、读写、播放)                      │
└─────────────────────────────────────────┘
                  ↑
┌─────────────────────────────────────────┐
│        Core Media / Core Video           │
│    (CMSampleBuffer, CVPixelBuffer...)    │
└─────────────────────────────────────────┘
```

## 📖 学习建议

1. **按顺序学习**: 从Layer 1开始，逐层深入，打好基础
2. **动手实践**: 每个示例都要亲自运行和调试
3. **阅读源码**: 仔细阅读示例代码中的注释
4. **修改实验**: 尝试修改参数，观察效果变化
5. **性能分析**: 使用Instruments分析性能瓶颈
6. **查阅文档**: 配合Apple官方文档学习

## 🔗 参考资源

- [AVFoundation Programming Guide](https://developer.apple.com/library/archive/documentation/AudioVideo/Conceptual/AVFoundationPG/Articles/00_Introduction.html)
- [Core Media Framework Reference](https://developer.apple.com/documentation/coremedia)
- [Core Video Programming Guide](https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/CoreVideo/CVProg_Intro/CVProg_Intro.html)
- [VideoToolbox Framework](https://developer.apple.com/documentation/videotoolbox)
- [Metal Programming Guide](https://developer.apple.com/metal/)

## 💡 常见问题

### Q1: BGRA和YUV哪个更好？
A: 取决于使用场景：
- BGRA: 适合显示和图像处理，CPU友好
- YUV: 适合视频编码，节省空间，硬件编码器支持

### Q2: 如何选择帧率？
A: 
- 15fps: 基础视频通话
- 30fps: 标准视频录制
- 60fps: 高质量视频、游戏录制

### Q3: 视频编码选H.264还是H.265？
A:
- H.264: 兼容性好，设备支持广
- H.265: 更高压缩率，文件更小，但编解码开销大

### Q4: 如何优化视频处理性能？
A:
1. 使用合适的分辨率
2. 优先使用硬件编解码
3. 避免不必要的格式转换
4. 使用Metal进行GPU处理
5. 合理使用alwaysDiscardsLateVideoFrames

---

## 🎯 学习目标检查清单

- [ ] 理解CMSampleBuffer的结构和作用
- [ ] 能够直接操作CVPixelBuffer的像素数据
- [ ] 掌握CMTime的使用和时间计算
- [ ] 了解常见像素格式的区别和适用场景
- [ ] 能够使用AVCaptureVideoDataOutput实时采集
- [ ] 能够使用AVAssetReader逐帧读取视频
- [ ] 能够使用AVAssetWriter将帧写入视频文件
- [ ] 理解VideoToolbox编解码原理
- [ ] 能够使用Metal进行视频处理
- [ ] 能够实现基础的视频特效

祝学习愉快！🎉

