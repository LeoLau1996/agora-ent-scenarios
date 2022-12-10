//
//  ShowAgoraKitManager+Setting.swift
//  AgoraEntScenarios
//
//  Created by FanPengpeng on 2022/12/5.
//

import Foundation
import AgoraRtcKit

// 标记是否已经打开过
private let hasOpenedKey = "hasOpenKey"
private let privateParamsTextKey = "privateParamsText"

extension ShowAgoraKitManager {
    
    private var dimensionsItems: [CGSize] {
        ShowAgoraVideoDimensions.allCases.map({$0.sizeValue})
    }
    
    private var fpsItems: [AgoraVideoFrameRate] {
        [
           .fps1,
           .fps7,
           .fps10,
           .fps15,
           .fps24,
           .fps30,
           .fps60
       ]
    }
    
    // 默认设置
    func defaultSetting() {
        // 默认音量设置
        ShowSettingKey.recordingSignalVolume.writeValue(80)
        ShowSettingKey.musincVolume.writeValue(30)
        let hasOpened = UserDefaults.standard.bool(forKey: hasOpenedKey)
        // 第一次进入房间的时候设置
        if hasOpened == false {
            // 默认值
            ShowSettingKey.colorEnhance_strength.writeValue(0.5)
            ShowSettingKey.colorEnhance_skinProtect.writeValue(1)
            updatePresetForType(presetType ?? .show_low, mode: .signle)
            UserDefaults.standard.set(true, forKey: hasOpenedKey)
        }
        updateSettingForkey(.lowlightEnhance)
        updateSettingForkey(.lowlightEnhance_mode)
        updateSettingForkey(.lowlightEnhance_level)
        
        updateSettingForkey(.colorEnhance)
        updateSettingForkey(.colorEnhance_strength)
        updateSettingForkey(.colorEnhance_skinProtect)
        
        updateSettingForkey(.videoDenoiser)
        updateSettingForkey(.videoDenoiser_mode)
        updateSettingForkey(.videoDenoiser_level)

        updateSettingForkey(.videoEncodeSize)
        updateSettingForkey(.beauty)
        updateSettingForkey(.PVC)
        updateSettingForkey(.SR)
        updateSettingForkey(.earmonitoring)
        updateSettingForkey(.recordingSignalVolume)
        updateSettingForkey(.musincVolume)
        updateSettingForkey(.audioBitRate)
        updateSettingForkey(.exposureface)
        // 设置私有参数
        setPrivateParamters(paramsJsonText)
    }
    
    // 预设模式
    private func _presetValuesWith(dimensions: ShowAgoraVideoDimensions, fps: AgoraVideoFrameRate, bitRate: Float, h265On: Bool, videoSize: ShowAgoraVideoDimensions) {
        ShowSettingKey.videoEncodeSize.writeValue(dimensionsItems.firstIndex(of: dimensions.sizeValue))
        ShowSettingKey.FPS.writeValue(fpsItems.firstIndex(of: fps))
        ShowSettingKey.videoBitRate.writeValue(bitRate)
        ShowSettingKey.H265.writeValue(h265On)
        ShowSettingKey.lowlightEnhance.writeValue(false)
        ShowSettingKey.colorEnhance.writeValue(false)
        ShowSettingKey.videoDenoiser.writeValue(false)
        ShowSettingKey.PVC.writeValue(false)
        
        updateSettingForkey(.videoEncodeSize)
        updateSettingForkey(.videoBitRate)
        updateSettingForkey(.FPS)
        updateSettingForkey(.H265)
        updateSettingForkey(.lowlightEnhance)
        updateSettingForkey(.colorEnhance)
        updateSettingForkey(.videoDenoiser)
        updateSettingForkey(.PVC)
    }
    
    /// 设置观众端画质增强
    private func _setQualityEnable(_ isOn: Bool, srType: ShowSRType? = nil){
        ShowSettingKey.SR.writeValue(isOn)
        agoraKit.setParameters("{\"rtc.video.enable_sr\":{\"enabled\":\(isOn), \"mode\": 2}}")
        if let xValue = srType?.xValue {
            agoraKit.setParameters("{\"rtc.video.sr_type\":\(xValue)}")
            agoraKit.setParameters("{\"rtc.video.sr_max_wh\":\(921600)}")
        }
    }
    
    /// 设置超分
    private func _setSRWithIndex(_ index: Int){
        let srType: ShowSRType = ShowSRType(rawValue: index) ?? .off
        agoraKit.setParameters("{\"rtc.video.enable_sr\":{\"enabled\":\(srType != .off), \"mode\": 2}}")
        if let xValue = srType.xValue {
            agoraKit.setParameters("{\"rtc.video.sr_type\":\(xValue)}")
            agoraKit.setParameters("{\"rtc.video.sr_max_wh\":\(921600)}")
        }
    }
    
    func updatePresetForType(_ type: ShowPresetType, mode: ShowMode) {
        switch type {
        case .show_low:
            switch mode {
            case .signle:
                _presetValuesWith(dimensions: ._960x540, fps: .fps15, bitRate: 1500, h265On: false, videoSize: ._1280x720)
            case .pk:
                _presetValuesWith(dimensions: ._480x360, fps: .fps15, bitRate: 700, h265On: false, videoSize: ._1280x720)
            }
            break
        case .show_medium:
            switch mode {
            case .signle:
                _presetValuesWith(dimensions: ._1280x720, fps: .fps24, bitRate: 1800, h265On: true, videoSize: ._1280x720)
            case .pk:
                _presetValuesWith(dimensions: ._960x540, fps: .fps15, bitRate: 800, h265On: true, videoSize: ._1280x720)
            }
            
            break
        case .show_high:
            
            switch mode {
            case .signle:
                _presetValuesWith(dimensions: ._1280x720, fps: .fps24, bitRate: 1800, h265On: true, videoSize: ._1280x720)
            case .pk:
                _presetValuesWith(dimensions: ._960x540, fps: .fps15, bitRate: 800, h265On: true, videoSize: ._1280x720)
            }
            
            break
            
        case .quality_low:
            _setQualityEnable(false)
            break
        case .quality_medium:
            _setQualityEnable(true, srType: ShowSRType.x1_5)
        case .quality_high:
            _setQualityEnable(true, srType: ShowSRType.x2)
        case .base_low:
            _setQualityEnable(false)
        case .base_medium:
            _setQualityEnable(false)
        case .base_high:
            _setQualityEnable(false)
        }
    }
    
    /// 更新设置
    /// - Parameter key: 要更新的key
    func updateSettingForkey(_ key: ShowSettingKey) {
        let isOn = key.boolValue
        let index = key.intValue
        let sliderValue = key.floatValue
        
        switch key {
        case .lowlightEnhance:
            agoraKit.setLowlightEnhanceOptions(isOn, options: lowlightOptions)
        case .colorEnhance:
            agoraKit.setColorEnhanceOptions(isOn, options: colorOptions)
        case .videoDenoiser:
            agoraKit.setVideoDenoiserOptions(isOn, options: videoDenoiserOptions)
        case .beauty:
            agoraKit.setBeautyEffectOptions(isOn, options: AgoraBeautyOptions())
        case .PVC:
            agoraKit.setParameters("{\"rtc.video.enable_pvc\":\(isOn)}")
        case .SR:
//            agoraKit.setParameters("{\"rtc.video.enable_sr\":{\"enabled\":\(isOn), \"mode\": 2}}")
            _setSRWithIndex(index)
        case .BFrame:
//            videoEncoderConfig.compressionPreference = isOn ? .quality : .lowLatency
            agoraKit.setVideoEncoderConfiguration(videoEncoderConfig)
           break
        case .videoEncodeSize:
            videoEncoderConfig.dimensions = dimensionsItems[index]
            agoraKit.setVideoEncoderConfiguration(videoEncoderConfig)
        case .videoBitRate:
            videoEncoderConfig.bitrate = Int(sliderValue)
            agoraKit.setVideoEncoderConfiguration(videoEncoderConfig)
        case .FPS:
            videoEncoderConfig.frameRate = fpsItems[index]
            agoraKit.setVideoEncoderConfiguration(videoEncoderConfig)
        case .H265:
            agoraKit.setParameters("{\"engine.video.enable_hw_encoder\":\(isOn)}")
            agoraKit.setParameters("{\"engine.video.codec_type\":\"\(isOn ? 3 : 2)\"}")
        case .earmonitoring:
            agoraKit.enable(inEarMonitoring: isOn)
        case .recordingSignalVolume:
            agoraKit.adjustRecordingSignalVolume(Int(sliderValue))
        case .musincVolume:
            agoraKit.adjustAudioMixingVolume(Int(sliderValue))
        case .audioBitRate:
            break
        case .exposureface:
            let isCameraAutoFocus = agoraKit.isCameraAutoExposureFaceModeSupported()
            if isCameraAutoFocus == true {
                agoraKit.setCameraAutoExposureFaceModeEnabled(isOn)
            } else {
//                showAlert(title: "", message: "不支持自动对焦")
            }
        case .lowlightEnhance_mode:
            lowlightOptions.mode = AgoraLowlightEnhanceMode(rawValue: UInt(index)) ?? .auto
            updateSettingForkey(.lowlightEnhance)
        case .lowlightEnhance_level:
            lowlightOptions.level = AgoraLowlightEnhanceLevel(rawValue: UInt(index)) ?? .quality
            updateSettingForkey(.lowlightEnhance)
        case .colorEnhance_strength:
            colorOptions.strengthLevel = sliderValue
            updateSettingForkey(.colorEnhance)
        case .colorEnhance_skinProtect:
            colorOptions.skinProtectLevel = sliderValue
            updateSettingForkey(.colorEnhance)
        case .videoDenoiser_mode:
            videoDenoiserOptions.mode = AgoraVideoDenoiserMode(rawValue: UInt(index)) ?? .auto
            updateSettingForkey(.videoDenoiser)
        case .videoDenoiser_level:
            videoDenoiserOptions.level = AgoraVideoDenoiserLevel(rawValue: UInt(index)) ?? .highQuality
            updateSettingForkey(.videoDenoiser)
        }
    }
    
    // 设置私有参数
    private func setPrivateParamters(_ jsonText: String?) {
        guard let jsonStr = jsonText else { return }
        let paramters = jsonStr.components(separatedBy: ",")
        for param in paramters {
            print("param =========> \(param)")
            agoraKit.setParameters(param)
        }
    }

}

extension ShowAgoraKitManager {
    
    var paramsJsonText: String? {
        set{
            if newValue != nil {
                setPrivateParamters(newValue)
                UserDefaults.standard.set(newValue, forKey: privateParamsTextKey)
            }else{
                UserDefaults.standard.removeObject(forKey: privateParamsTextKey)
            }
        }
        
        get{
            if let text: String = UserDefaults.standard.value(forKey: privateParamsTextKey) as? String {
                return text
            }
            return nil
        }
    }
    
    static var privateParamsText: String? {
        if let text: String = UserDefaults.standard.value(forKey: privateParamsTextKey) as? String {
            return text
        }
        return nil
    }
}
