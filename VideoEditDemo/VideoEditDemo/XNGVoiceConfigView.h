//
//  XNGVoiceConfigView.h
//  VideoEditDemo
//
//  Created by 吴吟迪 on 2018/11/12.
//  Copyright © 2018 吴吟迪. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    AudioStateBackground,   // 背景音乐
    AudioStateSoundMixing,  // 混音
    AudioStateVideoNative,  // 视频原生
} AudioState;

typedef void(^VoiceConfigHandler)(AudioState state);

@interface XNGVoiceConfigView : UIView

// 封装一个快速返回实例对象的类方法
+ (instancetype)voiceConfigView;

- (instancetype)initXNGViewWithFrame:(CGRect)frame;

@property (nonatomic, copy) VoiceConfigHandler voiceConfigHandler;

@end
