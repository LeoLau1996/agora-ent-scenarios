//
//  KTVPlayerApi.h
//  AgoraEntScenarios
//
//  Created by wushengtao on 2023/2/20.
//

#import <Foundation/Foundation.h>
@import AgoraRtcKit;

NS_ASSUME_NONNULL_BEGIN

@class KTVPlayerApi;
@class KTVSongConfiguration;
@protocol KTVApiDelegate <NSObject>

- (void)controller:(KTVPlayerApi*)controller song:(NSInteger)songCode didChangedToState:(AgoraMediaPlayerState)state local:(BOOL)local;
- (void)controller:(KTVPlayerApi*)controller song:(NSInteger)songCode config:(KTVSongConfiguration*)config didChangedToPosition:(NSInteger)position local:(BOOL)local;

@end

typedef void (^sendStreamSuccess)(BOOL ifSuccess);
typedef enum : NSUInteger {
    KTVSongTypeUnknown = 0,
    KTVSongTypeSolo,
    KTVSongTypeChorus
} KTVSongType;
typedef enum : NSUInteger {
    KTVSingRoleUnknown = 0,
    KTVSingRoleMainSinger,
    KTVSingRoleCoSinger,
    KTVSingRoleAudience
} KTVSingRole;
typedef enum : NSUInteger {
    KTVPlayerTrackOrigin = 0,
    KTVPlayerTrackAcc = 1
} KTVPlayerTrackMode;
typedef enum : NSUInteger {
    KTVLoadSongStateOK,
    KTVLoadSongStateInProgress,
    KTVLoadSongStateNoLyricUrl,
    KTVLoadSongStatePreloadFail,
    KTVLoadSongStateIdle
} KTVLoadSongState;

@interface KTVSongConfiguration : NSObject

@property(nonatomic, assign)KTVSongType type;
@property(nonatomic, assign)KTVSingRole role;
@property(nonatomic, assign)NSInteger songCode;
@property(nonatomic, assign)NSInteger mainSingerUid;
@property(nonatomic, assign)NSInteger coSingerUid;

+(KTVSongConfiguration*)configWithSongCode:(NSInteger)songCode;

@end

@interface KTVPlayerApi : NSObject
<
AgoraRtcMediaPlayerDelegate,
AgoraRtcEngineDelegate,
AgoraAudioFrameDelegate
>

@property(nonatomic, weak)AgoraRtcEngineKit* engine;
@property(nonatomic, weak)AgoraMusicContentCenter* musicCenter;
@property(nonatomic, weak)id<AgoraMusicPlayerProtocol> rtcMediaPlayer;
@property (nonatomic, strong, nullable) AgoraRtcConnection* subChorusConnection;
@property (atomic, assign) BOOL pushDirectAudioEnable;
@property (nonatomic, strong) NSString* channelName;
@property (nonatomic, assign) NSInteger localPlayerPosition;
@property (nonatomic, assign) NSInteger remotePlayerPosition;
@property (nonatomic, assign) NSInteger remotePlayerDuration;
@property (nonatomic, assign) NSInteger audioPlayoutDelay;
@property (nonatomic, assign) NSInteger dataStreamId;
@property (nonatomic, strong, nullable) KTVSongConfiguration* config;

@property (nonatomic, assign) NSInteger playerDuration;

@property (nonatomic, assign) int playoutVolume;
@property (nonatomic, assign) int publishSignalVolume;
@property (nonatomic, assign) int chorusRemoteUserVolume;

@property (nonatomic, assign) AgoraMediaPlayerState playerState;

@property(nonatomic, weak)id<KTVApiDelegate> delegate;


-(id)initWithRtcEngine:(AgoraRtcEngineKit *)engine
               channel:(NSString*)channelName
                player:(nonnull id<AgoraMusicPlayerProtocol>)rtcMediaPlayer
          dataStreamId:(NSInteger)streamId
              delegate:(id<KTVApiDelegate>)delegate;
-(void)playSong:(NSInteger)songCode;
-(void)stopSong;
-(void)resumePlay;
-(void)pausePlay;
-(void)selectTrackMode:(KTVPlayerTrackMode)mode;

- (void)adjustPlayoutVolume:(int)volume;
- (void)adjustPublishSignalVolume:(int)volume;

- (void)adjustChorusRemoteUserPlaybackVoulme:(int)volume;

-(NSTimeInterval)getTotalTime;
- (NSTimeInterval)getPlayerCurrentTime;
- (NSInteger)playerDuration;

- (void)mainRtcEngine:(AgoraRtcEngineKit *)engine didJoinedOfUid:(NSUInteger)uid elapsed:(NSInteger)elapsed;
- (void)mainRtcEngine:(AgoraRtcEngineKit *)engine
reportAudioVolumeIndicationOfSpeakers:(NSArray<AgoraRtcAudioVolumeInfo *> *)speakers
      totalVolume:(NSInteger)totalVolume;
- (void)mainRtcEngine:(AgoraRtcEngineKit * _Nonnull)engine
receiveStreamMessageFromUid:(NSUInteger)uid
         streamId:(NSInteger)streamId
             data:(NSData * _Nonnull)data;

- (void)mainRtcEngine:(AgoraRtcEngineKit *)engine localAudioStats:(AgoraRtcLocalAudioStats *)stats;
@end

NS_ASSUME_NONNULL_END
