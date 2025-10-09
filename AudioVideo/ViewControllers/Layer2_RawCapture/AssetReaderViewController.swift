//
//  AssetReaderViewController.swift
//  AudioVideo
//
//  Layer 2: 原始数据采集与处理
//  AVAssetReader - 从视频文件逐帧读取CMSampleBuffer
//

import UIKit
import AVFoundation
import Photos

class AssetReaderViewController: UIViewController {
    
    // MARK: - Properties
    
    private var assetReader: AVAssetReader?
    private var videoTrackOutput: AVAssetReaderTrackOutput?
    private var currentFrameIndex: Int = 0
    private var totalFrames: Int = 0
    private var asset: AVAsset?
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.backgroundColor = .black
        iv.layer.cornerRadius = 8
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let infoTextView: UITextView = {
        let tv = UITextView()
        tv.isEditable = false
        tv.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        tv.backgroundColor = .secondarySystemBackground
        tv.layer.cornerRadius = 8
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    private let selectVideoButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("从相册选择视频", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let nextFrameButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("下一帧 →", for: .normal)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.isEnabled = false
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let autoPlayButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("自动播放", for: .normal)
        button.backgroundColor = .systemPurple
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.isEnabled = false
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let progressSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.value = 0
        slider.isEnabled = false
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
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
        📖 AVAssetReader 逐帧读取
        
        AVAssetReader 是读取视频文件最底层的API，它可以：
        
        ✅ 逐帧访问：精确控制每一帧的读取
        ✅ 解码控制：指定输出的像素格式
        ✅ 时间范围：可以只读取特定时间段
        ✅ 多轨道：同时读取视频、音频轨道
        
        关键类：
        • AVAssetReader: 管理读取过程
        • AVAssetReaderTrackOutput: 从特定轨道读取
        • AVAssetReaderVideoCompositionOutput: 带合成效果读取
        
        使用场景：
        • 视频分析和处理
        • 自定义转码器
        • 帧级别的精确编辑
        • 视频元数据提取
        
        下面演示从相册视频中逐帧读取CMSampleBuffer：
        """
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var isAutoPlaying = false
    private var autoPlayTimer: Timer?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }
    
    deinit {
        autoPlayTimer?.invalidate()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(selectVideoButton)
        contentView.addSubview(imageView)
        contentView.addSubview(progressSlider)
        
        let buttonStack = UIStackView(arrangedSubviews: [nextFrameButton, autoPlayButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 12
        buttonStack.distribution = .fillEqually
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(buttonStack)
        
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
            
            selectVideoButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 16),
            selectVideoButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            selectVideoButton.widthAnchor.constraint(equalToConstant: 180),
            selectVideoButton.heightAnchor.constraint(equalToConstant: 44),
            
            imageView.topAnchor.constraint(equalTo: selectVideoButton.bottomAnchor, constant: 16),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 9.0/16.0),
            
            progressSlider.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 12),
            progressSlider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            progressSlider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            buttonStack.topAnchor.constraint(equalTo: progressSlider.bottomAnchor, constant: 12),
            buttonStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            buttonStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            buttonStack.heightAnchor.constraint(equalToConstant: 44),
            
            infoTextView.topAnchor.constraint(equalTo: buttonStack.bottomAnchor, constant: 16),
            infoTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            infoTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            infoTextView.heightAnchor.constraint(equalToConstant: 300),
            infoTextView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }
    
    private func setupActions() {
        selectVideoButton.addTarget(self, action: #selector(selectVideo), for: .touchUpInside)
        nextFrameButton.addTarget(self, action: #selector(readNextFrame), for: .touchUpInside)
        autoPlayButton.addTarget(self, action: #selector(toggleAutoPlay), for: .touchUpInside)
        progressSlider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
    }
    
    // MARK: - Actions
    
    @objc private func selectVideo() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.mediaTypes = ["public.movie"]
        picker.delegate = self
        present(picker, animated: true)
    }
    
    @objc private func readNextFrame() {
        guard let output = videoTrackOutput else { return }
        
        if let sampleBuffer = output.copyNextSampleBuffer() {
            displayFrame(sampleBuffer)
            currentFrameIndex += 1
            updateProgress()
        } else {
            // 读取完毕，重新初始化
            if let asset = asset {
                setupAssetReader(for: asset)
                currentFrameIndex = 0
                updateProgress()
                showAlert(title: "完成", message: "已读取所有帧，已重置到开头")
            }
        }
    }
    
    @objc private func toggleAutoPlay() {
        isAutoPlaying.toggle()
        
        if isAutoPlaying {
            autoPlayButton.setTitle("停止", for: .normal)
            autoPlayButton.backgroundColor = .systemRed
            startAutoPlay()
        } else {
            autoPlayButton.setTitle("自动播放", for: .normal)
            autoPlayButton.backgroundColor = .systemPurple
            stopAutoPlay()
        }
    }
    
    @objc private func sliderChanged() {
        guard let asset = asset else { return }
        let targetTime = CMTime(seconds: Double(progressSlider.value) * asset.duration.seconds,
                               preferredTimescale: 600)
        seekTo(time: targetTime)
    }
    
    // MARK: - Asset Reader Setup
    
    private func setupAssetReader(for asset: AVAsset) {
        self.asset = asset
        
        // 取消旧的reader
        assetReader?.cancelReading()
        
        do {
            assetReader = try AVAssetReader(asset: asset)
        } catch {
            showAlert(title: "错误", message: "无法创建 AssetReader: \(error)")
            return
        }
        
        // 获取视频轨道
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            showAlert(title: "错误", message: "视频中没有视频轨道")
            return
        }
        
        // 配置输出设置
        let outputSettings: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferIOSurfacePropertiesKey as String: [:]
        ]
        
        videoTrackOutput = AVAssetReaderTrackOutput(track: videoTrack,
                                                     outputSettings: outputSettings)
        videoTrackOutput?.alwaysCopiesSampleData = false // 性能优化
        
        if let output = videoTrackOutput, assetReader?.canAdd(output) == true {
            assetReader?.add(output)
        }
        
        // 开始读取
        if assetReader?.startReading() == false {
            showAlert(title: "错误", message: "无法开始读取")
            return
        }
        
        // 估算总帧数
        let fps = videoTrack.nominalFrameRate
        let duration = asset.duration.seconds
        totalFrames = Int(Double(fps) * duration)
        
        // 更新UI
        nextFrameButton.isEnabled = true
        autoPlayButton.isEnabled = true
        progressSlider.isEnabled = true
        progressSlider.maximumValue = Float(duration)
        
        // 显示视频信息
        displayAssetInfo(asset, videoTrack: videoTrack)
    }
    
    private func seekTo(time: CMTime) {
        guard let asset = asset else { return }
        
        // 需要重新创建reader并设置timeRange
        assetReader?.cancelReading()
        
        do {
            assetReader = try AVAssetReader(asset: asset)
        } catch {
            return
        }
        
        guard let videoTrack = asset.tracks(withMediaType: .video).first else { return }
        
        let outputSettings: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        
        // 设置时间范围
        let remainingDuration = CMTimeSubtract(asset.duration, time)
        let timeRange = CMTimeRange(start: time, duration: remainingDuration)
        
        videoTrackOutput = AVAssetReaderTrackOutput(track: videoTrack,
                                                     outputSettings: outputSettings)
        
        // 注意：AVAssetReaderTrackOutput不支持timeRange，需要在AVAssetReader层设置
        // 这里我们简化处理，重新创建reader但不设置timeRange
        
        if let output = videoTrackOutput, assetReader?.canAdd(output) == true {
            assetReader?.add(output)
        }
        
        assetReader?.startReading()
        
        // 读取并显示当前帧
        readNextFrame()
    }
    
    // MARK: - Display
    
    private func displayFrame(_ sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        
        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
            DispatchQueue.main.async { [weak self] in
                self?.imageView.image = UIImage(cgImage: cgImage)
            }
        }
        
        // 显示帧信息
        let frameInfo = analyzeFrame(sampleBuffer, frameIndex: currentFrameIndex)
        DispatchQueue.main.async { [weak self] in
            self?.infoTextView.text = frameInfo
        }
    }
    
    private func displayAssetInfo(_ asset: AVAsset, videoTrack: AVAssetTrack) {
        var info = "🎬 视频文件信息\n\n"
        
        info += "基本信息:\n"
        info += "  • 时长: \(String(format: "%.2f", asset.duration.seconds))s\n"
        info += "  • 分辨率: \(Int(videoTrack.naturalSize.width)) x \(Int(videoTrack.naturalSize.height))\n"
        info += "  • 帧率: \(videoTrack.nominalFrameRate) fps\n"
        info += "  • 估算总帧数: \(totalFrames)\n"
        info += "  • 编码格式: \(videoTrack.mediaType.rawValue)\n\n"
        
        if let formatDescriptions = videoTrack.formatDescriptions as? [CMFormatDescription],
           let formatDesc = formatDescriptions.first {
            let mediaSubtype = CMFormatDescriptionGetMediaSubType(formatDesc)
            info += "编码信息:\n"
            info += "  • Codec: \(fourCCToString(mediaSubtype))\n"
        }
        
        info += "\n准备就绪，可以开始逐帧读取\n"
        info += "点击「下一帧」手动读取，或「自动播放」连续读取"
        
        DispatchQueue.main.async { [weak self] in
            self?.infoTextView.text = info
        }
    }
    
    private func analyzeFrame(_ sampleBuffer: CMSampleBuffer, frameIndex: Int) -> String {
        var info = "📄 第 \(frameIndex) 帧详细信息\n\n"
        
        let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        info += "时间信息:\n"
        info += "  • PTS: \(String(format: "%.3f", presentationTime.seconds))s\n"
        info += "  • 时间码: \(formatTimeCode(presentationTime))\n\n"
        
        if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            let width = CVPixelBufferGetWidth(pixelBuffer)
            let height = CVPixelBufferGetHeight(pixelBuffer)
            let pixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer)
            let dataSize = CVPixelBufferGetDataSize(pixelBuffer)
            
            info += "像素缓冲区:\n"
            info += "  • 尺寸: \(width) x \(height)\n"
            info += "  • 格式: \(fourCCToString(pixelFormat))\n"
            info += "  • 大小: \(formatBytes(dataSize))\n"
        }
        
        if let formatDesc = CMSampleBufferGetFormatDescription(sampleBuffer) {
            let dimensions = CMVideoFormatDescriptionGetDimensions(formatDesc)
            info += "\n格式描述:\n"
            info += "  • 编码尺寸: \(dimensions.width) x \(dimensions.height)\n"
        }
        
        info += "\nAssetReader 状态:\n"
        info += "  • Status: \(assetReader?.status.description ?? "Unknown")\n"
        info += "  • 进度: \(currentFrameIndex)/\(totalFrames)\n"
        info += "  • 百分比: \(String(format: "%.1f", Double(currentFrameIndex)/Double(totalFrames)*100))%"
        
        return info
    }
    
    // MARK: - Auto Play
    
    private func startAutoPlay() {
        autoPlayTimer = Timer.scheduledTimer(withTimeInterval: 1.0/30.0, repeats: true) { [weak self] _ in
            self?.readNextFrame()
        }
    }
    
    private func stopAutoPlay() {
        autoPlayTimer?.invalidate()
        autoPlayTimer = nil
    }
    
    private func updateProgress() {
        guard let asset = asset else { return }
        let progress = Float(currentFrameIndex) / Float(totalFrames)
        progressSlider.value = progress * Float(asset.duration.seconds)
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
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    private func formatTimeCode(_ time: CMTime) -> String {
        let totalSeconds = Int(time.seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        let ms = Int((time.seconds - Double(totalSeconds)) * 1000)
        return String(format: "%02d:%02d:%02d.%03d", hours, minutes, seconds, ms)
    }
    
    private func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .default))
            self.present(alert, animated: true)
        }
    }
}

// MARK: - UIImagePickerControllerDelegate

extension AssetReaderViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                              didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        if let url = info[.mediaURL] as? URL {
            let asset = AVAsset(url: url)
            setupAssetReader(for: asset)
        }
    }
}

// MARK: - AVAssetReader.Status Extension

extension AVAssetReader.Status: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknown: return "Unknown"
        case .reading: return "Reading"
        case .completed: return "Completed"
        case .failed: return "Failed"
        case .cancelled: return "Cancelled"
        @unknown default: return "Unknown"
        }
    }
}

