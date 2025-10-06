//
//  VideoEditViewController.swift
//  AudioVideo
//
//  Created by tangyumeng on 2025/10/6.
//

import UIKit
import AVFoundation

class VideoEditViewController: UIViewController {
    
    // MARK: - Properties
    
    private let infoLabel: UILabel = {
        let label = UILabel()
        label.text = "视频编辑功能\nAVAssetExportSession 视频剪辑与导出"
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = """
        主要功能：
        • 视频裁剪（时间段截取）
        • 视频合并
        • 添加背景音乐
        • 调整视频速率
        • 视频格式转换
        • 导出不同分辨率
        """
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let urlTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "输入视频 URL"
        textField.borderStyle = .roundedRect
        textField.text = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let startTimeField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "开始时间（秒）"
        textField.borderStyle = .roundedRect
        textField.keyboardType = .decimalPad
        textField.text = "0"
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let endTimeField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "结束时间（秒）"
        textField.borderStyle = .roundedRect
        textField.keyboardType = .decimalPad
        textField.text = "10"
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let trimButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("✂️ 裁剪视频", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.translatesAutoresizingMaskIntoConstraints = false
        progress.isHidden = true
        return progress
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = "准备就绪"
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
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(infoLabel)
        view.addSubview(descriptionLabel)
        view.addSubview(urlTextField)
        view.addSubview(startTimeField)
        view.addSubview(endTimeField)
        view.addSubview(trimButton)
        view.addSubview(progressView)
        view.addSubview(statusLabel)
        
        NSLayoutConstraint.activate([
            infoLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            infoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            infoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            descriptionLabel.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 20),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            
            urlTextField.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 30),
            urlTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            urlTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            urlTextField.heightAnchor.constraint(equalToConstant: 44),
            
            startTimeField.topAnchor.constraint(equalTo: urlTextField.bottomAnchor, constant: 12),
            startTimeField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            startTimeField.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.4),
            startTimeField.heightAnchor.constraint(equalToConstant: 44),
            
            endTimeField.topAnchor.constraint(equalTo: urlTextField.bottomAnchor, constant: 12),
            endTimeField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            endTimeField.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.4),
            endTimeField.heightAnchor.constraint(equalToConstant: 44),
            
            trimButton.topAnchor.constraint(equalTo: startTimeField.bottomAnchor, constant: 30),
            trimButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            trimButton.widthAnchor.constraint(equalToConstant: 200),
            trimButton.heightAnchor.constraint(equalToConstant: 50),
            
            progressView.topAnchor.constraint(equalTo: trimButton.bottomAnchor, constant: 30),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            statusLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 12),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    private func setupActions() {
        trimButton.addTarget(self, action: #selector(trimVideo), for: .touchUpInside)
    }
    
    // MARK: - Actions
    
    @objc private func trimVideo() {
        view.endEditing(true)
        
        guard let urlString = urlTextField.text, !urlString.isEmpty,
              let url = URL(string: urlString),
              let startTime = Double(startTimeField.text ?? "0"),
              let endTime = Double(endTimeField.text ?? "10") else {
            showAlert(message: "请输入有效的参数")
            return
        }
        
        guard endTime > startTime else {
            showAlert(message: "结束时间必须大于开始时间")
            return
        }
        
        statusLabel.text = "正在加载视频..."
        progressView.isHidden = false
        progressView.progress = 0
        trimButton.isEnabled = false
        
        let asset = AVAsset(url: url)
        let startCMTime = CMTime(seconds: startTime, preferredTimescale: 600)
        let endCMTime = CMTime(seconds: endTime, preferredTimescale: 600)
        let timeRange = CMTimeRange(start: startCMTime, end: endCMTime)
        
        performTrimming(asset: asset, timeRange: timeRange)
    }
    
    // MARK: - Video Processing
    
    private func performTrimming(asset: AVAsset, timeRange: CMTimeRange) {
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            showAlert(message: "无法创建导出会话")
            resetUI()
            return
        }
        
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("trimmed_\(Date().timeIntervalSince1970).mp4")
        
        // 删除已存在的文件
        try? FileManager.default.removeItem(at: outputURL)
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.timeRange = timeRange
        
        statusLabel.text = "正在导出视频..."
        
        // 监听导出进度
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            DispatchQueue.main.async {
                self.progressView.progress = exportSession.progress
            }
            
            if exportSession.status != .exporting {
                timer.invalidate()
            }
        }
        
        exportSession.exportAsynchronously { [weak self] in
            DispatchQueue.main.async {
                timer.invalidate()
                self?.handleExportCompletion(session: exportSession, outputURL: outputURL)
            }
        }
    }
    
    private func handleExportCompletion(session: AVAssetExportSession, outputURL: URL) {
        progressView.progress = 1.0
        
        switch session.status {
        case .completed:
            statusLabel.text = "导出成功！✅\n文件: \(outputURL.lastPathComponent)"
            statusLabel.textColor = .systemGreen
            
            // 可以在这里播放或分享视频
            print("导出的视频路径: \(outputURL.path)")
            
        case .failed:
            statusLabel.text = "导出失败: \(session.error?.localizedDescription ?? "未知错误")"
            statusLabel.textColor = .systemRed
            
        case .cancelled:
            statusLabel.text = "导出已取消"
            statusLabel.textColor = .systemOrange
            
        default:
            break
        }
        
        trimButton.isEnabled = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.resetUI()
        }
    }
    
    // MARK: - Helpers
    
    private func resetUI() {
        progressView.isHidden = true
        progressView.progress = 0
        statusLabel.text = "准备就绪"
        statusLabel.textColor = .systemGray
        trimButton.isEnabled = true
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "提示", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}


