//
//  VideoPlayerViewController.swift
//  AudioVideo
//
//  Created by tangyumeng on 2025/10/6.
//

import UIKit
import AVFoundation
import AVKit

class VideoPlayerViewController: UIViewController {
    
    // MARK: - Properties
    
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let playButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "play.circle.fill"), for: .normal)
        button.setImage(UIImage(systemName: "pause.circle.fill"), for: .selected)
        button.tintColor = .white
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let urlTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "输入视频 URL (支持本地或网络)"
        textField.borderStyle = .roundedRect
        textField.text = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let loadButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("加载视频", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let infoLabel: UILabel = {
        let label = UILabel()
        label.text = "AVPlayer 视频播放示例\n支持本地文件和网络流媒体"
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = containerView.bounds
    }
    
    deinit {
        player?.pause()
        player = nil
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(infoLabel)
        view.addSubview(urlTextField)
        view.addSubview(loadButton)
        view.addSubview(containerView)
        view.addSubview(playButton)
        
        NSLayoutConstraint.activate([
            infoLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            infoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            infoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            urlTextField.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 20),
            urlTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            urlTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            urlTextField.heightAnchor.constraint(equalToConstant: 44),
            
            loadButton.topAnchor.constraint(equalTo: urlTextField.bottomAnchor, constant: 12),
            loadButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadButton.widthAnchor.constraint(equalToConstant: 120),
            loadButton.heightAnchor.constraint(equalToConstant: 44),
            
            containerView.topAnchor.constraint(equalTo: loadButton.bottomAnchor, constant: 20),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.heightAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 9.0/16.0),
            
            playButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            playButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 80),
            playButton.heightAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    private func setupActions() {
        playButton.addTarget(self, action: #selector(togglePlay), for: .touchUpInside)
        loadButton.addTarget(self, action: #selector(loadVideo), for: .touchUpInside)
    }
    
    // MARK: - Actions
    
    @objc private func loadVideo() {
        view.endEditing(true)
        
        guard let urlString = urlTextField.text, !urlString.isEmpty else {
            showAlert(title: "错误", message: "请输入视频 URL")
            return
        }
        
        guard let url = URL(string: urlString) else {
            showAlert(title: "错误", message: "URL 格式不正确")
            return
        }
        
        setupPlayer(with: url)
    }
    
    @objc private func togglePlay() {
        guard let player = player else { return }
        
        if player.timeControlStatus == .playing {
            player.pause()
            playButton.isSelected = false
        } else {
            player.play()
            playButton.isSelected = true
        }
    }
    
    // MARK: - Player Setup
    
    private func setupPlayer(with url: URL) {
        // 清除旧的播放器
        player?.pause()
        playerLayer?.removeFromSuperlayer()
        
        // 创建新播放器
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = containerView.bounds
        playerLayer?.videoGravity = .resizeAspect
        
        if let layer = playerLayer {
            containerView.layer.addSublayer(layer)
        }
        
        playButton.isSelected = false
        
        // 监听播放状态
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )
    }
    
    @objc private func playerDidFinishPlaying() {
        playButton.isSelected = false
        player?.seek(to: .zero)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}


