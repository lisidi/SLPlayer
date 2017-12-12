//
//  SLPlayerModel.h
//  SLPlayer
//
//  Created by lisd on 2017/12/12.
//  Copyright © 2017年 lisd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@interface SLPlayerModel : NSObject

@property (nonatomic, copy  ) NSString     *title;
@property (nonatomic, strong) NSURL        *videoURL;
@property (nonatomic, strong) UIImage      *placeholderImage;
@property (nonatomic, weak  ) UIView       *fatherView;
@property (nonatomic, copy  ) NSString     *placeholderImageURLString;
@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *resolutionDic;
@property (nonatomic, assign) NSInteger    seekTime;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) NSIndexPath  *indexPath;
@property (nonatomic, assign) NSInteger    fatherViewTag;

@end
