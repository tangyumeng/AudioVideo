//
//  AudioProcessViewController.swift
//  AudioVideo
//
//  Created by tangyumeng on 2025/10/6.
//

import UIKit
import AVFoundation

class AudioProcessViewController: UIViewController {
    
    // MARK: - Properties
    
    private var audioEngine: AVAudioEngine?
    private var audioPlayerNode: AVAudioPlayerNode?
    private var audioFile: AVAudioFile?
    private var reverb: AVAudioUnitReverb?
    private var delay: AVAudioUnitDelay?
    private var distortion: AVAudioUnitDistortion?
    
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
    
    private let reverbSwitch: UISwitch = {
        let switchControl = UISwitch()
        switchControl.translatesAutoresizingMaskIntoConstraints = false
        return switchControl
    }()
    
    private let delaySwitch: UISwitch = {
        let switchControl = UISwitch()
        switchControl.translatesAutoresizingMaskIntoConstraints = false
        return switchControl
    }()
    
    private let distortionSwitch: UISwitch = {
        let switchControl = UISwitch()
        switchControl.translatesAutoresizingMaskIntoConstraints = false
        return switchControl
    }()
    
    private let reverbSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 100
        slider.value = 50
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()
    
    private let delaySlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 2
        slider.value = 0.5
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()
    
    private let infoLabel: UILabel = {
        let label = UILabel()
        label.text = "AVAudioEngine 音频处理\n实时音效处理演示"
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = "加载示例音频..."
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 14)
        label.textColor = .systemGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        setupAudioEngine()
        loadSampleAudio()
    }
    
    deinit {
        audioEngine?.stop()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(infoLabel)
        view.addSubview(statusLabel)
        view.addSubview(playButton)
        
        // 创建音效控制面板
        let reverbLabel = createLabel(text: "混响 (Reverb)")
        let delayLabel = createLabel(text: "延迟 (Delay)")
        let distortionLabel = createLabel(text: "失真 (Distortion)")
        
        view.addSubview(reverbLabel)
        view.addSubview(reverbSwitch)
        view.addSubview(reverbSlider)
        
        view.addSubview(delayLabel)
        view.addSubview(delaySwitch)
        view.addSubview(delaySlider)
        
        view.addSubview(distortionLabel)
        view.addSubview(distortionSwitch)
        
        NSLayoutConstraint.activate([
            infoLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            infoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            infoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            statusLabel.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 20),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            playButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            playButton.widthAnchor.constraint(equalToConstant: 150),
            playButton.heightAnchor.constraint(equalToConstant: 50),
            
            // 混响
            reverbLabel.topAnchor.constraint(equalTo: playButton.bottomAnchor, constant: 50),
            reverbLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            
            reverbSwitch.centerYAnchor.constraint(equalTo: reverbLabel.centerYAnchor),
            reverbSwitch.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            
            reverbSlider.topAnchor.constraint(equalTo: reverbLabel.bottomAnchor, constant: 8),
            reverbSlider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            reverbSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            
            // 延迟
            delayLabel.topAnchor.constraint(equalTo: reverbSlider.bottomAnchor, constant: 25),
            delayLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            
            delaySwitch.centerYAnchor.constraint(equalTo: delayLabel.centerYAnchor),
            delaySwitch.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            
            delaySlider.topAnchor.constraint(equalTo: delayLabel.bottomAnchor, constant: 8),
            delaySlider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            delaySlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            
            // 失真
            distortionLabel.topAnchor.constraint(equalTo: delaySlider.bottomAnchor, constant: 25),
            distortionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            
            distortionSwitch.centerYAnchor.constraint(equalTo: distortionLabel.centerYAnchor),
            distortionSwitch.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30)
        ])
    }
    
    private func createLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    
    private func setupActions() {
        playButton.addTarget(self, action: #selector(togglePlay), for: .touchUpInside)
        reverbSwitch.addTarget(self, action: #selector(effectSwitchChanged), for: .valueChanged)
        delaySwitch.addTarget(self, action: #selector(effectSwitchChanged), for: .valueChanged)
        distortionSwitch.addTarget(self, action: #selector(effectSwitchChanged), for: .valueChanged)
        reverbSlider.addTarget(self, action: #selector(reverbSliderChanged), for: .valueChanged)
        delaySlider.addTarget(self, action: #selector(delaySliderChanged), for: .valueChanged)
    }
    
    // MARK: - Audio Engine Setup
    
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        audioPlayerNode = AVAudioPlayerNode()
        
        guard let engine = audioEngine,
              let playerNode = audioPlayerNode else {
            return
        }
        
        // 创建音效单元
        reverb = AVAudioUnitReverb()
        reverb?.loadFactoryPreset(.largeHall)
        reverb?.wetDryMix = 50
        
        delay = AVAudioUnitDelay()
        delay?.delayTime = 0.5
        delay?.feedback = 50
        delay?.wetDryMix = 50
        
        distortion = AVAudioUnitDistortion()
        distortion?.loadFactoryPreset(.multiDecimated1)
        
        // 添加节点
        engine.attach(playerNode)
        if let reverb = reverb { engine.attach(reverb) }
        if let delay = delay { engine.attach(delay) }
        if let distortion = distortion { engine.attach(distortion) }
        
        updateAudioChain()
    }
    
    private func updateAudioChain() {
        guard let engine = audioEngine,
              let playerNode = audioPlayerNode else {
            return
        }
        
        engine.disconnectNodeOutput(playerNode)
        
        var lastNode: AVAudioNode = playerNode
        let mainMixer = engine.mainMixerNode
        
        // 根据开关状态连接音效
        if reverbSwitch.isOn, let reverb = reverb {
            engine.connect(lastNode, to: reverb, format: nil)
            lastNode = reverb
        }
        
        if delaySwitch.isOn, let delay = delay {
            engine.connect(lastNode, to: delay, format: nil)
            lastNode = delay
        }
        
        if distortionSwitch.isOn, let distortion = distortion {
            engine.connect(lastNode, to: distortion, format: nil)
            lastNode = distortion
        }
        
        engine.connect(lastNode, to: mainMixer, format: nil)
    }
    
    private func loadSampleAudio() {
        // 生成一个简单的音频示例（1秒440Hz正弦波）
        let sampleRate = 44100.0
        let frequency = 440.0
        let duration = 2.0
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
        
        // 生成正弦波
        let channels = UnsafeBufferPointer(start: buffer.floatChannelData, count: Int(format.channelCount))
        for frame in 0..<Int(frameCount) {
            let value = sin(2.0 * .pi * frequency * Double(frame) / sampleRate)
            channels[0][frame] = Float(value) * 0.3
        }
        
        // 创建临时文件
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("sample_tone.caf")
        
        do {
            let audioFile = try AVAudioFile(forWriting: tempURL, settings: format.settings)
            try audioFile.write(from: buffer)
            self.audioFile = try AVAudioFile(forReading: tempURL)
            statusLabel.text = "示例音频已加载 ✅"
        } catch {
            statusLabel.text = "音频加载失败: \(error.localizedDescription)"
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
        } else {
            do {
                if !engine.isRunning {
                    try engine.start()
                }
                
                playerNode.scheduleFile(audioFile, at: nil) {
                    DispatchQueue.main.async { [weak self] in
                        self?.playButton.isSelected = false
                    }
                }
                playerNode.play()
                playButton.isSelected = true
            } catch {
                print("播放失败: \(error)")
            }
        }
    }
    
    @objc private func effectSwitchChanged() {
        updateAudioChain()
    }
    
    @objc private func reverbSliderChanged(_ slider: UISlider) {
        reverb?.wetDryMix = slider.value
    }
    
    @objc private func delaySliderChanged(_ slider: UISlider) {
        delay?.delayTime = TimeInterval(slider.value)
    }
}


