//
//  CVPixelBufferViewController.swift
//  AudioVideo
//
//  Layer 1: Core Media & Core Video
//  CVPixelBuffer 直接操作像素数据
//

import UIKit
import AVFoundation
import CoreVideo
import Accelerate

class CVPixelBufferViewController: UIViewController {
    
    // MARK: - Properties
    
    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    
    // 当前处理模式（线程安全的属性）
    private var currentProcessMode: Int = 0
    
    private let originalImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .black
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let processedImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .black
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let infoLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let startButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("开始处理", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let processModeSegment: UISegmentedControl = {
        let items = ["灰度", "反色", "亮度", "像素读取"]
        let segment = UISegmentedControl(items: items)
        segment.selectedSegmentIndex = 0
        segment.translatesAutoresizingMaskIntoConstraints = false
        return segment
    }()
    
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
        🖼 CVPixelBuffer 直接操作
        
        CVPixelBuffer 是 Core Video 中用于存储像素数据的核心结构。它提供了：
        • 直接访问像素数据的能力
        • 高效的内存管理（IOSurface支持）
        • GPU和CPU之间的零拷贝传输
        
        下面演示了几种常见的像素操作：
        1. 灰度转换 - 将RGB转为灰度
        2. 反色效果 - 反转所有颜色
        3. 亮度调整 - 增加或减少亮度
        4. 像素读取 - 直接读取像素值
        """
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        requestCameraPermission()
    }
    
    deinit {
        captureSession?.stopRunning()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(processModeSegment)
        contentView.addSubview(startButton)
        
        let stackView = UIStackView(arrangedSubviews: [
            createLabeledView(title: "原始画面", view: originalImageView),
            createLabeledView(title: "处理后画面", view: processedImageView)
        ])
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stackView)
        
        contentView.addSubview(infoLabel)
        
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
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            processModeSegment.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 16),
            processModeSegment.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            processModeSegment.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            startButton.topAnchor.constraint(equalTo: processModeSegment.bottomAnchor, constant: 16),
            startButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            startButton.widthAnchor.constraint(equalToConstant: 120),
            startButton.heightAnchor.constraint(equalToConstant: 44),
            
            stackView.topAnchor.constraint(equalTo: startButton.bottomAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            originalImageView.heightAnchor.constraint(equalToConstant: 200),
            processedImageView.heightAnchor.constraint(equalToConstant: 200),
            
            infoLabel.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 16),
            infoLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            infoLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            infoLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }
    
    private func createLabeledView(title: String, view: UIView) -> UIView {
        let container = UIView()
        
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(label)
        container.addSubview(view)
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            view.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 8),
            view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
    
    private func setupActions() {
        startButton.addTarget(self, action: #selector(toggleCapture), for: .touchUpInside)
        processModeSegment.addTarget(self, action: #selector(processModeChanged), for: .valueChanged)
    }
    
    @objc private func processModeChanged() {
        // 在主线程更新处理模式
        currentProcessMode = processModeSegment.selectedSegmentIndex
    }
    
    // MARK: - Camera Permission
    
    private func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            if !granted {
                self.showAlert(title: "相机权限", message: "请在设置中开启相机权限")
            }
        }
    }
    
    // MARK: - Actions
    
    @objc private func toggleCapture() {
        if captureSession?.isRunning == true {
            // 在后台线程停止session
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession?.stopRunning()
                
                // 更新UI需要回到主线程
                DispatchQueue.main.async {
                    self?.startButton.setTitle("开始处理", for: .normal)
                    self?.startButton.backgroundColor = .systemBlue
                }
            }
        } else {
            if captureSession == nil {
                setupCaptureSession()
            }
            
            // 在后台线程启动session
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession?.startRunning()
                
                // 更新UI需要回到主线程
                DispatchQueue.main.async {
                    self?.startButton.setTitle("停止处理", for: .normal)
                    self?.startButton.backgroundColor = .systemRed
                }
            }
        }
    }
    
    // MARK: - Capture Setup
    
    private func setupCaptureSession() {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .vga640x480
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            showAlert(title: "错误", message: "无法访问摄像头")
            return
        }
        
        if captureSession?.canAddInput(input) == true {
            captureSession?.addInput(input)
        }
        
        videoOutput = AVCaptureVideoDataOutput()
        // 使用 BGRA 格式，每个像素4字节
        videoOutput?.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        
        let queue = DispatchQueue(label: "com.audiovideo.pixelbuffer")
        videoOutput?.setSampleBufferDelegate(self, queue: queue)
        
        if let output = videoOutput, captureSession?.canAddOutput(output) == true {
            captureSession?.addOutput(output)
        }
    }
    
    // MARK: - Pixel Buffer Processing
    
    /// 将CVPixelBuffer转为灰度
    private func convertToGrayscale(_ pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        
        // 创建输出缓冲区
        var outputPixelBuffer: CVPixelBuffer?
        let options: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]
        
        CVPixelBufferCreate(kCFAllocatorDefault, width, height,
                           kCVPixelFormatType_32BGRA, options as CFDictionary,
                           &outputPixelBuffer)
        
        guard let output = outputPixelBuffer else { return nil }
        
        // 锁定像素缓冲区
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        CVPixelBufferLockBaseAddress(output, [])
        
        defer {
            CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
            CVPixelBufferUnlockBaseAddress(output, [])
        }
        
        guard let srcData = CVPixelBufferGetBaseAddress(pixelBuffer),
              let dstData = CVPixelBufferGetBaseAddress(output) else {
            return nil
        }
        
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        
        // 逐像素处理：BGRA格式
        for y in 0..<height {
            for x in 0..<width {
                let offset = y * bytesPerRow + x * 4
                let srcPtr = srcData.advanced(by: offset).assumingMemoryBound(to: UInt8.self)
                let dstPtr = dstData.advanced(by: offset).assumingMemoryBound(to: UInt8.self)
                
                let b = Float(srcPtr[0])
                let g = Float(srcPtr[1])
                let r = Float(srcPtr[2])
                
                // 灰度公式: 0.299*R + 0.587*G + 0.114*B
                let gray = UInt8(0.114 * b + 0.587 * g + 0.299 * r)
                
                dstPtr[0] = gray
                dstPtr[1] = gray
                dstPtr[2] = gray
                dstPtr[3] = srcPtr[3] // alpha
            }
        }
        
        return output
    }
    
    /// 反色效果
    private func invertColors(_ pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        
        var outputPixelBuffer: CVPixelBuffer?
        let options: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]
        
        CVPixelBufferCreate(kCFAllocatorDefault, width, height,
                           kCVPixelFormatType_32BGRA, options as CFDictionary,
                           &outputPixelBuffer)
        
        guard let output = outputPixelBuffer else { return nil }
        
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        CVPixelBufferLockBaseAddress(output, [])
        
        defer {
            CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
            CVPixelBufferUnlockBaseAddress(output, [])
        }
        
        guard let srcData = CVPixelBufferGetBaseAddress(pixelBuffer),
              let dstData = CVPixelBufferGetBaseAddress(output) else {
            return nil
        }
        
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        
        for y in 0..<height {
            for x in 0..<width {
                let offset = y * bytesPerRow + x * 4
                let srcPtr = srcData.advanced(by: offset).assumingMemoryBound(to: UInt8.self)
                let dstPtr = dstData.advanced(by: offset).assumingMemoryBound(to: UInt8.self)
                
                dstPtr[0] = 255 - srcPtr[0] // B
                dstPtr[1] = 255 - srcPtr[1] // G
                dstPtr[2] = 255 - srcPtr[2] // R
                dstPtr[3] = srcPtr[3]         // A
            }
        }
        
        return output
    }
    
    /// 调整亮度
    private func adjustBrightness(_ pixelBuffer: CVPixelBuffer, delta: Int = 50) -> CVPixelBuffer? {
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        
        var outputPixelBuffer: CVPixelBuffer?
        let options: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]
        
        CVPixelBufferCreate(kCFAllocatorDefault, width, height,
                           kCVPixelFormatType_32BGRA, options as CFDictionary,
                           &outputPixelBuffer)
        
        guard let output = outputPixelBuffer else { return nil }
        
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        CVPixelBufferLockBaseAddress(output, [])
        
        defer {
            CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
            CVPixelBufferUnlockBaseAddress(output, [])
        }
        
        guard let srcData = CVPixelBufferGetBaseAddress(pixelBuffer),
              let dstData = CVPixelBufferGetBaseAddress(output) else {
            return nil
        }
        
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        
        for y in 0..<height {
            for x in 0..<width {
                let offset = y * bytesPerRow + x * 4
                let srcPtr = srcData.advanced(by: offset).assumingMemoryBound(to: UInt8.self)
                let dstPtr = dstData.advanced(by: offset).assumingMemoryBound(to: UInt8.self)
                
                dstPtr[0] = UInt8(max(0, min(255, Int(srcPtr[0]) + delta)))
                dstPtr[1] = UInt8(max(0, min(255, Int(srcPtr[1]) + delta)))
                dstPtr[2] = UInt8(max(0, min(255, Int(srcPtr[2]) + delta)))
                dstPtr[3] = srcPtr[3]
            }
        }
        
        return output
    }
    
    /// 读取中心像素信息
    private func readPixelInfo(_ pixelBuffer: CVPixelBuffer) -> String {
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        
        guard let data = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            return "无法读取像素数据"
        }
        
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let centerX = width / 2
        let centerY = height / 2
        let offset = centerY * bytesPerRow + centerX * 4
        let ptr = data.advanced(by: offset).assumingMemoryBound(to: UInt8.self)
        
        let b = ptr[0]
        let g = ptr[1]
        let r = ptr[2]
        let a = ptr[3]
        
        var info = "中心像素 (\(centerX), \(centerY)):\n"
        info += "R: \(r), G: \(g), B: \(b), A: \(a)\n"
        info += "Hex: #\(String(format: "%02X%02X%02X", r, g, b))\n"
        info += "\n缓冲区信息:\n"
        info += "尺寸: \(width) x \(height)\n"
        info += "每行字节: \(bytesPerRow)\n"
        info += "像素格式: BGRA (32bit)\n"
        info += "数据大小: \(formatBytes(CVPixelBufferGetDataSize(pixelBuffer)))"
        
        return info
    }
    
    // MARK: - Helper Methods
    
    private func pixelBufferToUIImage(_ pixelBuffer: CVPixelBuffer) -> UIImage? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    private func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .default))
            self.present(alert, animated: true)
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CVPixelBufferViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                      didOutput sampleBuffer: CMSampleBuffer,
                      from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // ✅ 使用线程安全的属性，而不是直接访问UI控件
        let mode = currentProcessMode
        
        // 根据选择的模式处理像素
        let processedBuffer: CVPixelBuffer?
        var info = ""
        
        switch mode {
        case 0: // 灰度
            processedBuffer = convertToGrayscale(pixelBuffer)
            info = "灰度转换：使用公式 0.299*R + 0.587*G + 0.114*B"
        case 1: // 反色
            processedBuffer = invertColors(pixelBuffer)
            info = "反色效果：255 - 原始值"
        case 2: // 亮度
            processedBuffer = adjustBrightness(pixelBuffer, delta: 50)
            info = "亮度增强：每个通道 +50"
        case 3: // 像素读取
            processedBuffer = pixelBuffer
            info = readPixelInfo(pixelBuffer)
        default:
            processedBuffer = nil
        }
        
        // 更新UI
        DispatchQueue.main.async { [weak self] in
            if let originalImage = self?.pixelBufferToUIImage(pixelBuffer) {
                self?.originalImageView.image = originalImage
            }
            
            if let processed = processedBuffer,
               let processedImage = self?.pixelBufferToUIImage(processed) {
                self?.processedImageView.image = processedImage
            }
            
            self?.infoLabel.text = info
        }
    }
}

