package io.agora.scene.show.service

enum class ShowRoomStatus(val value: Int) {
    activity(0),//直播中
    end(1)//直播结束
}

enum class ShowRoomRequestStatus(val value: Int){
    idle(0),
    waitting(1),// 等待中
    accepted(2),//  已接受
    rejected(3),// 已拒绝
    ended(4)// 已结束
}

enum class ShowInteractionStatus(val value: Int) {
    idle(0), /// 空闲
    onSeat(1), /// 连麦中
    pking(2) /// pk中
}

// 房间详情信息
data class ShowRoomDetailModel(
    val roomNo: String,
    val roomName: String,
    val roomUserCount: Int,
    val thumbnailId: String,
    val ownerId: String,
    val roomStatus: Int = ShowRoomStatus.activity.value,
    val crateAt: Double,
    val updateAt: Double,
): java.io.Serializable {
    fun toMap(): Map<String, Any>{
        return mapOf(
            Pair("roomNo", roomNo),
            Pair("roomName", roomName),
            Pair("roomUserCount", 0),
            Pair("thumbnailId", ""),
            Pair("ownerId", ownerId),
            Pair("roomStatus", roomStatus),
            Pair("crateAt", crateAt),
            Pair("updateAt", updateAt),
        )
    }
}

//用户信息
data class ShowUser(
    val userId: String,
    val avatar: String,
    val userName: String,
    val status: ShowRoomRequestStatus = ShowRoomRequestStatus.idle //申请状态
)

// 聊天消息
data class ShowMessage(
    val userId: String,
    val userName: String,
    val message: String,
    val createAt: Double
)

// 连麦申请
data class ShowMicSeatApply(
    val userId: String,
    val userAvatar: String,
    val userName: String,
    val status: ShowRoomRequestStatus,
    val createAt: Double = System.currentTimeMillis().toDouble()
)

// 连麦邀请
data class ShowMicSeatInvitation(
    val userId: String,
    val avatar: String,
    val userName: String,
    val status: ShowRoomRequestStatus = ShowRoomRequestStatus.idle //申请状态
)

// PK邀请
data class ShowPKInvitation(
    val userId: String,
    var userName: String,
    val roomId: String,
    val fromUserId: String,
    val fromName: String,
    val fromRoomId: String,
    val status: ShowRoomRequestStatus,
    var userMuteAudio: Boolean,      //userId静音状态
    var fromUserMuteAudio: Boolean,
    val createAt: Double = System.currentTimeMillis().toDouble()
)

//房间列表信息
data class ShowRoomListModel(
    val roomId: String,                                //房间号
    val roomName: String,                             //房间名
    val roomUserCount: Int,                       //房间人数
    val thumbnailId: String,                         //缩略图id
    val ownerId: String,                             //房主user id (rtc uid)
    val ownerAvater: String,                           //房主头像
    val ownerName: String,                            //房主名
    val roomStatus: ShowRoomStatus,         //直播状态
    val interactStatus: ShowInteractionStatus,  //互动状态
    val createdAt: Long,                          //创建时间，与19700101时间比较的毫秒数
    val updatedAt: Long = System.currentTimeMillis()  //更新时间
)

//连麦/Pk模型
data class ShowInteractionInfo(
    val userId: String,                                 //用户id (rtc uid) pk是另一个房间的房主uid，连麦是连麦观众uid
    val userName: String,
    val roomId: String,                                 //用户所在房间id
    val interactStatus: ShowInteractionStatus,       //交互类型
    var muteAudio: Boolean = false,                  //userId静音状态
    var ownerMuteAudio: Boolean = false,             //房主静音状态（后续拆成两条interation info的muteAudio）
    val createdAt: Long = System.currentTimeMillis()  //创建时间, 与19700101时间比较的毫秒数
)