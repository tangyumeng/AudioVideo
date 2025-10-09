//
//  VideoDecoderViewController.swift
//  AudioVideo
//
//  Layer 3: 编解码与格式转换
//  VideoToolbox H.264/H.265 硬件解码
//

import UIKit

class VideoDecoderViewController: UIViewController {
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.text = """
        🔼 H.264/H.265 硬件解码
        
        使用VideoToolbox进行硬件加速解码
        
        核心知识：
        • VTDecompressionSession
        • NAL Unit解析
        • SPS/PPS处理
        • 解码优化
        
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

