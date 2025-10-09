# 像素格式内存计算详解

## 📊 420YpCbCr8BiPlanarVideoRange (NV12) 计算

### 问题：1920×1080 为什么是 3MB？

让我们一步步计算。

---

## 🎯 第一步：理解 YUV 4:2:0 采样

### 什么是 4:2:0？

```
原始像素网格（4×4示例）：

█ █ █ █
█ █ █ █
█ █ █ █
█ █ █ █
```

**Y（亮度）采样**：每个像素都有
```
Y Y Y Y
Y Y Y Y
Y Y Y Y
Y Y Y Y

总计：16个Y值
```

**UV（色度）采样**：每2×2像素块共享一组UV
```
U   U       V   V
            
U   U       V   V


总计：4个U值 + 4个V值
```

**4:2:0的含义**：
- **4**: 第一行有4个Y采样
- **2**: 第一行有2个色度采样（UV合计）
- **0**: 第二行没有额外的色度采样（与第一行共享）

---

## 🧮 第二步：计算 1920×1080 的内存

### Y 平面（亮度）

```
每个像素都有一个Y值
每个Y值占用 1 byte（8 bit）

计算：
宽度：1920 像素
高度：1080 像素
字节数：1920 × 1080 × 1 = 2,073,600 bytes
```

### UV 平面（色度）

由于是 4:2:0 采样，UV的分辨率是Y的 **1/2 × 1/2 = 1/4**

```
U 分量：
宽度：1920 / 2 = 960 像素
高度：1080 / 2 = 540 像素
字节数：960 × 540 × 1 = 518,400 bytes

V 分量：
宽度：1920 / 2 = 960 像素
高度：1080 / 2 = 540 像素
字节数：960 × 540 × 1 = 518,400 bytes

UV 总计：518,400 + 518,400 = 1,036,800 bytes
```

### 总内存

```
总字节数 = Y平面 + U平面 + V平面
        = 2,073,600 + 518,400 + 518,400
        = 3,110,400 bytes
```

**转换为MB**：
```
3,110,400 bytes ÷ 1,024 ÷ 1,024 = 2.97 MB ≈ 3 MB
```

---

## 🔍 第三步：验证公式

### 通用公式

对于 YUV 4:2:0 格式：

```
总字节数 = (宽 × 高) × 1.5

证明：
- Y平面: 宽 × 高 × 1
- U平面: (宽/2) × (高/2) × 1 = (宽 × 高) / 4
- V平面: (宽/2) × (高/2) × 1 = (宽 × 高) / 4

总计 = 宽 × 高 × (1 + 1/4 + 1/4)
     = 宽 × 高 × 1.5
```

### 应用公式

```
1920 × 1080 × 1.5 = 3,110,400 bytes ✓
```

---

## 📊 与其他格式对比

### RGB (BGRA) - 1920×1080

```
每个像素 = 4 bytes (B, G, R, A)

总字节数 = 1920 × 1080 × 4 = 8,294,400 bytes
        = 7.91 MB ≈ 8 MB
```

**对比**：
- BGRA: 8 MB
- YUV 4:2:0: 3 MB
- **节省**: 5 MB (62.5%)

### YUV 4:4:4 - 1920×1080

```
每个像素都有独立的 Y, U, V

Y平面：1920 × 1080 = 2,073,600 bytes
U平面：1920 × 1080 = 2,073,600 bytes
V平面：1920 × 1080 = 2,073,600 bytes

总计 = 2,073,600 × 3 = 6,220,800 bytes
     = 5.93 MB ≈ 6 MB
```

### YUV 4:2:2 - 1920×1080

```
Y平面：1920 × 1080 = 2,073,600 bytes
U平面：960 × 1080 = 1,036,800 bytes (宽度减半)
V平面：960 × 1080 = 1,036,800 bytes (宽度减半)

总计 = 2,073,600 + 1,036,800 + 1,036,800
     = 4,147,200 bytes
     = 3.95 MB ≈ 4 MB
```

### 格式对比表

| 格式 | 每像素字节 | 1920×1080 | 相对大小 |
|------|----------|----------|---------|
| BGRA (RGB) | 4 bytes | 8 MB | 100% |
| YUV 4:4:4 | 3 bytes | 6 MB | 75% |
| YUV 4:2:2 | 2 bytes | 4 MB | 50% |
| **YUV 4:2:0** | **1.5 bytes** | **3 MB** | **37.5%** |

---

## 🎨 BiPlanar (NV12) vs Planar 的区别

### Planar (I420) 内存布局

```
Y平面（连续）：
Y Y Y Y Y Y ...
Y Y Y Y Y Y ...
...

U平面（连续）：
U U U ...
U U U ...
...

V平面（连续）：
V V V ...
V V V ...
...
```

**内存分布**：
```
[YYYYYYYY...] [UUUU...] [VVVV...]
```

### BiPlanar (NV12) 内存布局

```
Y平面（连续）：
Y Y Y Y Y Y ...
Y Y Y Y Y Y ...
...

UV平面（交错）：
U V U V U V ...
U V U V U V ...
...
```

**内存分布**：
```
[YYYYYYYY...] [UVUVUVUV...]
```

**注意**：总内存大小**完全相同**，只是存储方式不同！

---

## 💻 iOS中的实际应用

### 查看CVPixelBuffer的大小

```swift
func analyzePixelBuffer(_ pixelBuffer: CVPixelBuffer) {
    let width = CVPixelBufferGetWidth(pixelBuffer)  // 1920
    let height = CVPixelBufferGetHeight(pixelBuffer)  // 1080
    
    // 获取总数据大小
    let dataSize = CVPixelBufferGetDataSize(pixelBuffer)
    print("总大小: \(dataSize) bytes")  // 3,110,400
    print("MB: \(Double(dataSize) / 1024 / 1024) MB")  // 2.97 MB
    
    // 获取平面数
    let planeCount = CVPixelBufferGetPlaneCount(pixelBuffer)
    print("平面数: \(planeCount)")  // 2 (BiPlanar)
    
    // 分析每个平面
    if planeCount > 0 {
        for i in 0..<planeCount {
            let planeWidth = CVPixelBufferGetWidthOfPlane(pixelBuffer, i)
            let planeHeight = CVPixelBufferGetHeightOfPlane(pixelBuffer, i)
            let planeBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, i)
            
            print("平面 \(i):")
            print("  尺寸: \(planeWidth) × \(planeHeight)")
            print("  每行字节: \(planeBytesPerRow)")
            
            // 平面0：Y平面
            // 尺寸: 1920 × 1080
            // 每行字节: 1920
            
            // 平面1：UV平面（交错）
            // 尺寸: 960 × 540
            // 每行字节: 1920 (因为UV交错，一行包含U和V)
        }
    }
}
```

### 实际输出示例

```
总大小: 3110400 bytes
MB: 2.9663085937500005 MB
平面数: 2

平面 0:
  尺寸: 1920 × 1080
  每行字节: 1920
  计算: 1920 × 1080 = 2,073,600 bytes

平面 1:
  尺寸: 960 × 540
  每行字节: 1920
  计算: 1920 × 540 = 1,036,800 bytes
  注意: 宽度是960，但每行1920字节，因为UV交错

总计: 2,073,600 + 1,036,800 = 3,110,400 bytes ✓
```

---

## 🎬 不同分辨率的内存占用

### 常见分辨率对比

| 分辨率 | 像素总数 | YUV 4:2:0 | BGRA |
|--------|---------|-----------|------|
| 4K (3840×2160) | 8,294,400 | 12 MB | 32 MB |
| 1080p (1920×1080) | 2,073,600 | 3 MB | 8 MB |
| 720p (1280×720) | 921,600 | 1.3 MB | 3.5 MB |
| 480p (640×480) | 307,200 | 0.4 MB | 1.2 MB |
| VGA (640×480) | 307,200 | 0.4 MB | 1.2 MB |

### 帧率和码流

以30fps视频为例：

**1080p YUV 4:2:0**:
```
每帧: 3 MB
每秒: 3 MB × 30 = 90 MB/s
每分钟: 90 MB × 60 = 5.4 GB/min (未压缩)
```

**1080p BGRA**:
```
每帧: 8 MB
每秒: 8 MB × 30 = 240 MB/s
每分钟: 240 MB × 60 = 14.4 GB/min (未压缩)
```

**使用H.264压缩后** (约1:100压缩比):
```
1080p 30fps @ 6Mbps = 45 MB/min
```

这就是为什么视频必须使用YUV + 压缩编码！

---

## 🧪 验证代码

### Swift代码验证

```swift
import AVFoundation

func calculateYUV420Size(width: Int, height: Int) -> Int {
    // Y平面
    let yPlaneSize = width * height
    
    // U平面 (1/4分辨率)
    let uPlaneSize = (width / 2) * (height / 2)
    
    // V平面 (1/4分辨率)
    let vPlaneSize = (width / 2) * (height / 2)
    
    return yPlaneSize + uPlaneSize + vPlaneSize
}

// 测试
let size = calculateYUV420Size(width: 1920, height: 1080)
print("1920×1080 YUV 4:2:0: \(size) bytes")
print("MB: \(Double(size) / 1024 / 1024)")

// 输出：
// 1920×1080 YUV 4:2:0: 3110400 bytes
// MB: 2.9663085937500005
```

### 简化公式

```swift
func quickCalculateYUV420(width: Int, height: Int) -> Int {
    return width * height * 3 / 2
}

// 或者
func quickCalculateYUV420Float(width: Int, height: Int) -> Double {
    return Double(width * height) * 1.5
}
```

---

## 📚 总结

### 记忆要点

1. **YUV 4:2:0 = 每像素1.5字节**
   ```
   Y: 1 byte/pixel (全分辨率)
   U: 0.25 byte/pixel (1/4分辨率)
   V: 0.25 byte/pixel (1/4分辨率)
   总计: 1.5 bytes/pixel
   ```

2. **快速计算公式**
   ```
   YUV 4:2:0 大小 = 宽 × 高 × 1.5 bytes
   ```

3. **1920×1080示例**
   ```
   1920 × 1080 × 1.5 = 3,110,400 bytes ≈ 3 MB
   ```

4. **为什么是1.5？**
   ```
   1 (Y) + 0.25 (U) + 0.25 (V) = 1.5
   
   或者：
   4个像素共享1组UV
   4个Y + 1个U + 1个V = 6 bytes
   6 ÷ 4 = 1.5 bytes/pixel
   ```

### 不同格式的系数

| 格式 | 系数 | 说明 |
|------|------|------|
| BGRA | 4.0 | 每像素4字节 |
| YUV 4:4:4 | 3.0 | 每像素3字节 |
| YUV 4:2:2 | 2.0 | 每像素2字节 |
| **YUV 4:2:0** | **1.5** | **每像素1.5字节** |

---

## 🎯 实际应用建议

### 何时使用YUV 4:2:0？

✅ **推荐场景**：
- 视频录制
- 视频编码（H.264/H.265）
- 视频传输
- 视频存储
- 实时通讯

❌ **不推荐场景**：
- 静态图片编辑（用RGB）
- 需要精确色彩（用YUV 4:4:4）
- 专业视频制作（用YUV 4:2:2或4:4:4）

### 性能考虑

**内存带宽**：
```
以30fps为例：

YUV 4:2:0: 3 MB × 30 = 90 MB/s
YUV 4:2:2: 4 MB × 30 = 120 MB/s
BGRA: 8 MB × 30 = 240 MB/s

选择YUV 4:2:0可以节省62.5%带宽！
```

---

希望这个详细计算解释清楚了为什么 1920×1080 的 YUV 4:2:0 是 3MB！

记住公式：**宽 × 高 × 1.5 = 总字节数** 🎯

