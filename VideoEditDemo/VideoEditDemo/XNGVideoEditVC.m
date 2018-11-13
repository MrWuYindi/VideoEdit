//
//  XNGVideoEditVC.m
//  VideoEditDemo
//
//  Created by 吴吟迪 on 2018/11/12.
//  Copyright © 2018 吴吟迪. All rights reserved.
//

#import "XNGVideoEditVC.h"
#import "XNGPlayerView.h"
#import "XNGVoiceConfigView.h"
#import "XNGVideoClipView.h"
#import "Masonry.h"

#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>

@interface XNGVideoEditVC () {
    BOOL _played;
    NSString *_totalTime;
    NSDateFormatter *_dateFormatter;
}

@property (nonatomic ,strong) XNGPlayerView *playerView;
@property (nonatomic ,strong) AVPlayerItem *playerItem;
@property (nonatomic ,strong) AVPlayer *player;
@property (nonatomic ,strong) id playbackTimeObserver;

@property (nonatomic, strong) UIButton *stateButton;    // 状态播放按钮

@property (nonatomic, strong) XNGVoiceConfigView *voiceConfigView;
@property (nonatomic, strong) XNGVideoClipView * videoClipView;

@end

@implementation XNGVideoEditVC

#pragma mark Lift-Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self navigationBarConfigure];
    [self layoutItemViews];
    [self observerConfigure];
}

- (void)dealloc {
    [self.playerItem removeObserver:self forKeyPath:@"status" context:nil];
    [self.playerItem removeObserver:self forKeyPath:@"loadedTimeRanges" context:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
    [self.playerView.player removeTimeObserver:self.playbackTimeObserver];
}

#pragma mark LayoutSubviews
- (void)layoutItemViews {
    self.view.backgroundColor = [UIColor blackColor];
    
    [self.view addSubview:self.playerView];
    [self.playerView addSubview:self.stateButton];
    
    UIEdgeInsets padding = UIEdgeInsetsMake(StatusBarH + NavigationBarH + 5, 10, TabbarH + 85.f, 10);
    __weak typeof(self) weakSelf = self;
    [self.playerView mas_makeConstraints:^(MASConstraintMaker *make) {
        __weak typeof(self) strongSelf = weakSelf;
        make.edges.equalTo(strongSelf.view).with.insets(padding);
    }];
    
    [self.stateButton mas_makeConstraints:^(MASConstraintMaker *make) {
        __weak typeof(self) strongSelf = weakSelf;
        make.height.mas_equalTo(40);
        make.width.mas_equalTo(40);
        make.center.equalTo(strongSelf.playerView);
    }];
    
    if (self.videoState == VideoStateVoiceConfig) {
        [self.view addSubview:self.voiceConfigView];
        [self.voiceConfigView mas_remakeConstraints:^(MASConstraintMaker *make) {
            __weak typeof(self) strongSelf = weakSelf;
            make.bottom.equalTo(strongSelf.view).with.offset(-TabbarH);
            make.width.mas_equalTo(KScreenWidth);
            make.height.mas_equalTo(85.f);
        }];
        self.voiceConfigView.voiceConfigHandler = ^(AudioState state) {
            
        };
    } else {
        [self.view addSubview:self.videoClipView];
        [self.videoClipView mas_remakeConstraints:^(MASConstraintMaker *make) {
            __weak typeof(self) strongSelf = weakSelf;
            make.bottom.equalTo(strongSelf.view).with.offset(-TabbarH);
            make.width.mas_equalTo(KScreenWidth);
            make.height.mas_equalTo(85.f);
        }];
    }
}

#pragma mark Private-Method
#pragma mark >>> 本地监听配置:KVO/Notification
- (void)observerConfigure {
    [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil]; // 监听status属性
    [self.playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil]; // 监听loadedTimeRanges属性
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayDidEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];  // 监听播放结束
}

#pragma mark >>> KVO方法
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    AVPlayerItem *playerItem = (AVPlayerItem *)object;
    if ([keyPath isEqualToString:@"status"]) {
        if ([playerItem status] == AVPlayerStatusReadyToPlay) {
            NSLog(@"AVPlayerStatusReadyToPlay");
            self.stateButton.enabled = YES;
            CMTime duration = self.playerItem.duration;// 获取视频总长度
            CGFloat totalSecond = playerItem.duration.value / playerItem.duration.timescale;// 转换成秒
            _totalTime = [self convertTime:totalSecond];// 转换成播放时间
//            [self customVideoSlider:duration];// 自定义UISlider外观
            NSLog(@"movie total duration:%f",CMTimeGetSeconds(duration));
            [self monitoringPlayback:self.playerItem];// 监听播放状态
        } else if ([playerItem status] == AVPlayerStatusFailed) {
            NSLog(@"AVPlayerStatusFailed");
        }
    } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        NSTimeInterval timeInterval = [self availableDuration];// 计算缓冲进度
        NSLog(@"Time Interval:%f",timeInterval);
        CMTime duration = _playerItem.duration;
        CGFloat totalDuration = CMTimeGetSeconds(duration);
//        [self.videoProgress setProgress:timeInterval / totalDuration animated:YES];
    }
}

#pragma mark >>> 计算缓冲进度
- (NSTimeInterval)availableDuration {
    NSArray *loadedTimeRanges = [[self.playerView.player currentItem] loadedTimeRanges];
    CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
    float startSeconds = CMTimeGetSeconds(timeRange.start);
    float durationSeconds = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval result = startSeconds + durationSeconds;// 计算缓冲总进度
    return result;
}

//- (void)customVideoSlider:(CMTime)duration {
//    self.videoSlider.maximumValue = CMTimeGetSeconds(duration);
//    UIGraphicsBeginImageContextWithOptions((CGSize){ 1, 1 }, NO, 0.0f);
//    UIImage *transparentImage = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
//
//    [self.videoSlider setMinimumTrackImage:transparentImage forState:UIControlStateNormal];
//    [self.videoSlider setMaximumTrackImage:transparentImage forState:UIControlStateNormal];
//}

//- (void)updateVideoSlider:(CGFloat)currentSecond {
//    [self.videoSlider setValue:currentSecond animated:YES];
//}

#pragma mark >>> 监听播放状态
- (void)monitoringPlayback:(AVPlayerItem *)playerItem {
    
    __weak typeof(self) weakSelf = self;
    self.playbackTimeObserver = [self.playerView.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:NULL usingBlock:^(CMTime time) {
        CGFloat currentSecond = playerItem.currentTime.value/playerItem.currentTime.timescale;// 计算当前在第几秒
//        [weakSelf.videoSlider setValue:currentSecond animated:YES];
//        NSString *timeString = [self convertTime:currentSecond];
//        weakSelf.timeLabel.text = [NSString stringWithFormat:@"%@/%@",timeString,_totalTime];
    }];
}

#pragma mark >>> 视频播放结束回调
- (void)moviePlayDidEnd:(NSNotification *)notification {
    NSLog(@"Play end");
    
    __weak typeof(self) weakSelf = self;
    [self.playerView.player seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {
//        [weakSelf.videoSlider setValue:0.0 animated:YES];
        [weakSelf.stateButton setTitle:@"播放" forState:UIControlStateNormal];
    }];
}

#pragma mark >>> 时间戳转换
- (NSString *)convertTime:(CGFloat)second{
    NSDate *d = [NSDate dateWithTimeIntervalSince1970:second];
    if (second/3600 >= 1) {
        [[self dateFormatter] setDateFormat:@"HH:mm:ss"];
    } else {
        [[self dateFormatter] setDateFormat:@"mm:ss"];
    }
    NSString *showtimeNew = [[self dateFormatter] stringFromDate:d];
    return showtimeNew;
}

#pragma mark >>> 获取本地的视频文件URL
- (NSURL *)getLocalVideoPath {
    NSString * path = [[NSBundle mainBundle] pathForResource:@"testVideo" ofType:@"mp4"];
    return [NSURL URLWithString:path];
}

#pragma mark 播放状态按钮点击按钮
- (void)stateButtonClickAction:(UIButton *) button {
    if (!_played) {
        [self.playerView.player play];
        [self.stateButton setTitle:@"Stop" forState:UIControlStateNormal];
    } else {
        [self.playerView.player pause];
        [self.stateButton setTitle:@"Play" forState:UIControlStateNormal];
    }
    _played = !_played;
}

#pragma mark 配置navigationBar相关
- (void)navigationBarConfigure {
    self.navigationController.navigationBar.tintColor = [UIColor blackColor];
    UIButton * leftItem = [UIButton buttonWithType:UIButtonTypeSystem];
    leftItem.titleLabel.textColor = [UIColor purpleColor];
    [leftItem setTitle:@"返回" forState:UIControlStateNormal];
    [leftItem addTarget:self action:@selector(leftItemAction) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:leftItem];
    
    UIButton * rightItem = [UIButton buttonWithType:UIButtonTypeSystem];
    rightItem.titleLabel.textColor = [UIColor purpleColor];
    [rightItem setTitle:@"完成" forState:UIControlStateNormal];
    [rightItem addTarget:self action:@selector(rightItemAction) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:rightItem];
}

- (void)leftItemAction {
    NSLog(@"----- 左侧Item按钮点击了 -----");
}

- (void)rightItemAction {
    NSLog(@"----- 右侧Item按钮点击了 -----");
}

#pragma mark Lazy-Load

- (XNGPlayerView *)playerView {
    if (!_playerView) {
        _playerView = [[XNGPlayerView alloc] init];
        _playerView.backgroundColor = [UIColor blackColor];
        _playerView.player = self.player;
    }
    return _playerView;
}

- (AVPlayerItem *)playerItem {
    if (!_playerItem) {
        _playerItem = [AVPlayerItem playerItemWithURL:[self getLocalVideoPath]];
    }
    return _playerItem;
}

- (AVPlayer *)player {
    if (!_player) {
        _player = [AVPlayer playerWithPlayerItem:self.playerItem];
    }
    return _player;
}

- (UIButton *)stateButton {
    if (!_stateButton) {
        _stateButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_stateButton setImage:[UIImage imageNamed:@"play-btn"] forState:UIControlStateNormal];
    }
    return _stateButton;
}

- (XNGVoiceConfigView *)voiceConfigView {
    if (!_voiceConfigView) {
        _voiceConfigView = [[XNGVoiceConfigView alloc] initXNGViewWithFrame:CGRectMake(0, 0, KScreenWidth, 105.f)];
    }
    return _voiceConfigView;
}

- (XNGVideoClipView *)videoClipView {
    if (!_videoClipView) {
        _videoClipView= [[XNGVideoClipView alloc] initWithFrame:CGRectMake(0, 0, KScreenWidth, 105.f) imageSource:@[]];
    }
    return _videoClipView;
}

- (NSDateFormatter *)dateFormatter {
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
    }
    return _dateFormatter;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
