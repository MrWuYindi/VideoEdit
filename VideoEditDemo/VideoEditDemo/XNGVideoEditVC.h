//
//  XNGVideoEditVC.h
//  VideoEditDemo
//
//  Created by 吴吟迪 on 2018/11/12.
//  Copyright © 2018 吴吟迪. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XNGVideoEditVC : UIViewController

@property (nonatomic, copy) NSString * videoUrl;    // 视频的URL：没有经过剪切的原生视频

@property (nonatomic, assign) NSInteger beginMusicTime;  // 毫秒

@property (nonatomic, assign) NSInteger endMusicTime;    // 毫秒

@end
