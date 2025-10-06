//
//  VideoFilterViewController.swift
//  AudioVideo
//
//  Created by tangyumeng on 2025/10/6.
//

import UIKit
import CoreImage

class VideoFilterViewController: UIViewController {
    
    // MARK: - Properties
    
    private let context = CIContext()
    private var currentFilter: CIFilter?
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .black
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let filterSegmentedControl: UISegmentedControl = {
        let items = ["原图", "黑白", "怀旧", "模糊", "边缘"]
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 0
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    private let intensitySlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.value = 1
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()
    
    private let infoLabel: UILabel = {
        let label = UILabel()
        label.text = "Core Image 视频滤镜\n实时滤镜效果演示"
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let intensityLabel: UILabel = {
        let label = UILabel()
        label.text = "滤镜强度"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var originalImage: UIImage?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        loadSampleImage()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(infoLabel)
        view.addSubview(imageView)
        view.addSubview(filterSegmentedControl)
        view.addSubview(intensityLabel)
        view.addSubview(intensitySlider)
        
        NSLayoutConstraint.activate([
            infoLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            infoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            infoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            imageView.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 20),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 3.0/4.0),
            
            filterSegmentedControl.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            filterSegmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            filterSegmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            intensityLabel.topAnchor.constraint(equalTo: filterSegmentedControl.bottomAnchor, constant: 20),
            intensityLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            intensitySlider.topAnchor.constraint(equalTo: intensityLabel.bottomAnchor, constant: 8),
            intensitySlider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            intensitySlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
    }
    
    private func setupActions() {
        filterSegmentedControl.addTarget(self, action: #selector(filterChanged), for: .valueChanged)
        intensitySlider.addTarget(self, action: #selector(intensityChanged), for: .valueChanged)
    }
    
    private func loadSampleImage() {
        // 创建一个示例图像
        let size = CGSize(width: 400, height: 300)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            // 绘制渐变背景
            let colors = [UIColor.systemBlue.cgColor, UIColor.systemPurple.cgColor]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                     colors: colors as CFArray,
                                     locations: [0, 1])!
            context.cgContext.drawLinearGradient(gradient,
                                                 start: .zero,
                                                 end: CGPoint(x: size.width, y: size.height),
                                                 options: [])
            
            // 绘制文字
            let text = "滤镜示例图像"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 40),
                .foregroundColor: UIColor.white
            ]
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(x: (size.width - textSize.width) / 2,
                                 y: (size.height - textSize.height) / 2,
                                 width: textSize.width,
                                 height: textSize.height)
            text.draw(in: textRect, withAttributes: attributes)
            
            // 绘制一些形状
            context.cgContext.setFillColor(UIColor.white.withAlphaComponent(0.3).cgColor)
            context.cgContext.fillEllipse(in: CGRect(x: 50, y: 50, width: 100, height: 100))
            context.cgContext.fillEllipse(in: CGRect(x: 250, y: 150, width: 100, height: 100))
        }
        
        originalImage = image
        imageView.image = image
    }
    
    // MARK: - Actions
    
    @objc private func filterChanged(_ sender: UISegmentedControl) {
        applyFilter()
    }
    
    @objc private func intensityChanged(_ sender: UISlider) {
        applyFilter()
    }
    
    // MARK: - Filters
    
    private func applyFilter() {
        guard let originalImage = originalImage,
              let ciImage = CIImage(image: originalImage) else {
            return
        }
        
        var outputImage: CIImage = ciImage
        let intensity = intensitySlider.value
        
        switch filterSegmentedControl.selectedSegmentIndex {
        case 0: // 原图
            outputImage = ciImage
            
        case 1: // 黑白
            if let filter = CIFilter(name: "CIPhotoEffectNoir") {
                filter.setValue(ciImage, forKey: kCIInputImageKey)
                if let output = filter.outputImage {
                    // 使用强度混合原图和滤镜效果
                    if intensity < 1.0 {
                        outputImage = blendImages(original: ciImage, filtered: output, intensity: CGFloat(intensity))
                    } else {
                        outputImage = output
                    }
                }
            }
            
        case 2: // 怀旧
            if let filter = CIFilter(name: "CIPhotoEffectTransfer") {
                filter.setValue(ciImage, forKey: kCIInputImageKey)
                if let output = filter.outputImage {
                    if intensity < 1.0 {
                        outputImage = blendImages(original: ciImage, filtered: output, intensity: CGFloat(intensity))
                    } else {
                        outputImage = output
                    }
                }
            }
            
        case 3: // 模糊
            if let filter = CIFilter(name: "CIGaussianBlur") {
                filter.setValue(ciImage, forKey: kCIInputImageKey)
                filter.setValue(intensity * 20, forKey: kCIInputRadiusKey)
                if let output = filter.outputImage {
                    outputImage = output.cropped(to: ciImage.extent)
                }
            }
            
        case 4: // 边缘检测
            if let filter = CIFilter(name: "CIEdges") {
                filter.setValue(ciImage, forKey: kCIInputImageKey)
                filter.setValue(intensity * 10, forKey: kCIInputIntensityKey)
                if let output = filter.outputImage {
                    outputImage = output
                }
            }
            
        default:
            break
        }
        
        // 转换为 UIImage
        if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
            imageView.image = UIImage(cgImage: cgImage)
        }
    }
    
    private func blendImages(original: CIImage, filtered: CIImage, intensity: CGFloat) -> CIImage {
        guard let blendFilter = CIFilter(name: "CIBlendWithMask") else {
            return filtered
        }
        
        // 创建强度遮罩
        let maskImage = CIImage(color: CIColor(red: intensity, green: intensity, blue: intensity))
            .cropped(to: original.extent)
        
        blendFilter.setValue(filtered, forKey: kCIInputImageKey)
        blendFilter.setValue(original, forKey: kCIInputBackgroundImageKey)
        blendFilter.setValue(maskImage, forKey: kCIInputMaskImageKey)
        
        return blendFilter.outputImage ?? filtered
    }
}


