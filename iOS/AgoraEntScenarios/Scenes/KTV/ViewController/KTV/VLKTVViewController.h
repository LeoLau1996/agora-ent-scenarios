//
//  VLKTVViewController.h
//  VoiceOnLine
//

#import "BaseViewController.h"
#import "KTVServiceProtocol.h"
#import "VLKTVViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface VLKTVViewController : BaseViewController
@property (nonatomic, strong) VLKTVViewModel* viewModel;
@end

NS_ASSUME_NONNULL_END
