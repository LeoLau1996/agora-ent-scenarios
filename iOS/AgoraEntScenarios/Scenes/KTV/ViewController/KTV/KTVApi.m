//
//  KTVSoloController.m
//  AgoraEntScenarios
//
//  Created by ZQZ on 2022/11/29.
//

#import "KTVApi.h"
#import "VLMacroDefine.h"
#import "KTVMacro.h"
#import <AgoraLyricsScore-Swift.h>
#import "AppContext+KTV.h"
#import "VLGlobalHelper.h"

typedef void (^LyricCallback)(NSString* lyricUrl);
typedef void (^LoadMusicCallback)(AgoraMusicContentCenterPreloadStatus);

@implementation KTVSongConfiguration

+(KTVSongConfiguration*)configWithSongCode:(NSInteger)songCode
{
    KTVSongConfiguration* configs = [KTVSongConfiguration new];
    configs.songCode = songCode;
    return configs;
}

@end

@interface KTVApi ()<
    AgoraMusicContentCenterEventDelegate,
    AgoraLrcViewDelegate,
    AgoraLrcDownloadDelegate
>

@property (nonatomic, strong) KTVPlayerApi* playerApi;
@property (nonatomic, weak)AgoraMusicContentCenter* musicCenter;
@property (nonatomic, strong) NSMutableDictionary<NSString*, LyricCallback>* lyricCallbacks;
@property (nonatomic, strong) NSMutableDictionary<NSString*, LoadMusicCallback>* musicCallbacks;
@property (nonatomic, strong) NSMutableDictionary<NSString*, NSNumber*>* loadDict;
@property (nonatomic, strong) NSMutableDictionary<NSString*, NSString*>* lyricUrlDict;
@end

@implementation KTVApi

-(id)initWithRtcEngine:(AgoraRtcEngineKit *)engine channel:(NSString*)channelName musicCenter:(AgoraMusicContentCenter*)musicCenter player:(nonnull id<AgoraMusicPlayerProtocol>)rtcMediaPlayer dataStreamId:(NSInteger)streamId delegate:(nonnull id<KTVApiDelegate>)delegate
{
    if (self = [super init]) {
        _playerApi = [[KTVPlayerApi alloc] initWithRtcEngine:engine
                                                     channel:channelName
                                                      player:rtcMediaPlayer
                                                dataStreamId:streamId
                                                    delegate:delegate];
//        self.delegate = delegate;
        self.lyricCallbacks = [NSMutableDictionary dictionary];
        self.musicCallbacks = [NSMutableDictionary dictionary];
        self.loadDict = [NSMutableDictionary dictionary];
        self.lyricUrlDict = [NSMutableDictionary dictionary];
        
        // 调节本地播放音量。0-100
        [self adjustPlayoutVolume:100];
        // 调节远端用户听到的音量。0-400
        [self adjustPublishSignalVolume:100];
        
        self.musicCenter = musicCenter;
        
        [[AppContext shared] registerEventDelegate:self];
    }
    return self;
}

-(void)dealloc
{
    [self cancelAsyncTasks];
}

-(void)loadSong:(NSInteger)songCode withConfig:(nonnull KTVSongConfiguration *)config withCallback:(void (^ _Nullable)(NSInteger songCode, NSString* lyricUrl, KTVSingRole role, KTVLoadSongState state))block
{
    self.playerApi.config = config;
    KTVSingRole role = config.role;
    NSNumber* loadHistory = [self.loadDict objectForKey:[self songCodeString:songCode]];
    if(loadHistory) {
        KTVLoadSongState state = [loadHistory intValue];
        KTVLogInfo(@"song %ld load state exits %ld", songCode, state);
        if(state == KTVLoadSongStateOK) {
            VL(weakSelf);
            
            return [self setLrcLyric:[self cachedLyricUrl:songCode] withCallback:^(NSString *lyricUrl) {
                return block(songCode, [weakSelf cachedLyricUrl:songCode], role, state);
            }];
        } else if(state == KTVLoadSongStateInProgress) {
            //overwrite callback
            //TODO
            return;
        }
    }

    [self.loadDict setObject:[NSNumber numberWithInt:KTVLoadSongStateInProgress] forKey:[self songCodeString:songCode]];

    dispatch_group_t group = dispatch_group_create();
    __block KTVLoadSongState state = KTVLoadSongStateInProgress;
    
    VL(weakSelf);
    if(role == KTVSingRoleMainSinger) {
        dispatch_group_enter(group);
        dispatch_group_async(group, dispatch_get_main_queue(), ^{
            [weakSelf loadLyric:songCode withCallback:^(NSString *lyricUrl) {
                if (lyricUrl == nil) {
                    [weakSelf.loadDict removeObjectForKey:[weakSelf songCodeString:songCode]];
                    state = KTVLoadSongStateNoLyricUrl;
                    return dispatch_group_leave(group);
                }
                [weakSelf.lyricUrlDict setObject:lyricUrl forKey:[weakSelf songCodeString:songCode]];
                [weakSelf setLrcLyric:lyricUrl withCallback:^(NSString *lyricUrl) {
                    return dispatch_group_leave(group);
                }];
            }];
        });
        
        dispatch_group_enter(group);
        dispatch_group_async(group, dispatch_get_main_queue(), ^{
            [weakSelf loadMusic:songCode withCallback:^(AgoraMusicContentCenterPreloadStatus status){
                if (status != AgoraMusicContentCenterPreloadStatusOK) {
                    [weakSelf.loadDict removeObjectForKey:[weakSelf songCodeString:songCode]];
                    state = KTVLoadSongStatePreloadFail;
                    return dispatch_group_leave(group);
                }
                return dispatch_group_leave(group);
            }];
        });
    } else if(role == KTVSingRoleCoSinger) {
        dispatch_group_enter(group);
        dispatch_group_async(group, dispatch_get_main_queue(), ^{
            [weakSelf loadLyric:songCode withCallback:^(NSString *lyricUrl) {
                if (lyricUrl == nil) {
                    [weakSelf.loadDict removeObjectForKey:[weakSelf songCodeString:songCode]];
                    state = KTVLoadSongStateNoLyricUrl;
                    return dispatch_group_leave(group);
                }
                [weakSelf.lyricUrlDict setObject:lyricUrl forKey:[weakSelf songCodeString:songCode]];
                [weakSelf setLrcLyric:lyricUrl withCallback:^(NSString *lyricUrl) {
                    return dispatch_group_leave(group);
                }];
            }];
        });
        
        dispatch_group_enter(group);
        dispatch_group_async(group, dispatch_get_main_queue(), ^{
            [weakSelf loadMusic:songCode withCallback:^(AgoraMusicContentCenterPreloadStatus status){
                if (status != AgoraMusicContentCenterPreloadStatusOK) {
                    [weakSelf.loadDict removeObjectForKey:[weakSelf songCodeString:songCode]];
                    state = KTVLoadSongStatePreloadFail;
                    return dispatch_group_leave(group);
                }
                return dispatch_group_leave(group);
            }];
        });
    } else if(role == KTVSingRoleAudience) {
        dispatch_group_enter(group);
        dispatch_group_async(group, dispatch_get_main_queue(), ^{
            [weakSelf loadLyric:songCode withCallback:^(NSString *lyricUrl) {
                if (lyricUrl == nil) {
                    [weakSelf.loadDict removeObjectForKey:[weakSelf songCodeString:songCode]];
                    state = KTVLoadSongStateNoLyricUrl;
                    return dispatch_group_leave(group);
                }
                [weakSelf.lyricUrlDict setObject:lyricUrl forKey:[weakSelf songCodeString:songCode]];
                [weakSelf setLrcLyric:lyricUrl withCallback:^(NSString *lyricUrl) {
                    return dispatch_group_leave(group);
                }];
            }];
        });
    }
    
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if(state == KTVLoadSongStateInProgress) {
            [weakSelf.loadDict setObject:[NSNumber numberWithInt:KTVLoadSongStateOK] forKey:[weakSelf songCodeString:songCode]];
            state = KTVLoadSongStateOK;
            return block(songCode, [self cachedLyricUrl:songCode], role, state);
        }
        return block(songCode, [self cachedLyricUrl:songCode], role, state);
    });
}

-(void)playSong:(NSInteger)songCode
{
    [self.playerApi playSong:songCode];
}

-(void)resumePlay
{
    [self.playerApi resumePlay];
}

-(void)pausePlay
{
    [self.playerApi pausePlay];
}

-(void)stopSong
{
    [self.playerApi stopSong];
    [self cancelAsyncTasks];
    [self.lrcView stop];
    [self.lrcView reset];
}

-(void)selectTrackMode:(KTVPlayerTrackMode)mode
{
    [self.playerApi selectTrackMode:mode];
}

- (void)adjustPlayoutVolume:(int)volume {
    [self.playerApi adjustPlayoutVolume:volume];
}

- (void)adjustPublishSignalVolume:(int)volume {
    [self.playerApi adjustPublishSignalVolume:volume];
}

- (void)adjustChorusRemoteUserPlaybackVoulme:(int)volume {
    [self.playerApi adjustChorusRemoteUserPlaybackVoulme:volume];
}

- (void)mainRtcEngine:(AgoraRtcEngineKit *)engine receiveStreamMessageFromUid:(NSUInteger)uid streamId:(NSInteger)streamId data:(NSData *)data
{
    NSDictionary *dict = [VLGlobalHelper dictionaryForJsonData:data];
    if (self.playerApi.config.role == KTVSingRoleMainSinger) {
        KTVLogWarn(@"recv %@ cmd invalid", dict[@"cmd"]);
        return;
    }
    if([dict[@"cmd"] isEqualToString:@"setVoicePitch"]) {
        int pitch = [dict[@"pitch"] intValue];
//        NSInteger time = [dict[@"time"] integerValue];
        [self.lrcView setVoicePitch:@[@(pitch)]];
//        KTVLogInfo(@"receiveStreamMessageFromUid1 setVoicePitch: %ld", time);
    } else {
        [self.playerApi mainRtcEngine:engine receiveStreamMessageFromUid:uid streamId:streamId data:data];
    }
}

- (void)mainRtcEngine:(AgoraRtcEngineKit *)engine reportAudioVolumeIndicationOfSpeakers:(NSArray<AgoraRtcAudioVolumeInfo *> *)speakers totalVolume:(NSInteger)totalVolume
{
    [self.playerApi mainRtcEngine:engine reportAudioVolumeIndicationOfSpeakers:speakers totalVolume:totalVolume];
    if (self.playerApi.config.role != KTVSingRoleMainSinger
        || self.playerApi.playerState != AgoraMediaPlayerStatePlaying) {
        return;
    }
    
    double pitch = speakers.firstObject.voicePitch;
    [self.lrcView setVoicePitch:@[@(pitch)]];
}

- (void)mainRtcEngine:(AgoraRtcEngineKit *)engine didJoinedOfUid:(NSUInteger)uid elapsed:(NSInteger)elapsed {
    [self.playerApi mainRtcEngine:engine didJoinedOfUid:uid elapsed:elapsed];
}

- (void)mainRtcEngine:(AgoraRtcEngineKit *)engine localAudioStats:(AgoraRtcLocalAudioStats *)stats {
    [self.playerApi mainRtcEngine:engine localAudioStats:stats];
}

#pragma mark - setter
- (void)setLrcView:(AgoraLrcScoreView *)lrcView
{
    _lrcView = lrcView;
    lrcView.downloadDelegate = self;
    lrcView.delegate = self;
}

#pragma mark - AgoraLrcViewDelegate
-(NSTimeInterval)getTotalTime {
    return [self.playerApi getTotalTime];
}

- (NSTimeInterval)getPlayerCurrentTime {
    return [self.playerApi getPlayerCurrentTime];
}

- (NSInteger)playerDuration {
    return [self.playerApi playerDuration];
}

#pragma mark - AgoraLrcDownloadDelegate
- (void)downloadLrcFinishedWithUrl:(NSString *)url {
    KTVLogInfo(@"download lrc finished %@",url);

    LyricCallback callback = [self.lyricCallbacks objectForKey:url];
    if(!callback) {
        return;
    }
    [self.lyricCallbacks removeObjectForKey:url];

    callback(url);
}

- (void)downloadLrcErrorWithUrl:(NSString *)url error:(NSError *)error {
    KTVLogInfo(@"download lrc fail %@: %@",url,error);

    LyricCallback callback = [self.lyricCallbacks objectForKey:url];
    if(!callback) {
        return;
    }
    [self.lyricCallbacks removeObjectForKey:url];

    callback(nil);
}

#pragma mark AgoraMusicContentCenterEventDelegate
- (void)onLyricResult:(nonnull NSString *)requestId
             lyricUrl:(nonnull NSString *)lyricUrl {
    LyricCallback callback = [self.lyricCallbacks objectForKey:requestId];
    if(!callback) {
        return;
    }
    [self.lyricCallbacks removeObjectForKey:requestId];
    
    if ([lyricUrl length] == 0) {
        callback(nil);
        return;
    }
    
    callback(lyricUrl);
}

- (void)onMusicChartsResult:(nonnull NSString *)requestId
                     status:(AgoraMusicContentCenterStatusCode)status
                     result:(nonnull NSArray<AgoraMusicChartInfo *> *)result {
}

- (void)onMusicCollectionResult:(nonnull NSString *)requestId
                         status:(AgoraMusicContentCenterStatusCode)status
                         result:(nonnull AgoraMusicCollection *)result {
}

- (void)onPreLoadEvent:(NSInteger)songCode
               percent:(NSInteger)percent
                status:(AgoraMusicContentCenterPreloadStatus)status
                   msg:(nonnull NSString *)msg
              lyricUrl:(nonnull NSString *)lyricUrl {
    if (status == AgoraMusicContentCenterPreloadStatusPreloading) {
        return;
    }
    NSString* sSongCode = [NSString stringWithFormat:@"%ld", songCode];
    LoadMusicCallback block = [self.musicCallbacks objectForKey:sSongCode];
    if(!block) {
        return;
    }
    [self.musicCallbacks removeObjectForKey:sSongCode];
    block(status);
}

- (void)cancelAsyncTasks
{
    [self.lyricCallbacks removeAllObjects];
    [self.musicCallbacks removeAllObjects];
}

- (void)setLrcLyric:(NSString*)url withCallback:(void (^ _Nullable)(NSString* lyricUrl))block
{
    BOOL taskExits = [self.lyricCallbacks objectForKey:url] != nil;
    if(!taskExits){
        //overwrite existing callback and use new
        [self.lyricCallbacks setObject:block forKey:url];
    }
    [self.lrcView setLrcUrlWithUrl:url];
}

- (NSString*)cachedLyricUrl:(NSInteger)songCode
{
    return [self.lyricUrlDict objectForKey:[self songCodeString:songCode]];
}

- (NSString*)songCodeString:(NSInteger)songCode
{
    return [NSString stringWithFormat: @"%ld", songCode];
}

- (void)loadLyric:(NSInteger)songNo withCallback:(void (^ _Nullable)(NSString* lyricUrl))block {
    KTVLogInfo(@"loadLyric: %ld", songNo);
    NSString* requestId = [self.musicCenter getLyricWithSongCode:songNo lyricType:0];
    if ([requestId length] == 0) {
        if (block) {
            block(nil);
        }
        return;
    }
    [self.lyricCallbacks setObject:block forKey:requestId];
}

- (void)loadMusic:(NSInteger)songCode withCallback:(LoadMusicCallback)block {
    KTVLogInfo(@"loadMusic: %ld", songCode);
    NSInteger songCodeIntValue = songCode;
    NSInteger error = [self.musicCenter isPreloadedWithSongCode:songCodeIntValue];
    if(error == 0) {
        if(block) {
            [self.musicCallbacks removeObjectForKey:[self songCodeString:songCode]];
            block(AgoraMusicContentCenterPreloadStatusOK);
        }
        
        return;
    }
    
    error = [self.musicCenter preloadWithSongCode:songCodeIntValue jsonOption:nil];
    if (error != 0) {
        if(block) {
            [self.musicCallbacks removeObjectForKey:[self songCodeString:songCode]];
            block(AgoraMusicContentCenterPreloadStatusError);
        }
        return;
    }
    [self.musicCallbacks setObject:block forKey:[self songCodeString:songCode]];
}

@end




