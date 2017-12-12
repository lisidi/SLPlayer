//
//  SLBrightnessView.h
//  SLPlayer
//
//  Created by lisd on 2017/12/12.
//  Copyright © 2017年 lisd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SLBrightnessView : UIView

@property (nonatomic, assign) BOOL     isLockScreen;
@property (nonatomic, assign) BOOL     isAllowLandscape;
@property (nonatomic, assign) BOOL     isStatusBarHidden;
@property (nonatomic, assign) BOOL     isLandscape;

+ (instancetype)sharedBrightnessView;

@end
