//
//  VoiceRoomViewController.swift
//  AgoraScene_iOS
//
//  Created by CP on 2022/9/6.
//

import AgoraChat
import AgoraRtcKit
import KakaJSON
import SnapKit
import SVGAPlayer
import UIKit
import ZSwiftBaseLib

public enum ROLE_TYPE {
    case owner
    case audience
}

let giftMap = [["gift_id": "VoiceRoomGift1", "gift_name": LanguageManager.localValue(key: "Sweet Heart"), "gift_price": "1", "gift_count": "1", "selected": true], ["gift_id": "VoiceRoomGift2", "gift_name": LanguageManager.localValue(key: "Flower"), "gift_price": "5", "gift_count": "1", "selected": false], ["gift_id": "VoiceRoomGift3", "gift_name": LanguageManager.localValue(key: "Crystal Box"), "gift_price": "10", "gift_count": "1", "selected": false], ["gift_id": "VoiceRoomGift4", "gift_name": LanguageManager.localValue(key: "Super Agora"), "gift_price": "20", "gift_count": "1", "selected": false], ["gift_id": "VoiceRoomGift5", "gift_name": LanguageManager.localValue(key: "Star"), "gift_price": "50", "gift_count": "1", "selected": false], ["gift_id": "VoiceRoomGift6", "gift_name": LanguageManager.localValue(key: "Lollipop"), "gift_price": "100", "gift_count": "1", "selected": false], ["gift_id": "VoiceRoomGift7", "gift_name": LanguageManager.localValue(key: "Diamond"), "gift_price": "500", "gift_count": "1", "selected": false], ["gift_id": "VoiceRoomGift8", "gift_name": LanguageManager.localValue(key: "Crown"), "gift_price": "1000", "gift_count": "1", "selected": false], ["gift_id": "VoiceRoomGift9", "gift_name": LanguageManager.localValue(key: "Rocket"), "gift_price": "1500", "gift_count": "1", "selected": false]]

fileprivate let ownerMic = ["index":0,"status":0,"member":["uid":VoiceRoomUserInfo.shared.user?.uid ?? "","chat_uid":VoiceRoomUserInfo.shared.user?.chat_uid ?? "","name":VoiceRoomUserInfo.shared.user?.name ?? "","portrait":VoiceRoomUserInfo.shared.user?.portrait ?? "","rtc_uid":VoiceRoomUserInfo.shared.user?.rtc_uid ?? "","mic_index":0]] as [String : Any]

class VoiceRoomViewController: VRBaseViewController {
    lazy var toastPoint: CGPoint = .init(x: self.view.center.x, y: self.view.center.y + 70)

    override public var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    var headerView: AgoraChatRoomHeaderView!
    var rtcView: AgoraChatRoomNormalRtcView!
    var sRtcView: AgoraChatRoom3DRtcView!

    @UserDefault("VoiceRoomUserAvatar", defaultValue: "") var userAvatar

    lazy var chatView: VoiceRoomChatView = .init(frame: CGRect(x: 0, y: ScreenHeight - CGFloat(ZBottombarHeight) - (ScreenHeight / 667) * 210 - 50, width: ScreenWidth, height: (ScreenHeight / 667) * 210))

    lazy var chatBar: VoiceRoomChatBar = .init(frame: CGRect(x: 0, y: ScreenHeight - CGFloat(ZBottombarHeight) - 50, width: ScreenWidth, height: 50), style: self.roomInfo?.room?.type ?? 0 == 1 ? .spatialAudio : .normal)

    lazy var inputBar: VoiceRoomInputBar = .init(frame: CGRect(x: 0, y: ScreenHeight, width: ScreenWidth, height: 60)).backgroundColor(.white)

    var preView: VMPresentView!
    var noticeView: VMNoticeView!
    var isShowPreSentView: Bool = false
    var rtckit: VoiceRoomRTCManager = VoiceRoomRTCManager.getSharedInstance()
    var isOwner: Bool = false
    var ains_state: AINS_STATE = .mid
    var local_index: Int?
    var alienCanPlay: Bool = true
    var vmType: VMMUSIC_TYPE = .social

    public var roomInfo: VRRoomInfo? {
        didSet {
            VoiceRoomUserInfo.shared.currentRoomOwner = self.roomInfo?.room?.owner
            if let mics = roomInfo?.mic_info {
                if let type = roomInfo?.room?.type {
                    if type == 0 && self.rtcView != nil {
                        self.rtcView.micInfos = mics
                    } else if type == 1 && self.sRtcView != nil {
                        self.sRtcView.micInfos = mics
                    }
                }
            }
        }
    }

    convenience init(info: VRRoomInfo) {
        self.init()
        roomInfo = info
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigation.isHidden = true
        UIApplication.shared.isIdleTimerDisabled = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setNeedsStatusBarAppearanceUpdate()

        guard let user = VoiceRoomUserInfo.shared.user else { return }
        guard let owner = roomInfo?.room?.owner else { return }
        guard let type = roomInfo?.room?.sound_effect else { return }
        isOwner = user.uid == owner.uid
        local_index = isOwner ? 0 : nil
        vmType = getSceneType(type)
        ChatRoomServiceImp.getSharedInstance().subscribeEvent(with: self)
        // 布局UI
        layoutUI()
        // 加载RTC+IM
        loadKit()
        // 处理底部事件
        charBarEvents()
        NotificationCenter.default.addObserver(self, selector: #selector(leaveRoom), name: Notification.Name("terminate"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateMicInfo), name: Notification.Name("updateMicInfo"), object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigation.isHidden = false
        UIApplication.shared.isIdleTimerDisabled = false
    }

    deinit {
        print("\(String(describing: self.swiftClassName)) is destroyed!")
        VoiceRoomUserInfo.shared.currentRoomOwner = nil
        VoiceRoomUserInfo.shared.user?.amount = 0
        ChatRoomServiceImp.getSharedInstance().cleanCache()
        ChatRoomServiceImp.getSharedInstance().unsubscribeEvent()
    }
}

extension VoiceRoomViewController {
    // 加载RTC
    func loadKit() {
        guard let channel_id = roomInfo?.room?.channel_id else { return }
        guard let roomId = roomInfo?.room?.chatroom_id else { return }
        let rtcUid = VLUserCenter.user.id
        rtckit.setClientRole(role: isOwner ? .owner : .audience)
        rtckit.delegate = self

        var rtcJoinSuccess = false
        var IMJoinSuccess = false

        let VMGroup = DispatchGroup()
        let imQueue = DispatchQueue(label: "com.im.vm.www")
        let rtcQueue = DispatchQueue(label: "com.rtc.vm.www")

        VMGroup.enter()
        rtcQueue.async { [weak self] in
            rtcJoinSuccess = self?.rtckit.joinVoicRoomWith(with: "\(channel_id)",token: VLUserCenter.user.agoraRTCToken, rtcUid: Int(rtcUid) ?? 0, type: self?.vmType ?? .social) == 0
            VMGroup.leave()
        }

        VMGroup.enter()
        imQueue.async {
            VoiceRoomIMManager.shared?.joinedChatRoom(roomId: roomId, completion: { room, error in
                IMJoinSuccess = error == nil
                VMGroup.leave()
            })
        }

        VMGroup.notify(queue: .main) { [weak self] in
            let joinSuccess = rtcJoinSuccess && IMJoinSuccess
            guard let `self` = self else { return }
            if !joinSuccess {
                self.view.makeToast("Join failed!")
                self.didHeaderAction(with: .back, destroyed: true)
            } else {
                if self.isOwner == true {
                    //房主更新环信KV
                    self.setChatroomAttributes()
                } else {
                    //观众更新拉取详情后更新kv
                    self.requestRoomDetail()
                    self.sendJoinedMessage()
                }
            }
        }
    }
    
    private func setChatroomAttributes() {
        VoiceRoomIMManager.shared?.setChatroomAttributes(attributes: ChatRoomServiceImp.getSharedInstance().createMics() , completion: { error in
            if error == nil {
                self.refreshRoomInfo()
            } else {
                self.view.makeToast("Set chatroom attributes failed!")
            }
        })
    }
    
    private func sendJoinedMessage() {
        guard let user = VoiceRoomUserInfo.shared.user else {return}
        user.mic_index = -1
        VoiceRoomIMManager.shared?.sendCustomMessage(roomId: self.roomInfo?.room?.chatroom_id ?? "", event: VoiceRoomJoinedMember, customExt: ["user" : user.kj.JSONString()], completion: { message, error in
            if error != nil {
                self.view.makeToast("Send joined chatroom message failed!")
            }
        })
    }
    
    func refreshRoomInfo() {
        self.roomInfo?.room?.member_list = [VRUser]()
        self.roomInfo?.room?.ranking_list = [VRUser]()
        if let info = self.roomInfo {
            info.mic_info = ChatRoomServiceImp.getSharedInstance().mics
            self.roomInfo = info
            self.headerView.updateHeader(with: info.room)
            ChatRoomServiceImp.getSharedInstance().userList = self.roomInfo?.room?.member_list
        }
    }

    func getSceneType(_ type: Int) -> VMMUSIC_TYPE {
        switch type {
        case 2: return .ktv
        case 3: return .game
        case 4: return .anchor
        default: return .social
        }
    }

    // 加入房间获取房间详情
    func requestRoomDetail() {
        // 如果不是房主。需要主动获取房间详情
        ChatRoomServiceImp.getSharedInstance().fetchRoomDetail(entity: self.roomInfo?.room ?? VRRoomEntity()) { [weak self] error, room_info in
            if error == nil {
                guard let info = room_info else { return }
                self?.roomInfoUpdateUI(info: info)
            } else {
                self?.fetchDetailError()
            }
        }
    }
    
    func roomInfoUpdateUI(info: VRRoomInfo) {
        self.roomInfo = info
        self.headerView.updateHeader(with: info.room)
        guard let mics = self.roomInfo?.mic_info else { return }
        if self.roomInfo?.room?.member_list == nil {
            self.roomInfo?.room?.member_list = [VRUser]()
        }
        self.roomInfo?.room?.member_list?.append(VoiceRoomUserInfo.shared.user!)
        VoiceRoomIMManager.shared?.setChatroomAttributes(attributes: ["member_list":self.roomInfo?.room?.member_list?.kj.JSONString() ?? ""], completion: { error in
            if error != nil {
                self.view.makeToast("update member_list failed!\(error?.errorDescription ?? "")")
            }
        })
        ChatRoomServiceImp.getSharedInstance().mics = mics
        ChatRoomServiceImp.getSharedInstance().userList = self.roomInfo?.room?.member_list
        self.roomInfo?.room?.ranking_list = info.room?.ranking_list
        if let first = info.room?.ranking_list?.first(where: { $0.chat_uid == VLUserCenter.user.chat_uid
        }) {
            VoiceRoomUserInfo.shared.user?.amount = first.amount
        }
    }
    
    func fetchDetailError() {
        DispatchQueue.main.async {
            self.notifySeverLeave()
            self.rtckit.leaveChannel()
            self.leaveRoom()
            self.isOwner ? self.ownerBack():self.backAction()
        }
    }

    func requestRankList() {
        ChatRoomServiceImp.getSharedInstance().fetchGiftContribute { error, users in
            if error == nil, users != nil {
                let info = self.roomInfo
                info?.room?.ranking_list = users
                self.headerView.updateHeader(with: info?.room)
            }
        }
    }

    func layoutUI() {
        SwiftyFitsize.reference(width: 375, iPadFitMultiple: 0.6)

        let bgImgView = UIImageView()
        bgImgView.image = UIImage("lbg")
        view.addSubview(bgImgView)

        headerView = AgoraChatRoomHeaderView()
        headerView.completeBlock = { [weak self] action in
            self?.didHeaderAction(with: action, destroyed: false)
        }
        view.addSubview(headerView)

        sRtcView = AgoraChatRoom3DRtcView()
        view.addSubview(sRtcView)

        rtcView = AgoraChatRoomNormalRtcView()
        rtcView.isOwner = isOwner
        rtcView.clickBlock = { [weak self] type, tag in
            self?.didRtcAction(with: type, tag: tag)
        }
        view.addSubview(rtcView)

        if let entity = roomInfo?.room {
            sRtcView.isHidden = entity.type == 0
            rtcView.isHidden = entity.type == 1
            headerView.updateHeader(with: entity)
        }

        bgImgView.snp.makeConstraints { make in
            make.left.right.top.bottom.equalTo(self.view)
        }

        let isHairScreen = SwiftyFitsize.isFullScreen
        headerView.snp.makeConstraints { make in
            make.left.top.right.equalTo(self.view)
            make.height.equalTo(isHairScreen ? 140~ : 140~ - 25)
        }

        sRtcView.snp.makeConstraints { make in
            make.top.equalTo(self.headerView.snp.bottom)
            make.left.right.equalTo(self.view)
            make.bottom.equalTo(self.view.snp.bottom).offset(isHairScreen ? -84 : -50)
        }

        rtcView.snp.makeConstraints { make in
            make.top.equalTo(self.headerView.snp.bottom)
            make.left.right.equalTo(self.view)
            make.height.equalTo(240~)
        }
        if roomInfo?.room?.type ?? 0 == 1 {
            view.addSubViews([chatBar])
            inputBar.isHidden = true
        } else {
            let pan = UIPanGestureRecognizer(target: self, action: #selector(resignKeyboard))
            pan.minimumNumberOfTouches = 1
            rtcView.addGestureRecognizer(pan)
            view.addSubViews([chatView, giftList(), chatBar, inputBar])
            inputBar.isHidden = true
        }
        chatView.messages?.append(startMessage())
    }


    func didHeaderAction(with action: HEADER_ACTION, destroyed: Bool) {
        if action == .back || action == .popBack {
            if isOwner && action != .popBack {
                if destroyed != true {
                    showEndLive()
                } else {
                    notifySeverLeave()
                    rtckit.leaveChannel()
                    ownerBack()
                }
            } else {
                notifySeverLeave()
                rtckit.leaveChannel()
                self.leaveRoom()
                backAction()
            }
        } else if action == .notice {
            showNoticeView(with: isOwner ? .owner : .audience)
        } else if action == .rank {
            // 展示土豪榜
            showUsers()
        } else if action == .soundClick {
            showSoundView()
        }
    }

    func didRtcAction(with type: AgoraChatRoomBaseUserCellType, tag: Int) {
        let index: Int = tag - 200
        guard let mic: VRRoomMic = ChatRoomServiceImp.getSharedInstance().mics[safe:index] else { return }
        if index == 6 { // 操作机器人
            if roomInfo?.room?.use_robot == false {
                showActiveAlienView(true)
            }
        } else {
            if isOwner {
                if index == 0 {
                    showMuteView(with: index)
                } else {
                    showApplyAlert(index)
                }
            } else {
                /*
                 1.如果当前麦位有用户，普通人只能操作自己
                 2.如果麦位没人 需要先判端是否是换麦还是申请上卖
                 */
                if let _ = mic.member {
                    if local_index == index {
                        showMuteView(with: index)
                    }
                } else {
                    if local_index != nil {
                        Throttler.throttle(delay: .seconds(1)) {
                            DispatchQueue.main.async {
                                self.changeMic(from: self.local_index!, to: tag - 200)
                            }
                        }
                    } else {
                        userApplyAlert(tag - 200)
                    }
                }
            }
        }
    }

    func notifySeverLeave() {
        guard let roomId = roomInfo?.room?.room_id else { return }
        if self.local_index == nil {
            ChatRoomServiceImp.getSharedInstance().leaveRoom(roomId) { error, flag in }
        } else {
            ChatRoomServiceImp.getSharedInstance().leaveMic(mic_index: self.local_index!) { error, result in
                ChatRoomServiceImp.getSharedInstance().leaveRoom(roomId) { error, flag in }
            }
        }

    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        inputBar.hiddenInputBar()
        if isShowPreSentView {
            UIView.animate(withDuration: 0.5, animations: {
                self.preView.frame = CGRect(x: 0, y: ScreenHeight, width: ScreenWidth, height: 450~)
            }) { _ in
                if self.preView == nil {return}
                self.preView.removeFromSuperview()
                self.preView = nil
                self.sRtcView.isUserInteractionEnabled = true
                self.rtcView.isUserInteractionEnabled = true
                self.headerView.isUserInteractionEnabled = true
                self.isShowPreSentView = false
            }
        }
    }

    func showNoticeView(with role: ROLE_TYPE) {
        let noticeView = VMNoticeView(frame: CGRect(x: 0, y: 0, width: ScreenWidth, height: 220))
        noticeView.roleType = role
        noticeView.noticeStr = roomInfo?.room?.announcement ?? ""
        noticeView.resBlock = { [weak self] flag, str in
            self?.dismiss(animated: true)
            guard let str = str else { return }
            // 修改群公告
            self?.updateNotice(with: str)
        }
        let noticeStr = roomInfo?.room?.announcement ?? ""
        noticeView.noticeStr = noticeStr
        let vc = VoiceRoomAlertViewController(compent: PresentedViewComponent(contentSize: CGSize(width: ScreenWidth, height: 220)), custom: noticeView)
        presentViewController(vc)
    }

    func showSoundView() {
        let soundView = VMSoundView(frame: CGRect(x: 0, y: 0, width: ScreenWidth, height: 180 + getDetailTextHeight(roomInfo?.room?.sound_effect ?? 1)), soundEffect: roomInfo?.room?.sound_effect ?? 1)
        let vc = VoiceRoomAlertViewController(compent: PresentedViewComponent(contentSize: CGSize(width: ScreenWidth, height: 180 + getDetailTextHeight(roomInfo?.room?.sound_effect ?? 1))), custom: soundView)
        presentViewController(vc)
    }

    func showActiveAlienView(_ active: Bool) {
        if !isOwner {
            view.makeToast("Host Bot".localized())
            return
        }
        let confirmView = VMConfirmView(frame: CGRect(x: 0, y: 0, width: ScreenWidth - 40~, height: 220~), type: .addbot)
        var compent = PresentedViewComponent(contentSize: CGSize(width: ScreenWidth - 40~, height: 220~))
        compent.destination = .center
        let vc = VoiceRoomAlertViewController(compent: compent, custom: confirmView)
        confirmView.resBlock = { [weak self] flag in
            self?.dismiss(animated: true)
            if flag == false { return }
            self?.activeAlien(active)
        }
        presentViewController(vc)
    }

    func activeAlien(_ flag: Bool) {
        if isOwner == false {
            view.makeToast("Host Bot".localized())
            return
        }
        guard let mic: VRRoomMic = roomInfo?.mic_info![6] else { return }
        ChatRoomServiceImp.getSharedInstance().enableRobot(enable: flag) { error in
            if error == nil {
                if self.alienCanPlay {
                    self.rtckit.adjustAudioMixingVolume(with: 50)
                    self.rtckit.playMusic(with: .alien)
                    self.alienCanPlay = false
                }

                let mic_info = mic
                mic_info.status = flag == true ? 5 : -2
                self.roomInfo?.room?.use_robot = flag
                self.roomInfo?.mic_info![6] = mic_info
                self.rtcView.updateAlien(mic_info.status)
            } else {
                print("激活机器人失败")
            }
        }
    }

    // announcement
    func updateNotice(with str: String) {
        ChatRoomServiceImp.getSharedInstance().updateAnnouncement(content: str) { result in
            if result {
                // 如果返回的结果为true 表示上麦成功
                self.view.makeToast("Notice Posted".localized())
                self.roomInfo?.room?.announcement = str
            } else {
                self.view.makeToast("Post Failed".localized())
            }
        }
    }

    func updateVolume(_ Vol: Int) {
        if isOwner == false { return }
        ChatRoomServiceImp.getSharedInstance().updateRobotVolume(value: Vol) { error in
            if error == nil {
                // 如果返回的结果为true 表示上麦成功
                guard let room = self.roomInfo?.room else { return }
                let newRoom = room
                newRoom.robot_volume = UInt(Vol)
                self.roomInfo?.room = newRoom
                self.rtckit.adjustAudioMixingVolume(with: Vol)
            }
        }
    }

    func charBarEvents() {
        chatBar.raiseKeyboard = { [weak self] in
            self?.inputBar.isHidden = false
            self?.inputBar.inputField.becomeFirstResponder()
        }
        inputBar.sendClosure = { [weak self] in
            self?.sendTextMessage(text: $0)
        }
        chatBar.events = { [weak self] in
            guard let self = self else { return }
            switch $0 {
            case .eq: self.showEQView()
            case .mic: self.changeMicState()
            case .gift: self.showGiftAlert()
            case .handsUp: self.changeHandsUpState()
            default: break
            }
        }
    }

    
    func showEndLive() {
        var compent = PresentedViewComponent(contentSize: CGSize(width: ScreenWidth - 70, height: 190))
        compent.destination = .center
        inputBar.hiddenInputBar()
        let micAlert = VoiceRoomEndLiveAlert(frame: CGRect(x: 0, y: 0, width: ScreenWidth - 70, height: 190), title: LanguageManager.localValue(key: "End Live"), content: LanguageManager.localValue(key: "The room will close after you leave."), cancel: LanguageManager.localValue(key: "Cancel"), confirm: LanguageManager.localValue(key: "Confirm")).cornerRadius(16).backgroundColor(.white)
        let vc = VoiceRoomAlertViewController(compent: compent, custom: micAlert)
        micAlert.actionEvents = { [weak self] in
            vc.dismiss(animated: true)
            if $0 != 30 {
                self?.notifySeverLeave()
                self?.rtckit.leaveChannel()
                // giveupStage()
                self?.ownerBack()
            }
        }
        presentViewController(vc)
    }

    private func ownerBack() {
        self.leaveRoom()
        if let vc = navigationController?.viewControllers.filter({ $0 is VRRoomsViewController
        }).first {
            navigationController?.popToViewController(vc, animated: true)
        }
    }

    func showInviteMicAlert() {
        inputBar.hiddenInputBar()
        var compent = PresentedViewComponent(contentSize: CGSize(width: ScreenWidth - 75, height: 200))
        compent.destination = .center
        let micAlert = VoiceRoomApplyAlert(frame: CGRect(x: 0, y: 0, width: ScreenWidth - 75, height: 200), content: "Anchor Invited You On-Stage", cancel: "Decline", confirm: "Accept", position: .center).cornerRadius(16).backgroundColor(.white)
        let vc = VoiceRoomAlertViewController(compent: compent, custom: micAlert)
        micAlert.actionEvents = { [weak self] in
            if $0 == 30 {
                self?.refuse()
            } else {
                self?.agreeInvite()
            }
            vc.dismiss(animated: true)
        }
        presentViewController(vc)
    }
    
    @objc func updateMicInfo(noti: Notification){
        guard let obj: VRRoomMic = noti.object as? VRRoomMic else {return}
        self.rtcView.updateUser(obj)
    }
    
    func textHeight(text: String, fontSize: CGFloat, width: CGFloat) -> CGFloat {
        return text.boundingRect(with: CGSize(width: width, height: CGFloat(MAXFLOAT)), options: .usesLineFragmentOrigin, attributes: [.font: UIFont.systemFont(ofSize: fontSize)], context: nil).size.height + 5
    }

    private func getDetailTextHeight(_ effect: Int) -> CGFloat{
        var detailStr: String = ""
        switch effect {
        case 1:
            detailStr = "This sound effect focuses on solving the voice call problem of the Social Chat scene, including noise cancellation and echo suppression of the anchor's voice. It can enable users of different network environments and models to enjoy ultra-low delay and clear and beautiful voice in multi-person chat.".localized()
        case 2:
            detailStr = "This sound effect focuses on solving all kinds of problems in the Karaoke scene of single-person or multi-person singing, including the balance processing of accompaniment and voice, the beautification of sound melody and voice line, the volume balance and real-time synchronization of multi-person chorus, etc. It can make the scenes of Karaoke more realistic and the singers' songs more beautiful.".localized()
        case 3:
            detailStr = "This sound effect focuses on solving all kinds of problems in the game scene where the anchor plays with him, including the collaborative reverberation processing of voice and game sound, the melody of sound and the beautification of sound lines. It can make the voice of the accompanying anchor more attractive and ensure the scene feeling of the game voice. ".localized()
        default:
            detailStr = "This sound effect focuses on solving the problems of poor sound quality of mono anchors and compatibility with mainstream external sound cards. The sound network stereo collection and high sound quality technology can greatly improve the sound quality of anchors using sound cards and enhance the attraction of live broadcasting rooms. At present, it has been adapted to mainstream sound cards in the market. ".localized()
        }
        return textHeight(text: detailStr, fontSize: 13, width: self.view.bounds.size.width - 40~)
    }
}

// MARK: - SVGAPlayerDelegate

extension VoiceRoomViewController: SVGAPlayerDelegate {
    func svgaPlayerDidFinishedAnimation(_ player: SVGAPlayer!) {
        let animation = view.viewWithTag(199)
        UIView.animate(withDuration: 0.3) {
            animation?.alpha = 0
        } completion: { finished in
            if finished { animation?.removeFromSuperview() }
        }
    }
}

// MARK: - ASManagerDelegate

extension VoiceRoomViewController: VMManagerDelegate {
    func didRtcLocalUserJoinedOfUid(uid: UInt) {
        
    }

    func didRtcRemoteUserJoinedOfUid(uid: UInt) {
        
    }

    func didRtcUserOfflineOfUid(uid: UInt) {}

    func reportAlien(with type: ALIEN_TYPE, musicType: VMMUSIC_TYPE) {
        rtcView.updateAlienMic(type)
    }

    func reportAudioVolumeIndicationOfSpeakers(speakers: [AgoraRtcAudioVolumeInfo]) {
        guard let micinfo = roomInfo?.mic_info else { return }
        for speaker in speakers {
            for mic in micinfo where mic.member != nil{
                let user = mic.member
                guard let rtcUid = Int(user?.rtc_uid ?? "0") else { return }
                if rtcUid == speaker.uid {
                    rtcView.updateVolume(with: mic.mic_index, vol: Int(speaker.volume))
                    break
                }
            }
        }
    }
}
