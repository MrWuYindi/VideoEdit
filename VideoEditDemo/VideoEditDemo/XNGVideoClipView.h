//
//  XNGVideoClipView.h
//  VideoEditDemo
//
//  Created by 吴吟迪 on 2018/11/12.
//  Copyright © 2018 吴吟迪. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XNGVideoClipView : UIView

- (instancetype)initWithFrame:(CGRect)frame imageSource:(NSArray *)images;

- (void)setModel:(NSMutableArray<UIImage *> *)imageSources;

@end
