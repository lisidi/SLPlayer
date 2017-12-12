//
//  SLPlayerView.h
//  SLPlayer
//
//  Created by lisd on 2017/12/12.
//  Copyright © 2017年 lisd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SLPlayerModel.h"
#import "SLPlayerControlViewDelagate.h"

@protocol SLPlayerDelegate <NSObject>
@optional
- (void)sl_playerBackAction;
- (void)sl_playerDownload:(NSString *)url;
- (void)sl_playerControlViewWillShow:(UIView *)controlView isFullscreen:(BOOL)fullscreen;
- (void)sl_playerControlViewWillHidden:(UIView *)controlView isFullscreen:(BOOL)fullscreen;
@end

typedef NS_ENUM(NSInteger, SLPlayerLayerGravity) {
    SLPlayerLayerGravityResize,
    SLPlayerLayerGravityResizeAspect,
    SLPlayerLayerGravityResizeAspectFill
};

typedef NS_ENUM(NSInteger, SLPlayerState) {
    SLPlayerStateFailed,
    SLPlayerStateBuffering,
    SLPlayerStatePlaying,
    SLPlayerStateStopped,
    SLPlayerStatePause
};

@interface SLPlayerView : UIView <SLPlayerControlViewDelagate>

@property (nonatomic, assign) SLPlayerLayerGravity    playerLayerGravity;
@property (nonatomic, assign) BOOL                    hasDownload;
@property (nonatomic, assign) BOOL                    hasPreviewView;
@property (nonatomic, weak) id<SLPlayerDelegate>      delegate;
@property (nonatomic, assign, readonly) BOOL          isPauseByUser;
@property (nonatomic, assign, readonly) SLPlayerState state;
@property (nonatomic, assign) BOOL                    mute;
@property (nonatomic, assign) BOOL                    stopPlayWhileCellNotVisable;
@property (nonatomic, assign) BOOL                    cellPlayerOnCenter;
@property (nonatomic, assign) BOOL                    playerPushedOrPresented;
@property (nonatomic, strong) NSURL        *videoURL;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) NSIndexPath  *indexPath;
@property (nonatomic, assign) NSInteger    fatherViewTag;
@property (nonatomic, strong) UIView       *controlView;
@property (nonatomic, weak) UIView       *fatherView;

+ (instancetype)sharedPlayerView;
- (void)playerControlView:(UIView *)controlView playerModel:(SLPlayerModel *)playerModel;
- (void)playWithControllView;
- (void)playWithVideoURL:(NSURL*)videoURl
              scrollView:(UIScrollView*)scrollView
               indexPath:(NSIndexPath*)indexPath
           fatherViewTag:(NSInteger)fatherViewTag;
- (void)playerModel:(SLPlayerModel *)playerModel;
- (void)autoPlayTheVideo;
- (void)resetPlayer;
- (void)resetToPlayNewVideo:(SLPlayerModel *)playerModel;
- (void)play;
- (void)pause;

@end
