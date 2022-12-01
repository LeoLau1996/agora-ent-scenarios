package io.agora.scene.show

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.LayoutInflater
import android.view.SurfaceView
import androidx.activity.ComponentActivity
import androidx.appcompat.app.AlertDialog
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import io.agora.rtc2.*
import io.agora.rtc2.video.VideoCanvas
import io.agora.scene.base.TokenGenerator
import io.agora.scene.base.manager.UserManager
import io.agora.scene.base.utils.LiveDataUtils
import io.agora.scene.base.utils.ToastUtils
import io.agora.scene.show.databinding.ShowLiveDetailActivityBinding
import io.agora.scene.show.service.*
import io.agora.scene.show.utils.PermissionHelp
import io.agora.scene.show.widget.link.LiveLinkDialog
import io.agora.scene.show.widget.link.OnLinkDialogActionListener
import io.agora.scene.show.widget.UserItem
import io.agora.scene.widget.utils.StatusBarUtil
import java.text.SimpleDateFormat
import java.util.*

class LiveDetailActivity : ComponentActivity(), OnLinkDialogActionListener {

    companion object {
        private val EXTRA_ROOM_DETAIL_INFO = "roomDetailInfo"

        fun launch(context: Context, roomDetail: ShowRoomDetailModel) {
            context.startActivity(Intent(context, LiveDetailActivity::class.java).apply {
                putExtra(EXTRA_ROOM_DETAIL_INFO, roomDetail)
            })
        }
    }

    private val mRoomInfo by lazy { intent.getSerializableExtra(EXTRA_ROOM_DETAIL_INFO) as ShowRoomDetailModel }
    private val mBinding by lazy { ShowLiveDetailActivityBinding.inflate(LayoutInflater.from(this)) }
    private val mService by lazy { ShowServiceProtocol.getImplInstance() }
    private val isRoomOwner by lazy { mRoomInfo.ownerId == UserManager.getInstance().user.id.toString() }

    private lateinit var mPermissionHelp: PermissionHelp
    private lateinit var mRtcEngine: RtcEngineEx

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        StatusBarUtil.setDarkStatusIcon(window, false)
        setContentView(mBinding.root)
        mPermissionHelp = PermissionHelp(this)
        initView()
        initService()
        initRtcEngine()
    }

    override fun onDestroy() {
        super.onDestroy()
        destroyService()
        destroyRtcEngine()
    }

    //================== UI Operation ===============

    private fun initView() {
        initTopLayout()
        initBottomLayout()
    }

    private fun initTopLayout() {
        val topLayout = mBinding.topLayout
        topLayout.ivOwnerAvatar.setImageResource(R.mipmap.portrait03)
        topLayout.tvRoomName.text = mRoomInfo.roomName
        topLayout.tvRoomId.text = getString(R.string.show_room_id, mRoomInfo.roomNo)
        topLayout.tvUserCount.text = mRoomInfo.roomUserCount.toString()
        topLayout.ivClose.setOnClickListener { onBackPressed() }

        // Start Timer counter
        val dataFormat =
            SimpleDateFormat("HH:mm:ss").apply { timeZone = TimeZone.getTimeZone("GMT+0") }
        topLayout.tvTimer.post(object : Runnable {
            override fun run() {
                topLayout.tvTimer.text =
                    dataFormat.format(System.currentTimeMillis() - mRoomInfo.crateAt)
                topLayout.tvTimer.postDelayed(this, 1000)
            }
        })

    }

    private fun initBottomLayout() {
        val bottomLayout = mBinding.bottomLayout
        bottomLayout.ivSetting.setOnClickListener {

        }
    }

    private fun showPermissionLeakDialog(yes: () -> Unit) {
        AlertDialog.Builder(this).apply {
            setMessage(R.string.show_live_perms_leak_tip)
            setCancelable(false)
            setPositiveButton(R.string.show_live_yes) { dialog, _ ->
                dialog.dismiss()
                checkRequirePerms(true, yes)
            }
            setNegativeButton(R.string.show_live_no) { dialog, _ ->
                dialog.dismiss()
                finish()
            }
            show()
        }
    }


    //================== Service Operation ===============

    private fun initService() {

    }

    private fun destroyService() {
        mService.leaveRoom()
    }


    //================== RTC Operation ===================

    private fun initRtcEngine() {
        val config = RtcEngineConfig()
        config.mContext = this
        config.mAppId = io.agora.scene.base.BuildConfig.AGORA_APP_ID
        config.mEventHandler = object : IRtcEngineEventHandler() {

            override fun onError(err: Int) {
                super.onError(err)
                ToastUtils.showToast(RtcEngine.getErrorDescription(err))
            }

        }
        mRtcEngine = RtcEngine.create(config) as RtcEngineEx
        mRtcEngine.enableVideo()

        checkRequirePerms {
            joinChannel()
        }
    }

    private fun destroyRtcEngine() {
        mRtcEngine.leaveChannel()
        RtcEngine.destroy()
    }

    private fun joinChannel() {
        val uid = UserManager.getInstance().user.id
        val channelName = mRoomInfo.roomNo
        TokenGenerator.generateTokens(
            channelName,
            uid.toString(),
            TokenGenerator.TokenGeneratorType.token006,
            arrayOf(TokenGenerator.AgoraTokenType.rtc),
            {
                val channelMediaOptions = ChannelMediaOptions()
                channelMediaOptions.clientRoleType =
                    if (isRoomOwner) Constants.CLIENT_ROLE_BROADCASTER else Constants.CLIENT_ROLE_AUDIENCE
                mRtcEngine.joinChannel(
                    it[TokenGenerator.AgoraTokenType.rtc],
                    channelName,
                    uid.toInt(),
                    channelMediaOptions
                )

                // Render host video
                val videoView = SurfaceView(this)
                mBinding.videoSinglehostLayout.videoContainer.addView(videoView)
                if (isRoomOwner) {
                    mRtcEngine.setupLocalVideo(VideoCanvas(videoView))
                } else {
                    mRtcEngine.setupRemoteVideo(
                        VideoCanvas(
                            videoView,
                            Constants.RENDER_MODE_HIDDEN,
                            mRoomInfo.ownerId.toInt()
                        )
                    )
                }
            })
    }

    private fun checkRequirePerms(force: Boolean = false, granted: () -> Unit) {
        if (!isRoomOwner) {
            granted.invoke()
            return
        }
        mPermissionHelp.checkCameraAndMicPerms(
            {
                granted.invoke()
            },
            {
                showPermissionLeakDialog(granted)
            },
            force
        )
    }

    // TODO HUGO
    val seatApplyList: MutableLiveData<List<ShowMicSeatApply>> = MutableLiveData<List<ShowMicSeatApply>>()
    // ----------------------------------- 连麦申请 -----------------------------------
    public fun initMicSeatApply() {
        mService.subscribeMicSeatApply({ status, apply -> {

            }
        })
    }

    // 获取上麦申请列表
    public fun getAllMicSeatApplyList() : LiveData<List<ShowMicSeatApply>> {
        var liveData = MutableLiveData<List<ShowMicSeatApply>>()
        mService.getAllMicSeatApplyList({ list ->
            run {
                // success
                liveData.postValue(list)
            }
        }, { e -> run {
            // failed
            seatApplyList.postValue(null)
        }})
        return liveData
    }

    // 观众申请连麦
    public fun createMicSeatApply() {
        mService.createMicSeatApply({
            // success
        }, { e -> {
            // failed
        }})
    }

    // 观众取消连麦申请
    public fun cancelMicSeatApply() {
        mService.cancelMicSeatApply({
            // success
        }, { e -> {
            // failed
        }})
    }

    // 主播接受连麦申请
    public fun acceptMicSeatApply(apply: ShowMicSeatApply) : LiveData<Boolean> {
        val liveData = MutableLiveData<Boolean>()
        mService.acceptMicSeatApply(apply, {
            // success
            liveData.postValue(true)
        }, { e -> {
            // failed
            liveData.postValue(false)
        }})
        return liveData;
    }

    // 主播拒绝连麦申请
    public fun rejectMicSeatApply(apply: ShowMicSeatApply) {
        mService.rejectMicSeatApply(apply, {
            // success
        }, { e -> {
            // failed
        }})
    }

    // ----------------------------------- 连麦邀请 -----------------------------------
    public fun initSeatInvitation() {

    }

    public fun getAllMicSeatInvitationList() {
        mService.getAllMicSeatInvitationList({
            // success
        }, { e -> {
            // failed
        }})
    }

    // 主播创建连麦邀请
    public fun createMicSeatInvitation(user: ShowUser) {
        mService.createMicSeatInvitation(user, {
            // success
        }, { e -> {
            // failed
        }})
    }

    // 主播取消连麦邀请
    public fun cancelMicSeatInvitation(userId: String) {
        mService.cancelMicSeatInvitation(userId, {
            // success
        }, { e -> {
            // failed
        }})
    }

    // 观众同意连麦
    public fun acceptMicSeatInvitation() {
        mService.acceptMicSeatInvitation({
            // success
        }, { e -> {
            // failed
        }})
    }

    // 观众拒绝连麦
    public fun rejectMicSeatInvitation() {
        mService.rejectMicSeatInvitation({
            // success
        }, { e -> {
            // failed
        }})
    }

    // ----------------------------------- pk邀请 -----------------------------------
    public fun initPKInvitation() {

    }

    public fun getAllPKInvitationList() {
        mService.getAllPKInvitationList({
            // success
        }, { e -> {
            // failed
        }})
    }

    // 创建PK邀请
    public fun createPKInvitation(room: ShowRoomListModel) {
        mService.createPKInvitation(room, {
            // success
        }, { e -> {
            // failed
        }})
    }

    // 同意PK
    public fun acceptPKInvitation() {
        mService.acceptPKInvitation({
            // success
        }, { e -> {
            // failed
        }})
    }

    // 拒绝PK
    public fun rejectPKInvitation() {
        mService.rejectPKInvitation({
            // success
        }, { e -> {
            // failed
        }})
    }

    // ----------------------------------- 互动状态 -----------------------------------
    public fun initInteration() {

    }

    // 获取互动列表
    public fun getAllInterationList() {
        mService.getAllInterationList({
            // success
        }, { e -> {
            // failed
        }})
    }

    // 停止互动
    public fun stopInteraction(interaction: ShowInteractionInfo) {
        mService.stopInteraction(interaction, {
            // success
        }, { e -> {
            // failed
        }})
    }

    // ------------- override OnLinkDialogActionListener -------------
    // 下拉刷新连麦请求列表
    override fun onRequestMessageRefreshing(dialog: LiveLinkDialog, index: Int) {
        LiveDataUtils.observerThenRemove(
            this,
            getAllMicSeatApplyList()
        ) { list -> run {
                //dialog.setSeatApplyList(list)
            }
        }
    }

    // 主播点击接受连麦
    override fun onAcceptMicSeatApplyChosen(dialog: LiveLinkDialog, userItem: UserItem) {
        val apply = ShowMicSeatApply(
            userItem.userId,
            userItem.userAvatar,
            userItem.userName,
            ShowRoomRequestStatus.accepted
        )
        LiveDataUtils.observerThenRemove(
            this,
            acceptMicSeatApply(apply)
        ) { success: Boolean ->
            if (success) {
                dialog.setSeatApplyItemStatus(null, true)
            }
        }
    }

    override fun onOnlineAudienceRefreshing(dialog: LiveLinkDialog, index: Int) {
        //TODO("Not yet implemented")
    }

    override fun onOnlineAudienceChosen(dialog: LiveLinkDialog, userItem: UserItem) {
        //TODO("Not yet implemented")
    }

    override fun onStopLinkingChosen(dialog: LiveLinkDialog) {
        //TODO("Not yet implemented")
    }
}