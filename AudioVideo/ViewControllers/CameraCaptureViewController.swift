//
//  CameraCaptureViewController.swift
//  AudioVideo
//
//  Created by tangyumeng on 2025/10/6.
//

import UIKit
import AVFoundation

class CameraCaptureViewController: UIViewController {
    
    // MARK: - Properties
    
    private var captureSession: AVCaptureSession?
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    private var captureDevice: AVCaptureDevice?
    
    private let previewView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let startButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("开始采集", for: .normal)
        button.setTitle("停止采集", for: .selected)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 25
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let infoLabel: UILabel = {
        let label = UILabel()
        label.text = "AVFoundation 相机采集示例\n使用 AVCaptureSession 进行视频采集"
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 14)
        label.textColor = .white
        label.backgroundColor = UIColor.black.withAlphaComponent(0.6)
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
        videoPreviewLayer?.frame = previewView.bounds
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(previewView)
        view.addSubview(infoLabel)
        view.addSubview(startButton)
        
        NSLayoutConstraint.activate([
            previewView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            previewView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            previewView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            infoLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            infoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            infoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            startButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startButton.widthAnchor.constraint(equalToConstant: 150),
            startButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupActions() {
        startButton.addTarget(self, action: #selector(toggleCapture), for: .touchUpInside)
    }
    
    // MARK: - Actions
    
    @objc private func toggleCapture() {
        if startButton.isSelected {
            stopCapture()
        } else {
            checkCameraPermission()
        }
        startButton.isSelected.toggle()
    }
    
    // MARK: - Camera Setup
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async {
                        self?.setupCamera()
                    }
                } else {
                    DispatchQueue.main.async {
                        self?.showPermissionAlert()
                    }
                }
            }
        default:
            showPermissionAlert()
        }
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .high
        
        guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("无法获取相机设备")
            return
        }
        
        self.captureDevice = captureDevice
        
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            captureSession?.addInput(input)
            
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
            videoPreviewLayer?.videoGravity = .resizeAspectFill
            videoPreviewLayer?.frame = previewView.bounds
            
            if let previewLayer = videoPreviewLayer {
                previewView.layer.addSublayer(previewLayer)
            }
            
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession?.startRunning()
            }
            
        } catch {
            print("设置相机失败: \(error)")
        }
    }
    
    private func stopCapture() {
        captureSession?.stopRunning()
        videoPreviewLayer?.removeFromSuperlayer()
        captureSession = nil
    }
    
    private func showPermissionAlert() {
        let alert = UIAlertController(
            title: "需要相机权限",
            message: "请在设置中允许访问相机",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "设置", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
        
        startButton.isSelected = false
    }
}


