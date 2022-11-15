package io.agora.scene.voice.model

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.LiveData
import io.agora.scene.voice.general.livedatas.SingleSourceLiveData
import io.agora.scene.voice.general.repositories.VoiceRoomRepository
import io.agora.scene.voice.service.VoiceRoomModel
import io.agora.voice.baseui.general.net.Resource

/**
 * @author create by zhangwei03
 */
class VoiceRoomViewModel constructor(application: Application) : AndroidViewModel(application) {

    private val voiceRoomRepository by lazy { VoiceRoomRepository() }

    private val _roomListObservable: SingleSourceLiveData<Resource<List<VoiceRoomModel>>> =
        SingleSourceLiveData()

    private val _checkPasswordObservable: SingleSourceLiveData<Resource<Boolean>> =
        SingleSourceLiveData()

    private val _createRoomObservable: SingleSourceLiveData<Resource<VoiceRoomModel>> =
        SingleSourceLiveData()

    fun roomListObservable(): LiveData<Resource<List<VoiceRoomModel>>> = _roomListObservable

    fun checkPasswordObservable(): LiveData<Resource<Boolean>> = _checkPasswordObservable

    fun createRoomObservable(): LiveData<Resource<VoiceRoomModel>> = _createRoomObservable

    /**
     * 获取房间列表
     * @param page 第几页，暂未用到
     * @param roomType 房间类型，暂未用到
     */
    fun getRoomList(page: Int, type: Int) {
        _roomListObservable.setSource(voiceRoomRepository.fetchRoomList(page, type))
    }

    /**
     * 私密房间密码校验，本地模拟验证
     * @param roomId 房间id
     * @param password 房间密码
     * @param userInput 用户输入
     */
    fun checkPassword(roomId: String, password: String, userInput: String) {
        _checkPasswordObservable.setSource(voiceRoomRepository.checkPassword(roomId, password, userInput))
    }

    /**
     * 创建普通房间
     * @param roomName 房间名
     * @param soundEffect 房间音效类型
     * @param password  私有房间，有秘密
     */
    fun createRoom(roomName: String, soundEffect: Int = 0, password: String? = null) {
        _createRoomObservable.setSource(voiceRoomRepository.createRoom(roomName, soundEffect, 0, password))
    }

    fun createSpatialRoom(roomName: String, soundEffect: Int = 0, password: String? = null) {
        _createRoomObservable.setSource(voiceRoomRepository.createRoom(roomName, soundEffect, 0, password))
    }
}