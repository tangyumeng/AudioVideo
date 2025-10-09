//
//  PixelFormatViewController.swift
//  AudioVideo
//
//  Layer 1: Core Media & Core Video
//  像素格式详解：RGB、YUV、BGRA等
//

import UIKit
import AVFoundation
import CoreVideo

class PixelFormatViewController: UIViewController {
    
    // MARK: - Properties
    
    private let scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        return scroll
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.text = """
        🎨 像素格式详解
        
        像素格式决定了图像数据在内存中的存储方式。不同格式在存储空间、色彩表示、性能等方面各有特点。
        
        主要格式分类：
        
        1️⃣ RGB 系列（用于显示）
        • BGRA: 每像素4字节，易于CPU处理
        • RGBA: 每像素4字节，适合某些GPU操作
        • RGB: 每像素3字节，无alpha通道
        
        2️⃣ YUV 系列（用于视频编码）
        • YUV 420：Y、U、V分离，节省空间
        • NV12: Y平面 + UV交错，常用格式
        • YUV 422: 色度采样率更高
        
        💡 为什么视频使用YUV？
        
        1. 更接近人眼感知
           • 人眼对亮度(Y)非常敏感
           • 人眼对色度(UV)相对不敏感
           • YUV将亮度和色度分离，符合人眼特性
        
        2. 色度降采样（节省50%空间）
           • YUV 4:2:0: 4个像素共享1组UV
           • 色度减少75%，视觉几乎无损
           • RGB无法这样压缩
        
        3. 高效编码
           • H.264/H.265编码器原生支持
           • 可以对Y通道保留更多细节
           • 对UV通道更激进压缩
        
        详细说明请查看 YUV_VS_RGB_EXPLAINED.md
        
        下面将详细介绍各种格式的特点和用途：
        """
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        createFormatCards()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(descriptionLabel)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            descriptionLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }
    
    // MARK: - Create Format Cards
    
    private func createFormatCards() {
        let formats: [(String, OSType, String, String, UIColor)] = [
            ("BGRA (32bit)", kCVPixelFormatType_32BGRA,
             "最常用的格式，每像素4字节\nB(8bit) G(8bit) R(8bit) A(8bit)\n适用于：屏幕显示、图像处理\n内存占用：1920x1080 = 8MB",
             "'BGRA'", .systemBlue),
            
            ("RGBA (32bit)", kCVPixelFormatType_32RGBA,
             "与BGRA类似，字节序不同\nR(8bit) G(8bit) B(8bit) A(8bit)\n适用于：OpenGL ES, Metal\n内存占用：1920x1080 = 8MB",
             "'RGBA'", .systemIndigo),
            
            ("ARGB (32bit)", kCVPixelFormatType_32ARGB,
             "Alpha通道在最前\nA(8bit) R(8bit) G(8bit) B(8bit)\n适用于：某些图形API\n内存占用：1920x1080 = 8MB",
             "'ARGB'", .systemPurple),
            
            ("420YpCbCr8BiPlanarVideoRange", kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
             "NV12格式，最常用的YUV格式\nY平面(全分辨率) + UV交错平面\n适用于：视频编码、H.264/H.265\n内存占用：1920x1080 = 3MB (节省37.5%)",
             "'420v'", .systemGreen),
            
            ("420YpCbCr8BiPlanarFullRange", kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
             "NV12全范围版本\n与420v类似，但取值范围0-255\n适用于：摄像头采集\n内存占用：1920x1080 = 3MB",
             "'420f'", .systemTeal),
            
            ("420YpCbCr8Planar", kCVPixelFormatType_420YpCbCr8Planar,
             "YUV 420 三平面格式\nY、U、V完全分离的三个平面\n适用于：视频处理、滤镜\n内存占用：1920x1080 = 3MB",
             "'y420'", .systemMint),
            
            ("422YpCbCr8", kCVPixelFormatType_422YpCbCr8,
             "YUV 422格式，色度水平采样1/2\n比420有更好的色彩质量\n适用于：专业视频\n内存占用：1920x1080 = 4MB",
             "'2vuy'", .systemCyan),
            
            ("RGB (24bit)", kCVPixelFormatType_24RGB,
             "无alpha通道的RGB\nR(8bit) G(8bit) B(8bit)\n适用于：不需要透明度的图像\n内存占用：1920x1080 = 6MB",
             "'24RGB'", .systemOrange),
            
            ("16Gray", kCVPixelFormatType_OneComponent8,
             "8位灰度图\n单通道，每像素1字节\n适用于：黑白图像、深度图\n内存占用：1920x1080 = 2MB",
             "'L008'", .systemGray),
            
            ("DepthFloat32", kCVPixelFormatType_DepthFloat32,
             "深度图格式\n每像素32位浮点数\n适用于：深度相机、AR\n内存占用：1920x1080 = 8MB",
             "'hdep'", .systemRed)
        ]
        
        var previousCard: UIView = descriptionLabel
        
        for format in formats {
            let card = createFormatCard(
                title: format.0,
                fourCC: format.1,
                description: format.2,
                fourCCString: format.3,
                color: format.4
            )
            
            contentView.addSubview(card)
            
            NSLayoutConstraint.activate([
                card.topAnchor.constraint(equalTo: previousCard.bottomAnchor, constant: 16),
                card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
            ])
            
            previousCard = card
        }
        
        // 添加转换示例
        let conversionCard = createConversionExamples()
        contentView.addSubview(conversionCard)
        
        NSLayoutConstraint.activate([
            conversionCard.topAnchor.constraint(equalTo: previousCard.bottomAnchor, constant: 16),
            conversionCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            conversionCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            conversionCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }
    
    private func createFormatCard(title: String, fourCC: OSType, description: String, fourCCString: String, color: UIColor) -> UIView {
        let container = UIView()
        container.backgroundColor = .secondarySystemBackground
        container.layer.cornerRadius = 12
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let headerView = UIView()
        headerView.backgroundColor = color.withAlphaComponent(0.2)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 17, weight: .bold)
        titleLabel.textColor = color
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let fourCCLabel = UILabel()
        fourCCLabel.text = "FourCC: \(fourCCString) (0x\(String(format: "%08X", fourCC)))"
        fourCCLabel.font = .monospacedSystemFont(ofSize: 12, weight: .medium)
        fourCCLabel.textColor = .secondaryLabel
        fourCCLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let descLabel = UILabel()
        descLabel.text = description
        descLabel.numberOfLines = 0
        descLabel.font = .systemFont(ofSize: 13)
        descLabel.textColor = .label
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let visualView = createPixelVisual(for: fourCC, color: color)
        
        headerView.addSubview(titleLabel)
        container.addSubview(headerView)
        container.addSubview(fourCCLabel)
        container.addSubview(descLabel)
        container.addSubview(visualView)
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: container.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 44),
            
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            
            fourCCLabel.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 12),
            fourCCLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            fourCCLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            
            descLabel.topAnchor.constraint(equalTo: fourCCLabel.bottomAnchor, constant: 8),
            descLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            descLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            
            visualView.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 12),
            visualView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            visualView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            visualView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12),
            visualView.heightAnchor.constraint(equalToConstant: 60)
        ])
        
        return container
    }
    
    private func createPixelVisual(for fourCC: OSType, color: UIColor) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.font = .monospacedSystemFont(ofSize: 10, weight: .medium)
        label.numberOfLines = 2
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        
        // 根据格式显示字节布局
        switch fourCC {
        case kCVPixelFormatType_32BGRA:
            label.text = "Byte Layout:\n[B] [G] [R] [A] | [B] [G] [R] [A] | ..."
        case kCVPixelFormatType_32RGBA:
            label.text = "Byte Layout:\n[R] [G] [B] [A] | [R] [G] [B] [A] | ..."
        case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:
            label.text = "Plane 0: [Y][Y][Y]...\nPlane 1: [UV][UV][UV]..."
        case kCVPixelFormatType_420YpCbCr8Planar:
            label.text = "Plane 0: [Y][Y]... Plane 1: [U][U]...\nPlane 2: [V][V]..."
        case kCVPixelFormatType_24RGB:
            label.text = "Byte Layout:\n[R] [G] [B] | [R] [G] [B] | ..."
        default:
            label.text = "See documentation for byte layout"
        }
        
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
    
    private func createConversionExamples() -> UIView {
        let container = UIView()
        container.backgroundColor = .systemIndigo.withAlphaComponent(0.1)
        container.layer.cornerRadius = 12
        container.layer.borderWidth = 2
        container.layer.borderColor = UIColor.systemIndigo.cgColor
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = "🔄 格式转换示例代码"
        titleLabel.font = .systemFont(ofSize: 17, weight: .bold)
        titleLabel.textColor = .systemIndigo
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let codeTextView = UITextView()
        codeTextView.isEditable = false
        codeTextView.isScrollEnabled = false
        codeTextView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        codeTextView.backgroundColor = .clear
        codeTextView.textColor = .label
        codeTextView.text = """
        // 1. 设置相机输出格式
        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: 
                kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
        ]
        
        // 2. RGB ↔ YUV 转换（使用 vImage）
        import Accelerate
        
        // BGRA → YUV
        var sourceBuffer = vImage_Buffer(...)
        var destYBuffer = vImage_Buffer(...)
        var destCbCrBuffer = vImage_Buffer(...)
        vImageConvert_ARGB8888To420Yp8_CbCr8(...)
        
        // 3. 使用 Core Image 转换
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        context.render(ciImage, to: outputBuffer)
        
        // 4. 手动转换 RGB → Grayscale
        let gray = 0.299*R + 0.587*G + 0.114*B
        
        // 5. Metal 着色器转换（最快）
        // 在 GPU 上执行格式转换
        """
        codeTextView.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(titleLabel)
        container.addSubview(codeTextView)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            
            codeTextView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            codeTextView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            codeTextView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            codeTextView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16)
        ])
        
        return container
    }
}

