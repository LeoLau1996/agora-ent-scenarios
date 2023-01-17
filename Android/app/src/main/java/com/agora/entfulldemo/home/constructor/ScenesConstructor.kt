package com.agora.entfulldemo.home.constructor

import android.content.Context
import com.agora.entfulldemo.R

/**
 * @author create by zhangwei03
 */
object ScenesConstructor {


    @JvmStatic
    fun buildData(context: Context): MutableList<ScenesModel> {
        return mutableListOf(
            ScenesModel(
                "io.agora.scene.show.RoomListActivity",
                context.getString(R.string.app_show_live),
                R.mipmap.bg_btn_home1,
                R.mipmap.bg_btn_home_ktv,
                true
            )
        )
    }
}