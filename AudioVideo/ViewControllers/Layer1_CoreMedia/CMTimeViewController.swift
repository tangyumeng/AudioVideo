//
//  CMTimeViewController.swift
//  AudioVideo
//
//  Layer 1: Core Media & Core Video
//  CMTime 精确的时间系统
//

import UIKit
import AVFoundation
import CoreMedia

class CMTimeViewController: UIViewController {
    
    // MARK: - Properties
    
    private var player: AVPlayer?
    private var timeObserver: Any?
    
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
        ⏱ CMTime 时间系统详解
        
        CMTime 是 Core Media 中用于表示时间的核心结构。与普通的浮点数秒不同，CMTime 使用有理数表示，提供更高的精度。
        
        结构组成：
        • value: 时间值（分子）
        • timescale: 时间刻度（分母）
        • flags: 状态标志
        • epoch: 纪元（用于循环时间）
        
        实际时间 = value / timescale 秒
        
        为什么不直接用Double？
        1. 精度：避免浮点误差累积
        2. 同步：音视频需要精确同步
        3. 编辑：帧级别的精确操作
        """
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let examplesContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let examplesLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let playerContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.layer.cornerRadius = 8
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let playButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("播放视频示例", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let timeInfoLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        label.textAlignment = .center
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        generateTimeExamples()
    }
    
    deinit {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
        player?.pause()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(examplesContainer)
        examplesContainer.addSubview(examplesLabel)
        contentView.addSubview(playButton)
        contentView.addSubview(playerContainer)
        contentView.addSubview(timeInfoLabel)
        
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
            
            examplesContainer.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 16),
            examplesContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            examplesContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            examplesLabel.topAnchor.constraint(equalTo: examplesContainer.topAnchor, constant: 12),
            examplesLabel.leadingAnchor.constraint(equalTo: examplesContainer.leadingAnchor, constant: 12),
            examplesLabel.trailingAnchor.constraint(equalTo: examplesContainer.trailingAnchor, constant: -12),
            examplesLabel.bottomAnchor.constraint(equalTo: examplesContainer.bottomAnchor, constant: -12),
            
            playButton.topAnchor.constraint(equalTo: examplesContainer.bottomAnchor, constant: 20),
            playButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 150),
            playButton.heightAnchor.constraint(equalToConstant: 44),
            
            playerContainer.topAnchor.constraint(equalTo: playButton.bottomAnchor, constant: 16),
            playerContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            playerContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            playerContainer.heightAnchor.constraint(equalToConstant: 200),
            
            timeInfoLabel.topAnchor.constraint(equalTo: playerContainer.bottomAnchor, constant: 16),
            timeInfoLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            timeInfoLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            timeInfoLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }
    
    private func setupActions() {
        playButton.addTarget(self, action: #selector(togglePlay), for: .touchUpInside)
    }
    
    // MARK: - Generate Examples
    
    private func generateTimeExamples() {
        var examples = "📚 CMTime 示例代码\n\n"
        
        // 示例1: 创建1秒的时间
        let oneSecond = CMTime(value: 1, timescale: 1)
        examples += "// 创建1秒\n"
        examples += "let time = CMTime(value: 1, timescale: 1)\n"
        examples += "结果: \(formatCMTime(oneSecond))\n\n"
        
        // 示例2: 创建0.5秒 (500毫秒)
        let halfSecond = CMTime(value: 500, timescale: 1000)
        examples += "// 创建0.5秒（500毫秒）\n"
        examples += "let time = CMTime(value: 500, timescale: 1000)\n"
        examples += "结果: \(formatCMTime(halfSecond))\n\n"
        
        // 示例3: 30fps视频中的一帧
        let oneFrame30fps = CMTime(value: 1, timescale: 30)
        examples += "// 30fps视频中的一帧\n"
        examples += "let time = CMTime(value: 1, timescale: 30)\n"
        examples += "结果: \(formatCMTime(oneFrame30fps))\n\n"
        
        // 示例4: CMTime运算
        let time1 = CMTime(seconds: 1.5, preferredTimescale: 600)
        let time2 = CMTime(seconds: 2.3, preferredTimescale: 600)
        let sum = CMTimeAdd(time1, time2)
        examples += "// 时间加法\n"
        examples += "let t1 = CMTime(seconds: 1.5, preferredTimescale: 600)\n"
        examples += "let t2 = CMTime(seconds: 2.3, preferredTimescale: 600)\n"
        examples += "let sum = CMTimeAdd(t1, t2)\n"
        examples += "结果: \(formatCMTime(sum))\n\n"
        
        // 示例5: CMTimeRange
        let start = CMTime(seconds: 2.0, preferredTimescale: 600)
        let duration = CMTime(seconds: 5.0, preferredTimescale: 600)
        let range = CMTimeRange(start: start, duration: duration)
        examples += "// CMTimeRange（时间范围）\n"
        examples += "let range = CMTimeRange(\n"
        examples += "  start: CMTime(seconds: 2.0, ...),\n"
        examples += "  duration: CMTime(seconds: 5.0, ...)\n"
        examples += ")\n"
        examples += "范围: \(formatCMTimeRange(range))\n\n"
        
        // 特殊值
        examples += "// 特殊CMTime值\n"
        examples += "CMTime.zero         // 零时间\n"
        examples += "CMTime.invalid      // 无效时间\n"
        examples += "CMTime.positiveInfinity  // 正无穷\n"
        examples += "CMTime.negativeInfinity  // 负无穷\n"
        
        examplesLabel.text = examples
    }
    
    // MARK: - Video Player
    
    @objc private func togglePlay() {
        if player == nil {
            setupPlayer()
        }
        
        if player?.timeControlStatus == .playing {
            player?.pause()
            playButton.setTitle("播放视频示例", for: .normal)
        } else {
            player?.play()
            playButton.setTitle("暂停", for: .normal)
        }
    }
    
    private func setupPlayer() {
        // 使用苹果示例视频
        guard let url = URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4") else {
            return
        }
        
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = playerContainer.bounds
        playerLayer.videoGravity = .resizeAspect
        playerContainer.layer.addSublayer(playerLayer)
        
        // 添加时间观察器，每秒更新10次
        let interval = CMTime(value: 1, timescale: 10) // 0.1秒
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.updateTimeInfo(time)
        }
        
        // 监听播放结束
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )
    }
    
    private func updateTimeInfo(_ time: CMTime) {
        var info = "🎬 当前播放时间信息\n\n"
        info += "CMTime 结构:\n"
        info += "  value: \(time.value)\n"
        info += "  timescale: \(time.timescale)\n"
        info += "  flags: \(formatCMTimeFlags(time.flags))\n"
        info += "  epoch: \(time.epoch)\n\n"
        
        info += "计算结果:\n"
        info += "  秒数: \(String(format: "%.3f", time.seconds))s\n"
        info += "  毫秒: \(String(format: "%.0f", time.seconds * 1000))ms\n"
        info += "  时间码: \(formatTimeCode(time))\n\n"
        
        if let duration = player?.currentItem?.duration, duration.isValid {
            info += "视频时长:\n"
            info += "  总时长: \(String(format: "%.2f", duration.seconds))s\n"
            let progress = time.seconds / duration.seconds * 100
            info += "  进度: \(String(format: "%.1f", progress))%\n\n"
            
            let remaining = CMTimeSubtract(duration, time)
            info += "  剩余: \(String(format: "%.2f", remaining.seconds))s\n"
        }
        
        timeInfoLabel.text = info
    }
    
    @objc private func playerDidFinishPlaying() {
        player?.seek(to: .zero)
        playButton.setTitle("播放视频示例", for: .normal)
        timeInfoLabel.text = "视频播放结束"
    }
    
    // MARK: - Formatting Helpers
    
    private func formatCMTime(_ time: CMTime) -> String {
        if !time.isValid {
            return "Invalid"
        }
        return String(format: "%.3fs (value: %lld, scale: %d)", time.seconds, time.value, time.timescale)
    }
    
    private func formatCMTimeRange(_ range: CMTimeRange) -> String {
        let start = range.start.seconds
        let end = range.end.seconds
        let duration = range.duration.seconds
        return String(format: "%.2fs - %.2fs (时长: %.2fs)", start, end, duration)
    }
    
    private func formatCMTimeFlags(_ flags: CMTimeFlags) -> String {
        var result: [String] = []
        if flags.contains(.valid) { result.append("Valid") }
        if flags.contains(.hasBeenRounded) { result.append("Rounded") }
        if flags.contains(.positiveInfinity) { result.append("+∞") }
        if flags.contains(.negativeInfinity) { result.append("-∞") }
        if flags.contains(.indefinite) { result.append("Indefinite") }
        return result.isEmpty ? "None" : result.joined(separator: ", ")
    }
    
    private func formatTimeCode(_ time: CMTime) -> String {
        let totalSeconds = Int(time.seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        let milliseconds = Int((time.seconds - Double(totalSeconds)) * 1000)
        return String(format: "%02d:%02d:%02d.%03d", hours, minutes, seconds, milliseconds)
    }
}

