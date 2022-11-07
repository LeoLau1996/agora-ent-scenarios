//
//  VLKTVViewModel.m
//  AgoraEntScenarios
//
//  Created by wushengtao on 2022/11/6.
//

#import "VLKTVViewModel.h"
#import "VLUserCenter.h"
#import "VLRoomSelSongModel.h"
#import "VLMacroDefine.h"

@implementation VLKTVViewModel

- (void)setRoomModel:(VLRoomListModel *)roomModel {
    _roomModel = roomModel;
    
    //update room mv cover index
    VLKTVSelBgModel *selBgModel = [VLKTVSelBgModel new];
    selBgModel.imageName = [NSString stringWithFormat:@"ktv_mvbg%d",(int)self.roomModel.bgOption];
    selBgModel.ifSelect = YES;
    self.choosedBgModel = selBgModel;
}

- (void)setRoomPeopleNum:(NSUInteger)roomPeopleNum {
    _roomPeopleNum = roomPeopleNum;
    self.roomModel.roomPeopleNum = [NSString stringWithFormat:@"%ld", roomPeopleNum];
}

- (void)setMvCoverIndex:(NSUInteger)mvCoverIndex {
    VLKTVSelBgModel *selBgModel = [VLKTVSelBgModel new];
    selBgModel.imageName = [NSString stringWithFormat:@"ktv_mvbg%d",(int)self.roomModel.bgOption];
    selBgModel.ifSelect = YES;
    self.choosedBgModel = selBgModel;
}

- (BOOL)isRoomOwner {
    return [self.roomModel.creator isEqualToString:VLUserCenter.user.userNo];
}

-(BOOL)isOnSeat{
    for (VLRoomSeatModel *seatModel in self.seatsArray) {
        if (seatModel.id != nil) {
            if ([seatModel.id isEqual:VLUserCenter.user.id]) {
                return YES;
            }
        }
    }
    return NO;
}

/// 当前用户是否在麦上
- (BOOL)currentUserIsOnSeat {
    if (!self.seatsArray.count) return NO;
    bool onSeat = NO;
    for (VLRoomSeatModel *seat in self.seatsArray) {
        if ([seat.userNo isEqualToString:VLUserCenter.user.userNo]) {
            return YES;
        }
    }
    return onSeat;
}


- (BOOL)updateOnSeatWithSeatModel:(VLRoomSeatModel*)seatModel {
    BOOL isMainSinger = NO;
    for (VLRoomSeatModel *model in self.seatsArray) {
        if (model.onSeat == seatModel.onSeat) {
            model.isMaster = seatModel.isMaster;
            model.headUrl = seatModel.headUrl;
            model.onSeat = seatModel.onSeat;
            model.name = seatModel.name;
            model.userNo = seatModel.userNo;
            model.id = seatModel.id;
            
            if([self isMainSinger:model.userNo]) {
                model.ifSelTheSingSong = YES;
                isMainSinger = YES;
            }
            VLRoomSelSongModel *song = self.selSongsArray.count ? self.selSongsArray.firstObject : nil;
            if (song != nil && song.isChorus && [song.chorusNo isEqualToString:seatModel.userNo]) {
                model.ifJoinedChorus = YES;
            }
        }
    }
    
    return isMainSinger;
}


- (VLRoomSeatModel*)updateAudioAndVideoOpenStatusWithSeatModel:(VLRoomSeatModel*)seatModel {
    for (VLRoomSeatModel *model in self.seatsArray) {
        if ([seatModel.userNo isEqualToString:model.userNo]) {
            model.isVideoMuted = seatModel.isVideoMuted;
            model.isSelfMuted = seatModel.isSelfMuted;
            return model;
        }
    }
    
    return nil;
}


- (BOOL)checkChrousWithSong: (VLRoomSelSongModel*)songInfo {
    if (songInfo.isChorus
        && self.currentPlayingSongNo == nil
        && songInfo.chorusNo != nil) {
        return YES;
    }
    
    return NO;
}


- (void)resetMicAndCameraStatus
{
    _isNowMicMuted = NO;
    _isNowCameraMuted = YES;
}

#pragma mark - Util functions to check user character for current song.

- (BOOL)isMainSinger:(NSString *)userNo {
    VLRoomSelSongModel *selSongModel = self.selSongsArray.firstObject;
    if (selSongModel != nil && [selSongModel.userNo isEqualToString:userNo]) {
        return YES;
    }
    else {
        return NO;
    }
}

- (BOOL)isChorusSinger:(NSString *)userNo {
    VLRoomSelSongModel *selSongModel = self.selSongsArray.firstObject;
    VLLog(@"Agora - Song chorusNo: %@, userNo: %@", selSongModel.chorusNo, userNo);
    if(selSongModel != nil && selSongModel.isChorus && [selSongModel.chorusNo isEqualToString:userNo]) {
        return YES;
    }
    else {
        return NO;
    }
}

- (BOOL) isIAmRoomMaster {
    return (VLUserCenter.user.ifMaster ? YES : NO);
}

- (NSString *)getMainSingerUserNo {
    VLRoomSelSongModel *selSongModel = self.selSongsArray.firstObject;
    if(selSongModel != nil) {
        return selSongModel.userNo;
    }
    else {
        return nil;
    }
}

- (NSString *)getChrousSingerUserNo {
    VLRoomSelSongModel *selSongModel = self.selSongsArray.firstObject;
    if(selSongModel != nil && selSongModel.isChorus && selSongModel.chorusNo != nil) {
        return selSongModel.chorusNo;
    }
    else {
        return nil;
    }
}

- (BOOL)isCurrentSongChorus {
    VLRoomSelSongModel *selSongModel = self.selSongsArray.firstObject;
    if(selSongModel != nil) {
        return selSongModel.isChorus;
    }
    else {
        return NO;
    }
}
@end
