//
//  XNGPlayerView.h
//  VideoEditDemo
//
//  Created by 吴吟迪 on 2018/11/12.
//  Copyright © 2018 吴吟迪. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>

typedef enum : NSUInteger {
    PlayerStateAcion,
    PlayerStateStop,
} PlayerState;

typedef void(^PlayerViewClickHandler)(PlayerState state);

@interface XNGPlayerView : UIView

@property (nonatomic ,strong) AVPlayer *player;

@property (nonatomic, copy) PlayerViewClickHandler playerViewClickHandler;

@end
