package io.agora.scene.show.widget

import android.content.Context
import android.os.SystemClock
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
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
        setClickWithLong(mBinding.btn1){ mBinding.editText.append("{")}
        setClickWithLong(mBinding.btn2){ mBinding.editText.append("}")}
        setClickWithLong(mBinding.btn3){ mBinding.editText.append("\"")}
        setClickWithLong(mBinding.btn4){ mBinding.editText.append(":")}
        setClickWithLong(mBinding.btn5){ mBinding.editText.append(",")}
        setClickWithLong(mBinding.btn8){ mBinding.editText.append(".")}
        setClickWithLong(mBinding.btn9){ mBinding.editText.append("_")}
        setClickWithLong(mBinding.btn6){
            val selection = mBinding.editText.selectionStart
            if(selection > 0){
                mBinding.editText.setSelection(selection - 1)
            }
        }
        setClickWithLong(mBinding.btn7){
            val selection = mBinding.editText.selectionEnd
            if(selection < mBinding.editText.text.length){
                mBinding.editText.setSelection(selection + 1)
            }
        }
    }

    fun setEditText(text: String) {
        mBinding.editText.setText(text)
    }

    fun setOnConfirmClickListener(onConfirmed: (ParameterDialog, String) -> Unit) {
        onConfirmListener = onConfirmed
    }

    private fun setClickWithLong(view: View, onClicked: () -> Unit) {
        val clickRepeatRun = object : Runnable{
            override fun run() {
                onClicked.invoke()
                view.postDelayed(this, 50)
            }
        }
        val longClickDuration = 500L
        var clickTime = 0L
        view.setOnTouchListener { v, event ->
            when(event.action){
                MotionEvent.ACTION_DOWN -> {
                    clickTime = SystemClock.elapsedRealtime()
                    view.postDelayed(clickRepeatRun, longClickDuration)
                }
                MotionEvent.ACTION_CANCEL -> {
                    view.removeCallbacks(clickRepeatRun)
                }
                MotionEvent.ACTION_UP -> {
                    view.removeCallbacks(clickRepeatRun)
                    onClicked.invoke()
                    if(SystemClock.elapsedRealtime() - clickTime > longClickDuration){
                        v.performLongClick()
                    }else{
                        v.performClick()
                    }
                }
            }
            return@setOnTouchListener true
        }
    }

}