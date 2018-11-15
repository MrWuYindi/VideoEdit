//
//  XNGVideoEditManager.m
//  VideoEditDemo
//
//  Created by 吴吟迪 on 2018/11/13.
//  Copyright © 2018 吴吟迪. All rights reserved.
//

#import "XNGVideoEditManager.h"

@interface XNGVideoEditManager ()

@end
@implementation XNGVideoEditManager

+ (id)shareVideoEditManager {
    static XNGVideoEditManager * _manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _manager = [[XNGVideoEditManager alloc] init];
    });
    return _manager;
}

/**
 获取关键帧图片是，需要压缩控制图片大小避免图片过多占用内存过大
 AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
 generator.maximumSize = CGSizeMake(KHVideoCoverImageSizeWidth*2, KHVideoCoverImageSizeHeight*2);
 
 30s 需要取出多少张图片呢？
 collectionview的30s宽度是KScreenWidth-20-6,
 一张图片的宽度是40，
 那么需要取出(KScreenWidth-26)/40向上取整张图片，也就是ceil((KScreenWidth-26)/40)
 取(KScreenWidth-26)/40张图片则需要每隔30s/((KScreenWidth-26)/40)s取一张图片，1200/(KScreenWidth-26)s
 
 CMTimeMake(a,b)    a当前第几帧, b每秒钟多少帧.当前播放时间a/b
 CMTimeMakeWithSeconds(a,b) a当前时间,b每秒钟多少帧.
 
 */
-(UIImage *)getAsset:(AVURLAsset *)asset currectTime:(CGFloat)second {
    AVAssetImageGenerator *gen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    AVPlayerItem *item = [[AVPlayerItem alloc]initWithAsset:asset];
    gen.appliesPreferredTrackTransform = YES;
    gen.maximumSize = CGSizeMake((KScreenWidth-26)/10, 60);
    gen.requestedTimeToleranceAfter = kCMTimeZero;
    gen.requestedTimeToleranceBefore = kCMTimeZero;
    CMTime time = CMTimeMakeWithSeconds(second, item.currentTime.timescale);
    NSError *error = nil;
    CMTime actualTime;
    CGImageRef image = [gen copyCGImageAtTime:time actualTime:&actualTime error:&error];
    UIImage *thumb = [[UIImage alloc] initWithCGImage:image];
    CGImageRelease(image);
    return thumb;
}

@end
