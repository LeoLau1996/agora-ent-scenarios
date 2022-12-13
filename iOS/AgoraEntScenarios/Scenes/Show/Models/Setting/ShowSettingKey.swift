//
//  ShowSettingManager.swift
//  AgoraEntScenarios
//
//  Created by FanPengpeng on 2022/11/16.
//

import Foundation
import AgoraRtcKit

enum ShowAgoraVideoDimensions: String, CaseIterable {
    
    case _320x240 = "320x240"
    case _480x360 = "480x360"
    case _360x640 = "360x640"
    case _960x540 = "960x540"
    case _960x720 = "960x720"
    case _1280x720 = "1280x720"
    case _1920x1080 = "1920x1080"
     
    var sizeValue: CGSize {
        let arr: [String] = rawValue.split(separator: "x").compactMap{"\($0)"}
        guard let first = arr.first, let width = Float(first), let last = arr.last, let height = Float(last) else {
            return CGSize(width: 320, height: 240)
        }
        return CGSize(width: CGFloat(width), height: CGFloat(height))
    }
}

extension AgoraVideoFrameRate {
    func stringValue() -> String {
        return "\(rawValue) fps"
    }
}

// 超分倍数
enum ShowSRType: Int, CaseIterable {
    case off
    case x1
    case x1_33
    case x1_5
    case x2
    case x_sharpen
    
    var xValue: Int? {
        switch self {
            
        case .off:
            return nil
        case .x1:
            return 6
        case .x1_33:
            return 7
        case .x1_5:
            return 8
        case .x2:
            return 3
        case .x_sharpen:
            return 11
        }
    }
    
    var title: String {
        switch self {
        case .off:
            return "关"
        case .x1:
            return "x1"
        case .x1_33:
            return "x1.33"
        case .x1_5:
            return "x1.5"
        case .x2:
            return "x2"
        case .x_sharpen:
            return "锐化"
        }
    }
}

extension AgoraVideoDenoiserMode {
    var title: String {
        switch self {
        case .auto:
            return "auto"
        case .manual:
            return "manual"
        @unknown default:
            return ""
        }
    }
    
    static var allcaseTitles: [String] {
        return ["auto","manual"]
    }
}

extension AgoraVideoDenoiserLevel {
    var title: String {
        switch self {
        case .highQuality:
            return "highQuality"
        case .fast:
            return "fast"
        case .strength:
            return "strength"
        @unknown default:
            return ""
        }
    }
    
    static var allcaseTitles: [String] {
        return ["highQuality","fast","strength"]
    }
}

extension AgoraLowlightEnhanceMode {
    var title: String {
        switch self {
        case .auto:
            return "auto"
        case .manual:
            return "manual"
        @unknown default:
            return ""
        }
    }
    
    static var allcaseTitles: [String] {
        return ["auto","manual"]
    }
}

extension AgoraLowlightEnhanceLevel {
    var title: String {
        switch self {
        case .quality:
            return "quality"
        case .fast:
            return "fast"
        @unknown default:
            return ""
        }
    }
    
    static var allcaseTitles: [String] {
        return ["highQuality","fast"]
    }
}


enum ShowSettingKey: String, CaseIterable {
    
    enum KeyType {
        case aSwitch
        case segment
        case slider
        case label
    }
    
    case lowlightEnhance        // 暗光增强
    case lowlightEnhance_mode
    case lowlightEnhance_level
    case colorEnhance           // 色彩增强
    case colorEnhance_strength
    case colorEnhance_skinProtect
    case videoDenoiser          // 降噪
    case videoDenoiser_mode
    case videoDenoiser_level
    case beauty                 // 美颜
    case PVC                    // pvc
    case SR                     // 超分
    case BFrame                 // b帧
    case videoEncodeSize       // 视频编码分辨率
    case FPS                    // 帧率
    case H265                   // h265
    case videoBitRate           // 视频码率
    case earmonitoring          // 耳返
    case recordingSignalVolume  // 人声音量
    case musincVolume           // 音乐音量
    case audioBitRate           // 音频码率
    case exposureface           // exposureface
    
    var title: String {
        switch self {
        case .lowlightEnhance:
            return "show_advance_setting_lowlight_title".show_localized
        case .colorEnhance:
            return "show_advance_setting_colorEnhance_title".show_localized
        case .videoDenoiser:
            return "show_advance_setting_videoDenoiser_title".show_localized
        case .beauty:
            return "show_advance_setting_beauty_title".show_localized
        case .PVC:
            return "show_advance_setting_PVC_title".show_localized
        case .SR:
            return "show_advance_setting_SR_title".show_localized
        case .BFrame:
            return "show_advance_setting_BFrame_title".show_localized
        case .videoEncodeSize:
            return "show_advance_setting_videoCaptureSize_title".show_localized
        case .FPS:
            return "show_advance_setting_FPS_title".show_localized
        case .videoBitRate:
            return "show_advance_setting_bitRate_title".show_localized
        case .H265:
            return "show_advance_setting_H265_title".show_localized
        case .earmonitoring:
            return "show_advance_setting_earmonitoring_title".show_localized
        case .recordingSignalVolume:
            return "show_advance_setting_recordingVolume_title".show_localized
        case .musincVolume:
            return "show_advance_setting_musicVolume_title".show_localized
        case .audioBitRate:
            return "show_advance_setting_audio_bitRate_title".show_localized
        case .exposureface:
            return "exposureface"
        case .lowlightEnhance_mode:
            return "show_advance_setting_lowlight_title".show_localized + "mode"
        case .lowlightEnhance_level:
            return "show_advance_setting_lowlight_title".show_localized + "level"
        case .colorEnhance_strength:
            return "show_advance_setting_colorEnhance_title".show_localized + "strength"
        case .colorEnhance_skinProtect:
            return "show_advance_setting_colorEnhance_title".show_localized + "skinProtect"
        case .videoDenoiser_mode:
            return "show_advance_setting_videoDenoiser_title".show_localized + "mode"
        case .videoDenoiser_level:
            return "show_advance_setting_videoDenoiser_title".show_localized + "level"
        }
    }
    
    // 类型
    var type: KeyType {
        switch self {
        case .lowlightEnhance:
            return .aSwitch
        case .colorEnhance:
            return .aSwitch
        case .videoDenoiser:
            return .aSwitch
        case .beauty:
            return .aSwitch
        case .PVC:
            return .aSwitch
        case .SR:
            return .label
        case .BFrame:
            return .aSwitch
        case .videoEncodeSize:
            return .label
        case .FPS:
            return .label
        case .H265:
            return .aSwitch
        case .videoBitRate:
            return .slider
        case .earmonitoring:
            return .aSwitch
        case .recordingSignalVolume:
            return .slider
        case .musincVolume:
            return .slider
        case .audioBitRate:
            return .label
        case .exposureface:
            return .aSwitch
        case .lowlightEnhance_mode:
            return .label
        case .lowlightEnhance_level:
            return .label
        case .colorEnhance_strength:
            return .slider
        case .colorEnhance_skinProtect:
            return .slider
        case .videoDenoiser_mode:
            return .label
        case .videoDenoiser_level:
            return .label
        }
    }
    
    // 弹窗提示文案
    var tips: String {
        switch self {
        case .lowlightEnhance:
            return "show_advance_setting_lowlightEnhance_tips".show_localized
        case .colorEnhance:
            return "show_advance_setting_colorEnhance_tips".show_localized
        case .videoDenoiser:
            return "show_advance_setting_videoDenoiser_tips".show_localized
        case .PVC:
            return "show_advance_setting_PVC_tips".show_localized
        case .SR:
            return "show_advance_setting_SR_tips".show_localized
        case .H265:
            return "show_advance_setting_H265_tips".show_localized
        default:
            return ""
        }
    }
    
    // slider的取值区间
    var sliderValueScope: (Float, Float) {
        switch self {
        case .videoBitRate:
            return (200, 2000)
        case .recordingSignalVolume:
            return (0, 100)
        case .musincVolume:
            return (0, 100)
        case .colorEnhance_strength:
            return (0.0, 1.0)
        case .colorEnhance_skinProtect:
            return (0.0, 1.0)
        default:
            return (0.0, 1.0)
        }
    }
    
    // 选项
    var items: [String] {
        switch self {
        case .videoEncodeSize:
            return ShowAgoraVideoDimensions.allCases.map({ $0.rawValue })
        case .FPS:
            return [AgoraVideoFrameRate.fps1.stringValue(),
                    AgoraVideoFrameRate.fps7.stringValue(),
                    AgoraVideoFrameRate.fps10.stringValue(),
                    AgoraVideoFrameRate.fps15.stringValue(),
                    AgoraVideoFrameRate.fps24.stringValue(),
                    AgoraVideoFrameRate.fps30.stringValue(),
                    AgoraVideoFrameRate.fps60.stringValue()
            ]
        case .audioBitRate:
            return ["2","3","5"]
        case .SR:
            return  ShowSRType.allCases.map({ $0.title })
            
        case .videoDenoiser_mode:
            return AgoraVideoDenoiserMode.allcaseTitles
        case .videoDenoiser_level:
            return AgoraVideoDenoiserLevel.allcaseTitles
        case .lowlightEnhance_mode:
            return AgoraLowlightEnhanceMode.allcaseTitles
        case .lowlightEnhance_level:
            return AgoraLowlightEnhanceLevel.allcaseTitles
        default:
            return []
        }
    }
    
    var boolValue: Bool {
        return UserDefaults.standard.bool(forKey: self.rawValue)
    }
    
    var floatValue: Float {
        return UserDefaults.standard.float(forKey: self.rawValue)
    }
    
    var intValue: Int {
        return UserDefaults.standard.integer(forKey: self.rawValue)
    }
    
    func writeValue(_ value: Any?){
        UserDefaults.standard.set(value, forKey: self.rawValue)
        UserDefaults.standard.synchronize()
    }
}

