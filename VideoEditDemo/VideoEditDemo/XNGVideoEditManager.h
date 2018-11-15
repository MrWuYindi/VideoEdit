//
//  XNGVideoEditManager.h
//  VideoEditDemo
//
//  Created by 吴吟迪 on 2018/11/13.
//  Copyright © 2018 吴吟迪. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

/**
 *  这是图片视频编辑管理类：预览视频和最后的制作视频
 *  需要实现的功能有一下2个：
 *      1、视频原声文件去除原声，添加背景音乐，保留视频原声文件
 *      2、视频原生文件添加背景音乐，形成混音视频文件，保留视频原生文件
 *  具体实现可分为一下几个方法实现：
 *      1、去除视频原声方法
 *      2、添加背景音乐到已经去除原声的视频文件方法
 *      3、视频原声文件添加背景音乐方法
 *      4、保留视频原声文件方法
 */

@interface XNGVideoEditManager : NSObject

+ (id)shareVideoEditManager;

#pragma mark === 视频预览过程 ===
/*
 给定视频URL，解析出相应时间的视频帧
 */
-(UIImage *)getAsset:(AVURLAsset *)asset currectTime:(CGFloat)second;

@end
