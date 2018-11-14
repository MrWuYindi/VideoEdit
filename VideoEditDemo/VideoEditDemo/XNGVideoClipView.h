//
//  XNGVideoClipView.h
//  VideoEditDemo
//
//  Created by 吴吟迪 on 2018/11/12.
//  Copyright © 2018 吴吟迪. All rights reserved.
//

#import <UIKit/UIKit.h>

@class XNGVideoClipView;
@protocol XNGVideoClipViewDelegate<NSObject>

@required
// 刚开始滑动

// 滑动时回调
- (void)videoClipViewDidScroll:(XNGVideoClipView *)videoClipView contentOffsetX:(CGFloat)offsetX;

@end

@interface XNGVideoClipView : UIView

@property (nonatomic, weak) id<XNGVideoClipViewDelegate> delegate;

- (instancetype)initWithFrame:(CGRect)frame imageSource:(NSArray *)images;

- (void)setModel:(NSMutableArray<UIImage *> *)imageSources;

@end
