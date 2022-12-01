package io.agora.scene.show.service

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.agora.scene.base.BuildConfig
import io.agora.scene.base.manager.UserManager
import io.agora.syncmanager.rtm.*
import io.agora.syncmanager.rtm.IObject
import io.agora.syncmanager.rtm.Scene
import io.agora.syncmanager.rtm.SceneReference
import io.agora.syncmanager.rtm.Sync.*
import io.agora.syncmanager.rtm.SyncManagerException
import kotlin.random.Random

class ShowSyncManagerServiceImpl(
    private val context: Context,
    private val errorHandler: (Exception) -> Unit
) : ShowServiceProtocol {
    private val kSceneId = "scene_show"

    private val SYNC_MANAGER_MESSAGE_COLLECTION = "show_message_collection"
    private val SYNC_MANAGER_SEAT_APPLY_COLLECTION = "show_seat_apply_collection"
    private val SYNC_MANAGER_SEAT_INVITATION_COLLECTION = "show_seat_invitation_collection"
    private val SYNC_MANAGER_PK_INVITATION_COLLECTION = "show_pk_invitation_collection"
    private val SYNC_MANAGER_INTERACTION_COLLECTION = "show_interaction_collection"

    @Volatile
    private var syncInitialized = false
    private val mainHandler by lazy { Handler(Looper.getMainLooper()) }

    // global cache data
    private val roomSubscribeListener = mutableListOf<Sync.EventListener>()

    private val roomMap = mutableMapOf<String, ShowRoomDetailModel>()
    private val micSeatApplyList = ArrayList<ShowMicSeatApply>()
    private val micSeatInvitationList = ArrayList<ShowMicSeatInvitation>()
    private val pKInvitationList = ArrayList<ShowPKInvitation>()
    private val interactionInfoList = ArrayList<ShowInteractionInfo>()
    
    // cache objectId
    private val objIdOfSeatApply = ArrayList<String>() // objectId of seat Apply
    private val objIdOfSeatInvitation = ArrayList<String>() // objectId of seat Invitation
    private val objIdOfPKInvitation = ArrayList<String>() // objectId of pk Invitation
    private val objIdOfInteractionInfo = ArrayList<String>() // objectId of pk Invitation

    // current room cache data
    private var currRoomNo : String = ""
    private var currSceneReference: SceneReference? = null

    // subscribers
    private var micSeatApplySubscriber: ((ShowServiceProtocol.ShowSubscribeStatus, ShowMicSeatApply?) -> Unit)? =
        null
    private var micSeatInvitationSubscriber: ((ShowServiceProtocol.ShowSubscribeStatus, ShowMicSeatInvitation?) -> Unit)? =
        null
    private var micPKInvitationSubscriber: ((ShowServiceProtocol.ShowSubscribeStatus, ShowPKInvitation?) -> Unit)? = null
    private var micInteractionInfoSubscriber: ((ShowServiceProtocol.ShowSubscribeStatus, ShowInteractionInfo?) -> Unit)? = null

    override fun getRoomList(
        success: (List<ShowRoomDetailModel>) -> Unit,
        error: ((Exception) -> Unit)?
    ) {
        initSync {
            Sync.Instance().getScenes(object : Sync.DataListCallback {
                override fun onSuccess(result: MutableList<IObject>?) {
                    val roomList = result!!.map {
                        it.toObject(ShowRoomDetailModel::class.java)
                    }
                    roomMap.clear()
                    roomList.forEach { roomMap[it.roomNo] = it.copy() }
                    success.invoke(roomList.sortedBy { it.crateAt })
                }

                override fun onFail(exception: SyncManagerException?) {
                    errorHandler.invoke(exception!!)
                    error?.invoke(exception!!)
                }
            })
        }
    }

    override fun createRoom(
        roomName: String,
        success: (ShowRoomDetailModel) -> Unit,
        error: ((Exception) -> Unit)?
    ) {
        initSync {
            val roomDetail = ShowRoomDetailModel(
                (Random(System.currentTimeMillis()).nextInt(10000) + 100000).toString(),
                roomName,
                0,
                "",
                UserManager.getInstance().user.id.toString(),
                ShowRoomStatus.activity.value,
                System.currentTimeMillis().toDouble(),
                System.currentTimeMillis().toDouble()
            )
            val scene = Scene().apply {
                id = roomDetail.roomNo
                userId = roomDetail.ownerId
                property = roomDetail.toMap()
            }
            Sync.Instance().createScene(
                scene,
                object : Sync.Callback {
                    override fun onSuccess() {
                        roomMap[roomDetail.roomNo] = roomDetail.copy()
                        success.invoke(roomDetail)
                    }

                    override fun onFail(exception: SyncManagerException?) {
                        errorHandler.invoke(exception!!)
                        error?.invoke(exception!!)
                    }
                })
        }
    }

    override fun joinRoom(
        roomNo: String,
        success: (ShowRoomDetailModel) -> Unit,
        error: ((Exception) -> Unit)?
    ) {
        if(currRoomNo.isNotEmpty()){
            error?.invoke(RuntimeException("There is a room joined or joining now!"))
            return
        }
        if(roomMap[roomNo] == null){
            error?.invoke(RuntimeException("The room has been destroyed!"))
            return
        }
        currRoomNo = roomNo
        initSync {
            Sync.Instance().joinScene(
                roomNo, object: Sync.JoinSceneCallback{
                    override fun onSuccess(sceneReference: SceneReference?) {

                        this@ShowSyncManagerServiceImpl.currSceneReference = sceneReference!!
                        success.invoke(roomMap[roomNo]!!)
                    }

                    override fun onFail(exception: SyncManagerException?) {
                        errorHandler.invoke(exception!!)
                        error?.invoke(exception!!)
                        currRoomNo = ""
                    }
                }
            )
        }
    }

    override fun leaveRoom() {
        if(currRoomNo.isEmpty()){
            return
        }
        val roomDetail = roomMap[currRoomNo] ?: return
        if(roomDetail.ownerId == UserManager.getInstance().user.id.toString()){
            val roomNo = currRoomNo
            currSceneReference?.delete(object:Sync.Callback{
                override fun onSuccess() {
                    roomMap.remove(roomNo)
                }

                override fun onFail(exception: SyncManagerException?) {
                    errorHandler.invoke(exception!!)
                }
            })
        }
        currRoomNo = ""
        currSceneReference = null
    }

    override fun getAllUserList(success: (List<ShowUser>) -> Unit, error: ((Exception) -> Unit)?) {
        TODO("Not yet implemented")
    }

    override fun subscribeUser(onUserChange: (ShowServiceProtocol.ShowSubscribeStatus, ShowUser) -> Unit) {
        TODO("Not yet implemented")
    }

    override fun sendChatMessage(
        message: ShowMessage,
        success: (() -> Unit)?,
        error: ((Exception) -> Unit)?
    ) {
        TODO("Not yet implemented")
    }

    override fun subscribeMessage(onMessageChange: (ShowServiceProtocol.ShowSubscribeStatus, ShowMessage) -> Unit) {
        TODO("Not yet implemented")
    }

    // TODO HUGO ------------------------------------------------------------------------------------------------------ 

    override fun getAllMicSeatApplyList(
        success: (List<ShowMicSeatApply>) -> Unit,
        error: ((Exception?) -> Unit)?
    ) {
        innerGetSeatApplyList(success, error)
    }

    override fun subscribeMicSeatApply(onMicSeatChange: (ShowServiceProtocol.ShowSubscribeStatus, ShowMicSeatApply?) -> Unit) {
        micSeatApplySubscriber = onMicSeatChange;
    }

    override fun createMicSeatApply(success: (() -> Unit)?, error: ((Exception?) -> Unit)?) {
        val apply = ShowMicSeatApply(
            UserManager.getInstance().user.userNo,
            UserManager.getInstance().user.headUrl,
            UserManager.getInstance().user.name,
            ShowRoomRequestStatus.waitting
        )
        innerCreateSeatApply(apply, success, error)
    }

    override fun cancelMicSeatApply(success: (() -> Unit)?, error: ((Exception?) -> Unit)?) {
        if (micSeatApplyList.size <= 0) {
            error?.invoke(RuntimeException("The seat apply list is empty!"))
            return
        }
        val targetApply = micSeatApplyList.filter { it.userId == UserManager.getInstance().user.userNo }.getOrNull(0)
        if (targetApply == null) {
            error?.invoke(RuntimeException("The seat apply found!"))
            return
        }

        val indexOf = micSeatApplyList.indexOf(targetApply);
        micSeatApplyList.removeAt(indexOf);
        val removedSeatApplyObjId = objIdOfSeatApply.removeAt(indexOf)

        innerRemoveSeatApply(removedSeatApplyObjId, success, error)
    }

    override fun acceptMicSeatApply(
        apply: ShowMicSeatApply,
        success: (() -> Unit)?,
        error: ((Exception?) -> Unit)?
    ) {
        if (micSeatApplyList.size <= 0) {
            error?.invoke(RuntimeException("The seat apply list is empty!"))
            return
        }
        val targetApply = micSeatApplyList.filter { it.userId == apply.userId }.getOrNull(0)
        if (targetApply == null) {
            error?.invoke(RuntimeException("The seat apply found!"))
            return
        }
        
        val seatApply = ShowMicSeatApply(
            targetApply.userId,
            targetApply.userAvatar,
            targetApply.userName,
            ShowRoomRequestStatus.accepted,
            targetApply.createAt
        )

        val indexOf = micSeatApplyList.indexOf(targetApply);
        micSeatApplyList[indexOf] = seatApply
        innerUpdateSeatApply(objIdOfSeatApply[indexOf], seatApply, success, error)

        val interaction = ShowInteractionInfo(
            apply.userId,
            apply.userName,
            currRoomNo,
            ShowInteractionStatus.onSeat
        )
        innerCreateInteration(interaction, null, null)
    }

    override fun rejectMicSeatApply(
        apply: ShowMicSeatApply,
        success: (() -> Unit)?,
        error: ((Exception?) -> Unit)?
    ) {
        if (micSeatApplyList.size <= 0) {
            error?.invoke(RuntimeException("The seat apply list is empty!"))
            return
        }
        val targetApply = micSeatApplyList.filter { it.userId == apply.userId }.getOrNull(0)
        if (targetApply == null) {
            error?.invoke(RuntimeException("The seat apply found!"))
            return
        }

        val seatApply = ShowMicSeatApply(
            targetApply.userId,
            targetApply.userAvatar,
            targetApply.userName,
            ShowRoomRequestStatus.rejected,
            targetApply.createAt
        )
        val indexOf = micSeatApplyList.indexOf(targetApply);
        micSeatApplyList[indexOf] = seatApply
        innerUpdateSeatApply(objIdOfSeatApply[indexOf], seatApply, success, error)
    }

    override fun getAllMicSeatInvitationList(
        success: (List<ShowMicSeatInvitation>) -> Unit,
        error: ((Exception?) -> Unit)?
    ) {
        innerGetSeatInvitationList(success, error)
    }

    override fun subscribeMicSeatInvitation(onMicSeatInvitationChange: (ShowServiceProtocol.ShowSubscribeStatus, ShowMicSeatInvitation?) -> Unit) {
        micSeatInvitationSubscriber = onMicSeatInvitationChange
    }

    override fun createMicSeatInvitation(
        user: ShowUser,
        success: (() -> Unit)?,
        error: ((Exception?) -> Unit)?
    ) {
        val invatation = ShowMicSeatInvitation(
            user.userId,
            user.avatar,
            user.userName,
            ShowRoomRequestStatus.waitting
        )
        innerCreateSeatInvitation(invatation, success, error)
    }

    override fun cancelMicSeatInvitation(
        userId: String,
        success: (() -> Unit)?,
        error: ((Exception?) -> Unit)?
    ) {
        if (micSeatInvitationList.size <= 0) {
            error?.invoke(RuntimeException("The seat invitation list is empty!"))
            return
        }
        val targetInvitation = micSeatInvitationList.filter { it.userId == userId }.getOrNull(0)
        if (targetInvitation == null) {
            error?.invoke(RuntimeException("The seat invitation found!"))
            return
        }

        val indexOf = micSeatInvitationList.indexOf(targetInvitation);
        micSeatInvitationList.removeAt(indexOf);
        val removedSeatInvitationObjId = objIdOfSeatInvitation.removeAt(indexOf)

        innerRemoveSeatInvitation(removedSeatInvitationObjId, success, error)
    }

    override fun acceptMicSeatInvitation(
        success: (() -> Unit)?,
        error: ((Exception?) -> Unit)?
    ) {
        if (micSeatInvitationList.size <= 0) {
            error?.invoke(RuntimeException("The seat invitation list is empty!"))
            return
        }
        val targetInvitation = micSeatInvitationList.filter { it.userId == UserManager.getInstance().user.userNo }.getOrNull(0)
        if (targetInvitation == null) {
            error?.invoke(RuntimeException("The seat invitation found!"))
            return
        }

        val invitation = ShowMicSeatInvitation(
            targetInvitation.userId,
            targetInvitation.userAvatar,
            targetInvitation.userName,
            targetInvitation.fromUserId,
            ShowRoomRequestStatus.accepted,
            targetInvitation.createAt
        )
        val indexOf = micSeatInvitationList.indexOf(targetInvitation);
        micSeatInvitationList[indexOf] = invitation;
        innerUpdateSeatInvitation(objIdOfSeatInvitation[indexOf], invitation, success, error)

        val interaction = ShowInteractionInfo(
            invitation.userId,
            currRoomNo,
            ShowInteractionStatus.onSeat
        )
        innerCreateInteration(interaction, {  }, {  })
    }

    override fun rejectMicSeatInvitation(
        success: (() -> Unit)?,
        error: ((Exception?) -> Unit)?
    ) {
        if (micSeatInvitationList.size <= 0) {
            error?.invoke(RuntimeException("The seat invitation list is empty!"))
            return
        }
        val targetInvitation = micSeatInvitationList.filter { it.userId == UserManager.getInstance().user.userNo }.getOrNull(0)
        if (targetInvitation == null) {
            error?.invoke(RuntimeException("The seat invitation found!"))
            return
        }

        val invitation = ShowMicSeatInvitation(
            targetInvitation.userId,
            targetInvitation.userAvatar,
            targetInvitation.userName,
            targetInvitation.fromUserId,
            ShowRoomRequestStatus.rejected,
            targetInvitation.createAt
        )
        val indexOf = micSeatInvitationList.indexOf(targetInvitation);
        micSeatInvitationList[indexOf] = invitation;
        innerUpdateSeatInvitation(objIdOfSeatInvitation[indexOf], invitation, success, error)
    }

    override fun getAllPKInvitationList(
        success: ((List<ShowPKInvitation>) -> Unit),
        error: ((Exception?) -> Unit)?
    ) {
        innerGetPKInvitationList(success, error)
    }

    override fun subscribePKInvitationChanged(onPKInvitationChanged: (ShowServiceProtocol.ShowSubscribeStatus, ShowPKInvitation?) -> Unit) {
       micPKInvitationSubscriber = onPKInvitationChanged
    }
    
    override fun createPKInvitation(
        room: ShowRoomListModel,
        success: (() -> Unit)?,
        error: ((Exception?) -> Unit)?
    ) {
        TODO("Not yet implemented")
    }
    
    override fun acceptPKInvitation(
        success: (() -> Unit)?,
        error: ((Exception?) -> Unit)?
    ) {
        if (pKInvitationList.size <= 0) {
            error?.invoke(RuntimeException("The seat invitation list is empty!"))
            return
        }
        val targetInvitation = pKInvitationList.filter { it.userId == UserManager.getInstance().user.userNo }.getOrNull(0)
        if (targetInvitation == null) {
            error?.invoke(RuntimeException("The seat invitation found!"))
            return
        }

        val invitation = ShowPKInvitation(
            targetInvitation.userId,
            currRoomNo,
            targetInvitation.fromUserId,
            targetInvitation.fromName,
            targetInvitation.fromRoomId,
            ShowRoomRequestStatus.rejected,
            targetInvitation.createAt
        )

        val indexOf = pKInvitationList.indexOf(targetInvitation);
        pKInvitationList[indexOf] = invitation;
        innerUpdatePKInvitation(objIdOfPKInvitation[indexOf], invitation, success, error)
    }

    override fun rejectPKInvitation(
        success: (() -> Unit)?,
        error: ((Exception?) -> Unit)?
    ) {
        if (pKInvitationList.size <= 0) {
            error?.invoke(RuntimeException("The seat invitation list is empty!"))
            return
        }
        val targetInvitation = pKInvitationList.filter { it.userId == UserManager.getInstance().user.userNo }.getOrNull(0)
        if (targetInvitation == null) {
            error?.invoke(RuntimeException("The seat invitation found!"))
            return
        }

        val invitation = ShowPKInvitation(
            targetInvitation.userId,
            currRoomNo,
            targetInvitation.fromUserId,
            targetInvitation.fromName,
            targetInvitation.fromRoomId,
            ShowRoomRequestStatus.rejected,
            targetInvitation.createAt
        )

        val indexOf = pKInvitationList.indexOf(targetInvitation);
        pKInvitationList[indexOf] = invitation;
        innerUpdatePKInvitation(objIdOfPKInvitation[indexOf], invitation, success, error)
    }

    override fun getAllInterationList(
        success: ((List<ShowInteractionInfo>) -> Unit)?,
        error: ((Exception?) -> Unit)?
    ) {
        innerGetAllInterationList(success, error)
    }

    override fun subscribeInteractionChanged(onInteractionChanged: (ShowServiceProtocol.ShowSubscribeStatus, ShowInteractionInfo?) -> Unit) {
        micInteractionInfoSubscriber = onInteractionChanged;
    }
    
    override fun stopInteraction(
        interaction: ShowInteractionInfo, 
        success: (() -> Unit)?,
        error: ((Exception?) -> Unit)?
    ) {
        if (interaction.interactStatus == ShowInteractionStatus.pking) return

    }

    // =================================== 内部实现 ===================================
    private fun runOnMainThread(r: Runnable) {
        if (Thread.currentThread() == mainHandler.looper.thread) {
            r.run()
        } else {
            mainHandler.post(r)
        }
    }

    private fun initSync(complete: () -> Unit) {
        if (syncInitialized) {
            complete.invoke()
            return
        }
        syncInitialized = true
        Sync.Instance().init(
            context,
            mutableMapOf(Pair("appid", BuildConfig.AGORA_APP_ID), Pair("defaultChannel", kSceneId)),
            object : Sync.Callback {
                override fun onSuccess() {
                    Handler(Looper.getMainLooper()).post { complete.invoke() }
                }

                override fun onFail(exception: SyncManagerException?) {
                    syncInitialized = false
                    errorHandler.invoke(exception!!)
                }
            }
        )
    }

    // ----------------------------------- 连麦申请 -----------------------------------
    private fun innerGetSeatApplyList(
        success: (List<ShowMicSeatApply>) -> Unit,
        error: ((Exception?) -> Unit)?
    ) {
        currSceneReference?.collection(SYNC_MANAGER_SEAT_APPLY_COLLECTION)?.get(object :
            Sync.DataListCallback {
            override fun onSuccess(result: MutableList<IObject>?) {
                val ret = ArrayList<ShowMicSeatApply>()
                val retObjId = ArrayList<String>()
                result?.forEach {
                    val obj = it.toObject(ShowMicSeatApply::class.java)
                    ret.add(obj)
                    retObjId.add(it.id)
                }
                micSeatApplyList.clear()
                micSeatApplyList.addAll(ret)
                objIdOfSeatApply.clear()
                objIdOfSeatApply.addAll(retObjId)

                //按照创建时间顺序排序
                //ret.sortBy { it.createdAt }
                runOnMainThread { success.invoke(ret) }
            }

            override fun onFail(exception: SyncManagerException?) {
                runOnMainThread { error?.invoke(exception) }
            }
        })
    }

    private fun innerCreateSeatApply(
        seatApply: ShowMicSeatApply,
        success: (() -> Unit)?,
        error: ((Exception?) -> Unit)?
    ) {
        currSceneReference?.collection(SYNC_MANAGER_SEAT_APPLY_COLLECTION)
            ?.add(seatApply, object : DataItemCallback {
                override fun onSuccess(result: IObject) {
                    //micSeatApplyList.add(seatApply)
                    runOnMainThread { success?.invoke() }
                }

                override fun onFail(exception: SyncManagerException?) {
                    runOnMainThread { error?.invoke(exception) }
                }
            })
    }

    private fun innerUpdateSeatApply(
        objectId: String,
        seatApply: ShowMicSeatApply,
        success: (() -> Unit)?,
        error: ((Exception?) -> Unit)?
    ) {
        currSceneReference?.collection(SYNC_MANAGER_SEAT_APPLY_COLLECTION)
            ?.update(objectId, seatApply, object : Callback {
                override fun onSuccess() {
                    runOnMainThread { success?.invoke() }
                }

                override fun onFail(exception: SyncManagerException?) {
                    runOnMainThread { error?.invoke(exception) }
                }
            })
    }

    private fun innerRemoveSeatApply(
        objectId: String,
        success: (() -> Unit)?,
        error: ((Exception?) -> Unit)?
    ) {
        currSceneReference?.collection(SYNC_MANAGER_SEAT_APPLY_COLLECTION)
            ?.delete(objectId, object : Callback {
                override fun onSuccess() {
                    runOnMainThread { success?.invoke() }
                }

                override fun onFail(exception: SyncManagerException?) {
                    runOnMainThread { error?.invoke(exception) }
                }
            })
    }

    private fun innerSubscribeSeatApplyChanged() {
         val listener = object : EventListener {
            override fun onCreated(item: IObject?) {
                // do Nothing
            }

            override fun onUpdated(item: IObject?) {
                val info = item?.toObject(ShowMicSeatApply::class.java) ?: return
                micSeatApplySubscriber?.invoke(
                    ShowServiceProtocol.ShowSubscribeStatus.updated,
                    info
                )
            }

            override fun onDeleted(item: IObject?) {
                micSeatApplySubscriber?.invoke(
                    ShowServiceProtocol.ShowSubscribeStatus.deleted,
                    null
                )
            }

            override fun onSubscribeError(ex: SyncManagerException?) {
            }
        }
        roomSubscribeListener.add(listener)
        currSceneReference?.subscribe(SYNC_MANAGER_SEAT_APPLY_COLLECTION, listener)
    }

    // ----------------------------------- 连麦邀请 -----------------------------------
    private fun innerGetSeatInvitationList(
        success: (List<ShowMicSeatInvitation>) -> Unit,
        error: ((Exception?) -> Unit)?
    ) {
        currSceneReference?.collection(SYNC_MANAGER_SEAT_INVITATION_COLLECTION)?.get(object : DataListCallback {
            override fun onSuccess(result: MutableList<IObject>?) {
                val ret = ArrayList<ShowMicSeatInvitation>()
                val retObjId = ArrayList<String>()
                result?.forEach {
                    val obj = it.toObject(ShowMicSeatInvitation::class.java)
                    ret.add(obj)
                    retObjId.add(it.id)
                }
                micSeatInvitationList.clear()
                micSeatInvitationList.addAll(ret)
                objIdOfSeatInvitation.clear()
                objIdOfSeatInvitation.addAll(retObjId)

                //按照创建时间顺序排序
                //ret.sortBy { it.createdAt }
                runOnMainThread { success.invoke(ret) }
            }

            override fun onFail(exception: SyncManagerException?) {
                runOnMainThread { error?.invoke(exception) }
            }
        })
    }

    private fun innerCreateSeatInvitation(
        seatInvitation: ShowMicSeatInvitation,
        success: (() -> Unit)?,
        error: ((Exception?) -> Unit)?
    ) {
        currSceneReference?.collection(SYNC_MANAGER_SEAT_INVITATION_COLLECTION)
            ?.add(seatInvitation, object : DataItemCallback {
                override fun onSuccess(result: IObject) {
                    runOnMainThread { success?.invoke() }
                }

                override fun onFail(exception: SyncManagerException?) {
                    runOnMainThread { error?.invoke(exception) }
                }
            })
    }

    private fun innerUpdateSeatInvitation(
        objectId: String,
        seatInvitation: ShowMicSeatInvitation,
        success: (() -> Unit)?,
        error: ((Exception?) -> Unit)?
    ) {
        currSceneReference?.collection(SYNC_MANAGER_SEAT_INVITATION_COLLECTION)
            ?.update(objectId, seatInvitation, object : Callback {
                override fun onSuccess() {
                    runOnMainThread { success?.invoke() }
                }

                override fun onFail(exception: SyncManagerException?) {
                    runOnMainThread { error?.invoke(exception) }
                }
            })
    }

    private fun innerRemoveSeatInvitation(
        objectId: String,
        success: (() -> Unit)?,
        error: ((Exception?) -> Unit)?
    ) {
        currSceneReference?.collection(SYNC_MANAGER_SEAT_INVITATION_COLLECTION)
            ?.delete(objectId, object : Callback {
                override fun onSuccess() {
                    runOnMainThread { success?.invoke() }
                }

                override fun onFail(exception: SyncManagerException?) {
                    runOnMainThread { error?.invoke(exception) }
                }
            })
    }

    private fun innerSubscribeSeatInvitationChanged() {
         val listener = object : EventListener {
            override fun onCreated(item: IObject?) {
                // do Nothing
            }

            override fun onUpdated(item: IObject?) {
                val info = item?.toObject(ShowMicSeatInvitation::class.java) ?: return
                micSeatInvitationSubscriber?.invoke(
                    ShowServiceProtocol.ShowSubscribeStatus.updated,
                    info
                )
            }

            override fun onDeleted(item: IObject?) {
                micSeatInvitationSubscriber?.invoke(
                    ShowServiceProtocol.ShowSubscribeStatus.deleted,
                    null
                )
            }

            override fun onSubscribeError(ex: SyncManagerException?) {
            }
        }
        roomSubscribeListener.add(listener)
        currSceneReference?.subscribe(SYNC_MANAGER_SEAT_INVITATION_COLLECTION, listener)
    }

    // ----------------------------------- pk邀请 -----------------------------------
    private fun innerGetPKInvitationList(
        success: (List<ShowPKInvitation>) -> Unit,
        error: ((Exception?) -> Unit)?
    ) {
        currSceneReference?.collection(SYNC_MANAGER_PK_INVITATION_COLLECTION)?.get(object : DataListCallback {
            override fun onSuccess(result: MutableList<IObject>?) {
                val ret = ArrayList<ShowPKInvitation>()
                val retObjId = ArrayList<String>()
                result?.forEach {
                    val obj = it.toObject(ShowPKInvitation::class.java)
                    ret.add(obj)
                    retObjId.add(it.id)
                }
                pKInvitationList.clear()
                pKInvitationList.addAll(ret)
                objIdOfPKInvitation.clear()
                objIdOfPKInvitation.addAll(retObjId)

                //按照创建时间顺序排序
                //ret.sortBy { it.createdAt }
                runOnMainThread { success.invoke(ret) }
            }

            override fun onFail(exception: SyncManagerException?) {
                runOnMainThread { error?.invoke(exception) }
            }
        })
    }

    private fun innerCreatePKInvitation(
        pkInvitation: ShowPKInvitation,
        success: (() -> Unit)?,
        error: ((Exception?) -> Unit)?
    ) {
        currSceneReference?.collection(SYNC_MANAGER_PK_INVITATION_COLLECTION)
            ?.add(pkInvitation, object : DataItemCallback {
                override fun onSuccess(result: IObject) {
                    runOnMainThread { success?.invoke() }
                }

                override fun onFail(exception: SyncManagerException?) {
                    runOnMainThread { error?.invoke(exception) }
                }
            })
    }

    private fun innerUpdatePKInvitation(
        objectId: String,
        pkInvitation: ShowPKInvitation,
        success: (() -> Unit)?,
        error: ((Exception?) -> Unit)?
    ) {
        currSceneReference?.collection(SYNC_MANAGER_PK_INVITATION_COLLECTION)
            ?.update(objectId, pkInvitation, object : Callback {
                override fun onSuccess() {
                    runOnMainThread { success?.invoke() }
                }

                override fun onFail(exception: SyncManagerException?) {
                    runOnMainThread { error?.invoke(exception) }
                }
            })
    }

    private fun innerRemovePKInvitation(
        objectId: String,
        success: (() -> Unit)?,
        error: ((Exception?) -> Unit)?
    ) {
        currSceneReference?.collection(SYNC_MANAGER_PK_INVITATION_COLLECTION)
            ?.delete(objectId, object : Callback {
                override fun onSuccess() {
                    runOnMainThread { success?.invoke() }
                }

                override fun onFail(exception: SyncManagerException?) {
                    runOnMainThread { error?.invoke(exception) }
                }
            })
    }

    private fun innerSubscribePKInvitationChanged() {
         val listener = object : EventListener {
            override fun onCreated(item: IObject?) {
                // do Nothing
            }

            override fun onUpdated(item: IObject?) {
                val info = item?.toObject(ShowPKInvitation::class.java) ?: return
                micPKInvitationSubscriber?.invoke(
                    ShowServiceProtocol.ShowSubscribeStatus.updated,
                    info
                )
            }

            override fun onDeleted(item: IObject?) {
                micPKInvitationSubscriber?.invoke(
                    ShowServiceProtocol.ShowSubscribeStatus.deleted,
                    null
                )
            }

            override fun onSubscribeError(ex: SyncManagerException?) {
            }
        }
        roomSubscribeListener.add(listener)
        currSceneReference?.subscribe(SYNC_MANAGER_PK_INVITATION_COLLECTION, listener)
    }

    // ----------------------------------- 互动状态 -----------------------------------
    private fun innerGetAllInterationList(
        success: ((List<ShowInteractionInfo>) -> Unit)?,
        error: ((Exception?) -> Unit)?
    ) {
        currSceneReference?.collection(SYNC_MANAGER_INTERACTION_COLLECTION)?.get(object : DataListCallback {
            override fun onSuccess(result: MutableList<IObject>?) {
                val ret = ArrayList<ShowInteractionInfo>()
                val retObjId = ArrayList<String>()
                result?.forEach {
                    val obj = it.toObject(ShowInteractionInfo::class.java)
                    ret.add(obj)
                    retObjId.add(it.id)
                }
                interactionInfoList.clear()
                interactionInfoList.addAll(ret)
                objIdOfInteractionInfo.clear()
                objIdOfInteractionInfo.addAll(retObjId)

                //按照创建时间顺序排序
                ret.sortBy { it.createdAt }
                runOnMainThread { success?.invoke(ret) }
            }

            override fun onFail(exception: SyncManagerException?) {
                runOnMainThread { error?.invoke(exception) }
            }
        })
    }

    private fun innerCreateInteration(
        info: ShowInteractionInfo,
        success: (() -> Unit)?,
        error: ((Exception?) -> Unit)?
    ) {
        currSceneReference?.collection(SYNC_MANAGER_INTERACTION_COLLECTION)
            ?.add(info, object : DataItemCallback {
                override fun onSuccess(result: IObject) {
                    runOnMainThread { success?.invoke() }
                }

                override fun onFail(exception: SyncManagerException?) {
                    runOnMainThread { error?.invoke(exception) }
                }
            })
    }

    private fun innerUpdateInteration(
        objectId: String,
        info: ShowInteractionInfo,
        success: (() -> Unit)?,
        error: ((Exception?) -> Unit)?
    ) {
        currSceneReference?.collection(SYNC_MANAGER_INTERACTION_COLLECTION)
            ?.update(objectId, info, object : Callback {
                override fun onSuccess() {
                    runOnMainThread { success?.invoke() }
                }

                override fun onFail(exception: SyncManagerException?) {
                    runOnMainThread { error?.invoke(exception) }
                }
            })
    }

    private fun innerRemoveInteration(
        objectId: String,
        success: (() -> Unit)?,
        error: ((Exception?) -> Unit)?
    ) {
        currSceneReference?.collection(SYNC_MANAGER_INTERACTION_COLLECTION)
            ?.delete(objectId, object : Callback {
                override fun onSuccess() {
                    runOnMainThread { success?.invoke() }
                }

                override fun onFail(exception: SyncManagerException?) {
                    runOnMainThread { error?.invoke(exception) }
                }
            })
    }

    private fun innerSubscribeInteractionChanged() {
         val listener = object : EventListener {
            override fun onCreated(item: IObject?) {
                // do Nothing
            }

            override fun onUpdated(item: IObject?) {
                val info = item?.toObject(ShowInteractionInfo::class.java) ?: return
                micInteractionInfoSubscriber?.invoke(
                    ShowServiceProtocol.ShowSubscribeStatus.updated,
                    info
                )
            }

            override fun onDeleted(item: IObject?) {
                micInteractionInfoSubscriber?.invoke(
                    ShowServiceProtocol.ShowSubscribeStatus.deleted,
                    null
                )
            }

            override fun onSubscribeError(ex: SyncManagerException?) {
            }
        }
        roomSubscribeListener.add(listener)
        currSceneReference?.subscribe(SYNC_MANAGER_INTERACTION_COLLECTION, listener)
    }
}