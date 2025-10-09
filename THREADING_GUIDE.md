# AVFoundation 线程管理指南

## ⚠️ 常见警告

### 警告1: AVCaptureSession 在主线程
```
[AVCaptureSession startRunning] should be called from background thread. 
Calling it on the main thread can lead to UI unresponsiveness.
```

### 警告2: UI控件在后台线程访问
```
UISegmentedControl.selectedSegmentIndex must be used from main thread only
UILabel.text must be used from main thread only
UIButton.isEnabled must be used from main thread only
```

### 问题原因

`AVCaptureSession` 的 `startRunning()` 和 `stopRunning()` 方法是**阻塞调用**，可能需要较长时间：

1. **startRunning()**:
   - 初始化硬件（摄像头、麦克风）
   - 建立音视频管线
   - 可能需要几百毫秒甚至更长

2. **stopRunning()**:
   - 释放硬件资源
   - 清理管线
   - 同样需要时间

如果在主线程调用，会**阻塞UI**，导致：
- 按钮点击无响应
- 界面卡顿
- 用户体验差

## ✅ 正确做法

### 修复前（❌ 错误）

```swift
@objc private func toggleCapture() {
    if captureSession?.isRunning == true {
        captureSession?.stopRunning()  // ❌ 在主线程，会阻塞UI
        startButton.setTitle("开始采集", for: .normal)
    } else {
        captureSession?.startRunning()  // ❌ 在主线程，会阻塞UI
        startButton.setTitle("停止采集", for: .normal)
    }
}
```

### 修复后（✅ 正确）

```swift
@objc private func toggleCapture() {
    if captureSession?.isRunning == true {
        // ✅ 在后台线程停止session
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.stopRunning()
            
            // ✅ 更新UI需要回到主线程
            DispatchQueue.main.async {
                self?.startButton.setTitle("开始采集", for: .normal)
                self?.startButton.backgroundColor = .systemBlue
            }
        }
    } else {
        if captureSession == nil {
            setupCaptureSession()
        }
        
        // ✅ 在后台线程启动session
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
            
            // ✅ 更新UI需要回到主线程
            DispatchQueue.main.async {
                self?.startButton.setTitle("停止采集", for: .normal)
                self?.startButton.backgroundColor = .systemRed
            }
        }
    }
}
```

## 📋 关键要点

### 1. 使用合适的QoS

```swift
// ✅ 推荐：用户主动触发的操作
DispatchQueue.global(qos: .userInitiated).async { ... }

// ❌ 不推荐：优先级太低
DispatchQueue.global(qos: .background).async { ... }
```

**QoS 级别说明**：
- `.userInteractive`: 用户交互，最高优先级（但通常用于主线程）
- `.userInitiated`: **推荐**，用户主动触发的任务
- `.utility`: 长时间运行的任务
- `.background`: 后台任务，优先级最低

### 2. UI更新必须在主线程

```swift
DispatchQueue.global(qos: .userInitiated).async {
    self?.captureSession?.startRunning()  // ✅ 后台线程
    
    DispatchQueue.main.async {
        // ✅ UI更新在主线程
        self?.startButton.setTitle("停止采集", for: .normal)
        self?.startButton.backgroundColor = .systemRed
    }
}
```

### 3. 使用 weak self 避免循环引用

```swift
DispatchQueue.global(qos: .userInitiated).async { [weak self] in
    //                                              ^^^^^^^^^^^
    // ✅ 使用 weak self，避免内存泄漏
    self?.captureSession?.startRunning()
}
```

## 📝 已修复的文件

本项目中以下文件已修复线程安全问题：

### 问题1: AVCaptureSession 在主线程

1. ✅ `CMSampleBufferViewController.swift`
   - `toggleCapture()` 方法

2. ✅ `CVPixelBufferViewController.swift`
   - `toggleCapture()` 方法

3. ✅ `VideoDataOutputViewController.swift`
   - `toggleCapture()` 方法

### 问题2: UI控件在后台线程访问

1. ✅ `CVPixelBufferViewController.swift`
   - `captureOutput` 回调中访问 `processModeSegment.selectedSegmentIndex`
   - 解决方案：添加 `currentProcessMode` 属性

2. ✅ `VideoDataOutputViewController.swift`
   - `analyzeFrame` 中访问 `fpsSegment.selectedSegmentIndex`
   - 解决方案：添加 `currentTargetFPS` 属性

## 🔍 其他需要注意的场景

### 场景1: 相机权限请求后启动

```swift
AVCaptureDevice.requestAccess(for: .video) { granted in
    if granted {
        // ⚠️ 这个回调可能在任意线程
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession?.startRunning()
        }
    }
}
```

### 场景2: deinit 中停止 session

```swift
deinit {
    // ✅ deinit 中可以直接调用
    // 因为对象已经在销毁，不会影响UI
    captureSession?.stopRunning()
}
```

### 场景3: 应用进入后台

```swift
NotificationCenter.default.addObserver(
    forName: UIApplication.didEnterBackgroundNotification,
    object: nil,
    queue: .main
) { [weak self] _ in
    // ✅ 在后台线程停止
    DispatchQueue.global(qos: .userInitiated).async {
        self?.captureSession?.stopRunning()
    }
}
```

## 🎯 最佳实践总结

### ✅ DO（推荐）

1. **始终在后台线程调用**:
   - `startRunning()`
   - `stopRunning()`

2. **使用合适的 QoS**:
   - 用户触发的操作使用 `.userInitiated`

3. **UI更新回到主线程**:
   - 所有UI操作必须在 `DispatchQueue.main`

4. **使用 weak self**:
   - 避免循环引用和内存泄漏

### ❌ DON'T（避免）

1. ❌ 在主线程调用 `startRunning()`/`stopRunning()`
2. ❌ 在后台线程更新UI
3. ❌ 忘记使用 `weak self`
4. ❌ 使用过低的 QoS 优先级

## 📚 参考文档

- [AVCaptureSession Documentation](https://developer.apple.com/documentation/avfoundation/avcapturesession)
- [Dispatch Queue Programming Guide](https://developer.apple.com/library/archive/documentation/General/Conceptual/ConcurrencyProgrammingGuide/)
- [Quality of Service Classes](https://developer.apple.com/documentation/dispatch/dispatchqos/qosclass)

## 💡 实用技巧

### 添加指示器

为了让用户知道相机正在启动，可以添加加载指示器：

```swift
@objc private func toggleCapture() {
    // 显示加载指示器
    activityIndicator.startAnimating()
    startButton.isEnabled = false
    
    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
        self?.captureSession?.startRunning()
        
        DispatchQueue.main.async {
            // 隐藏加载指示器
            self?.activityIndicator.stopAnimating()
            self?.startButton.isEnabled = true
            self?.startButton.setTitle("停止采集", for: .normal)
        }
    }
}
```

### 超时处理

对于可能耗时较长的操作，添加超时处理：

```swift
let timeoutWorkItem = DispatchWorkItem { [weak self] in
    self?.handleTimeout()
}

// 10秒超时
DispatchQueue.main.asyncAfter(deadline: .now() + 10, execute: timeoutWorkItem)

DispatchQueue.global(qos: .userInitiated).async { [weak self] in
    self?.captureSession?.startRunning()
    
    DispatchQueue.main.async {
        timeoutWorkItem.cancel()  // 取消超时
        // 更新UI...
    }
}
```

---

## 🎨 UI控件线程安全详解

### 问题场景

在 `AVCaptureVideoDataOutputSampleBufferDelegate` 回调中，回调在**后台线程**执行，但直接访问UI控件会导致崩溃或警告：

```swift
// ❌ 错误示例
func captureOutput(_ output: AVCaptureOutput,
                  didOutput sampleBuffer: CMSampleBuffer,
                  from connection: AVCaptureConnection) {
    // 这个回调在后台线程执行！
    
    let mode = processModeSegment.selectedSegmentIndex  // ❌ 崩溃！
    
    switch mode {
        // 处理...
    }
}
```

### 解决方案：使用缓存属性

**步骤1: 添加线程安全的属性**

```swift
class CVPixelBufferViewController: UIViewController {
    
    private var captureSession: AVCaptureSession?
    
    // ✅ 添加线程安全的属性
    private var currentProcessMode: Int = 0
    
    private let processModeSegment: UISegmentedControl = {
        // ...
    }()
}
```

**步骤2: 监听UI控件变化**

```swift
private func setupActions() {
    processModeSegment.addTarget(
        self, 
        action: #selector(processModeChanged), 
        for: .valueChanged
    )
}

@objc private func processModeChanged() {
    // ✅ 在主线程更新缓存
    currentProcessMode = processModeSegment.selectedSegmentIndex
}
```

**步骤3: 在后台线程使用缓存值**

```swift
func captureOutput(_ output: AVCaptureOutput,
                  didOutput sampleBuffer: CMSampleBuffer,
                  from connection: AVCaptureConnection) {
    // ✅ 使用线程安全的属性，而不是直接访问UI
    let mode = currentProcessMode
    
    switch mode {
    case 0:
        // 灰度处理
    case 1:
        // 反色处理
    default:
        break
    }
    
    // UI更新必须回到主线程
    DispatchQueue.main.async {
        self.imageView.image = processedImage
    }
}
```

### 为什么这样做？

1. **避免线程冲突**: UIKit不是线程安全的
2. **性能更好**: 避免频繁的线程切换
3. **更稳定**: 不会出现运行时崩溃
4. **符合Apple规范**: UIKit必须在主线程使用

### 其他UI控件示例

所有UI控件都必须在主线程访问：

```swift
// ❌ 错误：在后台线程访问UI
DispatchQueue.global().async {
    label.text = "更新"                    // ❌
    button.isEnabled = false               // ❌
    slider.value = 0.5                     // ❌
    tableView.reloadData()                 // ❌
}

// ✅ 正确：回到主线程更新UI
DispatchQueue.global().async {
    let result = performHeavyComputation()
    
    DispatchQueue.main.async {
        label.text = result                // ✅
        button.isEnabled = true            // ✅
        slider.value = 0.5                 // ✅
        tableView.reloadData()             // ✅
    }
}
```

### 快速检查清单

- [ ] AVCaptureSession 的 start/stop 在后台线程？
- [ ] UI控件访问都在主线程？
- [ ] 后台线程使用的数据是线程安全的？
- [ ] 使用了 `weak self` 避免循环引用？
- [ ] UI更新用 `DispatchQueue.main.async`？

---

记住：
- **AVFoundation操作 → 后台线程** ⚙️
- **UIKit操作 → 主线程** 🎨

**永远不要在主线程阻塞，永远不要在后台线程更新UI！** 🚫

