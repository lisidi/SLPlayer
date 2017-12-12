//
//  SLPlayerControlViewDelagate.h
//  SLPlayer
//
//  Created by lisd on 2017/12/12.
//  Copyright © 2017年 lisd. All rights reserved.
//

@protocol SLPlayerControlViewDelagate <NSObject>

@optional

- (void)sl_controlView:(UIView *)controlView backAction:(UIButton *)sender;
- (void)sl_controlView:(UIView *)controlView closeAction:(UIButton *)sender;
- (void)sl_controlView:(UIView *)controlView playAction:(UIButton *)sender;
- (void)sl_controlView:(UIView *)controlView fullScreenAction:(UIButton *)sender;
- (void)sl_controlView:(UIView *)controlView lockScreenAction:(UIButton *)sender;
- (void)sl_controlView:(UIView *)controlView repeatPlayAction:(UIButton *)sender;
- (void)sl_controlView:(UIView *)controlView cneterPlayAction:(UIButton *)sender;
- (void)sl_controlView:(UIView *)controlView failAction:(UIButton *)sender;
- (void)sl_controlView:(UIView *)controlView downloadVideoAction:(UIButton *)sender;
- (void)sl_controlView:(UIView *)controlView resolutionAction:(UIButton *)sender;
- (void)sl_controlView:(UIView *)controlView progressSliderTap:(CGFloat)value;
- (void)sl_controlView:(UIView *)controlView progressSliderTouchBegan:(UISlider *)slider;
- (void)sl_controlView:(UIView *)controlView progressSliderValueChanged:(UISlider *)slider;
- (void)sl_controlView:(UIView *)controlView progressSliderTouchEnded:(UISlider *)slider;
- (void)sl_controlViewWillShow:(UIView *)controlView isFullscreen:(BOOL)fullscreen;
- (void)sl_controlViewWillHidden:(UIView *)controlView isFullscreen:(BOOL)fullscreen;

@end
