//
//  AudioRecordViewController.swift
//  AudioVideo
//
//  Created by tangyumeng on 2025/10/6.
//

import UIKit
import AVFoundation

class AudioRecordViewController: UIViewController {
    
    // MARK: - Properties
    
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var recordingURL: URL?
    
    private let recordButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("🎤 开始录音", for: .normal)
        button.setTitle("⏹ 停止录音", for: .selected)
        button.backgroundColor = .systemRed
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.layer.cornerRadius = 25
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
        
    private let playButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("▶️ 播放录音", for: .normal)
        button.setTitle("⏸ 暂停播放", for: .selected)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.layer.cornerRadius = 25
        button.isEnabled = false
        button.alpha = 0.5
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = "准备录音"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let infoLabel: UILabel = {
        let label = UILabel()
        label.text = "AVAudioRecorder 音频录制\n录制高质量音频并支持播放"
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let waveformView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        setupAudioSession()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(infoLabel)
        view.addSubview(waveformView)
        view.addSubview(statusLabel)
        view.addSubview(recordButton)
        view.addSubview(playButton)
        
        NSLayoutConstraint.activate([
            infoLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            infoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            infoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            waveformView.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 30),
            waveformView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            waveformView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            waveformView.heightAnchor.constraint(equalToConstant: 150),
            
            statusLabel.topAnchor.constraint(equalTo: waveformView.bottomAnchor, constant: 30),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            recordButton.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 40),
            recordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            recordButton.widthAnchor.constraint(equalToConstant: 200),
            recordButton.heightAnchor.constraint(equalToConstant: 50),
            
            playButton.topAnchor.constraint(equalTo: recordButton.bottomAnchor, constant: 20),
            playButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 200),
            playButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupActions() {
        recordButton.addTarget(self, action: #selector(toggleRecording), for: .touchUpInside)
        playButton.addTarget(self, action: #selector(togglePlayback), for: .touchUpInside)
    }
    
    private func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("音频会话设置失败: \(error)")
        }
    }
    
    // MARK: - Actions
    
    @objc private func toggleRecording() {
        if recordButton.isSelected {
            stopRecording()
        } else {
            startRecording()
        }
        recordButton.isSelected.toggle()
    }
    
    @objc private func togglePlayback() {
        if playButton.isSelected {
            stopPlayback()
        } else {
            startPlayback()
        }
        playButton.isSelected.toggle()
    }
    
    // MARK: - Recording
    
    private func startRecording() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilename = documentsPath.appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")
        recordingURL = audioFilename
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.record()
            statusLabel.text = "录音中... 🔴"
            playButton.isEnabled = false
            playButton.alpha = 0.5
        } catch {
            print("录音失败: \(error)")
            statusLabel.text = "录音失败"
            recordButton.isSelected = false
        }
    }
    
    private func stopRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
        statusLabel.text = "录音完成 ✅\n文件: \(recordingURL?.lastPathComponent ?? "")"
        playButton.isEnabled = true
        playButton.alpha = 1.0
    }
    
    // MARK: - Playback
    
    private func startPlayback() {
        guard let url = recordingURL else { return }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
            statusLabel.text = "播放中... 🔊"
        } catch {
            print("播放失败: \(error)")
            statusLabel.text = "播放失败"
            playButton.isSelected = false
        }
    }
    
    private func stopPlayback() {
        audioPlayer?.pause()
        statusLabel.text = "播放暂停"
    }
}


