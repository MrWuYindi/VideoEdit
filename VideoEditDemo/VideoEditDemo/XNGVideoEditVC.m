//
//  XNGVideoEditVC.m
//  VideoEditDemo
//
//  Created by 吴吟迪 on 2018/11/12.
//  Copyright © 2018 吴吟迪. All rights reserved.
//

#import "XNGVideoEditVC.h"
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>

@interface XNGVideoEditVC ()

@property (nonatomic, strong) AVPlayer * player;

@end

@implementation XNGVideoEditVC

#pragma lift-cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self layoutSubviews];
}

#pragma layoutSubviews
- (void)layoutSubviews {
    self.view.backgroundColor = [UIColor blackColor];

    
}

#pragma private-method
/*
 * 获取本地的视频文件URL
 */
- (NSURL *)getLocalVideoFile {
    
    
    return [NSURL URLWithString:@""];
}

#pragma lazy-load
- (AVPlayer *)player {
    if (!_player) {
        
        _player = [[AVPlayer alloc] initWithURL:[NSURL URLWithString:@"https://www.baidu.com"]];
    }
    return _player;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
