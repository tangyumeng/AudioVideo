//
//  CMSampleBufferViewController.swift
//  AudioVideo
//
//  Layer 1: Core Media & Core Video
//  CMSampleBuffer 是视频帧的核心容器
//

import UIKit
import AVFoundation
import CoreMedia

class CMSampleBufferViewController: UIViewController {
    
    // MARK: - Properties
    
    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    private let infoTextView: UITextView = {
        let textView = UITextView()
        textView.isEditable = false
        textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.backgroundColor = .systemBackground
        textView.textColor = .label
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.systemGray4.cgColor
        textView.layer.cornerRadius = 8
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()
    
    private let previewView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.layer.cornerRadius = 8
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let startButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("开始采集", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
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
        📦 CMSampleBuffer 详解
        
        CMSampleBuffer 是 Core Media 框架中最核心的数据结构，它封装了媒体数据（如视频帧或音频样本）以及相关的元数据。
        
        核心组成部分：
        • CVImageBuffer (CVPixelBuffer): 实际的像素数据
        • CMTime: 精确的时间戳信息
        • CMFormatDescription: 格式描述（分辨率、颜色空间等）
        • CMAttachments: 附加信息（曝光时间、ISO等）
        
        下面的实时信息展示了每一帧的详细数据：
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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = previewView.bounds
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
        contentView.addSubview(startButton)
        contentView.addSubview(previewView)
        contentView.addSubview(infoTextView)
        
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
            
            startButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 16),
            startButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            startButton.widthAnchor.constraint(equalToConstant: 120),
            startButton.heightAnchor.constraint(equalToConstant: 44),
            
            previewView.topAnchor.constraint(equalTo: startButton.bottomAnchor, constant: 16),
            previewView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            previewView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            previewView.heightAnchor.constraint(equalTo: previewView.widthAnchor, multiplier: 4.0/3.0),
            
            infoTextView.topAnchor.constraint(equalTo: previewView.bottomAnchor, constant: 16),
            infoTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            infoTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            infoTextView.heightAnchor.constraint(equalToConstant: 400),
            infoTextView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }
    
    private func setupActions() {
        startButton.addTarget(self, action: #selector(toggleCapture), for: .touchUpInside)
    }
    
    // MARK: - Camera Permission
    
    private func requestCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    print("Camera permission granted")
                }
            }
        case .denied, .restricted:
            showAlert(title: "相机权限", message: "请在设置中开启相机权限")
        @unknown default:
            break
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
                    self?.startButton.setTitle("开始采集", for: .normal)
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
                    self?.startButton.setTitle("停止采集", for: .normal)
                    self?.startButton.backgroundColor = .systemRed
                }
            }
        }
    }
    
    // MARK: - Capture Setup
    
    private func setupCaptureSession() {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .vga640x480
        
        // 设置摄像头输入
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            showAlert(title: "错误", message: "无法访问摄像头")
            return
        }
        
        if captureSession?.canAddInput(input) == true {
            captureSession?.addInput(input)
        }
        
        // 设置视频数据输出
        videoOutput = AVCaptureVideoDataOutput()
        videoOutput?.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        
        let queue = DispatchQueue(label: "com.audiovideo.videoqueue")
        videoOutput?.setSampleBufferDelegate(self, queue: queue)
        videoOutput?.alwaysDiscardsLateVideoFrames = true
        
        if let output = videoOutput, captureSession?.canAddOutput(output) == true {
            captureSession?.addOutput(output)
        }
        
        // 设置预览图层
        let preview = AVCaptureVideoPreviewLayer(session: captureSession!)
        preview.videoGravity = .resizeAspectFill
        preview.frame = previewView.bounds
        previewView.layer.addSublayer(preview)
        previewLayer = preview
    }
    
    // MARK: - CMSampleBuffer Analysis
    
    private func analyzeSampleBuffer(_ sampleBuffer: CMSampleBuffer) -> String {
        var info = "╔═══ CMSampleBuffer 分析 ═══╗\n\n"
        
        // 1. 时间信息
        info += "⏱ 时间信息 (CMTime)\n"
        let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        info += "  • PTS (Presentation Time): \(presentationTime.seconds)s\n"
        info += "  • Time Value: \(presentationTime.value)\n"
        info += "  • Time Scale: \(presentationTime.timescale)\n"
        info += "  • Flags: \(presentationTime.flags)\n"
        
        let duration = CMSampleBufferGetDuration(sampleBuffer)
        if duration.isValid {
            info += "  • Duration: \(duration.seconds)s\n"
        }
        
        info += "\n"
        
        // 2. 格式描述
        if let formatDesc = CMSampleBufferGetFormatDescription(sampleBuffer) {
            info += "📐 格式描述 (CMFormatDescription)\n"
            
            let mediaType = CMFormatDescriptionGetMediaType(formatDesc)
            info += "  • Media Type: \(fourCCToString(mediaType))\n"
            
            let mediaSubtype = CMFormatDescriptionGetMediaSubType(formatDesc)
            info += "  • Media Subtype: \(fourCCToString(mediaSubtype))\n"
            
            let dimensions = CMVideoFormatDescriptionGetDimensions(formatDesc)
            info += "  • Dimensions: \(dimensions.width) x \(dimensions.height)\n"
            
            if let extensions = CMFormatDescriptionGetExtensions(formatDesc) as? [String: Any] {
                info += "  • Extensions: \(extensions.count) items\n"
            }
        }
        
        info += "\n"
        
        // 3. 像素缓冲区
        if let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            info += "🖼 像素缓冲区 (CVPixelBuffer)\n"
            
            let width = CVPixelBufferGetWidth(imageBuffer)
            let height = CVPixelBufferGetHeight(imageBuffer)
            info += "  • Size: \(width) x \(height)\n"
            
            let pixelFormat = CVPixelBufferGetPixelFormatType(imageBuffer)
            info += "  • Pixel Format: \(fourCCToString(pixelFormat))\n"
            
            let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
            info += "  • Bytes Per Row: \(bytesPerRow)\n"
            
            let dataSize = CVPixelBufferGetDataSize(imageBuffer)
            info += "  • Data Size: \(formatBytes(dataSize))\n"
            
            let planeCount = CVPixelBufferGetPlaneCount(imageBuffer)
            info += "  • Plane Count: \(planeCount)\n"
            
            // 检查是否为平面格式（如YUV）
            if planeCount > 0 {
                info += "  • Planar Format:\n"
                for i in 0..<planeCount {
                    let planeWidth = CVPixelBufferGetWidthOfPlane(imageBuffer, i)
                    let planeHeight = CVPixelBufferGetHeightOfPlane(imageBuffer, i)
                    let planeBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, i)
                    info += "    - Plane \(i): \(planeWidth)x\(planeHeight), \(planeBytesPerRow) bytes/row\n"
                }
            }
        }
        
        info += "\n"
        
        // 4. 附件信息（Attachments）
        if let attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: false) as? [[String: Any]] {
            info += "📎 附件信息 (Attachments)\n"
            if let firstAttachment = attachments.first {
                for (key, value) in firstAttachment {
                    info += "  • \(key): \(value)\n"
                }
            }
        }
        
        info += "\n"
        
        // 5. 数据就绪状态
        info += "✅ 状态信息\n"
        let dataReady = CMSampleBufferDataIsReady(sampleBuffer)
        info += "  • Data Ready: \(dataReady)\n"
        
        let numSamples = CMSampleBufferGetNumSamples(sampleBuffer)
        info += "  • Num Samples: \(numSamples)\n"
        
        let totalSize = CMSampleBufferGetTotalSampleSize(sampleBuffer)
        info += "  • Total Size: \(formatBytes(totalSize))\n"
        
        info += "\n╚═══════════════════════════╝"
        
        return info
    }
    
    // MARK: - Helper Methods
    
    private func fourCCToString(_ value: FourCharCode) -> String {
        let chars = [
            Character(UnicodeScalar((value >> 24) & 0xFF)!),
            Character(UnicodeScalar((value >> 16) & 0xFF)!),
            Character(UnicodeScalar((value >> 8) & 0xFF)!),
            Character(UnicodeScalar(value & 0xFF)!)
        ]
        return String(chars)
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

extension CMSampleBufferViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                      didOutput sampleBuffer: CMSampleBuffer,
                      from connection: AVCaptureConnection) {
        // 分析 CMSampleBuffer
        let info = analyzeSampleBuffer(sampleBuffer)
        
        // 更新UI（限制更新频率）
        DispatchQueue.main.async { [weak self] in
            self?.infoTextView.text = info
        }
    }
}

