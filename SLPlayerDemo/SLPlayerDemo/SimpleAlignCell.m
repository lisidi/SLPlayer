//
//  SimpleAlignCell.m
//  XYMaintenance
//
//  Created by lisd on 15/8/12.
//  Copyright (c) 2015年 Kingnet. All rights reserved.
//

#import "SimpleAlignCell.h"

@interface SimpleAlignCell()

@end

@implementation SimpleAlignCell

- (void)awakeFromNib {
    [super awakeFromNib];

}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

}

+ (NSString*)defaultReuseId{
   return @"SimpleAlignCell";
}

- (void)setData:(NSString*)data {
    self.xyDetailLabel.text = data;
}

- (IBAction)clickButton:(id)sender {
    !_playBlock ?: _playBlock(sender);
}

@end
