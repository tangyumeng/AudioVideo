//
//  MetalFilterViewController.swift
//  AudioVideo
//
//  Layer 4: Metal 渲染与自定义滤镜
//  自定义 Metal 着色器滤镜
//

import UIKit

class MetalFilterViewController: UIViewController {
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.text = """
        ✨ 自定义 Metal 滤镜
        
        编写Metal着色器实现滤镜
        
        核心知识：
        • Metal Shading Language
        • 片段着色器编程
        • 自定义滤镜效果
        • 性能优化
        
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

