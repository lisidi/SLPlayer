//
//  SLMarco.h
//  SLPlayer_test
//
//  Created by lisd on 2017/12/8.
//  Copyright © 2017年 lisd. All rights reserved.
//

#ifndef SLMarco_h
#define SLMarco_h

#define iPhone4s ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640, 960), [[UIScreen mainScreen] currentMode].size) : NO)
// 监听TableView的contentOffset
#define kSLPlayerViewContentOffset          @"contentOffset"
// player的单例
#define SLPlayerShared                      [SLBrightnessView sharedBrightnessView]
// 屏幕的宽
#define ScreenWidth                         [[UIScreen mainScreen] bounds].size.width
// 屏幕的高
#define ScreenHeight                        [[UIScreen mainScreen] bounds].size.height
// 颜色值RGB
#define RGBA(r,g,b,a)                       [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:a]
// 图片路径
#define SLPlayerSrcName(file)               [@"SLPlayer.bundle" stringByAppendingPathComponent:file]

#define SLPlayerFrameworkSrcName(file)      [@"Frameworks/SLPlayer.framework/SLPlayer.bundle" stringByAppendingPathComponent:file]

#define SLPlayerImage(file)                 [UIImage imageNamed:SLPlayerSrcName(file)] ? :[UIImage imageNamed:SLPlayerFrameworkSrcName(file)]

#define SLPlayerOrientationIsLandscape      UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation)

#define SLPlayerOrientationIsPortrait       UIDeviceOrientationIsPortrait([UIDevice currentDevice].orientation)

#endif /* SLMarco_h */
