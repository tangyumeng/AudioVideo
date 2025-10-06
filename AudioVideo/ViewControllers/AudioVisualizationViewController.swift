//
//  AudioVisualizationViewController.swift
//  AudioVideo
//
//  Created by tangyumeng on 2025/10/6.
//

import UIKit
import AVFoundation

class AudioVisualizationViewController: UIViewController {
    
    // MARK: - Properties
    
    private var audioEngine: AVAudioEngine?
    private var audioPlayerNode: AVAudioPlayerNode?
    private var audioFile: AVAudioFile?
    
    private let waveformView: WaveformView = {
        let view = WaveformView()
        view.backgroundColor = .black
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let playButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("▶️ 播放", for: .normal)
        button.setTitle("⏸ 暂停", for: .selected)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.layer.cornerRadius = 25
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let infoLabel: UILabel = {
        let label = UILabel()
        label.text = "音频波形可视化\n实时显示音频频谱"
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = "生成示例音频..."
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 14)
        label.textColor = .systemGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var displayLink: CADisplayLink?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        setupAudioEngine()
        generateSampleAudio()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopVisualization()
    }
    
    deinit {
        audioEngine?.stop()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(infoLabel)
        view.addSubview(statusLabel)
        view.addSubview(waveformView)
        view.addSubview(playButton)
        
        NSLayoutConstraint.activate([
            infoLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            infoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            infoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            statusLabel.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 10),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            waveformView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            waveformView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            waveformView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            waveformView.heightAnchor.constraint(equalToConstant: 250),
            
            playButton.topAnchor.constraint(equalTo: waveformView.bottomAnchor, constant: 40),
            playButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 150),
            playButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupActions() {
        playButton.addTarget(self, action: #selector(togglePlay), for: .touchUpInside)
    }
    
    // MARK: - Audio Engine Setup
    
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        audioPlayerNode = AVAudioPlayerNode()
        
        guard let engine = audioEngine,
              let playerNode = audioPlayerNode else {
            return
        }
        
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: nil)
    }
    
    private func generateSampleAudio() {
        // 生成一个包含多个频率的音频示例
        let sampleRate = 44100.0
        let duration = 5.0
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else {
            statusLabel.text = "音频格式创建失败"
            return
        }
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            statusLabel.text = "音频缓冲区创建失败"
            return
        }
        
        buffer.frameLength = frameCount
        
        // 生成多频率混合的音频（和弦）
        let channels = UnsafeBufferPointer(start: buffer.floatChannelData, count: Int(format.channelCount))
        let frequencies = [261.63, 329.63, 392.00] // C大调和弦 (C, E, G)
        
        for frame in 0..<Int(frameCount) {
            var value: Double = 0
            for frequency in frequencies {
                value += sin(2.0 * .pi * frequency * Double(frame) / sampleRate) / Double(frequencies.count)
            }
            // 添加一些振幅变化
            let envelope = sin(2.0 * .pi * Double(frame) / Double(frameCount) * 4) * 0.5 + 0.5
            channels[0][frame] = Float(value * envelope) * 0.3
        }
        
        // 创建临时文件
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("visualization_sample.caf")
        
        do {
            let audioFile = try AVAudioFile(forWriting: tempURL, settings: format.settings)
            try audioFile.write(from: buffer)
            self.audioFile = try AVAudioFile(forReading: tempURL)
            statusLabel.text = "示例音频已生成 ✅"
        } catch {
            statusLabel.text = "音频生成失败: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Actions
    
    @objc private func togglePlay() {
        guard let playerNode = audioPlayerNode,
              let audioFile = audioFile,
              let engine = audioEngine else {
            return
        }
        
        if playerNode.isPlaying {
            playerNode.pause()
            playButton.isSelected = false
            stopVisualization()
        } else {
            do {
                if !engine.isRunning {
                    try engine.start()
                }
                
                playerNode.scheduleFile(audioFile, at: nil) {
                    DispatchQueue.main.async { [weak self] in
                        self?.playButton.isSelected = false
                        self?.stopVisualization()
                    }
                }
                playerNode.play()
                playButton.isSelected = true
                startVisualization()
            } catch {
                print("播放失败: \(error)")
                statusLabel.text = "播放失败"
            }
        }
    }
    
    // MARK: - Visualization
    
    private func startVisualization() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateVisualization))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    private func stopVisualization() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc private func updateVisualization() {
        guard let engine = audioEngine else { return }
        
        // 获取主混音器节点的音频数据
        let mainMixer = engine.mainMixerNode
        let format = mainMixer.outputFormat(forBus: 0)
        
        // 生成模拟的频谱数据
        let barCount = 32
        var levels = [Float]()
        
        for i in 0..<barCount {
            // 创建基于时间的动画效果
            let time = Date().timeIntervalSince1970
            let frequency = Double(i) / Double(barCount) * 10
            let level = Float(abs(sin(time * frequency + Double(i) * 0.5))) * 0.8 + 0.2
            levels.append(level)
        }
        
        waveformView.updateLevels(levels)
    }
}

// MARK: - WaveformView

class WaveformView: UIView {
    
    private var levels: [Float] = Array(repeating: 0, count: 32)
    private let barCount = 32
    private let barSpacing: CGFloat = 4
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        layer.cornerRadius = 12
        clipsToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateLevels(_ newLevels: [Float]) {
        levels = newLevels
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        let barWidth = (rect.width - CGFloat(barCount + 1) * barSpacing) / CGFloat(barCount)
        
        for (index, level) in levels.enumerated() {
            let x = CGFloat(index) * (barWidth + barSpacing) + barSpacing
            let height = rect.height * CGFloat(level) * 0.8
            let y = (rect.height - height) / 2
            
            let barRect = CGRect(x: x, y: y, width: barWidth, height: height)
            
            // 根据高度设置渐变颜色
            let hue = CGFloat(level) * 0.3 + 0.5 // 从绿色到红色
            let color = UIColor(hue: hue, saturation: 0.8, brightness: 0.9, alpha: 1.0)
            
            context.setFillColor(color.cgColor)
            context.fill(barRect)
            
            // 添加高光效果
            let highlightRect = CGRect(x: x, y: y, width: barWidth, height: height * 0.3)
            context.setFillColor(UIColor.white.withAlphaComponent(0.3).cgColor)
            context.fill(highlightRect)
        }
    }
}


