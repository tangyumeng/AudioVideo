//
//  AudioVideoTopic.swift
//  AudioVideo
//
//  Created by tangyumeng on 2025/10/6.
//

import UIKit

/// 音视频开发知识点模型
struct AudioVideoTopic {
    let title: String
    let description: String
    let icon: String
    let viewController: UIViewController.Type
    
    /// 所有音视频开发知识点
    static let allTopics: [AudioVideoTopic] = [
        AudioVideoTopic(
            title: "📷 相机采集",
            description: "AVFoundation相机视频采集基础",
            icon: "camera.fill",
            viewController: CameraCaptureViewController.self
        ),
        AudioVideoTopic(
            title: "🎬 视频播放",
            description: "AVPlayer视频播放与控制",
            icon: "play.rectangle.fill",
            viewController: VideoPlayerViewController.self
        ),
        AudioVideoTopic(
            title: "🎤 音频录制",
            description: "AVAudioRecorder音频录制",
            icon: "mic.fill",
            viewController: AudioRecordViewController.self
        ),
        AudioVideoTopic(
            title: "🔊 音频播放",
            description: "AVAudioPlayer音频播放",
            icon: "speaker.wave.2.fill",
            viewController: AudioPlayViewController.self
        ),
        AudioVideoTopic(
            title: "✂️ 视频编辑",
            description: "AVAssetExportSession视频剪辑与导出",
            icon: "scissors",
            viewController: VideoEditViewController.self
        ),
        AudioVideoTopic(
            title: "🎨 视频滤镜",
            description: "Core Image实时视频滤镜效果",
            icon: "camera.filters",
            viewController: VideoFilterViewController.self
        ),
        AudioVideoTopic(
            title: "📹 视频录制",
            description: "AVCaptureMovieFileOutput视频录制",
            icon: "video.fill",
            viewController: VideoRecordViewController.self
        ),
        AudioVideoTopic(
            title: "🎵 音频处理",
            description: "AVAudioEngine音频处理与效果",
            icon: "waveform",
            viewController: AudioProcessViewController.self
        ),
        AudioVideoTopic(
            title: "📸 照片采集",
            description: "AVCapturePhotoOutput拍照功能",
            icon: "camera.shutter.button.fill",
            viewController: PhotoCaptureViewController.self
        ),
        AudioVideoTopic(
            title: "🎼 音频可视化",
            description: "音频波形与频谱可视化",
            icon: "chart.bar.fill",
            viewController: AudioVisualizationViewController.self
        )
    ]
}


