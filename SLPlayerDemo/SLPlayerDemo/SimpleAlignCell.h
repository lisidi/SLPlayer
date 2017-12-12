//
//  SimpleAlignCell.h
//  XYMaintenance
//
//  Created by DamocsYang on 15/8/12.
//  Copyright (c) 2015年 Kingnet. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SimpleAlignCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *xyTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *xyDetailLabel;
@property (weak, nonatomic) IBOutlet UIImageView *xyIndicator;

+ (NSString*)defaultReuseId;
@property (nonatomic, copy) void(^playBlock)(UIButton *);
@end
