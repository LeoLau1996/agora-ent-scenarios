//
//  KTVPlayerApi.m
//  AgoraEntScenarios
//
//  Created by wushengtao on 2023/2/20.
//

#import "KTVPlayerApi.h"
#import "KTVMacro.h"
#import "AppContext+KTV.h"
#import "VLGlobalHelper.h"
#import "VLMacroDefine.h"

time_t uptime(void) {
  if (@available(iOS 10.0, *)) {
    return clock_gettime_nsec_np(CLOCK_MONOTONIC_RAW) / 1000000;
  } else {
    return CFAbsoluteTimeGetCurrent() * 1000;
  }
}

@implementation KTVPlayerApi

-(id)initWithRtcEngine:(AgoraRtcEngineKit *)engine
               channel:(NSString*)channelName
                player:(nonnull id<AgoraMusicPlayerProtocol>)rtcMediaPlayer
          dataStreamId:(NSInteger)streamId
              delegate:(nonnull id<KTVApiDelegate>)delegate
{
    if (self = [super init]) {
        self.delegate = delegate;
        self.chorusRemoteUserVolume = 15;
        
        // 调节本地播放音量。0-100
        [self adjustPlayoutVolume:100];
        // 调节远端用户听到的音量。0-400
        [self adjustPublishSignalVolume:100];
        
        self.engine = engine;
        self.channelName = channelName;
        self.dataStreamId = streamId;
        self.rtcMediaPlayer = rtcMediaPlayer;
        
        //为了 尽量不超时 设置了1000ms
        [self.engine setParameters:@"{\"rtc.ntp_delay_drop_threshold\":1000}"];
        [self.engine setParameters:@"{\"che.audio.agc.enable\": true}"];
        [self.engine setParameters:@"{\"rtc.video.enable_sync_render_ntp\": true}"];
        [self.engine setParameters:@"{\"rtc.net.maxS2LDelay\": 800}"];
//        [self.engine setParameters:@"{\"che.audio.custom_bitrate\":128000}"];
//        [self.engine setParameters:@"{\"che.audio.custom_payload_type\":78}"];
        
//        [self.rtcMediaPlayer setPlayerOption:@"play_pos_change_callback" value:100];
        
        [[AppContext shared] registerPlayerEventDelegate:self];
        
//        [self.engine setDirectExternalAudioSource:YES];
//        [self.engine setAudioFrameDelegate:self];
        
    }
    return self;
}

-(void)dealloc
{
    [[AppContext shared] unregisterPlayerEventDelegate:self];
    [self.engine setAudioFrameDelegate:nil];
}

-(void)playSong:(NSInteger)songCode
{
    KTVSingRole role = self.config.role;
    KTVSongType type = self.config.type;
    if(type == KTVSongTypeSolo) {
        if(role == KTVSingRoleMainSinger) {
            [self.rtcMediaPlayer openMediaWithSongCode:songCode startPos:0];
            AgoraRtcChannelMediaOptions* options = [AgoraRtcChannelMediaOptions new];
            options.autoSubscribeAudio = YES;
            options.autoSubscribeVideo = YES;
            options.publishMediaPlayerId = [self.rtcMediaPlayer getMediaPlayerId];
            options.publishMediaPlayerAudioTrack = YES;
            [self.engine updateChannelWithMediaOptions:options];
        } else {
            AgoraRtcChannelMediaOptions* options = [AgoraRtcChannelMediaOptions new];
            options.autoSubscribeAudio = YES;
            options.autoSubscribeVideo = YES;
            options.publishMediaPlayerAudioTrack = NO;
            [self.engine updateChannelWithMediaOptions:options];
        }
    } else {
        if(role == KTVSingRoleMainSinger) {
            AgoraRtcChannelMediaOptions* options = [AgoraRtcChannelMediaOptions new];
            options.autoSubscribeAudio = YES;
            options.autoSubscribeVideo = YES;
            options.publishMediaPlayerId = [self.rtcMediaPlayer getMediaPlayerId];
            options.publishMediaPlayerAudioTrack = YES;
            options.publishMicrophoneTrack = YES;
            options.enableAudioRecordingOrPlayout = YES;
            [self.engine updateChannelWithMediaOptions:options];
            [self joinChorus2ndChannel];
            //openMediaWithSongCode必须在切换setAudioScenario之后，否则会造成mpk播放对齐不准的问题
            [self.rtcMediaPlayer openMediaWithSongCode:songCode startPos:0];
            [self.rtcMediaPlayer adjustPlayoutVolume:50];
            [self.rtcMediaPlayer adjustPublishSignalVolume:50];
        } else if(role == KTVSingRoleCoSinger) {
            AgoraRtcChannelMediaOptions* options = [AgoraRtcChannelMediaOptions new];
            options.autoSubscribeAudio = YES;
            options.autoSubscribeVideo = YES;
            //co singer do not publish media player
            options.publishMicrophoneTrack = YES;
            options.publishMediaPlayerAudioTrack = NO;
            [self.engine updateChannelWithMediaOptions:options];
            [self joinChorus2ndChannel];
            
            //mute main Singer player audio
            [self.engine muteRemoteAudioStream:self.config.mainSingerUid mute:YES];
            //openMediaWithSongCode必须在切换setAudioScenario之后，否则会造成mpk播放对齐不准的问题
            [self.rtcMediaPlayer openMediaWithSongCode:songCode startPos:0];
            [self.rtcMediaPlayer adjustPlayoutVolume:50];
            [self.rtcMediaPlayer adjustPublishSignalVolume:50];
        } else {
            AgoraRtcChannelMediaOptions* options = [AgoraRtcChannelMediaOptions new];
            options.autoSubscribeAudio = YES;
            options.autoSubscribeVideo = YES;
            options.publishMediaPlayerAudioTrack = NO;
            [self.engine updateChannelWithMediaOptions:options];
        }
    }
}

-(void)resumePlay
{
    if ([self.rtcMediaPlayer getPlayerState] == AgoraMediaPlayerStatePaused) {
        [self.rtcMediaPlayer resume];
    } else {
        [self.rtcMediaPlayer play];
    }
}

-(void)pausePlay
{
    [self.rtcMediaPlayer pause];
}

-(void)stopSong
{
    KTVLogInfo(@"stop song");
    [self.rtcMediaPlayer stop];
    if(self.config.type == KTVSongTypeChorus) {
        [self leaveChorus2ndChannel];
    }
    self.config = nil;
    
    [self.engine setAudioScenario:AgoraAudioScenarioGameStreaming];
    [self.engine setParameters: @"{\"che.audio.enable.md \": false}"];
}

-(void)selectTrackMode:(KTVPlayerTrackMode)mode
{
    [self.rtcMediaPlayer selectAudioTrack:mode == KTVPlayerTrackOrigin ? 0 : 1];
//    [self syncTrackMode:mode];
}

- (void)adjustPlayoutVolume:(int)volume {
    self.playoutVolume = volume;
    [self.rtcMediaPlayer adjustPlayoutVolume:volume];
}

- (void)adjustPublishSignalVolume:(int)volume {
    self.publishSignalVolume = volume;
    [self.rtcMediaPlayer adjustPublishSignalVolume:volume];
}

- (void)adjustChorusRemoteUserPlaybackVoulme:(int)volume {
    self.chorusRemoteUserVolume = volume;
    
    [self updateRemotePlayBackVolumeIfNeed];
}

#pragma mark private
- (void)updateCosingerPlayerStatusIfNeed {
    if (self.config.type == KTVSongTypeChorus && self.config.role == KTVSingRoleCoSinger) {
        switch (self.playerState) {
            case AgoraMediaPlayerStatePaused:
                [self pausePlay];
                break;
            case AgoraMediaPlayerStateStopped:
//                case AgoraMediaPlayerStatePlayBackAllLoopsCompleted:
                [self stopSong];
                break;
            case AgoraMediaPlayerStatePlaying:
                [self resumePlay];
                break;
            default:
                break;
        }
    }
}

- (void)updateRemotePlayBackVolumeIfNeed {
    if (self.config.type != KTVSongTypeChorus || self.config.role == KTVSingRoleAudience) {
        KTVLogInfo(@"updateRemotePlayBackVolumeIfNeed: %d, role: %ld", 100, self.config.role);
        [self.engine adjustPlaybackSignalVolume:100];
        return;
    }
    
    /*
     合唱的时候，建议把接受远端人声的音量降低（建议是25或者50，后续这个值可以根据 端到端延迟来自动确认，比如150ms内可以50。 否则音量25），相应的api是adjustUserPlaybackSignalVolume(remoteUid, volume)；一是可以解决在aec nlp等级降低的情况下出现小音量回声问题，二是可以减小远端固有延迟的合唱者声音给本地k歌带来的影响
     */
    int volume = self.playerState == AgoraMediaPlayerStatePlaying ? self.chorusRemoteUserVolume : 100;
    KTVLogInfo(@"updateRemotePlayBackVolumeIfNeed: %d, role: %ld", volume, self.config.role);
    if (self.config.role == KTVSingRoleMainSinger) {
        [self.engine adjustPlaybackSignalVolume:volume];
    } else if (self.config.role == KTVSingRoleCoSinger) {
        [self.engine adjustPlaybackSignalVolume:volume];
//        if (self.subChorusConnection == nil) {
//            KTVLogWarn(@"updateRemotePlayBackVolumeIfNeed fail, connection = nil");
//            return;
//        }
//        int uid = [VLLoginModel mediaPlayerUidWithUid:[NSString stringWithFormat:@"%ld", self.config.mainSingerUid]];
//        [self.engine adjustUserPlaybackSignalVolumeEx:uid volume:volume connection:self.subChorusConnection];
    }
}

- (NSInteger)getNtpTimeInMs {
    NSInteger localNtpTime = [self.engine getNtpTimeInMs];
    if (localNtpTime != 0) {
        localNtpTime -= 2208988800 * 1000;
    } else {
        localNtpTime = round([[NSDate date] timeIntervalSince1970] * 1000.0);
    }
    return localNtpTime;
}

#pragma mark - rtc delgate proxies
- (void)mainRtcEngine:(AgoraRtcEngineKit *)engine didJoinedOfUid:(NSUInteger)uid elapsed:(NSInteger)elapsed
{
    KTVLogInfo(@"didJoinedOfUid: %ld", uid);
//    if(self.config.type == KTVSongTypeChorus &&
//       self.config.role == KTVSingRoleCoSinger &&
//       uid == self.config.mainSingerUid) {
//        [self.engine muteRemoteAudioStream:uid mute:YES];
//    }
}

- (void)mainRtcEngine:(AgoraRtcEngineKit *)engine receiveStreamMessageFromUid:(NSUInteger)uid streamId:(NSInteger)streamId data:(NSData *)data
{
    NSDictionary *dict = [VLGlobalHelper dictionaryForJsonData:data];
    if (self.config.role == KTVSingRoleMainSinger) {
        KTVLogWarn(@"recv %@ cmd invalid", dict[@"cmd"]);
        return;
    }
    if ([dict[@"cmd"] isEqualToString:@"setLrcTime"]) {  //同步歌词
        NSInteger position = [dict[@"time"] integerValue];
        NSInteger duration = [dict[@"duration"] integerValue];
        NSInteger remoteNtp = [dict[@"ntp"] integerValue];
        AgoraMediaPlayerState state = [dict[@"playerState"] integerValue];
        if (self.playerState != state) {
            KTVLogInfo(@"recv state with setLrcTime : %ld", (long)state);
            self.playerState = state;
            [self updateCosingerPlayerStatusIfNeed];
            
            [self.delegate controller:self song:self.config.songCode didChangedToState:state local:NO];
        }
        
        self.remotePlayerPosition = uptime() - position;
        self.remotePlayerDuration = duration;
//        KTVLogInfo(@"setLrcTime: %ld / %ld", self.remotePlayerPosition, self.remotePlayerDuration);
        if(self.config.type == KTVSongTypeChorus && self.config.role == KTVSingRoleCoSinger) {
            if([self.rtcMediaPlayer getPlayerState] == AgoraMediaPlayerStatePlaying) {
                NSInteger localNtpTime = [self getNtpTimeInMs];
                NSInteger localPosition = uptime() - self.localPlayerPosition;
//                NSInteger localPosition2 = [self.rtcMediaPlayer getPosition];
                NSInteger expectPosition = position + localNtpTime - remoteNtp + self.audioPlayoutDelay;
                NSInteger threshold = expectPosition - localPosition;
                if(labs(threshold) > 40) {
                    KTVLogInfo(@"threshold: %ld  expectPosition: %ld  position: %ld, localNtpTime: %ld, remoteNtp: %ld, audioPlayoutDelay: %ld, localPosition: %ld", threshold, expectPosition, position, localNtpTime, remoteNtp, self.audioPlayoutDelay, localPosition);
                    [self.rtcMediaPlayer seekToPosition:expectPosition];
                }
            }
        }
        [self.delegate controller:self song:self.config.songCode config:self.config didChangedToPosition:position local:NO];
    } else if([dict[@"cmd"] isEqualToString:@"PlayerState"]) {
        AgoraMediaPlayerState state = [dict[@"state"] integerValue];
        KTVLogInfo(@"recv state with PlayerState: %ld, %@ %@", (long)state, dict[@"userId"], VLUserCenter.user.id);
        self.playerState = state;
        [self updateCosingerPlayerStatusIfNeed];
        
        [self.delegate controller:self song:self.config.songCode didChangedToState:state local:NO];
    } else if([dict[@"cmd"] isEqualToString:@"TrackMode"]) {
        
    }
}

- (void)mainRtcEngine:(AgoraRtcEngineKit *)engine reportAudioVolumeIndicationOfSpeakers:(NSArray<AgoraRtcAudioVolumeInfo *> *)speakers totalVolume:(NSInteger)totalVolume
{
    if (self.config.role != KTVSingRoleMainSinger
        || self.playerState != AgoraMediaPlayerStatePlaying) {
        return;
    }
    
    double pitch = speakers.firstObject.voicePitch;
    NSDictionary *dict = @{
        @"cmd":@"setVoicePitch",
        @"pitch":@(pitch),
        @"time": @([self getPlayerCurrentTime])
    };
    [self sendStreamMessageWithDict:dict success:^(BOOL ifSuccess) {
    }];
}


- (void)mainRtcEngine:(AgoraRtcEngineKit *)engine localAudioStats:(AgoraRtcLocalAudioStats *)stats {
    self.audioPlayoutDelay = stats.audioPlayoutDelay;
}

#pragma mark - setter
- (void)setPlayerState:(AgoraMediaPlayerState)playerState {
    _playerState = playerState;
    [self updateRemotePlayBackVolumeIfNeed];
}

#pragma mark - AgoraAudioFrameDelegate
- (BOOL)onRecordAudioFrame:(AgoraAudioFrame *)frame channelId:(NSString *)channelId
{
//    KTVLogInfo(@"onRecordAudioFrame: %@", frame);
    if(self.pushDirectAudioEnable) {
        [self.engine pushDirectAudioFrameRawData:frame.buffer samples:frame.channels*frame.samplesPerChannel sampleRate:frame.samplesPerSec channels:frame.channels];
    }
    return true;
}

- (AgoraAudioFramePosition)getObservedAudioFramePosition {
    return AgoraAudioFramePositionRecord;
}

- (AgoraAudioParams*)getRecordAudioParams {
    AgoraAudioParams* params = [AgoraAudioParams new];
    params.channel = 2;
    params.samplesPerCall = 960;
    params.sampleRate = 48000;
    params.mode = AgoraAudioRawFrameOperationModeReadOnly;
    return params;
}

#pragma mark - AgoraRtcMediaPlayerDelegate
-(void)AgoraRtcMediaPlayer:(id<AgoraRtcMediaPlayerProtocol>)playerKit didChangedToState:(AgoraMediaPlayerState)state error:(AgoraMediaPlayerError)error
{
    if (state == AgoraMediaPlayerStateOpenCompleted) {
        self.localPlayerPosition = uptime();
        self.playerDuration = 0;
        if (self.config.role == KTVSingRoleMainSinger) {
            //主唱播放，通过同步消息“setLrcTime”通知伴唱play
            [playerKit play];
        }
    } else if (state == AgoraMediaPlayerStateStopped) {
        self.localPlayerPosition = uptime();
        self.playerDuration = 0;
        self.remotePlayerPosition = uptime();
    } else if (state == AgoraMediaPlayerStatePlaying) {
        self.localPlayerPosition = uptime() - [self.rtcMediaPlayer getPosition];
        self.playerDuration = 0;
        self.remotePlayerPosition = uptime();
    }
    if (self.config.role == KTVSingRoleMainSinger) {
        [self syncPlayState:state];
    }
    self.playerState = state;
    KTVLogInfo(@"recv state with player callback : %ld", (long)state);
    [self.delegate controller:self song:self.config.songCode didChangedToState:state local:YES];
}

-(void)AgoraRtcMediaPlayer:(id<AgoraRtcMediaPlayerProtocol>)playerKit didChangedToPosition:(NSInteger)position
{
    self.localPlayerPosition = uptime() - position;
    
    if (self.config.role == KTVSingRoleMainSinger && position > self.audioPlayoutDelay) {
        //if i am main singer
        NSDictionary *dict = @{
            @"cmd":@"setLrcTime",
            @"duration":@(self.playerDuration),
            @"time":@(position - self.audioPlayoutDelay),   //不同机型delay不同，需要发送同步的时候减去发送机型的delay，在接收同步加上接收机型的delay
            @"ntp":@([self getNtpTimeInMs]),
            @"playerState":@(self.playerState)
        };
        [self sendStreamMessageWithDict:dict success:nil];
    }
    
    [self.delegate controller:self song:self.config.songCode config:self.config didChangedToPosition:position local:YES];
}

#pragma mark - AgoraLrcViewDelegate
-(NSTimeInterval)getTotalTime {
    if (self.config.role == KTVSingRoleMainSinger) {
        NSTimeInterval time = self.playerDuration;
        return time;
    }
    return self.remotePlayerDuration;
}

- (NSTimeInterval)getPlayerCurrentTime {
    if (self.config.role == KTVSingRoleMainSinger || self.config.role == KTVSingRoleCoSinger) {
        NSTimeInterval time = uptime() - self.localPlayerPosition;
        return time;
    }
    
    return uptime() - self.remotePlayerPosition;
}

- (NSInteger)playerDuration {
    if (_playerDuration == 0) {
        //只在特殊情况(播放、暂停等)调用getDuration(会耗时)
        _playerDuration = [_rtcMediaPlayer getDuration];
    }
    
    return _playerDuration;
}

#pragma RTC delegate for chorus channel2
//-(void)rtcEngine:(AgoraRtcEngineKit *)engine didJoinChannel:(NSString *)channel withUid:(NSUInteger)uid elapsed:(NSInteger)elapsed
//{
//    KTVLogInfo(@"KTVAPI didJoinChannel: %ld, %@", uid, channel);
//    [self.engine setAudioScenario:AgoraAudioScenarioChorus];
//}

-(void)rtcEngine:(AgoraRtcEngineKit *)engine didLeaveChannelWithStats:(AgoraChannelStats *)stats
{
    [self.engine setAudioScenario:AgoraAudioScenarioGameStreaming];
    [self.engine setParameters: @"{\"che.audio.enable.md \": false}"];
}

#pragma private apis
//发送流消息
- (void)sendStreamMessageWithDict:(NSDictionary *)dict
                         success:(_Nullable sendStreamSuccess)success {
//    VLLog(@"sendStremMessageWithDict:::%@",dict);
    NSData *messageData = [VLGlobalHelper compactDictionaryToData:dict];
    
    int code = [self.engine sendStreamMessage:self.dataStreamId
                                         data:messageData];
    if (code == 0 && success) {
        success(YES);
    }
    if (code != 0) {
        KTVLogError(@"sendStreamMessage fail: %d\n",code);
    };
}

- (void)syncPlayState:(AgoraMediaPlayerState)state {
    NSDictionary *dict = @{
            @"cmd":@"PlayerState",
            @"userId": VLUserCenter.user.id,
            @"state": [NSString stringWithFormat:@"%ld", state]
    };
    [self sendStreamMessageWithDict:dict success:nil];
}

- (void)syncTrackMode:(KTVPlayerTrackMode)mode {
    NSDictionary *dict = @{
        @"cmd":@"TrackMode",
        @"value":[NSString stringWithFormat:@"%ld", mode]
    };
    [self sendStreamMessageWithDict:dict success:nil];
}


- (void)joinChorus2ndChannel
{
    if(self.subChorusConnection) {
        KTVLogWarn(@"joinChorus2ndChannel fail! rejoin!");
        return;
    }
    
    KTVSingRole role = self.config.role;
    AgoraRtcChannelMediaOptions* options = [AgoraRtcChannelMediaOptions new];
    // main singer do not subscribe 2nd channel
    // co singer auto sub
    options.autoSubscribeAudio = role == KTVSingRoleMainSinger ? NO : YES;
    options.autoSubscribeVideo = NO;
    options.publishMicrophoneTrack = NO;
    //co singer record & playout
    options.enableAudioRecordingOrPlayout = role == KTVSingRoleMainSinger ? NO : YES;
    options.clientRoleType = AgoraClientRoleBroadcaster;
    options.publishDirectCustomAudioTrack = role == KTVSingRoleMainSinger ? YES : NO;;
    
    AgoraRtcConnection* connection = [AgoraRtcConnection new];
    connection.channelId = [NSString stringWithFormat:@"%@_ex", self.channelName];
    connection.localUid = [VLLoginModel mediaPlayerUidWithUid:VLUserCenter.user.id];//VLUserCenter.user.agoraPlayerRTCUid;
    self.subChorusConnection = connection;
    
    KTVLogInfo(@"will joinChannelExByToken: channelId: %@, enableAudioRecordingOrPlayout: %d, role: %ld", connection.channelId, options.enableAudioRecordingOrPlayout, role);
    VL(weakSelf);
    [self.engine setDirectExternalAudioSource:YES];
    [self.engine setAudioFrameDelegate:self];
    [self.engine setAudioScenario:AgoraAudioScenarioChorus];
    int ret =
    [self.engine joinChannelExByToken:VLUserCenter.user.agoraPlayerRTCToken connection:connection delegate:self mediaOptions:options joinSuccess:^(NSString * _Nonnull channel, NSUInteger uid, NSInteger elapsed) {
        KTVLogInfo(@"joinChannelExByToken success: channel: %@, uid: %ld", channel, uid);
        
        [weakSelf.engine setParameters: @"{\"che.audio.enable.md \": false}"];
        if(weakSelf.config.type == KTVSongTypeChorus &&
           weakSelf.config.role == KTVSingRoleMainSinger) {
            //fix pushDirectAudioFrameRawData frozen
            weakSelf.pushDirectAudioEnable = YES;
        }
        
        [weakSelf updateRemotePlayBackVolumeIfNeed];
    }];
    if(ret != 0) {
        KTVLogError(@"joinChannelExByToken status: %d channelId: %@ uid: %ld, token:%@ ", ret, connection.channelId, connection.localUid, VLUserCenter.user.agoraPlayerRTCToken);
    }
}

- (void)leaveChorus2ndChannel
{
    if(self.subChorusConnection == nil) {
        KTVLogWarn(@"leaveChorus2ndChannel fail connection = nil");
        return;
    }
    
    [self.engine setDirectExternalAudioSource:NO];
    [self.engine setAudioFrameDelegate:nil];
    KTVSingRole role = self.config.role;
    if(role == KTVSingRoleMainSinger) {
        AgoraRtcChannelMediaOptions* options = [AgoraRtcChannelMediaOptions new];
        options.publishDirectCustomAudioTrack = NO;
        [self.engine updateChannelExWithMediaOptions:options connection:self.subChorusConnection];
        [self.engine leaveChannelEx:self.subChorusConnection leaveChannelBlock:nil];
    } else if(role == KTVSingRoleCoSinger) {
        [self.engine leaveChannelEx:self.subChorusConnection leaveChannelBlock:nil];
        [self.engine muteRemoteAudioStream:self.config.mainSingerUid mute:NO];
    }
    
    [self adjustPlayoutVolume:self.playoutVolume];
    [self adjustPublishSignalVolume:self.publishSignalVolume];
    self.pushDirectAudioEnable = NO;
    self.subChorusConnection = nil;
}


@end
