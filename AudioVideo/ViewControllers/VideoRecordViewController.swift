//
//  VideoRecordViewController.swift
//  AudioVideo
//
//  Created by tangyumeng on 2025/10/6.
//

import UIKit
import AVFoundation

class VideoRecordViewController: UIViewController {
    
    // MARK: - Properties
    
    private var captureSession: AVCaptureSession?
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    private var movieFileOutput: AVCaptureMovieFileOutput?
    private var isRecording = false
    
    private let previewView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let recordButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("⏺ 开始录制", for: .normal)
        button.setTitle("⏹ 停止录制", for: .selected)
        button.backgroundColor = .systemRed
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.layer.cornerRadius = 25
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = "准备录制"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 14)
        label.textColor = .white
        label.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let recordingTimeLabel: UILabel = {
        let label = UILabel()
        label.text = "00:00"
        label.textAlignment = .center
        label.font = .monospacedDigitSystemFont(ofSize: 24, weight: .bold)
        label.textColor = .white
        label.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let infoLabel: UILabel = {
        let label = UILabel()
        label.text = "AVCaptureMovieFileOutput\n视频录制功能"
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 14)
        label.textColor = .white
        label.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var recordingTimer: Timer?
    private var recordingStartTime: Date?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        videoPreviewLayer?.frame = previewView.bounds
    }
    
    deinit {
        recordingTimer?.invalidate()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(previewView)
        view.addSubview(infoLabel)
        view.addSubview(statusLabel)
        view.addSubview(recordingTimeLabel)
        view.addSubview(recordButton)
        
        NSLayoutConstraint.activate([
            previewView.topAnchor.constraint(equalTo: view.topAnchor),
            previewView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            previewView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            infoLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            infoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            infoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            recordingTimeLabel.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 20),
            recordingTimeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            recordingTimeLabel.widthAnchor.constraint(equalToConstant: 100),
            recordingTimeLabel.heightAnchor.constraint(equalToConstant: 40),
            
            statusLabel.bottomAnchor.constraint(equalTo: recordButton.topAnchor, constant: -20),
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 150),
            statusLabel.heightAnchor.constraint(equalToConstant: 40),
            
            recordButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            recordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            recordButton.widthAnchor.constraint(equalToConstant: 180),
            recordButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupActions() {
        recordButton.addTarget(self, action: #selector(toggleRecording), for: .touchUpInside)
    }
    
    // MARK: - Actions
    
    @objc private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            checkPermissionsAndStartRecording()
        }
    }
    
    // MARK: - Camera Setup
    
    private func checkPermissionsAndStartRecording() {
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        let micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        
        if cameraStatus == .authorized && micStatus == .authorized {
            setupCameraAndStartRecording()
        } else {
            requestPermissions()
        }
    }
    
    private func requestPermissions() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] videoGranted in
            if videoGranted {
                AVCaptureDevice.requestAccess(for: .audio) { [weak self] audioGranted in
                    if audioGranted {
                        DispatchQueue.main.async {
                            self?.setupCameraAndStartRecording()
                        }
                    } else {
                        DispatchQueue.main.async {
                            self?.showPermissionAlert()
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self?.showPermissionAlert()
                }
            }
        }
    }
    
    private func setupCameraAndStartRecording() {
        if captureSession == nil {
            setupCamera()
        }
        startRecording()
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .high
        
        // 添加视频输入
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              captureSession?.canAddInput(videoInput) == true else {
            print("无法设置视频输入")
            return
        }
        captureSession?.addInput(videoInput)
        
        // 添加音频输入
        guard let audioDevice = AVCaptureDevice.default(for: .audio),
              let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
              captureSession?.canAddInput(audioInput) == true else {
            print("无法设置音频输入")
            return
        }
        captureSession?.addInput(audioInput)
        
        // 添加视频输出
        movieFileOutput = AVCaptureMovieFileOutput()
        if let movieOutput = movieFileOutput,
           captureSession?.canAddOutput(movieOutput) == true {
            captureSession?.addOutput(movieOutput)
        }
        
        // 设置预览层
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        videoPreviewLayer?.videoGravity = .resizeAspectFill
        videoPreviewLayer?.frame = previewView.bounds
        
        if let previewLayer = videoPreviewLayer {
            previewView.layer.addSublayer(previewLayer)
        }
        
        // 启动会话
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }
    
    // MARK: - Recording
    
    private func startRecording() {
        guard let movieOutput = movieFileOutput else { return }
        
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("video_\(Date().timeIntervalSince1970).mov")
        
        movieOutput.startRecording(to: outputURL, recordingDelegate: self)
        
        isRecording = true
        recordButton.isSelected = true
        statusLabel.text = "录制中 🔴"
        recordingTimeLabel.isHidden = false
        
        recordingStartTime = Date()
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateRecordingTime()
        }
    }
    
    private func stopRecording() {
        movieFileOutput?.stopRecording()
        
        isRecording = false
        recordButton.isSelected = false
        recordingTimer?.invalidate()
        recordingTimeLabel.isHidden = true
    }
    
    private func updateRecordingTime() {
        guard let startTime = recordingStartTime else { return }
        let elapsed = Date().timeIntervalSince(startTime)
        let minutes = Int(elapsed) / 60
        let seconds = Int(elapsed) % 60
        recordingTimeLabel.text = String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Helpers
    
    private func showPermissionAlert() {
        let alert = UIAlertController(
            title: "需要权限",
            message: "请在设置中允许访问相机和麦克风",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "设置", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate

extension VideoRecordViewController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("录制错误: \(error.localizedDescription)")
            statusLabel.text = "录制失败"
        } else {
            statusLabel.text = "录制完成 ✅\n文件: \(outputFileURL.lastPathComponent)"
            print("视频保存路径: \(outputFileURL.path)")
        }
    }
}


