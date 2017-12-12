//
//  SLPlayerView.m
//  SLPlayer
//
//  Created by lisd on 2017/12/12.
//  Copyright © 2017年 lisd. All rights reserved.
//

#import "SLPlayerView.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "UIView+ControlView.h"

#define CellPlayerFatherViewTag  200

#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"

typedef NS_ENUM(NSInteger, PanDirection){
    PanDirectionHorizontalMoved,
    PanDirectionVerticalMoved
};

@interface SLPlayerView () <UIGestureRecognizerDelegate,UIAlertViewDelegate>

@property (nonatomic, strong) AVPlayer               *player;
@property (nonatomic, strong) AVPlayerItem           *playerItem;
@property (nonatomic, strong) AVURLAsset             *urlAsset;
@property (nonatomic, strong) AVAssetImageGenerator  *imageGenerator;
@property (nonatomic, strong) AVPlayerLayer          *playerLayer;

@property (nonatomic, strong) id                     timeObserve;
@property (nonatomic, strong) UISlider               *volumeViewSlider;
@property (nonatomic, assign) CGFloat                sumTime;
@property (nonatomic, assign) PanDirection           panDirection;
@property (nonatomic, assign) SLPlayerState          state;
@property (nonatomic, assign) BOOL                   isFullScreen;
@property (nonatomic, assign) BOOL                   isLocked;
@property (nonatomic, assign) BOOL                   isVolume;
@property (nonatomic, assign) BOOL                   isPauseByUser;
@property (nonatomic, assign) BOOL                   isLocalVideo;
@property (nonatomic, assign) CGFloat                sliderLastValue;
@property (nonatomic, assign) BOOL                   repeatToPlay;
@property (nonatomic, assign) BOOL                   playDidEnd;
@property (nonatomic, assign) BOOL                   didEnterBackground;
@property (nonatomic, assign) BOOL                   isAutoPlay;
@property (nonatomic, strong) UITapGestureRecognizer *singleTap;
@property (nonatomic, strong) UITapGestureRecognizer *doubleTap;
@property (nonatomic, strong) NSArray                *videoURLArray;
@property (nonatomic, strong) UIImage                *thumbImg;
@property (nonatomic, strong) SLBrightnessView       *brightnessView;
@property (nonatomic, copy) NSString                 *videoGravity;

#pragma mark - UITableViewCell PlayerView
@property (nonatomic, assign) BOOL                   viewDisappear;
@property (nonatomic, assign) BOOL                   isCellVideo;
@property (nonatomic, assign) BOOL                   isBottomVideo;
@property (nonatomic, assign) BOOL                   isChangeResolution;
@property (nonatomic, assign) BOOL                   isDragged;
@property (nonatomic, assign) CGPoint                shrinkRightBottomPoint;
@property (nonatomic, strong) UIPanGestureRecognizer *shrinkPanGesture;
@property (nonatomic, strong) SLPlayerModel          *playerModel;
@property (nonatomic, assign) NSInteger              seekTime;
@property (nonatomic, strong) NSDictionary           *resolutionDic;
@end

@implementation SLPlayerView

#pragma mark - life Cycle

- (instancetype)init {
    self = [super init];
    if (self) { [self initializeThePlayer]; }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self initializeThePlayer];
}

- (void)initializeThePlayer {
    self.cellPlayerOnCenter = YES;
}

- (void)dealloc {
    self.playerItem = nil;
    self.scrollView  = nil;
    SLPlayerShared.isLockScreen = NO;
    [self.controlView sl_playerCancelAutoFadeOutControlView];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    
    if (self.timeObserve) {
        [self.player removeTimeObserver:self.timeObserve];
        self.timeObserve = nil;
    }
}

- (void)resetToPlayNewURL {
    self.repeatToPlay = YES;
    [self resetPlayer];
}

#pragma mark - 观察者、通知

- (void)addNotifications {
   
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterPlayground) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioRouteChangeListenerCallback:) name:AVAudioSessionRouteChangeNotification object:nil];
    
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDeviceOrientationChange)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onStatusBarOrientationChange)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];
}

#pragma mark - layoutSubviews

- (void)layoutSubviews {
    [super layoutSubviews];
    self.playerLayer.frame = self.bounds;
}

#pragma mark - Public Method

+ (instancetype)sharedPlayerView {
    static SLPlayerView *playerView = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        playerView = [[SLPlayerView alloc] init];
    });
    return playerView;
}

- (void)playerControlView:(UIView *)controlView playerModel:(SLPlayerModel *)playerModel {
    if (!controlView) {
        SLPlayerControlView *defaultControlView = [[SLPlayerControlView alloc] init];
        self.controlView = defaultControlView;
    } else {
        self.controlView = controlView;
    }
    self.playerModel = playerModel;
    
}

- (void)playWithVideoURL:(NSURL*)videoURl
              scrollView:(UIScrollView*)scrollView
               indexPath:(NSIndexPath*)indexPath
           fatherViewTag:(NSInteger)fatherViewTag{
    
    self.seekTime = 0;
    self.videoURL = videoURl;
    if (scrollView && indexPath && videoURl) {
        NSCAssert(fatherViewTag, @"请指定playerViews所在的faterViewTag");
        [self cellVideoWithScrollView:scrollView AtIndexPath:indexPath];
        if ([scrollView isKindOfClass:[UITableView class]]) {
            UITableView *tableView = (UITableView *)scrollView;
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            UIView *fatherView = [cell.contentView viewWithTag:fatherViewTag];
            [self addPlayerToFatherView:fatherView];
        } else if ([scrollView isKindOfClass:[UICollectionView class]]) {
            UICollectionView *collectionView = (UICollectionView *)scrollView;
            UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
            UIView *fatherView = [cell.contentView viewWithTag:fatherViewTag];
            [self addPlayerToFatherView:fatherView];
        }
    }
}

- (void)playWithControllView{
    if (self.scrollView && self.indexPath && self.videoURL) {
        NSCAssert(self.fatherViewTag, @"请指定playerViews所在的faterViewTag");
        [self cellVideoWithScrollView:self.scrollView AtIndexPath:self.indexPath];
        if ([self.scrollView isKindOfClass:[UITableView class]]) {
            UITableView *tableView = (UITableView *)self.scrollView;
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:self.indexPath];
            UIView *fatherView = [cell.contentView viewWithTag:self.fatherViewTag];
            [self addPlayerToFatherView:fatherView];
        } else if ([self.scrollView isKindOfClass:[UICollectionView class]]) {
            UICollectionView *collectionView = (UICollectionView *)self.scrollView;
            UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:self.indexPath];
            UIView *fatherView = [cell.contentView viewWithTag:self.fatherViewTag];
            [self addPlayerToFatherView:fatherView];
        }
    }
}

- (void)setPlayerModel:(SLPlayerModel *)playerModel {
    _playerModel = playerModel;
    
    self.seekTime = 0;
    self.videoURL = playerModel.videoURL;
    
    if (playerModel.scrollView && playerModel.indexPath && playerModel.videoURL) {
        NSCAssert(playerModel.fatherViewTag, @"请指定playerViews所在的faterViewTag");
        [self cellVideoWithScrollView:playerModel.scrollView AtIndexPath:playerModel.indexPath];
        if ([self.scrollView isKindOfClass:[UITableView class]]) {
            UITableView *tableView = (UITableView *)playerModel.scrollView;
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:playerModel.indexPath];
            UIView *fatherView = [cell.contentView viewWithTag:playerModel.fatherViewTag];
            [self addPlayerToFatherView:fatherView];
        } else if ([self.scrollView isKindOfClass:[UICollectionView class]]) {
            UICollectionView *collectionView = (UICollectionView *)playerModel.scrollView;
            UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:playerModel.indexPath];
            UIView *fatherView = [cell.contentView viewWithTag:playerModel.fatherViewTag];
            [self addPlayerToFatherView:fatherView];
        }
    } else {
        NSCAssert(playerModel.fatherView, @"请指定playerView的faterView");
        [self addPlayerToFatherView:playerModel.fatherView];
    }
}

- (void)playerModel:(SLPlayerModel *)playerModel {
    [self playerControlView:nil playerModel:playerModel];
}


- (void)autoPlayTheVideo {
    [self configSLPlayer];
}


- (void)addPlayerToFatherView:(UIView *)view {
    if (view) {
        [self removeFromSuperview];
        [view addSubview:self];
        [self mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.edges.mas_offset(UIEdgeInsetsZero);
        }];
    }
}

- (void)resetPlayer {
    self.playDidEnd         = NO;
    self.playerItem         = nil;
    self.didEnterBackground = NO;

    self.seekTime           = 0;
    self.isAutoPlay         = NO;
    if (self.timeObserve) {
        [self.player removeTimeObserver:self.timeObserve];
        self.timeObserve = nil;
    }

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self pause];
    [self.playerLayer removeFromSuperlayer];

    self.imageGenerator = nil;
    self.player         = nil;
    if (self.isChangeResolution) {
        [self.controlView sl_playerResetControlViewForResolution];
        self.isChangeResolution = NO;
    }else {
        [self.controlView sl_playerResetControlView];
    }
    self.controlView   = nil;
    self.isBottomVideo = NO;

    if (self.isCellVideo && !self.repeatToPlay) {
        self.viewDisappear = YES;
        self.isCellVideo   = NO;
        self.scrollView     = nil;
        self.indexPath     = nil;
    }
}

- (void)resetToPlayNewVideo:(SLPlayerModel *)playerModel {
    self.repeatToPlay = YES;
    [self resetPlayer];
    self.playerModel = playerModel;
    [self configSLPlayer];
}

- (void)play{
    [self.controlView sl_playerPlayBtnState:YES];
    if (self.state ==SLPlayerStatePause) { self.state = SLPlayerStatePlaying; }
    self.isPauseByUser = NO;
    [_player play];
}

- (void)pause {
    [self.controlView sl_playerPlayBtnState:NO];
    if (self.state == SLPlayerStatePlaying) { self.state = SLPlayerStatePause;}
    self.isPauseByUser = YES;
    [_player pause];
}

#pragma mark - Private Method

- (void)cellVideoWithScrollView:(UIScrollView *)scrollView
                    AtIndexPath:(NSIndexPath *)indexPath {
    if (!self.viewDisappear && self.playerItem) { [self resetPlayer]; }
    self.isCellVideo      = YES;
    self.viewDisappear    = NO;
    self.scrollView       = scrollView;
    self.indexPath        = indexPath;
    [self.controlView sl_playerCellPlay];
    
    self.shrinkPanGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(shrikPanAction:)];
    self.shrinkPanGesture.delegate = self;
    [self addGestureRecognizer:self.shrinkPanGesture];
}

- (void)configSLPlayer {
    self.urlAsset = [AVURLAsset assetWithURL:self.videoURL];
    self.playerItem = [AVPlayerItem playerItemWithAsset:self.urlAsset];
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    
    self.backgroundColor = [UIColor blackColor];
    self.playerLayer.videoGravity = self.videoGravity;
    self.isAutoPlay = YES;
    [self createTimer];
    [self configureVolume];
    
    if ([self.videoURL.scheme isEqualToString:@"file"]) {
        self.state = SLPlayerStatePlaying;
        self.isLocalVideo = YES;
        [self.controlView sl_playerDownloadBtnState:NO];
    } else {
        self.state = SLPlayerStateBuffering;
        self.isLocalVideo = NO;
        [self.controlView sl_playerDownloadBtnState:YES];
    }
    
    [self play];
    self.isPauseByUser = NO;
}


- (void)createGesture {

    self.singleTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(singleTapAction:)];
    self.singleTap.delegate                = self;
    self.singleTap.numberOfTouchesRequired = 1;
    self.singleTap.numberOfTapsRequired    = 1;
    [self addGestureRecognizer:self.singleTap];
    
    self.doubleTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(doubleTapAction:)];
    self.doubleTap.delegate                = self;
    self.doubleTap.numberOfTouchesRequired = 1;
    self.doubleTap.numberOfTapsRequired    = 2;
    [self addGestureRecognizer:self.doubleTap];
    
    [self.singleTap setDelaysTouchesBegan:YES];
    [self.doubleTap setDelaysTouchesBegan:YES];

    [self.singleTap requireGestureRecognizerToFail:self.doubleTap];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.isAutoPlay) {
        UITouch *touch = [touches anyObject];
        if(touch.tapCount == 1) {
            [self performSelector:@selector(singleTapAction:) withObject:@(NO) ];
        } else if (touch.tapCount == 2) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(singleTapAction:) object:nil];
            [self doubleTapAction:touch.gestureRecognizers.lastObject];
        }
    }
}

- (void)createTimer {
    __weak typeof(self) weakSelf = self;
    self.timeObserve = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1, 1) queue:nil usingBlock:^(CMTime time){
        AVPlayerItem *currentItem = weakSelf.playerItem;
        NSArray *loadedRanges = currentItem.seekableTimeRanges;
        if (loadedRanges.count > 0 && currentItem.duration.timescale != 0) {
            NSInteger currentTime = (NSInteger)CMTimeGetSeconds([currentItem currentTime]);
            CGFloat totalTime     = (CGFloat)currentItem.duration.value / currentItem.duration.timescale;
            CGFloat value         = CMTimeGetSeconds([currentItem currentTime]) / totalTime;
            [weakSelf.controlView sl_playerCurrentTime:currentTime totalTime:totalTime sliderValue:value];
        }
    }];
}

- (void)configureVolume {
    MPVolumeView *volumeView = [[MPVolumeView alloc] init];
    _volumeViewSlider = nil;
    for (UIView *view in [volumeView subviews]){
        if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
            _volumeViewSlider = (UISlider *)view;
            break;
        }
    }

    NSError *setCategoryError = nil;
    BOOL success = [[AVAudioSession sharedInstance]
                    setCategory: AVAudioSessionCategoryPlayback
                    error: &setCategoryError];
    
    if (!success) { /* handle the error in setCategoryError */ }
    
}

- (void)audioRouteChangeListenerCallback:(NSNotification*)notification {
    NSDictionary *interuptionDict = notification.userInfo;
    
    NSInteger routeChangeReason = [[interuptionDict valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    
    switch (routeChangeReason) {
            
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            break;
            
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
        {
            [self play];
        }
            break;
            
        case AVAudioSessionRouteChangeReasonCategoryChange:
            NSLog(@"AVAudioSessionRouteChangeReasonCategoryChange");
            break;
    }
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self.player.currentItem) {
        if ([keyPath isEqualToString:@"status"]) {
            
            if (self.player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
                [self setNeedsLayout];
                [self layoutIfNeeded];
                [self.layer insertSublayer:self.playerLayer atIndex:0];
                self.state = SLPlayerStatePlaying;
    
                UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panDirection:)];
                panRecognizer.delegate = self;
                [panRecognizer setMaximumNumberOfTouches:1];
                [panRecognizer setDelaysTouchesBegan:YES];
                [panRecognizer setDelaysTouchesEnded:YES];
                [panRecognizer setCancelsTouchesInView:YES];
                [self addGestureRecognizer:panRecognizer];
                
                if (self.seekTime) {
                    [self seekToTime:self.seekTime completionHandler:nil];
                }
                self.player.muted = self.mute;
            } else if (self.player.currentItem.status == AVPlayerItemStatusFailed) {
                self.state = SLPlayerStateFailed;
            }
        } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
            
            NSTimeInterval timeInterval = [self availableDuration];
            CMTime duration             = self.playerItem.duration;
            CGFloat totalDuration       = CMTimeGetSeconds(duration);
            [self.controlView sl_playerSetProgress:timeInterval / totalDuration];
            
        } else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {
            
            if (self.playerItem.playbackBufferEmpty) {
                self.state = SLPlayerStateBuffering;
                [self bufferingSomeSecond];
            }
            
        } else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
            
            if (self.playerItem.playbackLikelyToKeepUp && self.state == SLPlayerStateBuffering){
                self.state = SLPlayerStatePlaying;
            }
        }
    } else if (object == self.scrollView) {
        if ([keyPath isEqualToString:kSLPlayerViewContentOffset]) {
            if (self.isFullScreen) { return; }
            [self handleScrollOffsetWithDict:change];
        }
    }
}

#pragma mark - tableViewContentOffset

- (void)handleScrollOffsetWithDict:(NSDictionary*)dict {
    if ([self.scrollView isKindOfClass:[UITableView class]]) {
        UITableView *tableView = (UITableView *)self.scrollView;
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:self.indexPath];
        NSArray *visableCells = tableView.visibleCells;
        if ([visableCells containsObject:cell]) {
            [self updatePlayerViewToCell];
        } else {
            if (self.stopPlayWhileCellNotVisable) {
                [self resetPlayer];
            } else {
                [self updatePlayerViewToBottom];
            }
        }
    } else if ([self.scrollView isKindOfClass:[UICollectionView class]]) {
        UICollectionView *collectionView = (UICollectionView *)self.scrollView;
        UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:self.indexPath];
        if ( [collectionView.visibleCells containsObject:cell]) {
            [self updatePlayerViewToCell];
        } else {
            if (self.stopPlayWhileCellNotVisable) {
                [self resetPlayer];
            } else {
                [self updatePlayerViewToBottom];
            }
        }
    }
}

- (void)updatePlayerViewToBottom {
    if (self.isBottomVideo) { return; }
    self.isBottomVideo = YES;
    if (self.playDidEnd) {
        self.repeatToPlay = NO;
        self.playDidEnd   = NO;
        [self resetPlayer];
        return;
    }
    [[UIApplication sharedApplication].keyWindow addSubview:self];
    
    if (CGPointEqualToPoint(self.shrinkRightBottomPoint, CGPointZero)) {
        self.shrinkRightBottomPoint = CGPointMake(10, self.scrollView.contentInset.bottom+10);
    } else {
        [self setShrinkRightBottomPoint:self.shrinkRightBottomPoint];
    }
    [self.controlView sl_playerBottomShrinkPlay];
}

- (void)updatePlayerViewToCell {
    if (!self.isBottomVideo) { return; }
    self.isBottomVideo = NO;
    [self setOrientationPortraitConstraint];
    [self.controlView sl_playerCellPlay];
}

- (void)setOrientationLandscapeConstraint:(UIInterfaceOrientation)orientation {
    [self toOrientation:orientation];
    self.isFullScreen = YES;
}

- (void)setOrientationPortraitConstraint {
    if (self.isCellVideo) {
        if ([self.scrollView isKindOfClass:[UITableView class]]) {
            UITableView *tableView = (UITableView *)self.scrollView;
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:self.indexPath];
            self.isBottomVideo = NO;
            if (![tableView.visibleCells containsObject:cell]) {
                [self updatePlayerViewToBottom];
            } else {
                UIView *fatherView = [cell.contentView viewWithTag:self.playerModel.fatherViewTag];
                [self addPlayerToFatherView:fatherView];
            }
        } else if ([self.scrollView isKindOfClass:[UICollectionView class]]) {
            UICollectionView *collectionView = (UICollectionView *)self.scrollView;
            UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:self.indexPath];
            self.isBottomVideo = NO;
            if (![collectionView.visibleCells containsObject:cell]) {
                [self updatePlayerViewToBottom];
            } else {
                UIView *fatherView = [cell viewWithTag:self.playerModel.fatherViewTag];
                [self addPlayerToFatherView:fatherView];
            }
        }
    } else {
        [self addPlayerToFatherView:self.playerModel.fatherView];
    }
    
    [self toOrientation:UIInterfaceOrientationPortrait];
    self.isFullScreen = NO;
}

- (void)toOrientation:(UIInterfaceOrientation)orientation {

    UIInterfaceOrientation currentOrientation = [UIApplication sharedApplication].statusBarOrientation;
    if (currentOrientation == orientation) { return; }
    if (orientation != UIInterfaceOrientationPortrait) {//
        if (currentOrientation == UIInterfaceOrientationPortrait) {
            [self removeFromSuperview];
            SLBrightnessView *brightnessView = [SLBrightnessView sharedBrightnessView];
            [[UIApplication sharedApplication].keyWindow insertSubview:self belowSubview:brightnessView];
            [self mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.width.equalTo(@(ScreenHeight));
                make.height.equalTo(@(ScreenWidth));
                make.center.equalTo([UIApplication sharedApplication].keyWindow);
            }];
        }
    }
    [[UIApplication sharedApplication] setStatusBarOrientation:orientation animated:NO];

    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.3];

    self.transform = CGAffineTransformIdentity;
    self.transform = [self getTransformRotationAngle];

    [UIView commitAnimations];
}

- (CGAffineTransform)getTransformRotationAngle {
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;

    if (orientation == UIInterfaceOrientationPortrait) {
        return CGAffineTransformIdentity;
    } else if (orientation == UIInterfaceOrientationLandscapeLeft){
        return CGAffineTransformMakeRotation(-M_PI_2);
    } else if(orientation == UIInterfaceOrientationLandscapeRight){
        return CGAffineTransformMakeRotation(M_PI_2);
    }
    return CGAffineTransformIdentity;
}

#pragma mark 屏幕转屏相关

- (void)interfaceOrientation:(UIInterfaceOrientation)orientation {
    if (orientation == UIInterfaceOrientationLandscapeRight || orientation == UIInterfaceOrientationLandscapeLeft) {
        [self setOrientationLandscapeConstraint:orientation];
    } else if (orientation == UIInterfaceOrientationPortrait) {
        [self setOrientationPortraitConstraint];
    }
}

- (void)onDeviceOrientationChange {
    if (!self.player) { return; }
    if (SLPlayerShared.isLockScreen) { return; }
    if (self.didEnterBackground) { return; };
    if (self.playerPushedOrPresented) { return; }
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    UIInterfaceOrientation interfaceOrientation = (UIInterfaceOrientation)orientation;
    if (orientation == UIDeviceOrientationFaceUp || orientation == UIDeviceOrientationFaceDown || orientation == UIDeviceOrientationUnknown ) { return; }
    
    switch (interfaceOrientation) {
        case UIInterfaceOrientationPortraitUpsideDown:{
        }
            break;
        case UIInterfaceOrientationPortrait:{
            if (self.isFullScreen) {
                [self toOrientation:UIInterfaceOrientationPortrait];
                
            }
        }
            break;
        case UIInterfaceOrientationLandscapeLeft:{
            if (self.isFullScreen == NO) {
                [self toOrientation:UIInterfaceOrientationLandscapeLeft];
                self.isFullScreen = YES;
            } else {
                [self toOrientation:UIInterfaceOrientationLandscapeLeft];
            }
            
        }
            break;
        case UIInterfaceOrientationLandscapeRight:{
            if (self.isFullScreen == NO) {
                [self toOrientation:UIInterfaceOrientationLandscapeRight];
                self.isFullScreen = YES;
            } else {
                [self toOrientation:UIInterfaceOrientationLandscapeRight];
            }
        }
            break;
        default:
            break;
    }
}

- (void)onStatusBarOrientationChange {
    if (!self.didEnterBackground) {
        UIInterfaceOrientation currentOrientation = [UIApplication sharedApplication].statusBarOrientation;
        if (currentOrientation == UIInterfaceOrientationPortrait) {
            [self setOrientationPortraitConstraint];
            if (self.cellPlayerOnCenter) {
                if ([self.scrollView isKindOfClass:[UITableView class]]) {
                    UITableView *tableView = (UITableView *)self.scrollView;
                    [tableView scrollToRowAtIndexPath:self.indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
                    
                } else if ([self.scrollView isKindOfClass:[UICollectionView class]]) {
                    UICollectionView *collectionView = (UICollectionView *)self.scrollView;
                    [collectionView scrollToItemAtIndexPath:self.indexPath atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
                }
            }
            [self.brightnessView removeFromSuperview];
            [[UIApplication sharedApplication].keyWindow addSubview:self.brightnessView];
            [self.brightnessView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.width.height.mas_equalTo(155);
                make.leading.mas_equalTo((ScreenWidth-155)/2);
                make.top.mas_equalTo((ScreenHeight-155)/2);
            }];
        } else {
            if (currentOrientation == UIInterfaceOrientationLandscapeRight) {
                [self toOrientation:UIInterfaceOrientationLandscapeRight];
            } else if (currentOrientation == UIDeviceOrientationLandscapeLeft){
                [self toOrientation:UIInterfaceOrientationLandscapeLeft];
            }
            [self.brightnessView removeFromSuperview];
            [self addSubview:self.brightnessView];
            [self.brightnessView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.center.mas_equalTo(self);
                make.width.height.mas_equalTo(155);
            }];
            
        }
    }
}

- (void)lockScreenAction:(UIButton *)sender {
    sender.selected             = !sender.selected;
    self.isLocked               = sender.selected;
    SLPlayerShared.isLockScreen = sender.selected;
}

- (void)unLockTheScreen {
    SLPlayerShared.isLockScreen = NO;
    [self.controlView sl_playerLockBtnState:NO];
    self.isLocked = NO;
    [self interfaceOrientation:UIInterfaceOrientationPortrait];
}

#pragma mark - 缓冲较差时候

- (void)bufferingSomeSecond {
    self.state = SLPlayerStateBuffering;
    __block BOOL isBuffering = NO;
    if (isBuffering) return;
    isBuffering = YES;
    
    [self.player pause];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        if (self.isPauseByUser) {
            isBuffering = NO;
            return;
        }
        
        [self play];
    
        isBuffering = NO;
        if (!self.playerItem.isPlaybackLikelyToKeepUp) { [self bufferingSomeSecond]; }
        
    });
}

#pragma mark - 计算缓冲进度

- (NSTimeInterval)availableDuration {
    NSArray *loadedTimeRanges = [[_player currentItem] loadedTimeRanges];
    CMTimeRange timeRange     = [loadedTimeRanges.firstObject CMTimeRangeValue];
    float startSeconds        = CMTimeGetSeconds(timeRange.start);
    float durationSeconds     = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval result     = startSeconds + durationSeconds;
    return result;
}

#pragma mark - Action

- (void)singleTapAction:(UIGestureRecognizer *)gesture {
    if ([gesture isKindOfClass:[NSNumber class]] && ![(id)gesture boolValue]) {
        [self _fullScreenAction];
        return;
    }
    if (gesture.state == UIGestureRecognizerStateRecognized) {
        if (self.isBottomVideo && !self.isFullScreen) { [self _fullScreenAction]; }
        else {
            if (self.playDidEnd) { return; }
            else {
                [self.controlView sl_playerShowOrHideControlView];
            }
        }
    }
}

- (void)doubleTapAction:(UIGestureRecognizer *)gesture {
    if (self.playDidEnd) {return;}
    [self.controlView sl_playerShowControlView];
    if (self.isPauseByUser) { [self play]; }
    else { [self pause]; }
    if (!self.isAutoPlay) {
        self.isAutoPlay = YES;
        [self configSLPlayer];
    }
}

- (void)shrikPanAction:(UIPanGestureRecognizer *)gesture {
    CGPoint point = [gesture locationInView:[UIApplication sharedApplication].keyWindow];
    SLPlayerView *view = (SLPlayerView *)gesture.view;
    const CGFloat width = view.frame.size.width;
    const CGFloat height = view.frame.size.height;
    const CGFloat distance = 10;
    
    if (gesture.state == UIGestureRecognizerStateEnded) {

        if (point.x < width/2) {
            point.x = width/2 + distance;
        } else if (point.x > ScreenWidth - width/2) {
            point.x = ScreenWidth - width/2 - distance;
        }

        if (point.y < height/2) {
            point.y = height/2 + distance;
        } else if (point.y > ScreenHeight - height/2) {
            point.y = ScreenHeight - height/2 - distance;
        }
        
        [UIView animateWithDuration:0.5 animations:^{
            view.center = point;
            self.shrinkRightBottomPoint = CGPointMake(ScreenWidth - view.frame.origin.x - width, ScreenHeight - view.frame.origin.y - height);
        }];
        
    } else {
        view.center = point;
        self.shrinkRightBottomPoint = CGPointMake(ScreenWidth - view.frame.origin.x- view.frame.size.width, ScreenHeight - view.frame.origin.y-view.frame.size.height);
    }
}

- (void)_fullScreenAction {
    if (SLPlayerShared.isLockScreen) {
        [self unLockTheScreen];
        return;
    }
    if (self.isFullScreen) {
        [self interfaceOrientation:UIInterfaceOrientationPortrait];
        self.isFullScreen = NO;
        return;
    } else {
        UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
        if (orientation == UIDeviceOrientationLandscapeRight) {
            [self interfaceOrientation:UIInterfaceOrientationLandscapeLeft];
        } else {
            [self interfaceOrientation:UIInterfaceOrientationLandscapeRight];
        }
        self.isFullScreen = YES;
    }
}

#pragma mark - NSNotification Action

- (void)moviePlayDidEnd:(NSNotification *)notification {
    self.state = SLPlayerStateStopped;
    if (self.isBottomVideo && !self.isFullScreen) {
        self.repeatToPlay = NO;
        self.playDidEnd   = NO;
        [self resetPlayer];
    } else {
        if (!self.isDragged) {
            self.playDidEnd = YES;
            [self.controlView sl_playerPlayEnd];
        }
    }
}

- (void)appDidEnterBackground {
    self.didEnterBackground     = YES;
    SLPlayerShared.isLockScreen = YES;
    [_player pause];
    self.state                  = SLPlayerStatePause;
}

- (void)appDidEnterPlayground {
    self.didEnterBackground     = NO;
    SLPlayerShared.isLockScreen = self.isLocked;
    if (!self.isPauseByUser) {
        self.state         = SLPlayerStatePlaying;
        self.isPauseByUser = NO;
        [self play];
    }
}

- (void)seekToTime:(NSInteger)dragedSeconds completionHandler:(void (^)(BOOL finished))completionHandler {
    if (self.player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
        [self.controlView sl_playerActivity:YES];
        [self.player pause];
        CMTime dragedCMTime = CMTimeMake(dragedSeconds, 1);
        __weak typeof(self) weakSelf = self;
        [self.player seekToTime:dragedCMTime toleranceBefore:CMTimeMake(1,1) toleranceAfter:CMTimeMake(1,1) completionHandler:^(BOOL finished) {
            [weakSelf.controlView sl_playerActivity:NO];
            if (completionHandler) { completionHandler(finished); }
            [weakSelf.player play];
            weakSelf.seekTime = 0;
            weakSelf.isDragged = NO;
            
            [weakSelf.controlView sl_playerDraggedEnd];
            if (!weakSelf.playerItem.isPlaybackLikelyToKeepUp && !weakSelf.isLocalVideo) { weakSelf.state = SLPlayerStateBuffering; }
            
        }];
    }
}

#pragma mark - UIPanGestureRecognizer手势方法

- (void)panDirection:(UIPanGestureRecognizer *)pan {

    CGPoint locationPoint = [pan locationInView:self];
    CGPoint veloctyPoint = [pan velocityInView:self];
    
    switch (pan.state) {
        case UIGestureRecognizerStateBegan:{
            CGFloat x = fabs(veloctyPoint.x);
            CGFloat y = fabs(veloctyPoint.y);
            if (x > y) {
                self.panDirection = PanDirectionHorizontalMoved;
                CMTime time       = self.player.currentTime;
                self.sumTime      = time.value/time.timescale;
            }
            else if (x < y){
                self.panDirection = PanDirectionVerticalMoved;
                if (locationPoint.x > self.bounds.size.width / 2) {
                    self.isVolume = YES;
                }else {
                    self.isVolume = NO;
                }
            }
            break;
        }
        case UIGestureRecognizerStateChanged:{
            switch (self.panDirection) {
                case PanDirectionHorizontalMoved:{
                    [self horizontalMoved:veloctyPoint.x];
                    break;
                }
                case PanDirectionVerticalMoved:{
                    [self verticalMoved:veloctyPoint.y];
                    break;
                }
                default:
                    break;
            }
            break;
        }
        case UIGestureRecognizerStateEnded:{
            switch (self.panDirection) {
                case PanDirectionHorizontalMoved:{
                    self.isPauseByUser = NO;
                    [self seekToTime:self.sumTime completionHandler:nil];
                    self.sumTime = 0;
                    break;
                }
                case PanDirectionVerticalMoved:{
                    self.isVolume = NO;
                    break;
                }
                default:
                    break;
            }
            break;
        }
        default:
            break;
    }
}

- (void)verticalMoved:(CGFloat)value {
    self.isVolume ? (self.volumeViewSlider.value -= value / 10000) : ([UIScreen mainScreen].brightness -= value / 10000);
}

- (void)horizontalMoved:(CGFloat)value {
    self.sumTime += value / 200;
    
    CMTime totalTime           = self.playerItem.duration;
    CGFloat totalMovieDuration = (CGFloat)totalTime.value/totalTime.timescale;
    if (self.sumTime > totalMovieDuration) { self.sumTime = totalMovieDuration;}
    if (self.sumTime < 0) { self.sumTime = 0; }
    
    BOOL style = false;
    if (value > 0) { style = YES; }
    if (value < 0) { style = NO; }
    if (value == 0) { return; }
    
    self.isDragged = YES;
    [self.controlView sl_playerDraggedTime:self.sumTime totalTime:totalMovieDuration isForward:style hasPreview:NO];
}

- (NSString *)durationStringWithTime:(int)time {
    NSString *min = [NSString stringWithFormat:@"%02d",time / 60];
    NSString *sec = [NSString stringWithFormat:@"%02d",time % 60];
    return [NSString stringWithFormat:@"%@:%@", min, sec];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    
    if (gestureRecognizer == self.shrinkPanGesture && self.isCellVideo) {
        if (!self.isBottomVideo || self.isFullScreen) {
            return NO;
        }
    }
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] && gestureRecognizer != self.shrinkPanGesture) {
        if ((self.isCellVideo && !self.isFullScreen) || self.playDidEnd || self.isLocked){
            return NO;
        }
    }
    if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
        if (self.isBottomVideo && !self.isFullScreen) {
            return NO;
        }
    }
    if ([touch.view isKindOfClass:[UISlider class]]) {
        return NO;
    }
    
    return YES;
}

#pragma mark - Setter

- (void)setVideoURL:(NSURL *)videoURL {
    _videoURL = videoURL;
    
    self.repeatToPlay = NO;
    self.playDidEnd   = NO;
    [self addNotifications];
    self.isPauseByUser = YES;
    [self createGesture];
}

- (void)setState:(SLPlayerState)state {
    _state = state;
    
    [self.controlView sl_playerActivity:state == SLPlayerStateBuffering];
    if (state == SLPlayerStatePlaying || state == SLPlayerStateBuffering) {
        [self.controlView sl_playerItemPlaying];
    } else if (state == SLPlayerStateFailed) {
        NSError *error = [self.playerItem error];
        [self.controlView sl_playerItemStatusFailed:error];
    }
}

- (void)setPlayerItem:(AVPlayerItem *)playerItem {
    if (_playerItem == playerItem) {return;}
    
    if (_playerItem) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:_playerItem];
        [_playerItem removeObserver:self forKeyPath:@"status"];
        [_playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
        [_playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
        [_playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    }
    _playerItem = playerItem;
    if (playerItem) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayDidEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
        [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
        [playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
        [playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
        [playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    }
}

- (void)setScrollView:(UIScrollView *)scrollView {
    if (_scrollView == scrollView) { return; }
    if (_scrollView) {
        [_scrollView removeObserver:self forKeyPath:kSLPlayerViewContentOffset];
    }
    _scrollView = scrollView;
    if (scrollView) { [scrollView addObserver:self forKeyPath:kSLPlayerViewContentOffset options:NSKeyValueObservingOptionNew context:nil]; }
}

- (void)setPlayerLayerGravity:(SLPlayerLayerGravity)playerLayerGravity {
    _playerLayerGravity = playerLayerGravity;
    switch (playerLayerGravity) {
        case SLPlayerLayerGravityResize:
            self.playerLayer.videoGravity = AVLayerVideoGravityResize;
            self.videoGravity = AVLayerVideoGravityResize;
            break;
        case SLPlayerLayerGravityResizeAspect:
            self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
            self.videoGravity = AVLayerVideoGravityResizeAspect;
            break;
        case SLPlayerLayerGravityResizeAspectFill:
            self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
            self.videoGravity = AVLayerVideoGravityResizeAspectFill;
            break;
        default:
            break;
    }
}

- (void)setHasDownload:(BOOL)hasDownload {
    _hasDownload = hasDownload;
    [self.controlView sl_playerHasDownloadFunction:hasDownload];
}

- (void)setResolutionDic:(NSDictionary *)resolutionDic {
    _resolutionDic = resolutionDic;
    self.videoURLArray = [resolutionDic allValues];
}

- (void)setControlView:(UIView *)controlView {
    if (_controlView) {
        return;
    }
    _controlView = controlView;
    controlView.delegate = self;
    [self addSubview:controlView];
    [controlView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(UIEdgeInsetsZero);
    }];
}

- (void)setShrinkRightBottomPoint:(CGPoint)shrinkRightBottomPoint {
    _shrinkRightBottomPoint = shrinkRightBottomPoint;
    CGFloat width = ScreenWidth*0.5-20;
    CGFloat height = (self.bounds.size.height / self.bounds.size.width);
    [self mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(width);
        make.height.equalTo(self.mas_width).multipliedBy(height);
        make.trailing.mas_equalTo(-shrinkRightBottomPoint.x);
        make.bottom.mas_equalTo(-shrinkRightBottomPoint.y);
    }];
}

- (void)setPlayerPushedOrPresented:(BOOL)playerPushedOrPresented {
    _playerPushedOrPresented = playerPushedOrPresented;
    if (playerPushedOrPresented) {
        [self pause];
    } else {
        [self play];
    }
}
#pragma mark - Getter

- (AVAssetImageGenerator *)imageGenerator {
    if (!_imageGenerator) {
        _imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:self.urlAsset];
    }
    return _imageGenerator;
}

- (SLBrightnessView *)brightnessView {
    if (!_brightnessView) {
        _brightnessView = [SLBrightnessView sharedBrightnessView];
    }
    return _brightnessView;
}

- (NSString *)videoGravity {
    if (!_videoGravity) {
        _videoGravity = AVLayerVideoGravityResizeAspect;
    }
    return _videoGravity;
}

#pragma mark - SLPlayerControlViewDelegate

- (void)sl_controlView:(UIView *)controlView playAction:(UIButton *)sender {
    self.isPauseByUser = !self.isPauseByUser;
    if (self.isPauseByUser) {
        [self pause];
        if (self.state == SLPlayerStatePlaying) { self.state = SLPlayerStatePause;}
    } else {
        [self play];
        if (self.state == SLPlayerStatePause) { self.state = SLPlayerStatePlaying; }
    }
    
    if (!self.isAutoPlay) {
        self.isAutoPlay = YES;
        [self configSLPlayer];
    }
}

- (void)sl_controlView:(UIView *)controlView backAction:(UIButton *)sender {
    if (SLPlayerShared.isLockScreen) {
        [self unLockTheScreen];
    } else {
        if (!self.isFullScreen) {
            [self pause];
            if ([self.delegate respondsToSelector:@selector(sl_playerBackAction)]) { [self.delegate sl_playerBackAction]; }
        } else {
            [self interfaceOrientation:UIInterfaceOrientationPortrait];
        }
    }
}

- (void)sl_controlView:(UIView *)controlView closeAction:(UIButton *)sender {
    [self resetPlayer];
    [self removeFromSuperview];
}

- (void)sl_controlView:(UIView *)controlView fullScreenAction:(UIButton *)sender {
    [self _fullScreenAction];
}

- (void)sl_controlView:(UIView *)controlView lockScreenAction:(UIButton *)sender {
    self.isLocked = sender.selected;
    SLPlayerShared.isLockScreen = sender.selected;
}

- (void)sl_controlView:(UIView *)controlView cneterPlayAction:(UIButton *)sender {
    [self configSLPlayer];
}

- (void)sl_controlView:(UIView *)controlView repeatPlayAction:(UIButton *)sender {
    self.playDidEnd   = NO;
    self.repeatToPlay = NO;
    
    [self seekToTime:0 completionHandler:nil];
    if ([self.videoURL.scheme isEqualToString:@"file"]) {
        self.state = SLPlayerStatePlaying;
    } else {
        self.state = SLPlayerStateBuffering;
    }
}

- (void)sl_controlView:(UIView *)controlView failAction:(UIButton *)sender {
    [self configSLPlayer];
}

- (void)sl_controlView:(UIView *)controlView resolutionAction:(UIButton *)sender {
    NSInteger currentTime = (NSInteger)CMTimeGetSeconds([self.player currentTime]);
    NSString *videoStr = self.videoURLArray[sender.tag - 200];
    NSURL *videoURL = [NSURL URLWithString:videoStr];
    if ([videoURL isEqual:self.videoURL]) { return; }
    self.isChangeResolution = YES;
    [self resetToPlayNewURL];
    self.videoURL = videoURL;
    self.seekTime = currentTime;
    [self autoPlayTheVideo];
}

- (void)sl_controlView:(UIView *)controlView downloadVideoAction:(UIButton *)sender {
    NSString *urlStr = self.videoURL.absoluteString;
    if ([self.delegate respondsToSelector:@selector(sl_playerDownload:)]) {
        [self.delegate sl_playerDownload:urlStr];
    }
}

- (void)sl_controlView:(UIView *)controlView progressSliderTap:(CGFloat)value {
    CGFloat total = (CGFloat)self.playerItem.duration.value / self.playerItem.duration.timescale;
    NSInteger dragedSeconds = floorf(total * value);
    [self.controlView sl_playerPlayBtnState:YES];
    [self seekToTime:dragedSeconds completionHandler:^(BOOL finished) {}];
}

- (void)sl_controlView:(UIView *)controlView progressSliderValueChanged:(UISlider *)slider {
    if (self.player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
        self.isDragged = YES;
        BOOL style = false;
        CGFloat value   = slider.value - self.sliderLastValue;
        if (value > 0) { style = YES; }
        if (value < 0) { style = NO; }
        if (value == 0) { return; }
        
        self.sliderLastValue  = slider.value;
        
        CGFloat totalTime     = (CGFloat)_playerItem.duration.value / _playerItem.duration.timescale;
        CGFloat dragedSeconds = floorf(totalTime * slider.value);
        CMTime dragedCMTime   = CMTimeMake(dragedSeconds, 1);
        
        [controlView sl_playerDraggedTime:dragedSeconds totalTime:totalTime isForward:style hasPreview:self.isFullScreen ? self.hasPreviewView : NO];
        if (totalTime > 0) {
            if (self.isFullScreen && self.hasPreviewView) {
                
                [self.imageGenerator cancelAllCGImageGeneration];
                self.imageGenerator.appliesPreferredTrackTransform = YES;
                self.imageGenerator.maximumSize = CGSizeMake(100, 56);
                AVAssetImageGeneratorCompletionHandler handler = ^(CMTime requestedTime, CGImageRef im, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error){
                    NSLog(@"%zd",result);
                    if (result != AVAssetImageGeneratorSucceeded) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [controlView sl_playerDraggedTime:dragedSeconds sliderImage:self.thumbImg ? : SLPlayerImage(@"SLPlayer_loading_bgView")];
                        });
                    } else {
                        self.thumbImg = [UIImage imageWithCGImage:im];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [controlView sl_playerDraggedTime:dragedSeconds sliderImage:self.thumbImg ? : SLPlayerImage(@"SLPlayer_loading_bgView")];
                        });
                    }
                };
                [self.imageGenerator generateCGImagesAsynchronouslyForTimes:[NSArray arrayWithObject:[NSValue valueWithCMTime:dragedCMTime]] completionHandler:handler];
            }
        } else {
            slider.value = 0;
        }
        
    }else {
        slider.value = 0;
    }
    
}

- (void)sl_controlView:(UIView *)controlView progressSliderTouchEnded:(UISlider *)slider {
    if (self.player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
        self.isPauseByUser = NO;
        self.isDragged = NO;
        
        CGFloat total = (CGFloat)_playerItem.duration.value / _playerItem.duration.timescale;
        NSInteger dragedSeconds = floorf(total * slider.value);
        [self seekToTime:dragedSeconds completionHandler:nil];
    }
}

- (void)sl_controlViewWillShow:(UIView *)controlView isFullscreen:(BOOL)fullscreen {
    if ([self.delegate respondsToSelector:@selector(sl_playerControlViewWillShow:isFullscreen:)]) {
        [self.delegate sl_playerControlViewWillShow:controlView isFullscreen:fullscreen];
    }
}

- (void)sl_controlViewWillHidden:(UIView *)controlView isFullscreen:(BOOL)fullscreen {
    if ([self.delegate respondsToSelector:@selector(sl_playerControlViewWillHidden:isFullscreen:)]) {
        [self.delegate sl_playerControlViewWillHidden:controlView isFullscreen:fullscreen];
    }
}

#pragma clang diagnostic pop

@end

