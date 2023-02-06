package io.agora.scene.show.widget

import android.content.Context
import android.view.LayoutInflater
import android.view.inputmethod.EditorInfo
import io.agora.scene.base.utils.ToastUtils
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
        mBinding.etFpsCapture.setText(RtcEngineInstance.videoCaptureConfiguration.captureFormat.fps.toString())
        mBinding.etFpsCapture.setOnEditorActionListener { v, actionId, event ->
            if (actionId == EditorInfo.IME_ACTION_DONE) {
                RtcEngineInstance.videoCaptureConfiguration.captureFormat.fps = mBinding.etFpsCapture.text.toString().toIntOrNull()?: 30
                RtcEngineInstance.rtcEngine.setCameraCapturerConfiguration(RtcEngineInstance.videoCaptureConfiguration)
                v.clearFocus()
                ToastUtils.showToast("设置成功")
            }
            return@setOnEditorActionListener false
        }

        // 采集分辨率
        mBinding.etResolutionWidthCapture.setText(RtcEngineInstance.videoCaptureConfiguration.captureFormat.width.toString())
        mBinding.etResolutionHeightCapture.setText(RtcEngineInstance.videoCaptureConfiguration.captureFormat.height.toString())
        mBinding.etResolutionWidthCapture.setOnEditorActionListener { v, actionId, event ->
            if(actionId == EditorInfo.IME_ACTION_NEXT){
                mBinding.etResolutionHeightCapture.requestFocus()
            }
            return@setOnEditorActionListener false
        }
        mBinding.etResolutionHeightCapture.setOnEditorActionListener { v, actionId, event ->
            if(actionId == EditorInfo.IME_ACTION_DONE){
                RtcEngineInstance.videoCaptureConfiguration.captureFormat.width = mBinding.etResolutionWidthCapture.text.toString().toIntOrNull()?: 720
                RtcEngineInstance.videoCaptureConfiguration.captureFormat.height = mBinding.etResolutionHeightCapture.text.toString().toIntOrNull()?: 1080
                RtcEngineInstance.rtcEngine.setCameraCapturerConfiguration(RtcEngineInstance.videoCaptureConfiguration)
                ToastUtils.showToast("设置成功")
                v.clearFocus()
            }
            return@setOnEditorActionListener false
        }

        // 帧率
        mBinding.etFps.setText(RtcEngineInstance.videoEncoderConfiguration.frameRate.toString())
        mBinding.etFps.setOnEditorActionListener { v, actionId, event ->
            if (actionId == EditorInfo.IME_ACTION_DONE) {
                RtcEngineInstance.videoEncoderConfiguration.frameRate = mBinding.etFps.text.toString().toIntOrNull()?: 30
                RtcEngineInstance.rtcEngine.setVideoEncoderConfiguration(RtcEngineInstance.videoEncoderConfiguration)
                v.clearFocus()
                ToastUtils.showToast("设置成功")
            }
            return@setOnEditorActionListener false
        }
        
        // 分辨率
        mBinding.etResolutionWidth.setText(RtcEngineInstance.videoEncoderConfiguration.dimensions.width.toString())
        mBinding.etResolutionHeight.setText(RtcEngineInstance.videoEncoderConfiguration.dimensions.height.toString())
        mBinding.etResolutionWidth.setOnEditorActionListener { v, actionId, event ->
            if(actionId == EditorInfo.IME_ACTION_NEXT){
                mBinding.etResolutionHeight.requestFocus()
            }
            return@setOnEditorActionListener false
        }
        mBinding.etResolutionHeight.setOnEditorActionListener { v, actionId, event ->
            if(actionId == EditorInfo.IME_ACTION_DONE){
                RtcEngineInstance.videoEncoderConfiguration.dimensions.width = mBinding.etResolutionWidth.text.toString().toIntOrNull()?: 720
                RtcEngineInstance.videoEncoderConfiguration.dimensions.height = mBinding.etResolutionHeight.text.toString().toIntOrNull()?: 1080
                RtcEngineInstance.rtcEngine.setVideoEncoderConfiguration(RtcEngineInstance.videoEncoderConfiguration)
                ToastUtils.showToast("设置成功")
                v.clearFocus()
            }
            return@setOnEditorActionListener false
        }

        // 码率
        mBinding.etBitrate.setText(RtcEngineInstance.videoEncoderConfiguration.bitrate.toString())
        mBinding.etBitrate.setOnEditorActionListener { v, actionId, event ->
            if(actionId == EditorInfo.IME_ACTION_DONE){
                RtcEngineInstance.videoEncoderConfiguration.bitrate = mBinding.etBitrate.text.toString().toIntOrNull()?: 720
                RtcEngineInstance.rtcEngine.setVideoEncoderConfiguration(RtcEngineInstance.videoEncoderConfiguration)
                ToastUtils.showToast("设置成功")
                v.clearFocus()
            }
            return@setOnEditorActionListener false
        }

    }
}