//
//  XNGNewVideoClipView.m
//  VideoEditDemo
//
//  Created by 吴吟迪 on 2018/11/15.
//  Copyright © 2018 吴吟迪. All rights reserved.
//

#import "XNGNewVideoClipView.h"
#import "XNGVideoClipViewCell.h"

/*
 首先第一点，确定单位长度，单位时间的单位长度
 */

#define cellId   @"XNGVideoClipViewCellId"

@interface XNGNewVideoClipView ()<UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray<UIImage *> * imageSource;
@property (strong, nonatomic) AVAssetImageGenerator *imageGenerator;

@property (weak, nonatomic) IBOutlet UIButton *leftCursor;   // 左滑块 {20, 45}
@property (weak, nonatomic) IBOutlet UIView *centerCursor;   // 中间进度滑块 {20, 45}
@property (weak, nonatomic) IBOutlet UIButton *rightCursor;  // 右滑块 {20, 45}

// 初始位置设置原则
/**
 1、不能违背一个屏幕宽最多只展示30s的原则
 2、视频小于30s时，下方frames占满一个屏幕宽，一个屏幕宽就是视频的长度
 */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *leftCursorConstraint;  // 左滑块的初始位置设置   不管最小值有没有数据，都在最左侧
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *centerCursorConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *rightCursorConstraint; // 右滑块的初始位置设置

@property (weak, nonatomic) IBOutlet UILabel *leftTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *rightTimeLabel;

// 30s 一屏宽取10张图片、10s 一屏宽也去取10张图片，就是不管视频多长前30秒都取10张图片

@property (nonatomic, assign) CGFloat unitLen;  // 运行(KScreenWidth-30)的长度，unitLen代表每秒运行的距离
@property (nonatomic, assign) CGFloat itemRadius;   // 定位collectionview的中心Y
@property (nonatomic, assign) CGFloat itemSize; // 滑块的宽度
@property (nonatomic, assign) CGFloat borderW;  // collectionview距离边界的距离

/** 左游标按钮值(Left cursor button value) */
@property (nonatomic, assign) double leftValue;
/** 右游标按钮初始值(Right cursor button value) */
@property (nonatomic, assign) double rightValue;
/** 初始化collectionView 滑动相对于0.00的偏移时间差 */
@property (nonatomic, assign) double lastSlidingOffsetX;

@end

@implementation XNGNewVideoClipView

- (instancetype)initWithFrame:(CGRect)frame
                          bmt:(CGFloat)beginTime
                          emt:(CGFloat)endTime {
    
    self = [super initWithFrame:frame];
    if (self) {
        self = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:self options:nil][0];
        self.frame = frame;
        [self baseConfig];
        self.minValue = beginTime;
        self.maxValue = endTime;
        [self collectionViewConfig];
        [self addGestureRecognizer];
    }
    return self;
}

/**
 基本默认配置
 - 
 */
- (void)baseConfig {
    self.itemSize = 20.f;
    self.borderW = 5;
    self.leftValue = self.minValue;
    self.rightValue = self.maxValue;
    self.leftCursorConstraint.constant = self.borderW;
    self.centerCursorConstraint.constant = self.borderW + 8.5;
    self.leftTimeLabel.text = [NSString stringWithFormat:@"%@", [self convertTime:self.leftValue]];
    self.rightTimeLabel.text = [NSString stringWithFormat:@"%@", [self convertTime:self.rightValue]];
    self.alpha = 0;
}

/**
 collectionView 基本配置
 */
- (void)collectionViewConfig {
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.showsHorizontalScrollIndicator = NO;
    self.collectionView.bounces = NO;
    // 注册cell
    [_collectionView registerClass:[XNGVideoClipViewCell class] forCellWithReuseIdentifier:cellId];
}

/**
 添加手势
 */
- (void)addGestureRecognizer {
    UIPanGestureRecognizer* padLeft = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(eventPan:)];
    UIPanGestureRecognizer* padRight = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(eventPan:)];
    
    [self.leftCursor addGestureRecognizer:padLeft];
    [self.rightCursor addGestureRecognizer:padRight];
}

#pragma mark 触摸事件
- (void)eventPan:(UIPanGestureRecognizer*)pan
{
    /**
     locationInView:获取到的是手指点击屏幕实时的坐标点；
     translationInView：获取到的是手指移动后，在相对坐标中的偏移量
     */
    CGPoint point = [pan translationInView:self];
    static CGPoint center;
    if (pan.state == UIGestureRecognizerStateBegan) {
        // 识别器已经接收识别为此手势(状态)的触摸(Began)。在下一轮run循环中，响应方法将会被调用。
        center = pan.view.center;
        //one finger
        self.leftCursor.userInteractionEnabled = (pan.view == self.leftCursor);
        self.rightCursor.userInteractionEnabled = (pan.view == self.rightCursor);
    } else if(pan.state == UIGestureRecognizerStateEnded) {
        // 识别器已经接收到触摸，并且识别为手势结束(Ended)。在下一轮run循环中，响应方法将会被调用并且识别器将会被重置到UIGestureRecognizerStatePossible状态。
        self.leftCursor.userInteractionEnabled = YES;
        self.rightCursor.userInteractionEnabled = YES;
    }
    
    pan.view.center = CGPointMake(center.x + point.x, self.itemRadius);
    
    CGFloat ineffectiveLength = self.borderW*2+self.itemSize;//无效的坐标系长度
    if (pan.state == UIGestureRecognizerStateEnded) {
        // 有效长度的坐标首先偏移，找整数刻度值；之后将这个整数刻度值和之前的偏移还原回坐标系统
        if(pan.view == self.leftCursor){  // 左 Round函数返回一个数值，该数值是按照指定的小数位数进行四舍五入运算的结果。
            CGFloat countOfCalibration = round((pan.view.center.x - ineffectiveLength/2)/self.unitLen);
            pan.view.center = CGPointMake(countOfCalibration*self.unitLen+ineffectiveLength/2, pan.view.center.y);
            self.centerCursor.center = CGPointMake(countOfCalibration*self.unitLen+ineffectiveLength/2, pan.view.center.y);
        }else{  // 右
            CGFloat countOfCalibration = round((self.controlWidth - pan.view.center.x - ineffectiveLength/2)/self.unitLen);
            pan.view.center = CGPointMake(self.controlWidth - countOfCalibration*self.unitLen-ineffectiveLength/2, pan.view.center.y);
        }
    }
    
    // 视频剪切范围是3~30s,滑块之间的最小距离是 3*self.unitLen
    if(pan.view == self.leftCursor){
        
        if (CGRectGetMidX(self.leftCursor.frame) > CGRectGetMidX(self.rightCursor.frame) - 3*self.unitLen) {  // 俩滑块中间线距离小于3个单位长度
            CGRect frame = self.leftCursor.frame;
            frame.origin.x = CGRectGetMinX(self.rightCursor.frame) - 3*self.unitLen;
            self.leftCursor.frame = frame;
            
            CGRect centerFrame = self.self.centerCursor.frame;
            centerFrame.origin.x = CGRectGetMinX(self.rightCursor.frame) + 8.5;
            self.centerCursor.frame = centerFrame;
        }else{
            if (pan.view.center.x < self.borderW + self.itemSize/2) {
                CGPoint center = self.leftCursor.center;
                center.x = self.borderW + self.itemSize/2;
                self.leftCursor.center = center;
                self.centerCursor.center = center;
            }
            if (pan.view.center.x > CGRectGetWidth(self.bounds)-self.borderW-self.itemSize/2) {
                CGPoint center = self.leftCursor.center;
                center.x = CGRectGetWidth(self.bounds)-self.borderW-self.itemSize/2;
                self.leftCursor.center = center;
                self.centerCursor.center = center;
            }
        }
        
        _leftValue = round((self.leftCursor.center.x-self.borderW-self.itemSize/2+self.collectionView.contentOffset.x)/self.unitLen);
        self.leftTimeLabel.text = [NSString stringWithFormat:@"%@", [self convertTime:self.leftValue]];
        self.leftCursorConstraint.constant = self.leftCursor.center.x-self.itemSize/2;
        self.centerCursorConstraint.constant = self.leftCursor.center.x-1.5;
        
        if(self.blockOfValueDidChanged){
            self.blockOfValueDidChanged(_leftValue , _rightValue);
        }
        if([self.delegate respondsToSelector:@selector(videoClipView:sliderValueDidChangedOfLeft:right:)]){
            [self.delegate videoClipView:self sliderValueDidChangedOfLeft:_leftValue right:_rightValue];
        }
    } else {
        
        if (CGRectGetMidX(self.rightCursor.frame) < CGRectGetMidX(self.leftCursor.frame) + 3*self.unitLen) {
            CGRect frame = self.rightCursor.frame;
            frame.origin.x = CGRectGetMinX(self.leftCursor.frame) + 3*self.unitLen;
            self.rightCursor.frame = frame;
        }else{
            if (pan.view.center.x < self.borderW + self.itemSize/2) {
                CGPoint center = self.rightCursor.center;
                center.x = self.borderW + self.itemSize/2;
                self.rightCursor.center = center;
            }
            if (pan.view.center.x > CGRectGetWidth(self.bounds)-self.borderW-self.itemSize/2) {
                CGPoint center = self.rightCursor.center;
                center.x = CGRectGetWidth(self.bounds)-self.borderW-self.itemSize/2;
                self.rightCursor.center = center;
            }
        }
        
        _rightValue = round((self.rightCursor.center.x-self.borderW-self.itemSize/2+self.collectionView.contentOffset.x)/self.unitLen);
        self.rightTimeLabel.text = [NSString stringWithFormat:@"%@", [self convertTime:self.rightValue]];
        self.rightCursorConstraint.constant = self.controlWidth - self.rightCursor.center.x - self.itemSize/2;
        
        if(self.blockOfValueDidChanged){
            self.blockOfValueDidChanged(_leftValue , _rightValue);
        }
        if([self.delegate respondsToSelector:@selector(videoClipView:sliderValueDidChangedOfLeft:right:)]){
            [self.delegate videoClipView:self sliderValueDidChangedOfLeft:_leftValue right:_rightValue];
        }
    }
}

- (CGFloat)itemRadius
{
    return CGRectGetMidY(self.collectionView.frame);
}

- (CGFloat)controlWidth
{
    return KScreenWidth;
}

- (void)setCenterCursorPosition:(CGFloat)time {
    self.centerCursorConstraint.constant = (time - self.leftValue)*self.unitLen + self.leftCursor.center.x - 1.5;
}

- (void)addFrames:(AVURLAsset *)asset
{
    AVPlayerItem * item = [[AVPlayerItem alloc] initWithAsset:asset];
    self.imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    self.imageGenerator.appliesPreferredTrackTransform = YES;
    if ([self isRetina]){   // ((KScreenWidth-30)/10, 45)
        self.imageGenerator.maximumSize = CGSizeMake((KScreenWidth-30)/10*2, 45*2);
    } else {
        self.imageGenerator.maximumSize = CGSizeMake((KScreenWidth-30)/10, 45);
    }
    Float64 duration = CMTimeGetSeconds([asset duration]); // 视频的长度
    if (self.maxValue == 0.0f) {    // 原始视频文件，没有经过视频剪辑，minValue和maxValue都是0.0
        if (duration >= 30.f) {
            self.maxValue = 30.f;
        } else {
            self.maxValue = duration;
        }
        self.rightValue = self.maxValue;
        self.rightTimeLabel.text = [NSString stringWithFormat:@"%@", [self convertTime:self.rightValue]];
    }
    NSInteger actualFramesNeeded;   // 一共需要多少图片
    __block Float64 durationPerFrame;   // 隔多少时间取一次图片
    
    if (duration <= 30) {   // 如果视频长度小于等30s
        actualFramesNeeded = 10;
        durationPerFrame = duration / (actualFramesNeeded*1.0);
        self.unitLen = (self.controlWidth - self.borderW*2 - self.itemSize) / duration; // 1s 运行的距离
    } else {
        actualFramesNeeded = duration / 3.0;
        durationPerFrame = 3.0;
        self.unitLen = (self.controlWidth - 30) / 30; // 1s 运行的距离
    }
    
    self.lastSlidingOffsetX = self.minValue * self.unitLen; // 记录下初始collectionView的偏移量
    self.rightCursorConstraint.constant = self.controlWidth - self.borderW - self.itemSize - self.unitLen*(self.maxValue-self.minValue);
    
    NSMutableArray *times = [[NSMutableArray alloc] init];
    for (int i=0; i<actualFramesNeeded; i++){
        CMTime time = CMTimeMakeWithSeconds(i*durationPerFrame, item.currentTime.timescale);
        [times addObject:[NSValue valueWithCMTime:time]];
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (int i=1; i<=[times count]; i++) {
            CMTime time = [((NSValue *)[times objectAtIndex:i-1]) CMTimeValue];
            
            CGImageRef halfWayImage = [self.imageGenerator copyCGImageAtTime:time actualTime:NULL error:NULL];
            
            UIImage *videoScreen;
            if ([self isRetina]){
                videoScreen = [[UIImage alloc] initWithCGImage:halfWayImage scale:2.0 orientation:UIImageOrientationUp];
            } else {
                videoScreen = [[UIImage alloc] initWithCGImage:halfWayImage];
            }
            if (videoScreen) {
                [self.imageSource addObject:videoScreen];
            } else {
                [self.imageSource addObject:self.imageSource.lastObject];
            }
            CGImageRelease(halfWayImage);
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.collectionView reloadData];
            // 根据minValue的值，初始化设置collectionView的偏移量
            self.collectionView.contentOffset = CGPointMake(self.minValue*self.unitLen, self.collectionView.contentOffset.y);
            self.alpha = 1;
        });
    });
}

- (BOOL)isRetina
{
    return ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] &&
            ([UIScreen mainScreen].scale > 1.0));
}

#pragma mark >>> 时间戳转换
- (NSString *)convertTime:(CGFloat)second{
    NSDate *d = [NSDate dateWithTimeIntervalSince1970:second];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    if (second/3600 >= 1) {
        [formatter setDateFormat:@"HH:mm:ss"];
    } else {
        [formatter setDateFormat:@"mm:ss"];
    }
    NSString *showtimeNew = [formatter stringFromDate:d];
    return showtimeNew;
}

#pragma mark ========= UICollectionViewDataSource =========
// 指定Section个数
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

// 指定section中的collectionViewCell的个数
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.imageSource.count;
}

// 配置section中的collectionViewCell的显示
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    XNGVideoClipViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellId forIndexPath:indexPath];
    cell.imageView.image = self.imageSource[indexPath.row];
    return cell;
}

#pragma mark ========= UICollectionViewDelegateFlowLayout =========

//每个cell的大小，因为有indexPath，所以可以判断哪一组，或者哪一个item，可一个给特定的大小，等同于layout的itemSize属性
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake((KScreenWidth-30)/10, 45); // 宽度不确定需要确定30面显示多少张图片，再用屏幕宽度减去20除以图片张数就是图片的宽度
}

// 设置整个组的缩进量是多少
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 10, 0, 10);
}

// 设置最小行间距，也就是前一行与后一行的中间最小间隔
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 0.1f;
}

// 设置最小列间距，也就是左行与右一行的中间最小间隔
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 0.1f;
}

#pragma mark ========= UICollectionViewDelegate =========

// 选中操作
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
}

#pragma mark ========= UIScrollViewDelegate =========

// 当开始滚动视图时，执行该方法。一次有效滑动（开始滑动，滑动一小段距离，只要手指不松开，只算一次滑动），只执行一次。
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    DLOG(@"scrollViewWillBeginDragging");
}

//scrollView滚动时，就调用该方法。任何offset值改变都调用该方法。即滚动过程中，调用多次
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    _leftValue = round((self.leftCursor.center.x-self.borderW-self.itemSize/2+self.collectionView.contentOffset.x)/self.unitLen);
    _rightValue = round((self.rightCursor.center.x-self.borderW-self.itemSize/2+self.collectionView.contentOffset.x)/self.unitLen);
    
    self.leftTimeLabel.text = [NSString stringWithFormat:@"%@", [self convertTime:_leftValue]];
    self.rightTimeLabel.text = [NSString stringWithFormat:@"%@", [self convertTime:_rightValue]];
    
    if(self.blockOfValueDidChanged){
        self.blockOfValueDidChanged(_leftValue , _rightValue);
    }
    if([self.delegate respondsToSelector:@selector(videoClipView:sliderValueDidChangedOfLeft:right:)]){
        [self.delegate videoClipView:self sliderValueDidChangedOfLeft:_leftValue right:_rightValue];
    }
}

// 滑动scrollView，并且手指离开时执行。一次有效滑动，只执行一次。
// 当pagingEnabled属性为YES时，不调用，该方法
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset{
    DLOG(@"scrollViewWillEndDragging");
}

// 阻止scrollview的惯性滑动、 要在主线程执行，才有效果
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
//    if (decelerate)
//    {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            printf("STOP IT!!\n");
//            [scrollView setContentOffset:scrollView.contentOffset animated:NO];
//        });
//    }
}

#pragma mark Lazy-Load

- (NSMutableArray<UIImage *> *)imageSource {
    if (!_imageSource) {
        _imageSource = [NSMutableArray<UIImage *> array];
    }
    return _imageSource;
}

@end
