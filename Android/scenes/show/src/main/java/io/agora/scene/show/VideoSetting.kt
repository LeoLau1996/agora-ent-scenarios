package io.agora.scene.show

import io.agora.rtc2.video.CameraCapturerConfiguration
import io.agora.rtc2.video.LowLightEnhanceOptions
import io.agora.rtc2.video.VideoDenoiserOptions
import io.agora.rtc2.video.VideoEncoderConfiguration

object VideoSetting {

    enum class SuperResolution(val value:Int){
        //1倍：     n=6
        //1.33倍:  n=7
        //1.5倍：  n=8
        //2倍：     n=3
        //锐化：    n=10(android是10，iOS是11)
        SR_1(6),
        SR_1_33(7),
        SR_1_5(8),
        SR_2(3),
        SR_SHARP(10),
        SR_NONE(0)
    }

    enum class Resolution(val width: Int, val height: Int) {
        V_1080P(1920, 1080),
        V_720P(1080, 720),
        V_540P(960, 540),
        V_360P(640, 360),
        V_270P(480, 270),
        V_180P(360, 180),
    }

    fun Resolution.toIndex() = ResolutionList.indexOf(this)

    val ResolutionList = listOf(
        Resolution.V_180P,
        Resolution.V_270P,
        Resolution.V_360P,
        Resolution.V_540P,
        Resolution.V_720P,
        Resolution.V_1080P
    )

    fun SuperResolution.toIndex() = SuperResolutionList.indexOf(this)

    val SuperResolutionList = listOf(
        SuperResolution.SR_NONE,
        SuperResolution.SR_1,
        SuperResolution.SR_1_33,
        SuperResolution.SR_1_5,
        SuperResolution.SR_2,
        SuperResolution.SR_SHARP,
    )

    enum class FrameRate(val fps: Int) {
        FPS_1(1),
        FPS_7(7),
        FPS_10(10),
        FPS_15(15),
        FPS_24(24),
        FPS_30(30),
        FPS_60(60),
    }

    fun FrameRate.toIndex() = FrameRateList.indexOf(this)

    val FrameRateList = listOf(
        FrameRate.FPS_1,
        FrameRate.FPS_7,
        FrameRate.FPS_10,
        FrameRate.FPS_15,
        FrameRate.FPS_24,
        FrameRate.FPS_30,
        FrameRate.FPS_60,
    )

    enum class LowLightEnhanceMode(val value: Int){
        AUTO(LowLightEnhanceOptions.LOW_LIGHT_ENHANCE_AUTO),
        MANUAL(LowLightEnhanceOptions.LOW_LIGHT_ENHANCE_MANUAL)
    }

    fun LowLightEnhanceMode.toIndex() = LowLightEnhanceModeList.indexOf(this)

    val LowLightEnhanceModeList = listOf(
        LowLightEnhanceMode.AUTO,
        LowLightEnhanceMode.MANUAL
    )

    enum class LowLightEnhanceLevel(val value: Int){
        HIGH_QUALITY(LowLightEnhanceOptions.LOW_LIGHT_ENHANCE_LEVEL_HIGH_QUALITY),
        FAST(LowLightEnhanceOptions.LOW_LIGHT_ENHANCE_LEVEL_FAST)
    }

    fun LowLightEnhanceLevel.toIndex() = LowLightEnhanceLevelList.indexOf(this)

    val LowLightEnhanceLevelList = listOf(
        LowLightEnhanceLevel.HIGH_QUALITY,
        LowLightEnhanceLevel.FAST
    )

    enum class VideoDenoiserMode(val value: Int){
        AUTO(VideoDenoiserOptions.VIDEO_DENOISER_AUTO),
        MANUAL(VideoDenoiserOptions.VIDEO_DENOISER_MANUAL)
    }

    fun VideoDenoiserMode.toIndex() = VideoDenoiserModeList.indexOf(this)

    val VideoDenoiserModeList = listOf(
        VideoDenoiserMode.AUTO,
        VideoDenoiserMode.MANUAL
    )

    enum class VideoDenoiserLevel(val value:Int){
        HIGH_QUALITY(VideoDenoiserOptions.VIDEO_DENOISER_LEVEL_HIGH_QUALITY),
        FAST(VideoDenoiserOptions.VIDEO_DENOISER_LEVEL_FAST),
        STRENGTH(VideoDenoiserOptions.VIDEO_DENOISER_LEVEL_STRENGTH)
    }

    fun VideoDenoiserLevel.toIndex() = VideoDenoiserLevelList.indexOf(this)

    val VideoDenoiserLevelList = listOf(
        VideoDenoiserLevel.HIGH_QUALITY,
        VideoDenoiserLevel.FAST,
        VideoDenoiserLevel.STRENGTH
    )

    enum class DeviceLevel(val value: Int) {
        Low(0),
        Medium(1),
        High(2)
    }

    enum class LiveMode(val value: Int) {
        OneVOne(0),
        PK(1)
    }

    /**
     * 观众设置
     */
    data class AudienceSetting(
        val video: Video,
        val params: String = ""
    ) {
        data class Video(
            val SR: SuperResolution // 超分
        )
    }

    /**
     * 主播设置
     */
    data class BroadcastSetting(
        val video: Video,
        val audio: Audio,
        val params: String = ""
    ) {
        data class Video(
            val H265: Boolean, // 画质增强
            val colorEnhance: Boolean, // 色彩增强
            val colorEnhanceStrength: Float = 0.3f,
            val colorEnhanceSkinProtect: Float = 0.3f,
            val lowLightEnhance: Boolean, // 暗光增强
            val lowLightEnhanceMode: LowLightEnhanceMode = LowLightEnhanceMode.AUTO,
            val lowLightEnhanceLevel: LowLightEnhanceLevel = LowLightEnhanceLevel.HIGH_QUALITY,
            val videoDenoiser: Boolean, // 视频降噪
            val videoDenoiserMode: VideoDenoiserMode = VideoDenoiserMode.AUTO,
            val videoDenoiserLevel: VideoDenoiserLevel = VideoDenoiserLevel.STRENGTH,
            val PVC: Boolean, // 码率节省
            val bFrame: Boolean = false, // B帧
            val exposureface: Boolean = false, // 曝光脸
            val captureResolution: Resolution, // 采集分辨率
            val encodeResolution: Resolution, // 编码分辨率
            val frameRate: FrameRate, // 帧率
            val bitRate: Int // 码率
        )

        data class Audio(
            val inEarMonitoring: Boolean, // 耳返
            val recordingSignalVolume: Int, // 人声音量
            val audioMixingVolume: Int, // 音乐音量
        )
    }

    /**
     * 推荐设置
     */
    object RecommendBroadcastSetting {

        val LowDevice1v1 = BroadcastSetting(
            BroadcastSetting.Video(
                H265 = false,
                colorEnhance = false,
                lowLightEnhance = false,
                videoDenoiser = false,
                PVC = false,
                captureResolution = Resolution.V_720P,
                encodeResolution = Resolution.V_540P,
                frameRate = FrameRate.FPS_15,
                bitRate = 1500
            ),
            BroadcastSetting.Audio(false, 80, 30)
        )

        val MediumDevice1v1 = BroadcastSetting(
            BroadcastSetting.Video(
                H265 = true,
                colorEnhance = false,
                lowLightEnhance = false,
                videoDenoiser = false,
                PVC = false,
                captureResolution = Resolution.V_720P,
                encodeResolution = Resolution.V_720P,
                frameRate = FrameRate.FPS_15,
                bitRate = 1800
            ),
            BroadcastSetting.Audio(false, 80, 30)
        )

        val HighDevice1v1 = BroadcastSetting(
            BroadcastSetting.Video(
                H265 = true,
                colorEnhance = false,
                lowLightEnhance = false,
                videoDenoiser = false,
                PVC = false,
                captureResolution = Resolution.V_720P,
                encodeResolution = Resolution.V_720P,
                frameRate = FrameRate.FPS_15,
                bitRate = 1800
            ),
            BroadcastSetting.Audio(false, 80, 30)
        )

        val LowDevicePK = BroadcastSetting(
            BroadcastSetting.Video(
                H265 = false,
                colorEnhance = false,
                lowLightEnhance = false,
                videoDenoiser = false,
                PVC = false,
                captureResolution = Resolution.V_720P,
                encodeResolution = Resolution.V_360P,
                frameRate = FrameRate.FPS_15,
                bitRate = 700
            ),
            BroadcastSetting.Audio(false, 80, 30)
        )

        val MediumDevicePK = BroadcastSetting(
            BroadcastSetting.Video(
                H265 = true,
                colorEnhance = false,
                lowLightEnhance = false,
                videoDenoiser = false,
                PVC = false,
                captureResolution = Resolution.V_720P,
                encodeResolution = Resolution.V_540P,
                frameRate = FrameRate.FPS_15,
                bitRate = 800
            ),
            BroadcastSetting.Audio(false, 80, 30)
        )

        val HighDevicePK = BroadcastSetting(
            BroadcastSetting.Video(
                H265 = false,
                colorEnhance = false,
                lowLightEnhance = false,
                videoDenoiser = false,
                PVC = false,
                captureResolution = Resolution.V_720P,
                encodeResolution = Resolution.V_540P,
                frameRate = FrameRate.FPS_15,
                bitRate = 800
            ),
            BroadcastSetting.Audio(false, 80, 30)
        )

    }

    private var currAudienceSetting = AudienceSetting(AudienceSetting.Video(SuperResolution.SR_NONE))
    private var currBroadcastSetting = RecommendBroadcastSetting.LowDevice1v1
    private var currAudienceDeviceLevel = DeviceLevel.Low

    fun getCurrAudienceSetting() = currAudienceSetting
    fun getCurrBroadcastSetting() = currBroadcastSetting

    fun resetBroadcastSetting() {
        currBroadcastSetting = when(currAudienceDeviceLevel){
            DeviceLevel.Low -> RecommendBroadcastSetting.LowDevice1v1
            DeviceLevel.Medium -> RecommendBroadcastSetting.MediumDevice1v1
            DeviceLevel.High -> RecommendBroadcastSetting.HighDevice1v1
        }
    }

    fun updateAudienceSetting(
        isJoinedRoom: Boolean = true,
    ) {
        updateRTCAudioSetting(
            isJoinedRoom
        )
    }

    fun updateAudienceSetting(
        isJoinedRoom: Boolean = false,
        SR: SuperResolution? = null,
        params: String? = null
    ) {
        currAudienceSetting = AudienceSetting(
            AudienceSetting.Video(
                SR ?: currAudienceSetting.video.SR,
            ),
            params?: currAudienceSetting.params
        )
        updateRTCAudioSetting(isJoinedRoom, SR, params)
    }

    fun updateBroadcastSetting(deviceLevel: DeviceLevel, isJoinedRoom: Boolean = false, isByAudience: Boolean = false) {
        var liveMode = LiveMode.OneVOne
        if (isByAudience) {
            currAudienceDeviceLevel = deviceLevel
        }else{
            liveMode = when (currBroadcastSetting) {
                RecommendBroadcastSetting.LowDevice1v1, RecommendBroadcastSetting.MediumDevice1v1, RecommendBroadcastSetting.HighDevice1v1 -> LiveMode.OneVOne
                RecommendBroadcastSetting.LowDevicePK, RecommendBroadcastSetting.MediumDevicePK, RecommendBroadcastSetting.HighDevicePK -> LiveMode.PK
                else -> LiveMode.OneVOne
            }
        }

        updateBroadcastSetting(
            when (liveMode) {
                LiveMode.OneVOne -> when (deviceLevel) {
                    DeviceLevel.Low -> RecommendBroadcastSetting.LowDevice1v1
                    DeviceLevel.Medium -> RecommendBroadcastSetting.MediumDevice1v1
                    DeviceLevel.High -> RecommendBroadcastSetting.HighDevice1v1
                }
                LiveMode.PK -> when (deviceLevel) {
                    DeviceLevel.Low -> RecommendBroadcastSetting.LowDevicePK
                    DeviceLevel.Medium -> RecommendBroadcastSetting.MediumDevicePK
                    DeviceLevel.High -> RecommendBroadcastSetting.HighDevicePK
                }
            },
            isJoinedRoom
        )
    }

    fun updateBroadcastSetting(liveMode: LiveMode, isJoinedRoom: Boolean = true) {
        val deviceLevel = when (currBroadcastSetting) {
            RecommendBroadcastSetting.LowDevice1v1, RecommendBroadcastSetting.LowDevicePK -> DeviceLevel.Low
            RecommendBroadcastSetting.MediumDevice1v1, RecommendBroadcastSetting.MediumDevicePK -> DeviceLevel.Medium
            RecommendBroadcastSetting.HighDevice1v1, RecommendBroadcastSetting.HighDevicePK -> DeviceLevel.High
            else -> return
        }

        updateBroadcastSetting(
            when (liveMode) {
                LiveMode.OneVOne -> when (deviceLevel) {
                    DeviceLevel.Low -> RecommendBroadcastSetting.LowDevice1v1
                    DeviceLevel.Medium -> RecommendBroadcastSetting.MediumDevice1v1
                    DeviceLevel.High -> RecommendBroadcastSetting.HighDevice1v1
                }
                LiveMode.PK -> when (deviceLevel) {
                    DeviceLevel.Low -> RecommendBroadcastSetting.LowDevicePK
                    DeviceLevel.Medium -> RecommendBroadcastSetting.MediumDevicePK
                    DeviceLevel.High -> RecommendBroadcastSetting.HighDevicePK
                }
            },
            isJoinedRoom
        )
    }

    private fun updateBroadcastSetting(recommendSetting: BroadcastSetting, isJoinedRoom: Boolean) {
        currBroadcastSetting = recommendSetting
        updateRTCBroadcastSetting(
            isJoinedRoom,

            h265 = currBroadcastSetting.video.H265,

            colorEnhance = currBroadcastSetting.video.colorEnhance,
            colorEnhanceStrength = currBroadcastSetting.video.colorEnhanceStrength,
            colorEnhanceSkinProtect = currBroadcastSetting.video.colorEnhanceSkinProtect,

            lowLightEnhance = currBroadcastSetting.video.lowLightEnhance,
            lowLightEnhanceMode = currBroadcastSetting.video.lowLightEnhanceMode,
            lowLightEnhanceLevel = currBroadcastSetting.video.lowLightEnhanceLevel,

            videoDenoiser = currBroadcastSetting.video.videoDenoiser,
            videoDenoiserMode = currBroadcastSetting.video.videoDenoiserMode,
            videoDenoiserLevel = currBroadcastSetting.video.videoDenoiserLevel,

            PVC = currBroadcastSetting.video.PVC,
            bFrame = currBroadcastSetting.video.bFrame,
            exposureface = currBroadcastSetting.video.exposureface,
            captureResolution = currBroadcastSetting.video.captureResolution,
            encoderResolution = currBroadcastSetting.video.encodeResolution,
            frameRate = currBroadcastSetting.video.frameRate,
            bitRate = currBroadcastSetting.video.bitRate,

            inEarMonitoring = currBroadcastSetting.audio.inEarMonitoring,
            recordingSignalVolume = currBroadcastSetting.audio.recordingSignalVolume,
            audioMixingVolume = currBroadcastSetting.audio.audioMixingVolume
        )
    }

    fun updateBroadcastSetting(
        isJoinedRoom: Boolean = true,

        h265: Boolean? = null,
        colorEnhance: Boolean? = null,
        colorEnhanceStrength: Float? = null,
        colorEnhanceSkinProtect: Float? = null,

        lowLightEnhance: Boolean? = null,
        lowLightEnhanceMode: LowLightEnhanceMode? = null,
        lowLightEnhanceLevel: LowLightEnhanceLevel? = null,

        videoDenoiser: Boolean? = null,
        videoDenoiserMode: VideoDenoiserMode? = null,
        videoDenoiserLevel: VideoDenoiserLevel? = null,

        PVC: Boolean? = null,
        bFrame: Boolean? = null,
        exposureface: Boolean? = null,

        captureResolution: Resolution? = null,
        encoderResolution: Resolution? = null,
        frameRate: FrameRate? = null,
        bitRate: Int? = null,

        inEarMonitoring: Boolean? = null,
        recordingSignalVolume: Int? = null,
        audioMixingVolume: Int? = null,

        params: String? = null,
    ) {
        currBroadcastSetting = BroadcastSetting(
            BroadcastSetting.Video(
                h265 ?: currBroadcastSetting.video.H265,
                colorEnhance ?: currBroadcastSetting.video.colorEnhance,
                colorEnhanceStrength ?: currBroadcastSetting.video.colorEnhanceStrength,
                colorEnhanceSkinProtect ?: currBroadcastSetting.video.colorEnhanceSkinProtect,

                lowLightEnhance ?: currBroadcastSetting.video.lowLightEnhance,
                lowLightEnhanceMode?: currBroadcastSetting.video.lowLightEnhanceMode,
                lowLightEnhanceLevel?: currBroadcastSetting.video.lowLightEnhanceLevel,


                videoDenoiser ?: currBroadcastSetting.video.videoDenoiser,
                videoDenoiserMode ?: currBroadcastSetting.video.videoDenoiserMode,
                videoDenoiserLevel ?: currBroadcastSetting.video.videoDenoiserLevel,

                PVC ?: currBroadcastSetting.video.PVC,
                bFrame?: currBroadcastSetting.video.bFrame,
                exposureface?: currBroadcastSetting.video.exposureface,

                captureResolution ?: currBroadcastSetting.video.captureResolution,
                encoderResolution ?: currBroadcastSetting.video.encodeResolution,
                frameRate ?: currBroadcastSetting.video.frameRate,
                bitRate ?: currBroadcastSetting.video.bitRate
            ),
            BroadcastSetting.Audio(
                inEarMonitoring ?: currBroadcastSetting.audio.inEarMonitoring,
                recordingSignalVolume ?: currBroadcastSetting.audio.recordingSignalVolume,
                audioMixingVolume ?: currBroadcastSetting.audio.audioMixingVolume
            ),
            params ?: currBroadcastSetting.params
        )

        updateRTCBroadcastSetting(
            isJoinedRoom,

            h265 = h265,
            colorEnhance =
            if (colorEnhanceStrength != null || colorEnhanceSkinProtect != null)
                colorEnhance ?: currBroadcastSetting.video.colorEnhance else colorEnhance,
            colorEnhanceStrength = colorEnhanceStrength,
            colorEnhanceSkinProtect = colorEnhanceSkinProtect,

            lowLightEnhance =
            if (lowLightEnhanceMode != null || lowLightEnhanceLevel != null)
                lowLightEnhance ?: currBroadcastSetting.video.lowLightEnhance else lowLightEnhance,
            lowLightEnhanceMode = lowLightEnhanceMode,
            lowLightEnhanceLevel = lowLightEnhanceLevel,

            videoDenoiser =
            if (videoDenoiserMode != null || videoDenoiserLevel != null)
                videoDenoiser ?: currBroadcastSetting.video.videoDenoiser else videoDenoiser,
            videoDenoiserMode = videoDenoiserMode,
            videoDenoiserLevel = videoDenoiserLevel,

            PVC = PVC,
            bFrame = bFrame,
            exposureface = exposureface,
            captureResolution = captureResolution,
            encoderResolution = encoderResolution,
            frameRate = frameRate,
            bitRate = bitRate,
            inEarMonitoring = inEarMonitoring,
            recordingSignalVolume = recordingSignalVolume,
            audioMixingVolume = audioMixingVolume,

            params = params
        )

    }

    fun isCurrBroadcastSettingRecommend(): Boolean {
        return currBroadcastSetting == RecommendBroadcastSetting.LowDevice1v1
                || currBroadcastSetting == RecommendBroadcastSetting.MediumDevice1v1
                || currBroadcastSetting == RecommendBroadcastSetting.HighDevice1v1
                || currBroadcastSetting == RecommendBroadcastSetting.LowDevicePK
                || currBroadcastSetting == RecommendBroadcastSetting.MediumDevicePK
                || currBroadcastSetting == RecommendBroadcastSetting.HighDevicePK
    }


    private fun updateRTCAudioSetting(
        isJoinedRoom: Boolean,
        SR: SuperResolution? = null,
        params: String? = null
    ) {
        val rtcEngine = RtcEngineInstance.rtcEngine
        SR?.let {
            if (!isJoinedRoom) {
                // 超分，只能在加入频道前配置
                val open = SR != SuperResolution.SR_NONE
                // 超分开关
                rtcEngine.setParameters("{\"rtc.video.enable_sr\":{\"enabled\":${open}, \"mode\": 2}}")
                if(open){
                    // 设置最大分辨率
                    rtcEngine.setParameters("{\"rtc.video.sr_max_wh\":921600")
                    //超分倍数选项
                    //1倍：     n=6
                    //1.33倍:  n=7
                    //1.5倍：  n=8
                    //2倍：     n=3
                    //锐化：    n=10(android是10，iOS是11)
                    val n = SR.value
                    rtcEngine.setParameters("{\"rtc.video.sr_type\":${n}")
                }
            }
        }
        params?.let {
            it.split("},").let { list ->
                list.forEachIndexed { index, param ->
                    if (index == list.size - 1) {
                        rtcEngine.setParameters(param)
                    } else {
                        rtcEngine.setParameters("$param}")
                    }
                }
            }
        }
    }


    private fun updateRTCBroadcastSetting(
        isJoinedRoom: Boolean,

        h265: Boolean? = null,
        colorEnhance: Boolean? = null,
        colorEnhanceStrength: Float? = null,
        colorEnhanceSkinProtect: Float? = null,

        lowLightEnhance: Boolean? = null,
        lowLightEnhanceMode: LowLightEnhanceMode? = null,
        lowLightEnhanceLevel: LowLightEnhanceLevel? = null,

        videoDenoiser: Boolean? = null,
        videoDenoiserMode: VideoDenoiserMode? = null,
        videoDenoiserLevel: VideoDenoiserLevel? = null,

        PVC: Boolean? = null,
        bFrame: Boolean? = null,
        exposureface: Boolean? = null,

        captureResolution: Resolution? = null,
        encoderResolution: Resolution? = null,
        frameRate: FrameRate? = null,
        bitRate: Int? = null,

        inEarMonitoring: Boolean? = null,
        recordingSignalVolume: Int? = null,
        audioMixingVolume: Int? = null,

        params: String? = null
    ) {
        val rtcEngine = RtcEngineInstance.rtcEngine
        val videoEncoderConfiguration = RtcEngineInstance.videoEncoderConfiguration
        val colorEnhanceOptions = RtcEngineInstance.colorEnhanceOptions
        val lowLightEnhanceOptions = RtcEngineInstance.lowLightEnhanceOptions
        val videoDenoiserOptions = RtcEngineInstance.videoDenoiserOptions

        h265?.let {
            if (!isJoinedRoom) {
                // 只能在加入房间前设置，否则rtc sdk会崩溃
                rtcEngine.setParameters("{\"engine.video.enable_hw_encoder\":${it}}")
                rtcEngine.setParameters("{\"engine.video.codec_type\":\"${if (it) 3 else 2}\"}")
            }
        }
        colorEnhance?.let {
            colorEnhanceStrength?.let {
                colorEnhanceOptions.strengthLevel = it
            }
            colorEnhanceSkinProtect?.let {
                colorEnhanceOptions.skinProtectLevel = it
            }
            rtcEngine.setColorEnhanceOptions(colorEnhance, colorEnhanceOptions)
        }

        lowLightEnhance?.let {
            lowLightEnhanceMode?.let {
                lowLightEnhanceOptions.lowlightEnhanceMode = it.value
            }
            lowLightEnhanceLevel?.let {
                lowLightEnhanceOptions.lowlightEnhanceLevel = it.value
            }
            rtcEngine.setLowlightEnhanceOptions(lowLightEnhance, lowLightEnhanceOptions)
        }


        videoDenoiser?.let {
            videoDenoiserMode?.let {
                videoDenoiserOptions.denoiserMode = it.value
            }
            videoDenoiserLevel?.let {
                videoDenoiserOptions.denoiserLevel = it.value
            }
            rtcEngine.setVideoDenoiserOptions(videoDenoiser, videoDenoiserOptions)
        }



        PVC?.let {
            // RTC 4.0.0.9版本 不支持，强行设置rtc sdk会崩溃
            // RTC 4.1.1 版本支持
            rtcEngine.setParameters("{\"rtc.video.enable_pvc\":${it}}")
        }
        bFrame?.let {
            videoEncoderConfiguration.advanceOptions.compressionPreference =
                if (it) VideoEncoderConfiguration.COMPRESSION_PREFERENCE.PREFER_QUALITY else VideoEncoderConfiguration.COMPRESSION_PREFERENCE.PREFER_LOW_LATENCY
            rtcEngine.setVideoEncoderConfiguration(videoEncoderConfiguration)
        }
        exposureface?.let {
            rtcEngine.setCameraAutoFocusFaceModeEnabled(it)
        }
        captureResolution?.let {
            rtcEngine.setCameraCapturerConfiguration(CameraCapturerConfiguration(
                CameraCapturerConfiguration.CaptureFormat(it.width, it.height, 15)
            ).apply {
                followEncodeDimensionRatio = false
            })
        }
        encoderResolution?.let {
            videoEncoderConfiguration.dimensions =
                VideoEncoderConfiguration.VideoDimensions(it.width, it.height)
            rtcEngine.setVideoEncoderConfiguration(videoEncoderConfiguration)
        }
        frameRate?.let {
            videoEncoderConfiguration.frameRate = it.fps
            rtcEngine.setVideoEncoderConfiguration(videoEncoderConfiguration)
        }
        bitRate?.let {
            videoEncoderConfiguration.bitrate = it
            rtcEngine.setVideoEncoderConfiguration(videoEncoderConfiguration)
        }

        inEarMonitoring?.let {
            rtcEngine.enableInEarMonitoring(it)
        }
        recordingSignalVolume?.let {
            rtcEngine.adjustRecordingSignalVolume(it)
        }
        audioMixingVolume?.let {
            rtcEngine.adjustAudioMixingVolume(it)
        }

        params?.let {
            it.split("},").let { list ->
                list.forEachIndexed { index, param ->
                    if (index == list.size - 1) {
                        rtcEngine.setParameters(param)
                    } else {
                        rtcEngine.setParameters("$param}")
                    }
                }
            }
        }
    }

}