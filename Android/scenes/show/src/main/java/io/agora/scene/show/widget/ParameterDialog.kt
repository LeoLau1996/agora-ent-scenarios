package io.agora.scene.show.widget

import android.content.Context
import android.view.LayoutInflater
import io.agora.scene.show.databinding.ShowParameterDialogBinding

class ParameterDialog(context: Context) : BottomFullDialog(context) {

    private val mBinding by lazy {
        ShowParameterDialogBinding.inflate(LayoutInflater.from(context))
    }

    private var onConfirmListener: ((ParameterDialog, String) -> Unit)? = null

    init {
        setContentView(mBinding.root)
        mBinding.ivBack.setOnClickListener {
            dismiss()
        }
        mBinding.tvConfirm.setOnClickListener {
            onConfirmListener?.invoke(this@ParameterDialog, mBinding.editText.text.toString())
            dismiss()
        }
    }

    fun setEditText(text: String) {
        mBinding.editText.setText(text)
    }

    fun setOnConfirmClickListener(onConfirmed: (ParameterDialog, String) -> Unit) {
        onConfirmListener = onConfirmed
    }

}