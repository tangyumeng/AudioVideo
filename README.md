# iOS 音视频开发学习项目

这是一个系统学习 iOS 音视频开发技术的示例项目，包含了常用的音视频采集、处理、播放等功能的完整实现。

## 📚 项目简介

本项目采用主页列表的形式，将音视频开发的各个知识点作为独立模块展示，每个模块都包含完整的示例代码和交互界面，方便学习和测试。

## 🎯 功能模块

### 1. 📷 相机采集 (Camera Capture)
- **技术栈**: `AVFoundation`, `AVCaptureSession`, `AVCaptureDevice`
- **功能**: 
  - 实时相机预览
  - 前后摄像头切换
  - 相机权限管理
- **文件**: `CameraCaptureViewController.swift`

### 2. 🎬 视频播放 (Video Player)
- **技术栈**: `AVPlayer`, `AVPlayerLayer`, `AVPlayerItem`
- **功能**:
  - 本地/网络视频播放
  - 播放控制（播放/暂停）
  - 自定义播放器界面
- **文件**: `VideoPlayerViewController.swift`

### 3. 🎤 音频录制 (Audio Recording)
- **技术栈**: `AVAudioRecorder`, `AVAudioSession`
- **功能**:
  - 高质量音频录制
  - 实时录音时长显示
  - 录音文件保存与管理
- **文件**: `AudioRecordViewController.swift`

### 4. 🔊 音频播放 (Audio Playback)
- **技术栈**: `AVAudioPlayer`
- **功能**:
  - 音频文件播放
  - 播放进度控制
  - 音量调节
  - 网络音频加载
- **文件**: `AudioPlayViewController.swift`

### 5. ✂️ 视频编辑 (Video Editing)
- **技术栈**: `AVAssetExportSession`, `AVAsset`, `CMTime`
- **功能**:
  - 视频时间裁剪
  - 视频导出
  - 进度监控
  - 多种导出质量选项
- **文件**: `VideoEditViewController.swift`

### 6. 🎨 视频滤镜 (Video Filters)
- **技术栈**: `Core Image`, `CIFilter`, `CIContext`
- **功能**:
  - 实时滤镜效果
  - 多种滤镜（黑白、怀旧、模糊、边缘检测）
  - 滤镜强度调节
  - 滤镜混合效果
- **文件**: `VideoFilterViewController.swift`

### 7. 📹 视频录制 (Video Recording)
- **技术栈**: `AVCaptureMovieFileOutput`, `AVCaptureSession`
- **功能**:
  - 视频录制
  - 实时预览
  - 录制时长显示
  - 前后摄像头切换
  - 音视频同步录制
- **文件**: `VideoRecordViewController.swift`

### 8. 🎵 音频处理 (Audio Processing)
- **技术栈**: `AVAudioEngine`, `AVAudioUnitReverb`, `AVAudioUnitDelay`, `AVAudioUnitDistortion`
- **功能**:
  - 实时音效处理
  - 混响效果
  - 延迟效果
  - 失真效果
  - 音效参数调节
- **文件**: `AudioProcessViewController.swift`

### 9. 📸 照片采集 (Photo Capture)
- **技术栈**: `AVCapturePhotoOutput`, `AVCaptureDevice`
- **功能**:
  - 高质量照片拍摄
  - 闪光灯控制
  - 前后摄像头切换
  - 实时预览
  - 照片保存
- **文件**: `PhotoCaptureViewController.swift`

### 10. 🎼 音频可视化 (Audio Visualization)
- **技术栈**: `AVAudioEngine`, `Core Graphics`, `CADisplayLink`
- **功能**:
  - 实时音频波形显示
  - 频谱可视化
  - 动态色彩效果
  - 自定义绘制
- **文件**: `AudioVisualizationViewController.swift`

## 🏗️ 项目结构

```
AudioVideo/
├── AudioVideo/
│   ├── AppDelegate.swift           # 应用程序委托
│   ├── SceneDelegate.swift         # 场景委托
│   ├── ViewController.swift        # 主页列表控制器
│   ├── AudioVideoTopic.swift       # 知识点数据模型
│   └── ViewControllers/            # 各功能模块视图控制器
│       ├── CameraCaptureViewController.swift
│       ├── VideoPlayerViewController.swift
│       ├── AudioRecordViewController.swift
│       ├── AudioPlayViewController.swift
│       ├── VideoEditViewController.swift
│       ├── VideoFilterViewController.swift
│       ├── VideoRecordViewController.swift
│       ├── AudioProcessViewController.swift
│       ├── PhotoCaptureViewController.swift
│       └── AudioVisualizationViewController.swift
└── README.md                       # 项目说明文档
```

## 🚀 快速开始

1. **克隆项目**
   ```bash
   git clone [repository-url]
   cd AudioVideo
   ```

2. **打开项目**
   ```bash
   open AudioVideo.xcodeproj
   ```

3. **运行项目**
   - 选择目标设备（建议使用真机，因为某些功能需要相机和麦克风）
   - 点击运行按钮或使用快捷键 `⌘ + R`

## ⚠️ 注意事项

### 权限配置

项目需要以下权限，请在 `Info.plist` 中添加相应的权限说明：

- **相机权限**: `NSCameraUsageDescription`
- **麦克风权限**: `NSMicrophoneUsageDescription`
- **相册权限**: `NSPhotoLibraryAddUsageDescription`（如果需要保存照片/视频）

示例配置：
```xml
<key>NSCameraUsageDescription</key>
<string>需要访问相机进行视频采集和拍照</string>
<key>NSMicrophoneUsageDescription</key>
<string>需要访问麦克风进行音频录制</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>需要访问相册保存照片和视频</string>
```

### 设备要求

- **iOS 13.0+**
- **Xcode 12.0+**
- **Swift 5.0+**
- **真机测试**（相机和麦克风功能在模拟器上无法使用）

## 📖 学习路径建议

1. **入门**: 从音频播放和视频播放开始，了解基本的媒体播放 API
2. **进阶**: 学习音视频采集和录制，掌握 AVFoundation 核心功能
3. **高级**: 深入音视频处理、滤镜和可视化，了解实时处理技术

## 🛠️ 技术栈

- **语言**: Swift
- **框架**: 
  - AVFoundation（核心音视频框架）
  - Core Image（图像处理）
  - Core Graphics（图形绘制）
  - UIKit（用户界面）

## 📝 代码特点

- ✅ 完整的注释说明
- ✅ 清晰的代码结构
- ✅ MARK 标记分类
- ✅ 错误处理机制
- ✅ 用户友好的界面
- ✅ 权限管理示例

## 🔗 相关资源

- [Apple AVFoundation 官方文档](https://developer.apple.com/av-foundation/)
- [Core Image 编程指南](https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/CoreImaging/ci_intro/ci_intro.html)
- [Audio Session 编程指南](https://developer.apple.com/library/archive/documentation/Audio/Conceptual/AudioSessionProgrammingGuide/Introduction/Introduction.html)

## 📄 许可证

本项目仅供学习使用。

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

---

**祝你学习愉快！🎉**
