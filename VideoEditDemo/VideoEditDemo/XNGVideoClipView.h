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
// 滑动时回调
- (void)videoClipViewDidScroll:(XNGVideoClipView *)videoClipView contentOffsetX:(CGFloat)offsetX;

// 停止滑动，只调用一次
- (void)videoClipViewDidEndDragging:(XNGVideoClipView *)videoClipView contentOffsetX:(CGFloat)offsetX;

@end

@interface XNGVideoClipView : UIView

@property (nonatomic, weak) id<XNGVideoClipViewDelegate> delegate;

// 进度滑块定时器
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *sliderLeftConstraint;

- (instancetype)initWithFrame:(CGRect)frame imageSource:(NSArray *)images;

/**
 设置模型变量
 
 @param imageSources 外界传递的模型
 */
- (void)setModel:(NSMutableArray<UIImage *> *)imageSources;

- (void)setSliderPosition:(NSTimeInterval)time;

/**
 设置时间显示控件
 */
- (void)settingBegin:(NSTimeInterval)begin;

@end
