//
//  MetalBasicsViewController.swift
//  AudioVideo
//
//  Layer 4: Metal 渲染与自定义滤镜
//  Metal 视频渲染管线基础
//

import UIKit

class MetalBasicsViewController: UIViewController {
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.text = """
        ⚡️ Metal 视频渲染管线
        
        GPU加速视频处理基础
        
        核心知识：
        • MTLDevice、CommandQueue
        • 纹理和着色器
        • CVPixelBuffer → Texture
        • 渲染管线配置
        
        (示例代码待实现)
        """
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        view.addSubview(descriptionLabel)
        
        NSLayoutConstraint.activate([
            descriptionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            descriptionLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])
    }
}

