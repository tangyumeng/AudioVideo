//
//  VideoDataOutputViewController.swift
//  AudioVideo
//
//  Layer 2: 原始数据采集与处理
//  AVCaptureVideoDataOutput - 实时获取原始视频帧
//

import UIKit
import AVFoundation

class VideoDataOutputViewController: UIViewController {
    
    // MARK: - Properties
    
    private var captureSession: AVCaptureSession?
    private var videoDataOutput: AVCaptureVideoDataOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    private var frameCount: Int = 0
    private var startTime: CFAbsoluteTime = 0
    private var droppedFrames: Int = 0
    
    private let previewView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.layer.cornerRadius = 8
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let statsLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .monospacedSystemFont(ofSize: 12, weight: .medium)
        label.textAlignment = .left
        label.textColor = .label
        label.backgroundColor = .systemBackground.withAlphaComponent(0.9)
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let controlPanel: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let startButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("开始采集", for: .normal)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let fpsSegment: UISegmentedControl = {
        let items = ["15fps", "30fps", "60fps"]
        let segment = UISegmentedControl(items: items)
        segment.selectedSegmentIndex = 1
        segment.translatesAutoresizingMaskIntoConstraints = false
        return segment
    }()
    
    private let formatSegment: UISegmentedControl = {
        let items = ["BGRA", "YUV"]
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
        📹 AVCaptureVideoDataOutput 详解
        
        这是获取原始视频帧最核心的方式，相比AVCaptureMovieFileOutput，它提供：
        
        ✅ 逐帧访问：每一帧都通过回调传递
        ✅ 实时处理：可以在回调中直接处理像素数据
        ✅ 格式控制：精确控制像素格式
        ✅ 帧率控制：设置最小/最大帧间隔
        
        关键配置：
        • videoSettings: 指定输出的像素格式
        • alwaysDiscardsLateVideoFrames: 是否丢弃延迟帧
        • setSampleBufferDelegate: 设置帧回调
        
        适用场景：
        • 实时滤镜和特效
        • 人脸识别、目标检测
        • 自定义编码器
        • 帧级别的精确控制
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
        contentView.addSubview(controlPanel)
        controlPanel.addSubview(createLabel(text: "帧率:"))
        controlPanel.addSubview(fpsSegment)
        controlPanel.addSubview(createLabel(text: "格式:"))
        controlPanel.addSubview(formatSegment)
        controlPanel.addSubview(startButton)
        contentView.addSubview(previewView)
        contentView.addSubview(statsLabel)
        
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
            
            controlPanel.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 16),
            controlPanel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            controlPanel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            controlPanel.heightAnchor.constraint(equalToConstant: 160),
            
            previewView.topAnchor.constraint(equalTo: controlPanel.bottomAnchor, constant: 16),
            previewView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            previewView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            previewView.heightAnchor.constraint(equalTo: previewView.widthAnchor, multiplier: 4.0/3.0),
            
            statsLabel.topAnchor.constraint(equalTo: previewView.bottomAnchor, constant: 16),
            statsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            statsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            statsLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
        
        setupControlPanelLayout()
    }
    
    private func setupControlPanelLayout() {
        guard let fpsLabel = controlPanel.subviews[0] as? UILabel,
              let formatLabel = controlPanel.subviews[2] as? UILabel else { return }
        
        NSLayoutConstraint.activate([
            fpsLabel.topAnchor.constraint(equalTo: controlPanel.topAnchor, constant: 16),
            fpsLabel.leadingAnchor.constraint(equalTo: controlPanel.leadingAnchor, constant: 16),
            
            fpsSegment.centerYAnchor.constraint(equalTo: fpsLabel.centerYAnchor),
            fpsSegment.leadingAnchor.constraint(equalTo: fpsLabel.trailingAnchor, constant: 12),
            fpsSegment.trailingAnchor.constraint(equalTo: controlPanel.trailingAnchor, constant: -16),
            
            formatLabel.topAnchor.constraint(equalTo: fpsLabel.bottomAnchor, constant: 16),
            formatLabel.leadingAnchor.constraint(equalTo: controlPanel.leadingAnchor, constant: 16),
            
            formatSegment.centerYAnchor.constraint(equalTo: formatLabel.centerYAnchor),
            formatSegment.leadingAnchor.constraint(equalTo: formatLabel.trailingAnchor, constant: 12),
            formatSegment.trailingAnchor.constraint(equalTo: controlPanel.trailingAnchor, constant: -16),
            
            startButton.topAnchor.constraint(equalTo: formatLabel.bottomAnchor, constant: 16),
            startButton.centerXAnchor.constraint(equalTo: controlPanel.centerXAnchor),
            startButton.widthAnchor.constraint(equalToConstant: 120),
            startButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func createLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    
    private func setupActions() {
        startButton.addTarget(self, action: #selector(toggleCapture), for: .touchUpInside)
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
            captureSession?.stopRunning()
            startButton.setTitle("开始采集", for: .normal)
            startButton.backgroundColor = .systemGreen
        } else {
            setupCaptureSession()
            captureSession?.startRunning()
            startButton.setTitle("停止采集", for: .normal)
            startButton.backgroundColor = .systemRed
            
            frameCount = 0
            droppedFrames = 0
            startTime = CFAbsoluteTimeGetCurrent()
        }
    }
    
    // MARK: - Capture Setup
    
    private func setupCaptureSession() {
        // 停止旧的session
        captureSession?.stopRunning()
        previewLayer?.removeFromSuperlayer()
        
        captureSession = AVCaptureSession()
        
        // 设置分辨率
        captureSession?.sessionPreset = .vga640x480
        
        // 摄像头输入
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            showAlert(title: "错误", message: "无法访问摄像头")
            return
        }
        
        if captureSession?.canAddInput(input) == true {
            captureSession?.addInput(input)
        }
        
        // 设置帧率
        let fps = [15, 30, 60][fpsSegment.selectedSegmentIndex]
        try? camera.lockForConfiguration()
        camera.activeVideoMinFrameDuration = CMTime(value: 1, timescale: CMTimeScale(fps))
        camera.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: CMTimeScale(fps))
        camera.unlockForConfiguration()
        
        // 配置VideoDataOutput
        videoDataOutput = AVCaptureVideoDataOutput()
        
        // 设置像素格式
        let pixelFormat: OSType
        if formatSegment.selectedSegmentIndex == 0 {
            pixelFormat = kCVPixelFormatType_32BGRA
        } else {
            pixelFormat = kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
        }
        
        videoDataOutput?.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: pixelFormat
        ]
        
        // 是否丢弃延迟帧（性能关键设置）
        videoDataOutput?.alwaysDiscardsLateVideoFrames = true
        
        // 设置代理队列
        let queue = DispatchQueue(label: "com.audiovideo.videodata", qos: .userInitiated)
        videoDataOutput?.setSampleBufferDelegate(self, queue: queue)
        
        if let output = videoDataOutput, captureSession?.canAddOutput(output) == true {
            captureSession?.addOutput(output)
        }
        
        // 设置视频方向
        if let connection = videoDataOutput?.connection(with: .video) {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
            if connection.isVideoMirroringSupported {
                connection.isVideoMirrored = true
            }
        }
        
        // 预览图层
        let preview = AVCaptureVideoPreviewLayer(session: captureSession!)
        preview.videoGravity = .resizeAspectFill
        preview.frame = previewView.bounds
        previewView.layer.addSublayer(preview)
        previewLayer = preview
    }
    
    // MARK: - Frame Analysis
    
    private func analyzeFrame(_ sampleBuffer: CMSampleBuffer) -> String {
        frameCount += 1
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        let actualFPS = Double(frameCount) / elapsed
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return "无法获取像素数据"
        }
        
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let pixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer)
        let dataSize = CVPixelBufferGetDataSize(pixelBuffer)
        let planeCount = CVPixelBufferGetPlaneCount(pixelBuffer)
        
        let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        let duration = CMSampleBufferGetDuration(sampleBuffer)
        
        var info = "📊 实时统计\n\n"
        info += "性能指标:\n"
        info += "  • 已处理帧数: \(frameCount)\n"
        info += "  • 目标FPS: \([15, 30, 60][fpsSegment.selectedSegmentIndex])\n"
        info += "  • 实际FPS: \(String(format: "%.1f", actualFPS))\n"
        info += "  • 丢帧数: \(droppedFrames)\n"
        info += "  • 运行时间: \(String(format: "%.1f", elapsed))s\n\n"
        
        info += "帧信息:\n"
        info += "  • 分辨率: \(width) x \(height)\n"
        info += "  • 像素格式: \(fourCCToString(pixelFormat))\n"
        info += "  • 数据大小: \(formatBytes(dataSize))\n"
        info += "  • 平面数: \(planeCount)\n\n"
        
        info += "时间信息:\n"
        info += "  • PTS: \(String(format: "%.3f", presentationTime.seconds))s\n"
        if duration.isValid {
            info += "  • Duration: \(String(format: "%.4f", duration.seconds))s\n"
            info += "  • Expected FPS: \(String(format: "%.1f", 1.0/duration.seconds))\n"
        }
        
        info += "\n"
        
        if planeCount > 0 {
            info += "平面详情:\n"
            for i in 0..<planeCount {
                let planeWidth = CVPixelBufferGetWidthOfPlane(pixelBuffer, i)
                let planeHeight = CVPixelBufferGetHeightOfPlane(pixelBuffer, i)
                let planeBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, i)
                info += "  Plane \(i): \(planeWidth)x\(planeHeight), \(planeBytesPerRow) B/row\n"
            }
        }
        
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

extension VideoDataOutputViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                      didOutput sampleBuffer: CMSampleBuffer,
                      from connection: AVCaptureConnection) {
        // 这里每一帧都会回调
        // 可以在这里进行实时处理：滤镜、识别、编码等
        
        let info = analyzeFrame(sampleBuffer)
        
        // 限制更新频率，每秒更新5次
        if frameCount % 6 == 0 {
            DispatchQueue.main.async { [weak self] in
                self?.statsLabel.text = info
            }
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput,
                      didDrop sampleBuffer: CMSampleBuffer,
                      from connection: AVCaptureConnection) {
        // 当处理速度跟不上时，这里会被调用
        droppedFrames += 1
        print("⚠️ 丢弃一帧 - 总丢帧数: \(droppedFrames)")
    }
}

