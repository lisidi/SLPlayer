//
//  SLPlayerControlView.m
//  SLPlayer
//
//  Created by lisd on 2017/12/12.
//  Copyright © 2017年 lisd. All rights reserved.
//

#import "SLPlayerControlView.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "UIView+ControlView.h"
#import <Masonry.h>
#import "SLMarco.h"
#import "SLBrightnessView.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"

static const CGFloat SLPlayerAnimationTimeInterval             = 7.0f;
static const CGFloat SLPlayerControlBarAutoFadeOutTimeInterval = 0.35f;

@interface SLPlayerControlView () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UILabel                 *titleLabel;
@property (nonatomic, strong) UIButton                *startBtn;
@property (nonatomic, strong) UILabel                 *currentTimeLabel;
@property (nonatomic, strong) UILabel                 *totalTimeLabel;
@property (nonatomic, strong) UIProgressView          *progressView;
@property (nonatomic, strong) UISlider   *videoSlider;
@property (nonatomic, strong) UIButton                *fullScreenBtn;
@property (nonatomic, strong) UIButton                *lockBtn;
@property (nonatomic,strong) UIActivityIndicatorView *loadingView;
@property (nonatomic, strong) UIButton                *backBtn;
@property (nonatomic, strong) UIButton                *closeBtn;
@property (nonatomic, strong) UIButton                *repeatBtn;
@property (nonatomic, strong) UIImageView             *bottomImageView;
@property (nonatomic, strong) UIImageView             *topImageView;
@property (nonatomic, strong) UIButton                *downLoadBtn;
@property (nonatomic, strong) UIButton                *resolutionBtn;
@property (nonatomic, strong) UIView                  *resolutionView;
@property (nonatomic, strong) UIButton                *playeBtn;
@property (nonatomic, strong) UIButton                *failBtn;
@property (nonatomic, strong) UIView                  *fastView;
@property (nonatomic, strong) UIProgressView          *fastProgressView;
@property (nonatomic, strong) UILabel                 *fastTimeLabel;
@property (nonatomic, strong) UIImageView             *fastImageView;
@property (nonatomic, weak  ) UIButton                *resoultionCurrentBtn;
@property (nonatomic, strong) UIImageView             *placeholderImageView;
@property (nonatomic, strong) UIProgressView          *bottomProgressView;
@property (nonatomic, strong) NSArray                 *resolutionArray;
@property (nonatomic, assign, getter=isShowing) BOOL  showing;
@property (nonatomic, assign, getter=isShrink ) BOOL  shrink;
@property (nonatomic, assign, getter=isCellVideo)BOOL cellVideo;
@property (nonatomic, assign, getter=isDragged) BOOL  dragged;
@property (nonatomic, assign, getter=isPlayEnd) BOOL  playeEnd;
@property (nonatomic, assign,getter=isFullScreen)BOOL fullScreen;

@end

@implementation SLPlayerControlView

- (instancetype)init {
    self = [super init];
    if (self) {
        [self addSubview:self.placeholderImageView];
        [self addSubview:self.topImageView];
        [self addSubview:self.bottomImageView];
        [self.bottomImageView addSubview:self.startBtn];
        [self.bottomImageView addSubview:self.currentTimeLabel];
        [self.bottomImageView addSubview:self.progressView];
        [self.bottomImageView addSubview:self.videoSlider];
        [self.bottomImageView addSubview:self.fullScreenBtn];
        [self.bottomImageView addSubview:self.totalTimeLabel];
        
        [self.topImageView addSubview:self.downLoadBtn];
        [self addSubview:self.lockBtn];
        [self.topImageView addSubview:self.backBtn];
        [self addSubview:self.loadingView];
        [self addSubview:self.repeatBtn];
        [self addSubview:self.playeBtn];
        [self addSubview:self.failBtn];
        
        [self addSubview:self.fastView];
        [self.fastView addSubview:self.fastImageView];
        [self.fastView addSubview:self.fastTimeLabel];
        [self.fastView addSubview:self.fastProgressView];
        
        [self.topImageView addSubview:self.resolutionBtn];
        [self.topImageView addSubview:self.titleLabel];
        [self addSubview:self.closeBtn];
        [self addSubview:self.bottomProgressView];
        
        [self makeSubViewsConstraints];
        self.downLoadBtn.hidden     = YES;
        self.resolutionBtn.hidden   = YES;
        [self sl_playerResetControlView];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterPlayground) name:UIApplicationDidBecomeActiveNotification object:nil];
        
        [self listeningRotating];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

- (void)makeSubViewsConstraints {
    [self.placeholderImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(UIEdgeInsetsZero);
    }];
    
    [self.closeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(self.mas_trailing).offset(7);
        make.top.equalTo(self.mas_top).offset(-7);
        make.width.height.mas_equalTo(20);
    }];
    
    [self.topImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self);
        make.top.equalTo(self.mas_top).offset(0);
        make.height.mas_equalTo(50);
    }];
    
    [self.backBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.topImageView.mas_leading).offset(10);
        make.top.equalTo(self.topImageView.mas_top).offset(3);
        make.width.height.mas_equalTo(40);
    }];
    
    [self.downLoadBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(40);
        make.height.mas_equalTo(49);
        make.trailing.equalTo(self.topImageView.mas_trailing).offset(-10);
        make.centerY.equalTo(self.backBtn.mas_centerY);
    }];
    
    [self.resolutionBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(40);
        make.height.mas_equalTo(25);
        make.trailing.equalTo(self.downLoadBtn.mas_leading).offset(-10);
        make.centerY.equalTo(self.backBtn.mas_centerY);
    }];
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.backBtn.mas_trailing).offset(5);
        make.centerY.equalTo(self.backBtn.mas_centerY);
        make.trailing.equalTo(self.resolutionBtn.mas_leading).offset(-10);
    }];
    
    [self.bottomImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.bottom.mas_equalTo(0);
        make.height.mas_equalTo(50);
    }];
    
    [self.startBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.bottomImageView.mas_leading).offset(5);
        make.bottom.equalTo(self.bottomImageView.mas_bottom).offset(-5);
        make.width.height.mas_equalTo(30);
    }];
    
    [self.currentTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.startBtn.mas_trailing).offset(-3);
        make.centerY.equalTo(self.startBtn.mas_centerY);
        make.width.mas_equalTo(43);
    }];
    
    [self.fullScreenBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(30);
        make.trailing.equalTo(self.bottomImageView.mas_trailing).offset(-5);
        make.centerY.equalTo(self.startBtn.mas_centerY);
    }];
    
    [self.totalTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(self.fullScreenBtn.mas_leading).offset(3);
        make.centerY.equalTo(self.startBtn.mas_centerY);
        make.width.mas_equalTo(43);
    }];
    
    [self.progressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.currentTimeLabel.mas_trailing).offset(4);
        make.trailing.equalTo(self.totalTimeLabel.mas_leading).offset(-4);
        make.centerY.equalTo(self.startBtn.mas_centerY);
    }];
    
    [self.videoSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.currentTimeLabel.mas_trailing).offset(4);
        make.trailing.equalTo(self.totalTimeLabel.mas_leading).offset(-4);
        make.centerY.equalTo(self.currentTimeLabel.mas_centerY).offset(-1);
        make.height.mas_equalTo(30);
    }];
    
    [self.lockBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.mas_leading).offset(15);
        make.centerY.equalTo(self.mas_centerY);
        make.width.height.mas_equalTo(32);
    }];
    
    [self.repeatBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
    }];
    
    [self.playeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(50);
        make.center.equalTo(self);
    }];
    
    [self.loadingView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
        make.width.with.height.mas_equalTo(45);
    }];
    
    [self.failBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
        make.width.mas_equalTo(130);
        make.height.mas_equalTo(33);
    }];
    
    [self.fastView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(125);
        make.height.mas_equalTo(80);
        make.center.equalTo(self);
    }];
    
    [self.fastImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_offset(32);
        make.height.mas_offset(32);
        make.top.mas_equalTo(5);
        make.centerX.mas_equalTo(self.fastView.mas_centerX);
    }];
    
    [self.fastTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.with.trailing.mas_equalTo(0);
        make.top.mas_equalTo(self.fastImageView.mas_bottom).offset(2);
    }];
    
    [self.fastProgressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(12);
        make.trailing.mas_equalTo(-12);
        make.top.mas_equalTo(self.fastTimeLabel.mas_bottom).offset(10);
    }];
    
    [self.bottomProgressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.mas_offset(0);
        make.bottom.mas_offset(0);
    }];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    UIInterfaceOrientation currentOrientation = [UIApplication sharedApplication].statusBarOrientation;
    if (currentOrientation == UIDeviceOrientationPortrait) {
        [self setOrientationPortraitConstraint];
    } else {
        [self setOrientationLandscapeConstraint];
    }
}

#pragma mark - Action

- (void)changeResolution:(UIButton *)sender {
    sender.selected = YES;
    if (sender.isSelected) {
        sender.backgroundColor = RGBA(86, 143, 232, 1);
    } else {
        sender.backgroundColor = [UIColor clearColor];
    }
    self.resoultionCurrentBtn.selected = NO;
    self.resoultionCurrentBtn.backgroundColor = [UIColor clearColor];
    self.resoultionCurrentBtn = sender;
    self.resolutionView.hidden  = YES;
    self.resolutionBtn.selected = NO;
    [self.resolutionBtn setTitle:sender.titleLabel.text forState:UIControlStateNormal];
    if ([self.delegate respondsToSelector:@selector(sl_controlView:resolutionAction:)]) {
        [self.delegate sl_controlView:self resolutionAction:sender];
    }
}

/**
 *  UISlider TapAction
 */
- (void)tapSliderAction:(UITapGestureRecognizer *)tap {
    if ([tap.view isKindOfClass:[UISlider class]]) {
        UISlider *slider = (UISlider *)tap.view;
        CGPoint point = [tap locationInView:slider];
        CGFloat length = slider.frame.size.width;
        CGFloat tapValue = point.x / length;
        if ([self.delegate respondsToSelector:@selector(sl_controlView:progressSliderTap:)]) {
            [self.delegate sl_controlView:self progressSliderTap:tapValue];
        }
    }
}

- (void)panRecognizer:(UIPanGestureRecognizer *)sender {}

- (void)backBtnClick:(UIButton *)sender {
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (self.isCellVideo && orientation == UIInterfaceOrientationPortrait) {
        if ([self.delegate respondsToSelector:@selector(sl_controlView:closeAction:)]) {
            [self.delegate sl_controlView:self closeAction:sender];
        }
    } else {
        if ([self.delegate respondsToSelector:@selector(sl_controlView:backAction:)]) {
            [self.delegate sl_controlView:self backAction:sender];
        }
    }
}

- (void)lockScrrenBtnClick:(UIButton *)sender {
    sender.selected = !sender.selected;
    self.showing = NO;
    [self sl_playerShowControlView];
    if ([self.delegate respondsToSelector:@selector(sl_controlView:lockScreenAction:)]) {
        [self.delegate sl_controlView:self lockScreenAction:sender];
    }
}

- (void)playBtnClick:(UIButton *)sender {
    sender.selected = !sender.selected;
    if ([self.delegate respondsToSelector:@selector(sl_controlView:playAction:)]) {
        [self.delegate sl_controlView:self playAction:sender];
    }
}

- (void)closeBtnClick:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(sl_controlView:closeAction:)]) {
        [self.delegate sl_controlView:self closeAction:sender];
    }
}

- (void)fullScreenBtnClick:(UIButton *)sender {
    sender.selected = !sender.selected;
    if ([self.delegate respondsToSelector:@selector(sl_controlView:fullScreenAction:)]) {
        [self.delegate sl_controlView:self fullScreenAction:sender];
    }
}

- (void)repeatBtnClick:(UIButton *)sender {
    [self sl_playerResetControlView];
    [self sl_playerShowControlView];
    if ([self.delegate respondsToSelector:@selector(sl_controlView:repeatPlayAction:)]) {
        [self.delegate sl_controlView:self repeatPlayAction:sender];
    }
}

- (void)downloadBtnClick:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(sl_controlView:downloadVideoAction:)]) {
        [self.delegate sl_controlView:self downloadVideoAction:sender];
    }
}

- (void)resolutionBtnClick:(UIButton *)sender {
    sender.selected = !sender.selected;
    self.resolutionView.hidden = !sender.isSelected;
}

- (void)centerPlayBtnClick:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(sl_controlView:cneterPlayAction:)]) {
        [self.delegate sl_controlView:self cneterPlayAction:sender];
    }
}

- (void)failBtnClick:(UIButton *)sender {
    self.failBtn.hidden = YES;
    if ([self.delegate respondsToSelector:@selector(sl_controlView:failAction:)]) {
        [self.delegate sl_controlView:self failAction:sender];
    }
}


- (void)progressSliderTouchBegan:(UISlider *)sender {
    [self sl_playerCancelAutoFadeOutControlView];
    if ([self.delegate respondsToSelector:@selector(sl_controlView:progressSliderTouchBegan:)]) {
        [self.delegate sl_controlView:self progressSliderTouchBegan:sender];
    }
}

- (void)progressSliderValueChanged:(UISlider *)sender {
    if ([self.delegate respondsToSelector:@selector(sl_controlView:progressSliderValueChanged:)]) {
        [self.delegate sl_controlView:self progressSliderValueChanged:sender];
    }
}


- (void)progressSliderTouchEnded:(UISlider *)sender {
    self.showing = YES;
    if ([self.delegate respondsToSelector:@selector(sl_controlView:progressSliderTouchEnded:)]) {
        [self.delegate sl_controlView:self progressSliderTouchEnded:sender];
    }
}

- (void)appDidEnterBackground {
    [self sl_playerCancelAutoFadeOutControlView];
}

- (void)appDidEnterPlayground {
    if (!self.isShrink) { [self sl_playerShowControlView]; }
}

- (void)playerPlayDidEnd {
    self.backgroundColor  = RGBA(0, 0, 0, .6);
    self.repeatBtn.hidden = NO;
    self.showing = NO;
    [self sl_playerShowControlView];
}

- (void)onDeviceOrientationChange {
    if (SLPlayerShared.isLockScreen) { return; }
    self.lockBtn.hidden         = !self.isFullScreen;
    self.fullScreenBtn.selected = self.isFullScreen;
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    if (orientation == UIDeviceOrientationFaceUp || orientation == UIDeviceOrientationFaceDown || orientation == UIDeviceOrientationUnknown || orientation == UIDeviceOrientationPortraitUpsideDown) { return; }
    if (!self.isShrink && !self.isPlayEnd && !self.showing) {
        [self sl_playerShowOrHideControlView];
    }
}

- (void)setOrientationLandscapeConstraint {
    if (self.isCellVideo) {
        self.shrink             = NO;
    }
    self.fullScreen             = YES;
    self.lockBtn.hidden         = !self.isFullScreen;
    self.fullScreenBtn.selected = self.isFullScreen;
    [self.backBtn setImage:SLPlayerImage(@"SLPlayer_back_full") forState:UIControlStateNormal];
    [self.backBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.topImageView.mas_top).offset(23);
        make.leading.equalTo(self.topImageView.mas_leading).offset(10);
        make.width.height.mas_equalTo(40);
    }];
}

- (void)setOrientationPortraitConstraint {
    self.fullScreen             = NO;
    self.lockBtn.hidden         = !self.isFullScreen;
    self.fullScreenBtn.selected = self.isFullScreen;
    [self.backBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.topImageView.mas_top).offset(3);
        make.leading.equalTo(self.topImageView.mas_leading).offset(10);
        make.width.height.mas_equalTo(40);
    }];
    
    if (self.isCellVideo) {
        [self.backBtn setImage:SLPlayerImage(@"SLPlayer_close") forState:UIControlStateNormal];
    }
}

#pragma mark - Private Method

- (void)showControlView {
    self.showing = YES;
    if (self.lockBtn.isSelected) {
        self.topImageView.alpha    = 0;
        self.bottomImageView.alpha = 0;
    } else {
        self.topImageView.alpha    = 1;
        self.bottomImageView.alpha = 1;
    }
    self.backgroundColor           = RGBA(0, 0, 0, 0.3);
    self.lockBtn.alpha             = 1;
    if (self.isCellVideo) {
        self.shrink                = NO;
    }
    self.bottomProgressView.alpha  = 0;
    SLPlayerShared.isStatusBarHidden = NO;
}

- (void)hideControlView {
    self.showing = NO;
    self.backgroundColor          = RGBA(0, 0, 0, 0);
    self.topImageView.alpha       = self.playeEnd;
    self.bottomImageView.alpha    = 0;
    self.lockBtn.alpha            = 0;
    self.bottomProgressView.alpha = 1;
    self.resolutionBtn.selected = YES;
    [self resolutionBtnClick:self.resolutionBtn];
    if (self.isFullScreen && !self.playeEnd && !self.isShrink) {
        SLPlayerShared.isStatusBarHidden = YES;
    }
}

- (void)listeningRotating {
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDeviceOrientationChange)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
}


- (void)autoFadeOutControlView {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(sl_playerHideControlView) object:nil];
    [self performSelector:@selector(sl_playerHideControlView) withObject:nil afterDelay:SLPlayerAnimationTimeInterval];
}

- (CGRect)thumbRect {
    return [self.videoSlider thumbRectForBounds:self.videoSlider.bounds
                                      trackRect:[self.videoSlider trackRectForBounds:self.videoSlider.bounds]
                                          value:self.videoSlider.value];
}

#pragma mark - setter

- (void)setShrink:(BOOL)shrink {
    _shrink = shrink;
    self.closeBtn.hidden = !shrink;
    self.bottomProgressView.hidden = shrink;
}

- (void)setFullScreen:(BOOL)fullScreen {
    _fullScreen = fullScreen;
    SLPlayerShared.isLandscape = fullScreen;
}

#pragma mark - getter

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.font = [UIFont systemFontOfSize:15.0];
    }
    return _titleLabel;
}

- (UIButton *)backBtn {
    if (!_backBtn) {
        _backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_backBtn setImage:SLPlayerImage(@"SLPlayer_back_full") forState:UIControlStateNormal];
        [_backBtn addTarget:self action:@selector(backBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backBtn;
}

- (UIImageView *)topImageView {
    if (!_topImageView) {
        _topImageView                        = [[UIImageView alloc] init];
        _topImageView.userInteractionEnabled = YES;
        _topImageView.alpha                  = 0;
        _topImageView.image                  = SLPlayerImage(@"SLPlayer_top_shadow");
    }
    return _topImageView;
}

- (UIImageView *)bottomImageView {
    if (!_bottomImageView) {
        _bottomImageView                        = [[UIImageView alloc] init];
        _bottomImageView.userInteractionEnabled = YES;
        _bottomImageView.alpha                  = 0;
        _bottomImageView.image                  = SLPlayerImage(@"SLPlayer_bottom_shadow");
    }
    return _bottomImageView;
}

- (UIButton *)lockBtn {
    if (!_lockBtn) {
        _lockBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_lockBtn setImage:SLPlayerImage(@"SLPlayer_unlock-nor") forState:UIControlStateNormal];
        [_lockBtn setImage:SLPlayerImage(@"SLPlayer_lock-nor") forState:UIControlStateSelected];
        [_lockBtn addTarget:self action:@selector(lockScrrenBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        
    }
    return _lockBtn;
}

- (UIButton *)startBtn {
    if (!_startBtn) {
        _startBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_startBtn setImage:SLPlayerImage(@"SLPlayer_play") forState:UIControlStateNormal];
        [_startBtn setImage:SLPlayerImage(@"SLPlayer_pause") forState:UIControlStateSelected];
        [_startBtn addTarget:self action:@selector(playBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _startBtn;
}

- (UIButton *)closeBtn {
    if (!_closeBtn) {
        _closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_closeBtn setImage:SLPlayerImage(@"SLPlayer_close") forState:UIControlStateNormal];
        [_closeBtn addTarget:self action:@selector(closeBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        _closeBtn.hidden = YES;
    }
    return _closeBtn;
}

- (UILabel *)currentTimeLabel {
    if (!_currentTimeLabel) {
        _currentTimeLabel               = [[UILabel alloc] init];
        _currentTimeLabel.textColor     = [UIColor whiteColor];
        _currentTimeLabel.font          = [UIFont systemFontOfSize:12.0f];
        _currentTimeLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _currentTimeLabel;
}

- (UIProgressView *)progressView {
    if (!_progressView) {
        _progressView                   = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        _progressView.progressTintColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.5];
        _progressView.trackTintColor    = [UIColor clearColor];
    }
    return _progressView;
}

-(UISlider *)videoSlider {
    if (!_videoSlider) {
        _videoSlider                       = [[UISlider alloc] init];
        
        _videoSlider.value = 0.0;
        [_videoSlider setThumbImage:SLPlayerImage(@"SLPlayer_slider") forState:UIControlStateNormal];
        _videoSlider.maximumValue          = 1;
        _videoSlider.minimumTrackTintColor = [UIColor whiteColor];
        _videoSlider.maximumTrackTintColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.5];
        
        [_videoSlider addTarget:self action:@selector(progressSliderTouchBegan:) forControlEvents:UIControlEventTouchDown];
        [_videoSlider addTarget:self action:@selector(progressSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
        [_videoSlider addTarget:self action:@selector(progressSliderTouchEnded:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchCancel | UIControlEventTouchUpOutside];
        
        UITapGestureRecognizer *sliderTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapSliderAction:)];
        [_videoSlider addGestureRecognizer:sliderTap];
        
        UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panRecognizer:)];
        panRecognizer.delegate = self;
        [panRecognizer setMaximumNumberOfTouches:1];
        [panRecognizer setDelaysTouchesBegan:YES];
        [panRecognizer setDelaysTouchesEnded:YES];
        [panRecognizer setCancelsTouchesInView:YES];
        [_videoSlider addGestureRecognizer:panRecognizer];
    }
    return _videoSlider;
}

- (UILabel *)totalTimeLabel {
    if (!_totalTimeLabel) {
        _totalTimeLabel               = [[UILabel alloc] init];
        _totalTimeLabel.textColor     = [UIColor whiteColor];
        _totalTimeLabel.font          = [UIFont systemFontOfSize:12.0f];
        _totalTimeLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _totalTimeLabel;
}

- (UIButton *)fullScreenBtn {
    if (!_fullScreenBtn) {
        _fullScreenBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_fullScreenBtn setImage:SLPlayerImage(@"SLPlayer_fullscreen") forState:UIControlStateNormal];
        [_fullScreenBtn setImage:SLPlayerImage(@"SLPlayer_shrinkscreen") forState:UIControlStateSelected];
        [_fullScreenBtn addTarget:self action:@selector(fullScreenBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _fullScreenBtn;
}

- (UIActivityIndicatorView *)loadingView {
    if (!_loadingView) {
        _loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    }
    return _loadingView;
}

- (UIButton *)repeatBtn {
    if (!_repeatBtn) {
        _repeatBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_repeatBtn setImage:[UIImage imageNamed:@"SLPlayer_repeat_video"] forState:UIControlStateNormal];
        [_repeatBtn addTarget:self action:@selector(repeatBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _repeatBtn;
}

- (UIButton *)downLoadBtn {
    if (!_downLoadBtn) {
        _downLoadBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_downLoadBtn setImage:SLPlayerImage(@"Player_download") forState:UIControlStateNormal];
        [_downLoadBtn setImage:SLPlayerImage(@"SLPlayer_not_download") forState:UIControlStateDisabled];
        [_downLoadBtn addTarget:self action:@selector(downloadBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _downLoadBtn;
}

- (UIButton *)resolutionBtn {
    if (!_resolutionBtn) {
        _resolutionBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _resolutionBtn.titleLabel.font = [UIFont systemFontOfSize:12];
        _resolutionBtn.backgroundColor = RGBA(0, 0, 0, 0.7);
        [_resolutionBtn addTarget:self action:@selector(resolutionBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _resolutionBtn;
}

- (UIButton *)playeBtn {
    if (!_playeBtn) {
        _playeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_playeBtn setImage:SLPlayerImage(@"SLPlayer_play_btn") forState:UIControlStateNormal];
        [_playeBtn addTarget:self action:@selector(centerPlayBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _playeBtn;
}

- (UIButton *)failBtn {
    if (!_failBtn) {
        _failBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [_failBtn setTitle:@"加载失败,点击重试" forState:UIControlStateNormal];
        [_failBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _failBtn.titleLabel.font = [UIFont systemFontOfSize:14.0];
        _failBtn.backgroundColor = RGBA(0, 0, 0, 0.7);
        [_failBtn addTarget:self action:@selector(failBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _failBtn;
}

- (UIView *)fastView {
    if (!_fastView) {
        _fastView                     = [[UIView alloc] init];
        _fastView.backgroundColor     = RGBA(0, 0, 0, 0.8);
        _fastView.layer.cornerRadius  = 4;
        _fastView.layer.masksToBounds = YES;
    }
    return _fastView;
}

- (UIImageView *)fastImageView {
    if (!_fastImageView) {
        _fastImageView = [[UIImageView alloc] init];
    }
    return _fastImageView;
}

- (UILabel *)fastTimeLabel {
    if (!_fastTimeLabel) {
        _fastTimeLabel               = [[UILabel alloc] init];
        _fastTimeLabel.textColor     = [UIColor whiteColor];
        _fastTimeLabel.textAlignment = NSTextAlignmentCenter;
        _fastTimeLabel.font          = [UIFont systemFontOfSize:14.0];
    }
    return _fastTimeLabel;
}

- (UIProgressView *)fastProgressView {
    if (!_fastProgressView) {
        _fastProgressView                   = [[UIProgressView alloc] init];
        _fastProgressView.progressTintColor = [UIColor whiteColor];
        _fastProgressView.trackTintColor    = [[UIColor lightGrayColor] colorWithAlphaComponent:0.4];
    }
    return _fastProgressView;
}

- (UIImageView *)placeholderImageView {
    if (!_placeholderImageView) {
        _placeholderImageView = [[UIImageView alloc] init];
        _placeholderImageView.userInteractionEnabled = YES;
    }
    return _placeholderImageView;
}

- (UIProgressView *)bottomProgressView {
    if (!_bottomProgressView) {
        _bottomProgressView                   = [[UIProgressView alloc] init];
        _bottomProgressView.progressTintColor = [UIColor whiteColor];
        _bottomProgressView.trackTintColor    = [UIColor clearColor];
    }
    return _bottomProgressView;
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    CGRect rect = [self thumbRect];
    CGPoint point = [touch locationInView:self.videoSlider];
    if ([touch.view isKindOfClass:[UISlider class]]) {
        if (point.x <= rect.origin.x + rect.size.width && point.x >= rect.origin.x) { return NO; }
    }
    return YES;
}

#pragma mark - Public method

- (void)sl_playerResetControlView {
    [self.loadingView stopAnimating];
    self.videoSlider.value           = 0;
    self.bottomProgressView.progress = 0;
    self.progressView.progress       = 0;
    self.currentTimeLabel.text       = @"00:00";
    self.totalTimeLabel.text         = @"00:00";
    self.fastView.hidden             = YES;
    self.repeatBtn.hidden            = YES;
    self.playeBtn.hidden             = YES;
    self.resolutionView.hidden       = YES;
    self.failBtn.hidden              = YES;
    self.backgroundColor             = [UIColor clearColor];
    self.downLoadBtn.enabled         = YES;
    self.shrink                      = NO;
    self.showing                     = NO;
    self.playeEnd                    = NO;
    self.lockBtn.hidden              = !self.isFullScreen;
    self.failBtn.hidden              = YES;
    self.placeholderImageView.alpha  = 1;
    [self hideControlView];
}

- (void)sl_playerResetControlViewForResolution {
    self.fastView.hidden        = YES;
    self.repeatBtn.hidden       = YES;
    self.resolutionView.hidden  = YES;
    self.playeBtn.hidden        = YES;
    self.downLoadBtn.enabled    = YES;
    self.failBtn.hidden         = YES;
    self.backgroundColor        = [UIColor clearColor];
    self.shrink                 = NO;
    self.showing                = NO;
    self.playeEnd               = NO;
}

- (void)sl_playerCancelAutoFadeOutControlView {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)sl_playerItemPlaying {
    [UIView animateWithDuration:1.0 animations:^{
        self.placeholderImageView.alpha = 0;
    }];
}

- (void)sl_playerShowOrHideControlView {
    if (self.isShowing) {
        [self sl_playerHideControlView];
    } else {
        [self sl_playerShowControlView];
    }
}

- (void)sl_playerShowControlView {
    if ([self.delegate respondsToSelector:@selector(sl_controlViewWillShow:isFullscreen:)]) {
        [self.delegate sl_controlViewWillShow:self isFullscreen:self.isFullScreen];
    }
    [self sl_playerCancelAutoFadeOutControlView];
    [UIView animateWithDuration:SLPlayerControlBarAutoFadeOutTimeInterval animations:^{
        [self showControlView];
    } completion:^(BOOL finished) {
        self.showing = YES;
        [self autoFadeOutControlView];
    }];
}

- (void)sl_playerHideControlView {
    if ([self.delegate respondsToSelector:@selector(sl_controlViewWillHidden:isFullscreen:)]) {
        [self.delegate sl_controlViewWillHidden:self isFullscreen:self.isFullScreen];
    }
    [self sl_playerCancelAutoFadeOutControlView];
    [UIView animateWithDuration:SLPlayerControlBarAutoFadeOutTimeInterval animations:^{
        [self hideControlView];
    } completion:^(BOOL finished) {
        self.showing = NO;
    }];
}

- (void)sl_playerBottomShrinkPlay {
    self.shrink = YES;
    [self hideControlView];
}

- (void)sl_playerCellPlay {
    self.cellVideo = YES;
    self.shrink    = NO;
    [self.backBtn setImage:SLPlayerImage(@"SLPlayer_close") forState:UIControlStateNormal];
}

- (void)sl_playerCurrentTime:(NSInteger)currentTime totalTime:(NSInteger)totalTime sliderValue:(CGFloat)value {

    NSInteger proMin = currentTime / 60;
    NSInteger proSec = currentTime % 60;

    NSInteger durMin = totalTime / 60;
    NSInteger durSec = totalTime % 60;
    if (!self.isDragged) {
        self.videoSlider.value           = value;
        self.bottomProgressView.progress = value;
        self.currentTimeLabel.text       = [NSString stringWithFormat:@"%02zd:%02zd", proMin, proSec];
    }

    self.totalTimeLabel.text = [NSString stringWithFormat:@"%02zd:%02zd", durMin, durSec];
}

- (void)sl_playerDraggedTime:(NSInteger)draggedTime totalTime:(NSInteger)totalTime isForward:(BOOL)forawrd hasPreview:(BOOL)preview {
    [self.loadingView stopAnimating];
    NSInteger proMin = draggedTime / 60;
    NSInteger proSec = draggedTime % 60;
    
    NSInteger durMin = totalTime / 60;
    NSInteger durSec = totalTime % 60;
    
    NSString *currentTimeStr = [NSString stringWithFormat:@"%02zd:%02zd", proMin, proSec];
    NSString *totalTimeStr   = [NSString stringWithFormat:@"%02zd:%02zd", durMin, durSec];
    CGFloat  draggedValue    = (CGFloat)draggedTime/(CGFloat)totalTime;
    NSString *timeStr        = [NSString stringWithFormat:@"%@ / %@", currentTimeStr, totalTimeStr];
    
    self.videoSlider.value            = draggedValue;
    self.bottomProgressView.progress  = draggedValue;
    self.dragged = YES;
    
    if (forawrd) {
        self.fastImageView.image = SLPlayerImage(@"SLPlayer_fast_forward");
    } else {
        self.fastImageView.image = SLPlayerImage(@"SLPlayer_fast_backward");
    }
    self.fastView.hidden           = preview;
    self.fastTimeLabel.text        = timeStr;
    self.fastProgressView.progress = draggedValue;
}

- (void)sl_playerDraggedEnd {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.fastView.hidden = YES;
    });
    self.dragged = NO;
    self.startBtn.selected = YES;
    [self autoFadeOutControlView];
}

- (void)sl_playerDraggedTime:(NSInteger)draggedTime sliderImage:(UIImage *)image; {
    self.fastView.hidden = YES;
}

- (void)sl_playerSetProgress:(CGFloat)progress {
    [self.progressView setProgress:progress animated:NO];
}

- (void)sl_playerItemStatusFailed:(NSError *)error {
    self.failBtn.hidden = NO;
}

- (void)sl_playerActivity:(BOOL)animated {
    if (animated) {
        [self.loadingView startAnimating];
        self.fastView.hidden = YES;
    } else {
        [self.loadingView stopAnimating];
    }
}

- (void)sl_playerPlayEnd {
    self.repeatBtn.hidden = NO;
    self.playeEnd         = YES;
    self.showing          = NO;
    [self hideControlView];
    self.backgroundColor  = RGBA(0, 0, 0, .3);
    SLPlayerShared.isStatusBarHidden = NO;
    self.bottomProgressView.alpha = 0;
}

- (void)sl_playerHasDownloadFunction:(BOOL)sender {
    self.downLoadBtn.hidden = !sender;
}

- (void)sl_playerResolutionArray:(NSArray *)resolutionArray {
    self.resolutionBtn.hidden = NO;
    
    _resolutionArray = resolutionArray;
    [_resolutionBtn setTitle:resolutionArray.firstObject forState:UIControlStateNormal];
    self.resolutionView = [[UIView alloc] init];
    self.resolutionView.hidden = YES;
    self.resolutionView.backgroundColor = RGBA(0, 0, 0, 0.7);
    [self addSubview:self.resolutionView];
    
    [self.resolutionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(40);
        make.height.mas_equalTo(25*resolutionArray.count);
        make.leading.equalTo(self.resolutionBtn.mas_leading).offset(0);
        make.top.equalTo(self.resolutionBtn.mas_bottom).offset(0);
    }];
    
    for (NSInteger i = 0 ; i < resolutionArray.count; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.layer.borderColor = [UIColor whiteColor].CGColor;
        btn.layer.borderWidth = 0.5;
        btn.tag = 200+i;
        btn.frame = CGRectMake(0, 25*i, 40, 25);
        btn.titleLabel.font = [UIFont systemFontOfSize:12];
        [btn setTitle:resolutionArray[i] forState:UIControlStateNormal];
        if (i == 0) {
            self.resoultionCurrentBtn = btn;
            btn.selected = YES;
            btn.backgroundColor = RGBA(86, 143, 232, 1);
        }
        [self.resolutionView addSubview:btn];
        [btn addTarget:self action:@selector(changeResolution:) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)sl_playerPlayBtnState:(BOOL)state {
    self.startBtn.selected = state;
}

- (void)sl_playerLockBtnState:(BOOL)state {
    self.lockBtn.selected = state;
}

- (void)sl_playerDownloadBtnState:(BOOL)state {
    self.downLoadBtn.enabled = state;
}

@end


