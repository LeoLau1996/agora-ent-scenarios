package io.agora.scene.show.widget

import android.content.Context
import android.view.LayoutInflater
import android.widget.EditText
import io.agora.scene.show.RtcEngineInstance
import io.agora.scene.show.databinding.ShowWidgetDebugSettingDialogBinding

class DebugSettingDialog(context: Context) : BottomFullDialog(context) {

    private val mBinding by lazy {
        ShowWidgetDebugSettingDialogBinding.inflate(
            LayoutInflater.from(
                context
            )
        )
    }

    init {
        setContentView(mBinding.root)

        mBinding.ivBack.setOnClickListener {
            dismiss()
        }
        // 采集帧率
        setText(mBinding.etFpsCapture, RtcEngineInstance.videoCaptureConfiguration.captureFormat.fps.toString())
        // 采集分辨率
        setText(mBinding.etResolutionWidthCapture, RtcEngineInstance.videoCaptureConfiguration.captureFormat.width.toString())
        setText(mBinding.etResolutionHeightCapture, RtcEngineInstance.videoCaptureConfiguration.captureFormat.height.toString())

        // 帧率
        setText(mBinding.etFps, RtcEngineInstance.videoEncoderConfiguration.frameRate.toString())
        // 分辨率
        setText(mBinding.etResolutionWidth, RtcEngineInstance.videoEncoderConfiguration.dimensions.width.toString())
        setText(mBinding.etResolutionHeight, RtcEngineInstance.videoEncoderConfiguration.dimensions.height.toString())
        // 码率
        setText(mBinding.etBitrate, RtcEngineInstance.videoEncoderConfiguration.bitrate.toString())

        mBinding.tvSure.setOnClickListener {
            RtcEngineInstance.videoCaptureConfiguration.captureFormat.fps = mBinding.etFpsCapture.text.toString().toIntOrNull()?: 30
            RtcEngineInstance.videoCaptureConfiguration.captureFormat.width = mBinding.etResolutionWidthCapture.text.toString().toIntOrNull()?: 720
            RtcEngineInstance.videoCaptureConfiguration.captureFormat.height = mBinding.etResolutionHeightCapture.text.toString().toIntOrNull()?: 1080
            RtcEngineInstance.rtcEngine.setCameraCapturerConfiguration(RtcEngineInstance.videoCaptureConfiguration)

            RtcEngineInstance.videoEncoderConfiguration.frameRate = mBinding.etFps.text.toString().toIntOrNull()?: 30
            RtcEngineInstance.videoEncoderConfiguration.dimensions.width = mBinding.etResolutionWidth.text.toString().toIntOrNull()?: 720
            RtcEngineInstance.videoEncoderConfiguration.dimensions.height = mBinding.etResolutionHeight.text.toString().toIntOrNull()?: 1080
            RtcEngineInstance.videoEncoderConfiguration.bitrate = mBinding.etBitrate.text.toString().toIntOrNull()?: 720
            RtcEngineInstance.rtcEngine.setVideoEncoderConfiguration(RtcEngineInstance.videoEncoderConfiguration)

            dismiss()
        }
    }

    private fun setText(editText: EditText, content: String){
        editText.setText(content)
        editText.setSelection(content.length)
    }
}