//
//  AudioPlayViewController.swift
//  AudioVideo
//
//  Created by tangyumeng on 2025/10/6.
//

import UIKit
import AVFoundation

class AudioPlayViewController: UIViewController {
    
    // MARK: - Properties
    
    private var audioPlayer: AVAudioPlayer?
    
    private let playButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "play.circle.fill"), for: .normal)
        button.setImage(UIImage(systemName: "pause.circle.fill"), for: .selected)
        button.tintColor = .systemBlue
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let progressSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.value = 0
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.text = "00:00 / 00:00"
        label.textAlignment = .center
        label.font = .monospacedDigitSystemFont(ofSize: 16, weight: .regular)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let volumeSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.value = 0.5
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()
    
    private let urlTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "输入音频文件 URL"
        textField.borderStyle = .roundedRect
        textField.text = "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3"
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let loadButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("加载音频", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let infoLabel: UILabel = {
        let label = UILabel()
        label.text = "AVAudioPlayer 音频播放\n支持多种音频格式和播放控制"
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var progressTimer: Timer?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }
    
    deinit {
        progressTimer?.invalidate()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(infoLabel)
        view.addSubview(urlTextField)
        view.addSubview(loadButton)
        view.addSubview(playButton)
        view.addSubview(progressSlider)
        view.addSubview(timeLabel)
        view.addSubview(volumeSlider)
        
        let volumeIcon = UIImageView(image: UIImage(systemName: "speaker.wave.2.fill"))
        volumeIcon.tintColor = .systemGray
        volumeIcon.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(volumeIcon)
        
        NSLayoutConstraint.activate([
            infoLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            infoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            infoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            urlTextField.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 30),
            urlTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            urlTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            urlTextField.heightAnchor.constraint(equalToConstant: 44),
            
            loadButton.topAnchor.constraint(equalTo: urlTextField.bottomAnchor, constant: 12),
            loadButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadButton.widthAnchor.constraint(equalToConstant: 120),
            loadButton.heightAnchor.constraint(equalToConstant: 44),
            
            playButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 100),
            playButton.heightAnchor.constraint(equalToConstant: 100),
            
            progressSlider.topAnchor.constraint(equalTo: playButton.bottomAnchor, constant: 40),
            progressSlider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            progressSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            timeLabel.topAnchor.constraint(equalTo: progressSlider.bottomAnchor, constant: 8),
            timeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            volumeIcon.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 30),
            volumeIcon.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            volumeIcon.widthAnchor.constraint(equalToConstant: 24),
            volumeIcon.heightAnchor.constraint(equalToConstant: 24),
            
            volumeSlider.centerYAnchor.constraint(equalTo: volumeIcon.centerYAnchor),
            volumeSlider.leadingAnchor.constraint(equalTo: volumeIcon.trailingAnchor, constant: 12),
            volumeSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
    }
    
    private func setupActions() {
        playButton.addTarget(self, action: #selector(togglePlay), for: .touchUpInside)
        loadButton.addTarget(self, action: #selector(loadAudio), for: .touchUpInside)
        progressSlider.addTarget(self, action: #selector(progressChanged), for: .valueChanged)
        volumeSlider.addTarget(self, action: #selector(volumeChanged), for: .valueChanged)
    }
    
    // MARK: - Actions
    
    @objc private func loadAudio() {
        view.endEditing(true)
        
        guard let urlString = urlTextField.text, !urlString.isEmpty else {
            return
        }
        
        guard let url = URL(string: urlString) else {
            return
        }
        
        // 下载并加载音频
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self, let data = data, error == nil else {
                print("下载失败: \(error?.localizedDescription ?? "")")
                return
            }
            
            DispatchQueue.main.async {
                do {
                    self.audioPlayer = try AVAudioPlayer(data: data)
                    self.audioPlayer?.prepareToPlay()
                    self.audioPlayer?.volume = self.volumeSlider.value
                    self.updateProgress()
                } catch {
                    print("加载音频失败: \(error)")
                }
            }
        }.resume()
    }
    
    @objc private func togglePlay() {
        guard let player = audioPlayer else { return }
        
        if player.isPlaying {
            player.pause()
            playButton.isSelected = false
            progressTimer?.invalidate()
        } else {
            player.play()
            playButton.isSelected = true
            startProgressTimer()
        }
    }
    
    @objc private func progressChanged(_ slider: UISlider) {
        guard let player = audioPlayer else { return }
        player.currentTime = TimeInterval(slider.value) * player.duration
        updateTimeLabel()
    }
    
    @objc private func volumeChanged(_ slider: UISlider) {
        audioPlayer?.volume = slider.value
    }
    
    // MARK: - Helpers
    
    private func startProgressTimer() {
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateProgress()
        }
    }
    
    private func updateProgress() {
        guard let player = audioPlayer else { return }
        
        if player.duration > 0 {
            progressSlider.value = Float(player.currentTime / player.duration)
            updateTimeLabel()
        }
        
        if !player.isPlaying && player.currentTime >= player.duration {
            playButton.isSelected = false
            progressTimer?.invalidate()
        }
    }
    
    private func updateTimeLabel() {
        guard let player = audioPlayer else {
            timeLabel.text = "00:00 / 00:00"
            return
        }
        
        let current = formatTime(player.currentTime)
        let total = formatTime(player.duration)
        timeLabel.text = "\(current) / \(total)"
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}


