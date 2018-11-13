//
//  XNGVideoClipViewCell.m
//  VideoEditDemo
//
//  Created by 吴吟迪 on 2018/11/13.
//  Copyright © 2018 吴吟迪. All rights reserved.
//

#import "XNGVideoClipViewCell.h"

@implementation XNGVideoClipViewCell

#pragma mark ========= InitCycle =========

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self.contentView addSubview:self.imageView];
    }
    return self;
}

#pragma mark ========= lazing =========

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] initWithFrame:self.contentView.frame];
    }
    return _imageView;
}

@end
