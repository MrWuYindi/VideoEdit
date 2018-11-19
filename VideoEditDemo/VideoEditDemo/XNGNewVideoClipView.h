//
//  XNGNewVideoClipView.h
//  VideoEditDemo
//
//  Created by 吴吟迪 on 2018/11/15.
//  Copyright © 2018 吴吟迪. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

typedef void(^BlockOfValueDidChanged)(double left, double right);

@class XNGNewVideoClipView;
@protocol XNGNewVideoClipViewDelegate <NSObject>
- (void)videoClipView:(XNGNewVideoClipView *)videoClipView sliderValueDidChangedOfLeft:(double)left right:(double)right;
@end

@interface XNGNewVideoClipView : UIView

/** 最小值，根据传入的值做赋值； */
@property (nonatomic,assign) double minValue;
/** 最大值，根据传入的值做赋值；如果是从未修改过的视频，传入的最小值和最大值都是0，这是需要根据视频的长度进行判断，如果视频的长度大于30，那么最大值就是30，否则就是视频的长度 */
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

/** 播放进度滑块 方法1 */
- (void)setCenterCursorPosition:(CGFloat)time;


/** 播放进度滑块 方法2 */
- (void)beginTimerAction;
- (void)endTimerAction;
- (void)sliderInitialStatus;

@end
