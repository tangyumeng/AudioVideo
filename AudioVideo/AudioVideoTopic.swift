//
//  AudioVideoTopic.swift
//  AudioVideo
//
//  Created by tangyumeng on 2025/10/6.
//

import UIKit

/// 视频知识层级
enum VideoLayer: String {
    case coreMedia = "Layer 1: Core Media & Core Video"
    case rawCapture = "Layer 2: 原始数据采集与处理"
    case codecFormat = "Layer 3: 编解码与格式转换"
    case metalRender = "Layer 4: Metal 渲染与自定义滤镜"
    case advanced = "Layer 5: 高级视频应用"
}

/// 音视频开发知识点模型
struct AudioVideoTopic {
    let title: String
    let description: String
    let icon: String
    let layer: VideoLayer
    let viewController: UIViewController.Type
    
    /// 按层级组织的视频知识点
    static let videoTopicsByLayer: [VideoLayer: [AudioVideoTopic]] = [
        // 第一层：Core Media & Core Video 最底层API
        .coreMedia: [
            AudioVideoTopic(
                title: "CMSampleBuffer 详解",
                description: "视频帧的容器，包含像素数据、时间戳、格式描述等",
                icon: "cube.fill",
                layer: .coreMedia,
                viewController: CMSampleBufferViewController.self
            ),
            AudioVideoTopic(
                title: "CVPixelBuffer 操作",
                description: "直接操作像素数据，像素格式转换、内存管理",
                icon: "square.grid.3x3.fill",
                layer: .coreMedia,
                viewController: CVPixelBufferViewController.self
            ),
            AudioVideoTopic(
                title: "CMTime 时间系统",
                description: "精确的时间表示，时间计算与转换",
                icon: "clock.fill",
                layer: .coreMedia,
                viewController: CMTimeViewController.self
            ),
            AudioVideoTopic(
                title: "像素格式详解",
                description: "YUV、RGB、BGRA等格式，颜色空间转换",
                icon: "paintpalette.fill",
                layer: .coreMedia,
                viewController: PixelFormatViewController.self
            )
        ],
        
        // 第二层：AVFoundation 原始数据采集
        .rawCapture: [
            AudioVideoTopic(
                title: "AVCaptureVideoDataOutput",
                description: "实时获取原始视频帧数据，帧率控制",
                icon: "camera.metering.matrix",
                layer: .rawCapture,
                viewController: VideoDataOutputViewController.self
            ),
            AudioVideoTopic(
                title: "AVAssetReader 逐帧读取",
                description: "从视频文件中逐帧读取CMSampleBuffer",
                icon: "doc.text.magnifyingglass",
                layer: .rawCapture,
                viewController: AssetReaderViewController.self
            ),
            AudioVideoTopic(
                title: "AVAssetWriter 逐帧写入",
                description: "将CMSampleBuffer写入视频文件",
                icon: "square.and.arrow.down.fill",
                layer: .rawCapture,
                viewController: AssetWriterViewController.self
            ),
            AudioVideoTopic(
                title: "相机深度控制",
                description: "手动对焦、曝光、白平衡、ISO、快门速度",
                icon: "slider.horizontal.3",
                layer: .rawCapture,
                viewController: CameraControlViewController.self
            )
        ],
        
        // 第三层：编解码与格式转换
        .codecFormat: [
            AudioVideoTopic(
                title: "H.264/H.265 硬编码",
                description: "使用VideoToolbox进行硬件编码",
                icon: "arrow.down.circle.fill",
                layer: .codecFormat,
                viewController: VideoEncoderViewController.self
            ),
            AudioVideoTopic(
                title: "H.264/H.265 硬解码",
                description: "使用VideoToolbox进行硬件解码",
                icon: "arrow.up.circle.fill",
                layer: .codecFormat,
                viewController: VideoDecoderViewController.self
            ),
            AudioVideoTopic(
                title: "格式转换与转码",
                description: "MOV↔MP4，分辨率、码率、帧率转换",
                icon: "arrow.triangle.2.circlepath",
                layer: .codecFormat,
                viewController: VideoTranscodeViewController.self
            ),
            AudioVideoTopic(
                title: "AVAssetExportSession",
                description: "高层API进行视频导出与压缩",
                icon: "square.and.arrow.up.fill",
                layer: .codecFormat,
                viewController: AssetExportViewController.self
            )
        ],
        
        // 第四层：Metal 渲染
        .metalRender: [
            AudioVideoTopic(
                title: "Metal 视频渲染管线",
                description: "Metal基础，纹理、着色器、渲染管线",
                icon: "cpu.fill",
                layer: .metalRender,
                viewController: MetalBasicsViewController.self
            ),
            AudioVideoTopic(
                title: "自定义 Metal 滤镜",
                description: "编写Metal着色器实现滤镜效果",
                icon: "wand.and.stars",
                layer: .metalRender,
                viewController: MetalFilterViewController.self
            ),
            AudioVideoTopic(
                title: "Core Image + Metal",
                description: "Core Image与Metal结合，自定义CIKernel",
                icon: "photo.fill.on.rectangle.fill",
                layer: .metalRender,
                viewController: CoreImageMetalViewController.self
            ),
            AudioVideoTopic(
                title: "GPU 视频处理优化",
                description: "Metal Performance Shaders，性能优化技巧",
                icon: "speedometer",
                layer: .metalRender,
                viewController: GPUOptimizationViewController.self
            )
        ],
        
        // 第五层：高级应用
        .advanced: [
            AudioVideoTopic(
                title: "实时美颜算法",
                description: "磨皮、美白、瘦脸等实时美颜效果",
                icon: "face.smiling.fill",
                layer: .advanced,
                viewController: BeautyFilterViewController.self
            ),
            AudioVideoTopic(
                title: "绿幕抠图 (Chroma Key)",
                description: "实时色度键控，背景替换",
                icon: "photo.on.rectangle.angled",
                layer: .advanced,
                viewController: ChromaKeyViewController.self
            ),
            AudioVideoTopic(
                title: "多轨道视频合成",
                description: "AVComposition多视频轨道混合",
                icon: "square.stack.3d.up.fill",
                layer: .advanced,
                viewController: VideoCompositionViewController.self
            ),
            AudioVideoTopic(
                title: "视频水印与字幕",
                description: "AVVideoComposition自定义合成器",
                icon: "text.badge.plus",
                layer: .advanced,
                viewController: WatermarkViewController.self
            ),
            AudioVideoTopic(
                title: "实时视频直播",
                description: "RTMP推流，HLS播放",
                icon: "antenna.radiowaves.left.and.right",
                layer: .advanced,
                viewController: LiveStreamViewController.self
            )
        ]
    ]
    
    /// 所有知识点（按层级排序）
    static let allTopics: [AudioVideoTopic] = {
        let layers: [VideoLayer] = [.coreMedia, .rawCapture, .codecFormat, .metalRender, .advanced]
        return layers.flatMap { videoTopicsByLayer[$0] ?? [] }
    }()
}



