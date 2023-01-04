package io.agora.scene.show.widget

import android.content.Context
import android.view.LayoutInflater
import androidx.annotation.StringRes
import io.agora.scene.show.R
import io.agora.scene.show.VideoSetting
import io.agora.scene.show.VideoSetting.toIndex
import io.agora.scene.show.databinding.ShowSettingAdvanceDialogAudienceBinding
import io.agora.scene.show.databinding.ShowSettingAdvanceItemSelectorBinding

/**
 * 高级设置弹窗
 */
class AdvanceSettingAudienceDialog(context: Context) : BottomFullDialog(context) {

    companion object {
        private const val ITEM_ID_SWITCH_BASE = 0x00000001
        const val ITEM_ID_SELECTOR_QUALITY_ENHANCE = ITEM_ID_SWITCH_BASE + 1

    }

    private val mBinding by lazy {
        ShowSettingAdvanceDialogAudienceBinding.inflate(
            LayoutInflater.from(
                context
            )
        )
    }

    private val defaultItemValues = mutableMapOf<Int, Int>().apply {
        put(ITEM_ID_SELECTOR_QUALITY_ENHANCE, VideoSetting.getCurrAudienceSetting().video.SR.toIndex())
    }

    init {
        setContentView(mBinding.root)

        mBinding.ivBack.setOnClickListener {
            dismiss()
        }
        mBinding.tvParameter.setOnClickListener {
            showParameterDialog()
        }
        setupSelectorItem(
            ITEM_ID_SELECTOR_QUALITY_ENHANCE,
            mBinding.qualityEnhance,
            R.string.show_setting_advance_quality_enhance,
            VideoSetting.SuperResolutionList.map {
                when (it){
                    VideoSetting.SuperResolution.SR_NONE -> getContext().getString(R.string.show_setting_advance_sr_close)
                    VideoSetting.SuperResolution.SR_1 -> getContext().getString(R.string.show_setting_advance_sr_1)
                    VideoSetting.SuperResolution.SR_1_33 -> getContext().getString(R.string.show_setting_advance_sr_1_33)
                    VideoSetting.SuperResolution.SR_1_5 -> getContext().getString(R.string.show_setting_advance_sr_1_5)
                    VideoSetting.SuperResolution.SR_2 -> getContext().getString(R.string.show_setting_advance_sr_2)
                    VideoSetting.SuperResolution.SR_SHARP -> getContext().getString(R.string.show_setting_advance_sr_sharp)
                }
            }
        )
    }

    private fun showParameterDialog(){
        ParameterDialog(context).apply {
            setEditText(VideoSetting.getCurrAudienceSetting().params)
            setOnConfirmClickListener { _, params ->
                VideoSetting.updateAudienceSetting(false, params = params)
            }
            show()
        }
    }

    private fun setupSelectorItem(
        itemId: Int,
        binding: ShowSettingAdvanceItemSelectorBinding,
        @StringRes title: Int,
        selectList: List<String>
    ) {
        binding.tvTitle.text = context.getString(title)
        val selectPosition = defaultItemValues[itemId] ?: 0
        binding.tvValue.text = selectList.getOrNull(selectPosition)
        onSelectorChanged(itemId, selectPosition)
        binding.root.setOnClickListener {
            BottomLightListDialog(context).apply {
                setTitle(title)
                setListData(selectList)
                setSelectedPosition(defaultItemValues[itemId] ?: 0)
                setOnSelectedChangedListener { dialog, index ->
                    defaultItemValues[itemId] = index
                    binding.tvValue.text = selectList.getOrNull(index)
                    onSelectorChanged(itemId, index)
                    dialog.dismiss()
                }
                show()
            }
        }
    }

    private fun onSelectorChanged(itemId: Int, index: Int){
        when(itemId){
            ITEM_ID_SELECTOR_QUALITY_ENHANCE -> {
                VideoSetting.updateAudienceSetting(false, SR = VideoSetting.SuperResolutionList[index])
            }
        }
    }

}

