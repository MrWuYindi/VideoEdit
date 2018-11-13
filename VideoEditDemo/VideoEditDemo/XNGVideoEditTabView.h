//
//  XNGVideoEditTabView.h
//  VideoEditDemo
//
//  Created by 吴吟迪 on 2018/11/13.
//  Copyright © 2018 吴吟迪. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    VideoStateVoiceConfig,  // 混音设置
    VideoStateVideoClip,    // 裁剪影片
} VideoState;

typedef void(^VideoEditSelectHandler)(VideoState state);

@interface XNGVideoEditTabView : UIView

@property (nonatomic, copy) VideoEditSelectHandler selectHandler;

@end
