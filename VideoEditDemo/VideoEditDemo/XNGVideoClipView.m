//
//  XNGVideoClipView.m
//  VideoEditDemo
//
//  Created by 吴吟迪 on 2018/11/12.
//  Copyright © 2018 吴吟迪. All rights reserved.
//

#import "XNGVideoClipView.h"
#import "XNGVideoClipViewCell.h"

#define cellId   @"XNGVideoClipViewCellId"

@interface XNGVideoClipView ()<UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout> {
    NSInteger beginIndex;   // 刚开始构建为0，从0开始播放；当滑动时根据contentOffSet计算beginIndex,单位是秒
}

@property (weak, nonatomic) IBOutlet UIView *topLineView;
@property (weak, nonatomic) IBOutlet UIView *bottomLineView;
@property (weak, nonatomic) IBOutlet UIView *leftLineView;
@property (weak, nonatomic) IBOutlet UIView *rightLineView;

@property (weak, nonatomic) IBOutlet UILabel *startTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *endTimeLabel;

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray * imageSource;

@end

@implementation XNGVideoClipView

- (instancetype)initWithFrame:(CGRect)frame imageSource:(NSArray *)images {
    self = [super initWithFrame:frame];
    if (self) {
        self = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:self options:nil][0];
        self.frame = frame;
        beginIndex = 0;
        self.imageSource = [NSMutableArray arrayWithArray:images];
        [self collectionViewConfig];
        [self layoutLineView];
    }
    return self;
}

/**
 collectionView 基本配置
 */
- (void)collectionViewConfig {
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    // 注册cell
    [_collectionView registerClass:[XNGVideoClipViewCell class] forCellWithReuseIdentifier:cellId];
}

/**
 画出边框的样式
 */
- (void)layoutLineView {
    //设置切哪个直角
    /**
     *  UIRectCornerTopLeft     = 1 << 0,  左上角
     *  UIRectCornerTopRight    = 1 << 1,  右上角
     *  UIRectCornerBottomLeft  = 1 << 2,  左下角
     *  UIRectCornerBottomRight = 1 << 3,  右下角
     *  UIRectCornerAllCorners  = ~0UL     全部角
     */
    //得到view的遮罩路径
    UIBezierPath * topMaskPath = [UIBezierPath bezierPathWithRoundedRect:self.topLineView.bounds byRoundingCorners:UIRectCornerTopLeft|UIRectCornerTopRight cornerRadii:CGSizeMake(3, 3)];
    UIBezierPath * bottomMaskPath = [UIBezierPath bezierPathWithRoundedRect:self.bottomLineView.bounds byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight cornerRadii:CGSizeMake(3, 3)];
    UIBezierPath * leftMaskPath = [UIBezierPath bezierPathWithRoundedRect:self.leftLineView.bounds byRoundingCorners:UIRectCornerTopLeft|UIRectCornerBottomLeft cornerRadii:CGSizeMake(3, 3)];
    UIBezierPath * rightMaskPath = [UIBezierPath bezierPathWithRoundedRect:self.rightLineView.bounds byRoundingCorners:UIRectCornerTopRight|UIRectCornerBottomRight cornerRadii:CGSizeMake(3, 3)];
    //创建 layer
    CAShapeLayer * topMaskLayer = [[CAShapeLayer alloc] init];
    topMaskLayer.frame = self.topLineView.bounds;
    CAShapeLayer * bottomMaskLayer = [[CAShapeLayer alloc] init];
    bottomMaskLayer.frame = self.bottomLineView.bounds;
    CAShapeLayer * leftMaskLayer = [[CAShapeLayer alloc] init];
    leftMaskLayer.frame = self.leftLineView.bounds;
    CAShapeLayer * rightMaskLayer = [[CAShapeLayer alloc] init];
    rightMaskLayer.frame = self.rightLineView.bounds;
    //赋值
    topMaskLayer.path = topMaskPath.CGPath;
    self.topLineView.layer.mask = topMaskLayer;
    bottomMaskLayer.path = bottomMaskPath.CGPath;
    self.bottomLineView.layer.mask = bottomMaskLayer;
    leftMaskLayer.path = leftMaskPath.CGPath;
    self.leftLineView.layer.mask = leftMaskLayer;
    rightMaskLayer.path = rightMaskPath.CGPath;
    self.rightLineView.layer.mask = rightMaskLayer;
}

#pragma mark ========= UICollectionViewDataSource =========
// 指定Section个数
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

// 指定section中的collectionViewCell的个数
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 20;
}

// 配置section中的collectionViewCell的显示
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    XNGVideoClipViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellId forIndexPath:indexPath];
    cell.contentView.backgroundColor = [UIColor colorWithRed:((float)arc4random_uniform(256) / 255.0) green:((float)arc4random_uniform(256) / 255.0) blue:((float)arc4random_uniform(256) / 255.0) alpha:1.0];

//    cell.imageView = self.imageSource[indexPath.row];

    return cell;
}

#pragma mark ========= UICollectionViewDelegateFlowLayout =========

//每个cell的大小，因为有indexPath，所以可以判断哪一组，或者哪一个item，可一个给特定的大小，等同于layout的itemSize属性
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(40, 70); // 宽度不确定需要确定30面显示多少张图片，再用屏幕宽度减去20除以图片张数就是图片的宽度
}

// 设置整个组的缩进量是多少
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 0, 0, 0);
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
//    if (self.clickRecommendProduct) {
//        self.clickRecommendProduct(indexPath.row);
//    }
}

@end
