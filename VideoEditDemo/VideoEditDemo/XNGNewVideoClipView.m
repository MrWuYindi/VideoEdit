//
//  XNGNewVideoClipView.m
//  VideoEditDemo
//
//  Created by 吴吟迪 on 2018/11/15.
//  Copyright © 2018 吴吟迪. All rights reserved.
//

#import "XNGNewVideoClipView.h"
#import "XNGVideoClipViewCell.h"

#define CursorBtnW 20
#define CursorBtnH 65

#define cellId   @"XNGVideoClipViewCellId"

@interface XNGNewVideoClipView ()<UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray<UIImage *> * imageSource;
@property (strong, nonatomic) AVAssetImageGenerator *imageGenerator;

@property (weak, nonatomic) IBOutlet UIButton *leftCursor;   // 左滑块 {20, 65}
@property (weak, nonatomic) IBOutlet UIImageView *centerCursor;   // 中间进度滑块 {20, 65}
@property (weak, nonatomic) IBOutlet UIButton *rightCursor;  // 右滑块 {20, 65}

@property (weak, nonatomic) IBOutlet UILabel *leftTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *rightTimeLabel;

// 30s 一屏宽取10张图片、10s 一屏宽也去取10张图片，就是不管视频多长前30秒都取10张图片

//@property (nonatomic, assign) CGFloat
@property (nonatomic, assign) CGFloat unitLen;  // 30s运行(KScreenWidth-30)的长度，unitLen代表每秒运行的距离
@property (nonatomic, assign) CGFloat itemRadius;   // 定位collectionview的中心Y
@property (nonatomic, assign) CGFloat itemSize; // 滑块的宽度
@property (nonatomic, assign) CGFloat borderW;  // collectionview距离边界的距离

/** 左游标按钮值(Left cursor button value) */
@property (nonatomic, assign) double leftValue;
/** 右游标按钮初始值(Right cursor button value) */
@property (nonatomic, assign) double rightValue;

@property (nonatomic, assign) double lastSlidingOffsetX; // collectionView 滑动相对于0.00的偏移时间差；
@property (nonatomic, assign) double rightCursorValue;  // 右滑块value

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
        endTime = endTime == 0 ? 30.f : endTime;
        self.minValue = beginTime;
        self.maxValue = endTime;
        self.rightCursorValue = self.maxValue;
        [self collectionViewConfig];
        [self addGestureRecognizer];
    }
    return self;
}

/**
 基本配置
 */
- (void)baseConfig {
    self.unitLen = (KScreenWidth-30)/30;
    self.itemSize = 20.f;
    self.borderW = 5;
    self.minimumSize = 1.f;
    self.leftValue = 0.0;
    self.rightValue = 30.0;
    self.leftTimeLabel.text = [NSString stringWithFormat:@"%@", [self convertTime:self.leftValue]];
    self.rightTimeLabel.text = [NSString stringWithFormat:@"%@", [self convertTime:self.rightValue]];
//    self.centerCursor.hidden = YES;
    self.alpha = 0;
    self.lastSlidingOffsetX = 0.0f;
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
    if (pan.state == UIGestureRecognizerStateBegan) {   // 识别器已经接收识别为此手势(状态)的触摸(Began)。在下一轮run循环中，响应方法将会被调用。
        
        center = pan.view.center;
        //one finger
        self.leftCursor.userInteractionEnabled = (pan.view == self.leftCursor);
        self.rightCursor.userInteractionEnabled = (pan.view == self.rightCursor);
    } else if(pan.state == UIGestureRecognizerStateEnded) {    // 识别器已经接收到触摸，并且识别为手势结束(Ended)。在下一轮run循环中，响应方法将会被调用并且识别器将会被重置到UIGestureRecognizerStatePossible状态。
        self.leftCursor.userInteractionEnabled = YES;
        self.rightCursor.userInteractionEnabled = YES;
    }
    
    pan.view.center = CGPointMake(center.x + point.x, self.itemRadius);
    
    NSInteger totalOfCalibration = (self.maxValue - self.minValue)/self.minimumSize;//刻度总份数
    CGFloat ineffectiveLength = self.borderW*2+self.itemSize;//无效的坐标系长度
    CGFloat widthOfCalibration = (self.controlWidth-ineffectiveLength)/totalOfCalibration;//一个刻度的宽
    if (pan.state == UIGestureRecognizerStateEnded) {
        /*
         有效长度的坐标首先偏移，找整数刻度值；之后将这个整数刻度值和之前的偏移还原回坐标系统
         */
        if(pan.view == self.leftCursor){  // 左 Round函数返回一个数值，该数值是按照指定的小数位数进行四舍五入运算的结果。
            CGFloat countOfCalibration = round((pan.view.center.x - self.itemSize/2 - self.borderW)/widthOfCalibration);
            pan.view.center = CGPointMake(countOfCalibration*widthOfCalibration+ineffectiveLength/2, pan.view.center.y);
        }else{  // 右
            CGFloat countOfCalibration = round((self.controlWidth - pan.view.center.x - self.itemSize/2 - self.borderW)/widthOfCalibration);
            pan.view.center = CGPointMake(self.controlWidth - countOfCalibration*widthOfCalibration-ineffectiveLength/2, pan.view.center.y);
        }
    }
    
    // 视频剪切范围是3~30s,滑块之间的距离是最少 3*widthOfCalibration
    if(pan.view == self.leftCursor){
        
        if (CGRectGetMidX(self.leftCursor.frame) > CGRectGetMidX(self.rightCursor.frame) - 3*widthOfCalibration) {  // 俩滑块中间线距离小于3个单位长度
            CGRect frame = self.leftCursor.frame;
            frame.origin.x = CGRectGetMinX(self.rightCursor.frame) - 3*widthOfCalibration;
            self.leftCursor.frame = frame;
        }else{
            if (pan.view.center.x < self.borderW + self.itemSize/2) {
                CGPoint center = self.leftCursor.center;
                center.x = self.borderW + self.itemSize/2;
                self.leftCursor.center = center;
            }
            if (pan.view.center.x > CGRectGetWidth(self.bounds)-self.borderW-self.itemSize/2) {
                CGPoint center = self.leftCursor.center;
                center.x = CGRectGetWidth(self.bounds)-self.borderW-self.itemSize/2;
                self.leftCursor.center = center;
            }
        }
        
        _leftValue = round((self.leftCursor.center.x-self.borderW-self.itemSize/2)/widthOfCalibration)*self.minimumSize+self.minValue + self.lastSlidingOffsetX;
        self.leftTimeLabel.text = [NSString stringWithFormat:@"%@", [self convertTime:self.leftValue]];

        if(self.blockOfValueDidChanged){
            self.blockOfValueDidChanged(_leftValue , _rightValue);
        }
        if([self.delegate respondsToSelector:@selector(videoClipView:sliderValueDidChangedOfLeft:right:)]){
            [self.delegate videoClipView:self sliderValueDidChangedOfLeft:_leftValue right:_rightValue];
        }
    } else {
        
        if (CGRectGetMidX(self.rightCursor.frame) < CGRectGetMidX(self.leftCursor.frame) + 3*widthOfCalibration) {
            CGRect frame = self.rightCursor.frame;
            frame.origin.x = CGRectGetMinX(self.leftCursor.frame) + 3*widthOfCalibration;
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
        
        _rightValue = self.maxValue - round((self.controlWidth-self.rightCursor.center.x-self.borderW-self.itemSize/2)/widthOfCalibration)*self.minimumSize;
        self.rightTimeLabel.text = [NSString stringWithFormat:@"%@", [self convertTime:self.rightValue]];

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
    NSInteger actualFramesNeeded;   // 一共需要多少图片
    Float64 durationPerFrame;   // 隔多少时间取一次图片
    
    if (duration <= 30) {
        actualFramesNeeded = 10;
        durationPerFrame = duration / (actualFramesNeeded*1.0);
    } else {
        actualFramesNeeded = duration / 3.0;
        durationPerFrame = 3.0;
    }
    
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
    
//    cell.contentView.backgroundColor = randomColor;
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
    
    NSLog(@"scrollViewWillBeginDragging");
}

//scrollView滚动时，就调用该方法。任何offset值改变都调用该方法。即滚动过程中，调用多次
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    NSInteger totalOfCalibration = (self.maxValue - self.minValue)/self.minimumSize;//刻度总份数
    CGFloat ineffectiveLength = self.borderW*2+self.itemSize;//无效的坐标系长度
    CGFloat widthOfCalibration = (self.controlWidth-ineffectiveLength)/totalOfCalibration;//一个刻度的宽
    
    _leftValue = self.minValue + round(scrollView.contentOffset.x/widthOfCalibration)*self.minimumSize;
    _rightValue = self.maxValue + round(scrollView.contentOffset.x/widthOfCalibration)*self.minimumSize;
    
    self.rightCursorValue = _rightValue;
    
    self.leftTimeLabel.text = [NSString stringWithFormat:@"%@", [self convertTime:self.leftValue]];
    self.rightTimeLabel.text = [NSString stringWithFormat:@"%@", [self convertTime:self.rightValue]];
    
    self.lastSlidingOffsetX = round(scrollView.contentOffset.x/widthOfCalibration)*self.minimumSize;
    
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
    
    NSLog(@"scrollViewWillEndDragging");
    
}

// 阻止scrollview的惯性滑动、 要在主线程执行，才有效果
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{

}

#pragma mark Lazy-Load

- (NSMutableArray<UIImage *> *)imageSource {
    if (!_imageSource) {
        _imageSource = [NSMutableArray<UIImage *> array];
    }
    return _imageSource;
}

@end
