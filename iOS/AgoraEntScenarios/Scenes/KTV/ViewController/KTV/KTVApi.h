//
//  KTVSoloController.h
//  AgoraEntScenarios
//
//  Created by ZQZ on 2022/11/29.
//

#import <Foundation/Foundation.h>
#import <AgoraLyricsScore-Swift.h>
#import "KTVPlayerApi.h"
@import AgoraRtcKit;

NS_ASSUME_NONNULL_BEGIN



@interface KTVApi : NSObject

//@property(nonatomic, weak)id<KTVApiDelegate> delegate;
@property(nonatomic, weak)AgoraLrcScoreView* lrcView;

-(id)initWithRtcEngine:(AgoraRtcEngineKit *)engine channel:(NSString*)channelName musicCenter:(AgoraMusicContentCenter*)musicCenter player:(nonnull id<AgoraMusicPlayerProtocol>)rtcMediaPlayer dataStreamId:(NSInteger)streamId delegate:(id<KTVApiDelegate>)delegate;
-(void)loadSong:(NSInteger)songCode withConfig:(KTVSongConfiguration*)config withCallback:(void (^ _Nullable)(NSInteger songCode, NSString* lyricUrl, KTVSingRole role, KTVLoadSongState state))block;
-(void)playSong:(NSInteger)songCode;
-(void)stopSong;
-(void)resumePlay;
-(void)pausePlay;
-(void)selectTrackMode:(KTVPlayerTrackMode)mode;

- (void)adjustPlayoutVolume:(int)volume;
- (void)adjustPublishSignalVolume:(int)volume;

- (void)adjustChorusRemoteUserPlaybackVoulme:(int)volume;


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
