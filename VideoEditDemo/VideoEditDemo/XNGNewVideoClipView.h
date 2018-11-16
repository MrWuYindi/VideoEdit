//
//  XNGNewVideoClipView.h
//  VideoEditDemo
//
//  Created by 吴吟迪 on 2018/11/15.
//  Copyright © 2018 吴吟迪. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

/**
 @property (nonatomic,copy) void(^blockOfValueDidChanged)(double left, double right);
 */
typedef void(^BlockOfValueDidChanged)(double left, double right);

@class XNGNewVideoClipView;
@protocol XNGNewVideoClipViewDelegate <NSObject>
- (void)videoClipView:(XNGNewVideoClipView *)videoClipView sliderValueDidChangedOfLeft:(double)left right:(double)right;
@end
/**
 *双滑块选择器(Double slider selector)
 *可设置制精度和取值位置，可设置控件样式(Can set the precision and value position, can set control style)
 *便利的使用性(Ease to use)
 *注意(Attention)：
 *控件高度固定为游标按钮宽度(itemSize)，且不可更改;(The control height is fixed as the cursor button width (itemSize) and cannot be changed.)
 *使用KVC可以完全控制游标接触时的刻度差值:[slider setValue:@(5) forKey:@"_valueMargin"];(using KVC can completely control the scale difference when the cursor is in contact:[slider setValue:@(5) forKey:@"valueMargin"])
 */
@interface XNGNewVideoClipView : UIView

/** 最小刻度，默认1.0(Minimum scale, default 1.0) */
@property (nonatomic,assign) double minimumSize;
/** 最小值，默认0.0；使用[update]展示变化(default is 0.0;Use [update] to show changes) */
@property (nonatomic,assign) double minValue;
/** 最大值，默认30.0；使用[update]展示变化(default is 100.0;Use [update] to show changes) */
@property (nonatomic,assign) double maxValue;

@property (nonatomic,weak) id<XNGNewVideoClipViewDelegate> delegate;
@property (nonatomic,copy) BlockOfValueDidChanged blockOfValueDidChanged;

/**
 双向滑块选择器构造方法

 @param frame 选择器的frame
 @param beginTime 开始播放时间
 @param endTime 停止播放时间
 @return 双向选择器的对象
 */
- (instancetype)initWithFrame:(CGRect)frame
                          bmt:(CGFloat)beginTime
                          emt:(CGFloat)endTime;

/**
 获取关键帧图片，并刷新数据

 @param asset AVURLAsset
 */
- (void)addFrames:(AVURLAsset *)asset;

@end
