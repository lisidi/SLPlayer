//
//  UIView+CustomControlView1.h
//  SLPlayer
//
//  Created by lisd on 2017/12/12.
//  Copyright © 2017年 lisd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SLPlayer.h"

@interface UIView (ControlView)
@property (nonatomic, weak) id<SLPlayerControlViewDelagate> delegate;

- (void)sl_playerModel:(SLPlayerModel *)playerModel;
- (void)sl_playerShowOrHideControlView;
- (void)sl_playerShowControlView;
- (void)sl_playerHideControlView;
- (void)sl_playerResetControlView;
- (void)sl_playerResetControlViewForResolution;
- (void)sl_playerCancelAutoFadeOutControlView;
- (void)sl_playerItemPlaying;
- (void)sl_playerPlayEnd;
- (void)sl_playerHasDownloadFunction:(BOOL)sender;
- (void)sl_playerResolutionArray:(NSArray *)resolutionArray;
- (void)sl_playerPlayBtnState:(BOOL)state;
- (void)sl_playerLockBtnState:(BOOL)state;
- (void)sl_playerDownloadBtnState:(BOOL)state;
- (void)sl_playerActivity:(BOOL)animated;
- (void)sl_playerDraggedTime:(NSInteger)draggedTime sliderImage:(UIImage *)image;
- (void)sl_playerDraggedTime:(NSInteger)draggedTime totalTime:(NSInteger)totalTime isForward:(BOOL)forawrd hasPreview:(BOOL)preview;
- (void)sl_playerDraggedEnd;
- (void)sl_playerCurrentTime:(NSInteger)currentTime totalTime:(NSInteger)totalTime sliderValue:(CGFloat)value;
- (void)sl_playerSetProgress:(CGFloat)progress;
- (void)sl_playerItemStatusFailed:(NSError *)error;
- (void)sl_playerBottomShrinkPlay;
- (void)sl_playerCellPlay;

@end

