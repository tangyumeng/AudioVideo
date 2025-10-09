//
//  ChromaKeyViewController.swift
//  AudioVideo
//
//  Layer 5: 高级视频应用
//  绿幕抠图 (Chroma Key)
//

import UIKit

class ChromaKeyViewController: UIViewController {
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.text = """
        🎬 绿幕抠图 (Chroma Key)
        
        实时色度键控与背景替换
        
        核心算法：
        • HSV色彩空间
        • 颜色距离计算
        • 边缘羽化
        • 背景合成
        
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

