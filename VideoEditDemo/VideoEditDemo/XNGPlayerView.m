//
//  XNGPlayerView.m
//  VideoEditDemo
//
//  Created by 吴吟迪 on 2018/11/12.
//  Copyright © 2018 吴吟迪. All rights reserved.
//

#import "XNGPlayerView.h"

@implementation XNGPlayerView {
    PlayerState state;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self singleClickViewConfig];
    }
    return self;
}

// playerView 单击手势配置
- (void)singleClickViewConfig {
    self.userInteractionEnabled = YES;
    state = PlayerStateStop;
    UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleClickAction:)];
    [self addGestureRecognizer:tap];
}

- (void)singleClickAction:(UITapGestureRecognizer *)tap {
    if (state == PlayerStateStop) {
        state = PlayerStateAcion;
    } else {
        state = PlayerStateStop;
    }
    if (self.playerViewClickHandler) {
        self.playerViewClickHandler(state);
    }
}

+ (Class)layerClass {
    return [AVPlayerLayer class];
}

- (AVPlayer *)player {
    return [(AVPlayerLayer *)[self layer] player];
}

- (void)setPlayer:(AVPlayer *)player {
    [(AVPlayerLayer *)[self layer] setPlayer:player];
}

@end
