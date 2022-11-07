//
//  VLKTVViewModel.h
//  AgoraEntScenarios
//
//  Created by wushengtao on 2022/11/6.
//

#import <Foundation/Foundation.h>
#import "VLRoomListModel.h"
#import "VLRoomSeatModel.h"
#import "VLSongItmModel.h"
#import "VLBelcantoModel.h"
#import "VLKTVSelBgModel.h"
#import "VLRoomSeatModel.h"
#import "VLRoomSelSongModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface VLKTVViewModel : NSObject

@property (nonatomic, strong) VLRoomListModel *roomModel;
//麦位数组
@property (nonatomic, strong) NSArray <VLRoomSeatModel *> *seatsArray;

@property (nonatomic, strong) VLKTVSelBgModel *choosedBgModel;
@property (nonatomic, strong) VLBelcantoModel *selBelcantoModel;
@property (nonatomic, strong) NSArray *selSongsArray;
@property (nonatomic, strong) VLSongItmModel *choosedSongModel; //点的歌曲
@property (nonatomic, assign) float currentTime;

@property (nonatomic, strong) NSString *mutedRemoteUserId;
@property (nonatomic, strong, nullable) NSString *currentPlayingSongNo;

@property (nonatomic, assign) BOOL isEarOn;
@property (nonatomic, assign) BOOL isNowMicMuted;
@property (nonatomic, assign) BOOL isNowCameraMuted;


@property (nonatomic, assign) NSUInteger roomPeopleNum;

- (BOOL)isRoomOwner;

-(BOOL)isOnSeat;

- (BOOL)currentUserIsOnSeat;

- (BOOL)updateOnSeatWithSeatModel:(VLRoomSeatModel*)seatModel;

- (VLRoomSeatModel*)updateAudioAndVideoOpenStatusWithSeatModel:(VLRoomSeatModel*)seatModel;

- (BOOL)checkChrousWithSong: (VLRoomSelSongModel*)songInfo;


- (void)resetMicAndCameraStatus;

- (BOOL)isMainSinger:(NSString *)userNo;
- (BOOL)isChorusSinger:(NSString *)userNo;
- (BOOL) isIAmRoomMaster;
- (NSString *)getMainSingerUserNo;
- (NSString *)getChrousSingerUserNo;
- (BOOL)isCurrentSongChorus;

@end

NS_ASSUME_NONNULL_END
