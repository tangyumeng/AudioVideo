//
//  PhotoCaptureViewController.swift
//  AudioVideo
//
//  Created by tangyumeng on 2025/10/6.
//

import UIKit
import AVFoundation

class PhotoCaptureViewController: UIViewController {
    
    // MARK: - Properties
    
    private var captureSession: AVCaptureSession?
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    private var photoOutput: AVCapturePhotoOutput?
    private var captureDevice: AVCaptureDevice?
    
    private let previewView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let captureButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .white
        button.layer.cornerRadius = 35
        button.layer.borderWidth = 5
        button.layer.borderColor = UIColor.systemBlue.cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let flashButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "bolt.slash.fill"), for: .normal)
        button.setImage(UIImage(systemName: "bolt.fill"), for: .selected)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        button.layer.cornerRadius = 25
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let switchCameraButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "camera.rotate.fill"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        button.layer.cornerRadius = 25
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let photoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.backgroundColor = .darkGray
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let infoLabel: UILabel = {
        let label = UILabel()
        label.text = "AVCapturePhotoOutput 照片采集\n支持闪光灯、前后摄像头切换"
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 12)
        label.textColor = .white
        label.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var currentCameraPosition: AVCaptureDevice.Position = .back
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        checkCameraPermission()
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
        view.addSubview(flashButton)
        view.addSubview(switchCameraButton)
        view.addSubview(captureButton)
        view.addSubview(photoImageView)
        
        NSLayoutConstraint.activate([
            previewView.topAnchor.constraint(equalTo: view.topAnchor),
            previewView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            previewView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            infoLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            infoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            infoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            flashButton.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 20),
            flashButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            flashButton.widthAnchor.constraint(equalToConstant: 50),
            flashButton.heightAnchor.constraint(equalToConstant: 50),
            
            switchCameraButton.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 20),
            switchCameraButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            switchCameraButton.widthAnchor.constraint(equalToConstant: 50),
            switchCameraButton.heightAnchor.constraint(equalToConstant: 50),
            
            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.widthAnchor.constraint(equalToConstant: 70),
            captureButton.heightAnchor.constraint(equalToConstant: 70),
            
            photoImageView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            photoImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            photoImageView.widthAnchor.constraint(equalToConstant: 60),
            photoImageView.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    private func setupActions() {
        captureButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        flashButton.addTarget(self, action: #selector(toggleFlash), for: .touchUpInside)
        switchCameraButton.addTarget(self, action: #selector(switchCamera), for: .touchUpInside)
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
    
    private func setupCamera(position: AVCaptureDevice.Position = .back) {
        // 清除旧的会话
        captureSession?.stopRunning()
        captureSession = nil
        videoPreviewLayer?.removeFromSuperlayer()
        
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .photo
        
        guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) else {
            print("无法获取相机设备")
            return
        }
        
        self.captureDevice = captureDevice
        currentCameraPosition = position
        
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            
            if captureSession?.canAddInput(input) == true {
                captureSession?.addInput(input)
            }
            
            photoOutput = AVCapturePhotoOutput()
            if let photoOutput = photoOutput,
               captureSession?.canAddOutput(photoOutput) == true {
                captureSession?.addOutput(photoOutput)
            }
            
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
    
    // MARK: - Actions
    
    @objc private func capturePhoto() {
        guard let photoOutput = photoOutput else { return }
        
        let settings = AVCapturePhotoSettings()
        
        // 设置闪光灯
        if flashButton.isSelected {
            settings.flashMode = .on
        } else {
            settings.flashMode = .off
        }
        
        // 添加拍照动画
        animateCaptureButton()
        
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    @objc private func toggleFlash() {
        flashButton.isSelected.toggle()
    }
    
    @objc private func switchCamera() {
        let newPosition: AVCaptureDevice.Position = currentCameraPosition == .back ? .front : .back
        setupCamera(position: newPosition)
    }
    
    // MARK: - Animations
    
    private func animateCaptureButton() {
        UIView.animate(withDuration: 0.1, animations: {
            self.captureButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.captureButton.transform = .identity
            }
        }
        
        // 闪光效果
        let flashView = UIView(frame: previewView.bounds)
        flashView.backgroundColor = .white
        flashView.alpha = 0.8
        previewView.addSubview(flashView)
        
        UIView.animate(withDuration: 0.2, animations: {
            flashView.alpha = 0
        }) { _ in
            flashView.removeFromSuperview()
        }
    }
    
    // MARK: - Helpers
    
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
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension PhotoCaptureViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("拍照失败: \(error)")
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("无法获取图像数据")
            return
        }
        
        // 显示拍摄的照片
        DispatchQueue.main.async {
            self.photoImageView.image = image
            
            // 保存到相册（可选）
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        }
    }
}


