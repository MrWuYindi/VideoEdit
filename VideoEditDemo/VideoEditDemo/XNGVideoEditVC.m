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
#import "XNGVideoEditTabView.h"
#import "XNGVideoEditManager.h"
#import "Masonry.h"

#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>

@interface XNGVideoEditVC ()<XNGVideoClipViewDelegate> {
    NSString *_totalTime;
    NSDateFormatter *_dateFormatter;
    AudioState audioState;  // 向后台传值使用，暂时没有用，只是赋值了
}

@property (nonatomic ,strong) XNGPlayerView *playerView;
@property (nonatomic ,strong) AVPlayerItem *playerItem;
@property (nonatomic ,strong) AVPlayer *player;             //  视频播放器
@property (nonatomic ,strong) AVPlayerItem *audioPlayerItem;
@property (nonatomic, strong) AVPlayer *audioPlayer;  //  音频播放器

@property (nonatomic ,strong) id playbackTimeObserver;

@property (nonatomic, strong) UIImageView *stateImageView;  // 状态播放按钮

@property (nonatomic, strong) XNGVoiceConfigView *voiceConfigView;
@property (nonatomic, strong) XNGVideoClipView * videoClipView;
@property (nonatomic, strong) XNGVideoEditTabView * videoEditTabView;

@end

@implementation XNGVideoEditVC

#pragma mark ===    XNGVideoClipViewDelegate    ===
/* 滑动预览图片代理通知到控制器 */
- (void)videoClipViewDidScroll:(XNGVideoClipView *)videoClipView contentOffsetX:(CGFloat)offsetX {
    NSLog(@"-videoClipView-offsetX:%f", offsetX);
    
}

#pragma mark Lift-Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    [self navigationBarConfigure];
    [self layoutItemViews];
    [self observerConfigure];
    [self analysisOfVideoKeyFramePicturesBeginTime:0.0 endTime:30.0];
}

- (void)dealloc {
    [self.playerItem removeObserver:self forKeyPath:@"status" context:nil];
    [self.playerItem removeObserver:self forKeyPath:@"loadedTimeRanges" context:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.audioPlayerItem];
    [self.playerView.player removeTimeObserver:self.playbackTimeObserver];
}

#pragma mark LayoutSubviews
- (void)layoutItemViews {
    self.view.backgroundColor = [UIColor blackColor];
    
    [self.view addSubview:self.playerView];
    [self.playerView addSubview:self.stateImageView];
    [self.view addSubview:self.voiceConfigView];
    [self.view addSubview:self.videoClipView];
    [self.view addSubview:self.videoEditTabView];
    
    UIEdgeInsets padding = UIEdgeInsetsMake(StatusBarH + NavigationBarH + 5, 10, TabbarH + 85.f, 10);
    __weak typeof(self) weakSelf = self;
    [self.playerView mas_makeConstraints:^(MASConstraintMaker *make) {
        __weak typeof(self) strongSelf = weakSelf;
        make.edges.equalTo(strongSelf.view).with.insets(padding);
    }];
    
    [self.stateImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        __weak typeof(self) strongSelf = weakSelf;
        make.height.mas_equalTo(60);
        make.width.mas_equalTo(60);
        make.center.equalTo(strongSelf.playerView);
    }];
    
    self.playerView.playerViewClickHandler = ^(PlayerState state) {
        __weak typeof(self) strongSelf = weakSelf;
        // 点击播放器的回调
        [strongSelf playerStateConfig:state];
    };
    
    [self.voiceConfigView mas_remakeConstraints:^(MASConstraintMaker *make) {
        __weak typeof(self) strongSelf = weakSelf;
        make.bottom.equalTo(strongSelf.view).with.offset(-49);
        make.width.mas_equalTo(KScreenWidth);
        make.height.mas_equalTo(85.f);
    }];
    self.voiceConfigView.voiceConfigHandler = ^(AudioState state) {
        // 点击：背景音乐、混音、视频原生 的回调
        __weak typeof(self) strongSelf = weakSelf;
        [strongSelf voiceStateConfig:state];
    };
    
    [self.videoClipView mas_remakeConstraints:^(MASConstraintMaker *make) {
        __weak typeof(self) strongSelf = weakSelf;
        make.bottom.equalTo(strongSelf.view).with.offset(-49);
        make.width.mas_equalTo(KScreenWidth);
        make.height.mas_equalTo(85.f);
    }];
    
    self.videoClipView.delegate = self;
    
    self.voiceConfigView.hidden = NO;
    self.videoClipView.hidden = YES;
    
    [self.videoEditTabView mas_remakeConstraints:^(MASConstraintMaker *make) {
        __weak typeof(self) strongSelf = weakSelf;
        make.bottom.mas_equalTo(strongSelf.view);
        make.left.right.mas_equalTo(0);
        make.height.mas_equalTo(49);
    }];
    self.videoEditTabView.selectHandler = ^(VideoState state) {
        __weak typeof(self) strongSelf = weakSelf;
        if (state == VideoStateVoiceConfig) {
            strongSelf.voiceConfigView.hidden = NO;
            strongSelf.videoClipView.hidden = YES;
        } else {
            strongSelf.voiceConfigView.hidden = YES;
            strongSelf.videoClipView.hidden = NO;
        }
    };
}

- (void)playerStateConfig:(PlayerState)state {
    if (state == PlayerStateAcion) {
        [self.playerView.player play];
        [self.audioPlayer play];
        [UIView animateWithDuration:0.5 animations:^{
            self.stateImageView.alpha = 0;
        }];
    } else {
        [self.playerView.player pause];
        [self.audioPlayer pause];
        [UIView animateWithDuration:0.5 animations:^{
            self.stateImageView.alpha = 1;
        }];
    }
}

- (void)voiceStateConfig:(AudioState)state {
    
    audioState = state;
    
    // 预览视频播放，不涉及制作，将用户选项记录到本地
    if (state == AudioStateBackground) {    // 背景音乐
        [self.playerView.player setVolume:0];
        [self.audioPlayer setVolume:1];
    } else if (state == AudioStateSoundMixing) {    // 混音
        [self.playerView.player setVolume:0.7];
        [self.audioPlayer setVolume:0.3];
    } else {    // 视频原声
        [self.playerView.player setVolume:1];
        [self.audioPlayer setVolume:0];
    }
}

#pragma mark 获取图片视频帧图片

- (void)analysisOfVideoKeyFramePicturesBeginTime:(CGFloat)begin endTime:(CGFloat)end {
    
//    1200/(KScreenWidth-26)s
    
    NSMutableArray<UIImage *> * array = [NSMutableArray<UIImage *> array];
    
    for (CGFloat i = begin; i < end; i += 3) {
        @autoreleasepool {
            UIImage * image = [[XNGVideoEditManager shareVideoEditManager] getImage:[self getLocalVideoPath] currectTime:i];
            [array addObject:image];
        }
    }
    [self.videoClipView setModel:array];
}

#pragma mark Private-Method
#pragma mark >>> 本地监听配置:KVO/Notification
- (void)observerConfigure {
    [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil]; // 监听status属性
    [self.playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil]; // 监听loadedTimeRanges属性
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayDidEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];  // 监听播放结束
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioPlayDidEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.audioPlayerItem];  // 监听audio播放结束
}

#pragma mark >>> KVO方法
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    AVPlayerItem *playerItem = (AVPlayerItem *)object;
    if ([keyPath isEqualToString:@"status"]) {
        if ([playerItem status] == AVPlayerStatusReadyToPlay) {
            NSLog(@"AVPlayerStatusReadyToPlay");
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

#pragma mark >>> 监听播放状态
- (void)monitoringPlayback:(AVPlayerItem *)playerItem {
    
    __weak typeof(self) weakSelf = self;
    self.playbackTimeObserver = [self.playerView.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:NULL usingBlock:^(CMTime time) {
        CGFloat currentSecond = playerItem.currentTime.value/playerItem.currentTime.timescale;// 计算当前在第几秒
//        [weakSelf.videoSlider setValue:currentSecond animated:YES];
        NSString *timeString = [weakSelf convertTime:currentSecond];
//        weakSelf.timeLabel.text = [NSString stringWithFormat:@"%@/%@",timeString,_totalTime];
        NSLog(@"%@", [NSString stringWithFormat:@"监听播放状态：%@/%@",timeString,self->_totalTime]);
    }];
}

#pragma mark >>> 视频播放结束回调
- (void)moviePlayDidEnd:(NSNotification *)notification {
    NSLog(@"Play end");
    [self.audioPlayer pause];
    __weak typeof(self) weakSelf = self;
    [self.playerView.player seekToTime:kCMTimeZero completionHandler:^(BOOL finished) { // 跳转到相应的播放位置
        [UIView animateWithDuration:0.5 animations:^{
            weakSelf.stateImageView.alpha = 1;
        }];
    }];
    [self.audioPlayer seekToTime:kCMTimeZero];
}

/**
 能到达这个文件说明音频比视频可播放时长短，采取的措施是音频重头开始播放
 */
- (void)audioPlayDidEnd:(NSNotification *)notification {
    NSLog(@"Play end");
    [self.audioPlayer pause];
    [self.audioPlayer seekToTime:kCMTimeZero];
    [self.audioPlayer play];
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
// 视频原生
- (NSURL *)getLocalVideoPath {
    NSString * path = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"mp4"];
    return [NSURL fileURLWithPath:path];
}

#pragma mark >>> 获取本地的音频文件URL
- (NSURL *)getLocalVoicePath {
    NSString * path = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"mp3"];
    return [NSURL fileURLWithPath:path];
}

#pragma mark 配置navigationBar相关
- (void)navigationBarConfigure {

    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    backBtn.frame = CGRectMake(0, 0, 45, 30);
    [backBtn setImage:[UIImage imageNamed:@"left_pick"] forState:UIControlStateNormal];
    [backBtn setImage:[UIImage imageNamed:@"left_pick"] forState:UIControlStateHighlighted];
    [backBtn setTitle:@"返回" forState:UIControlStateNormal];
    [backBtn setTitleColor:UIColorFromRGB(0xFF2064) forState:UIControlStateNormal];
    backBtn.titleLabel.font = [UIFont systemFontOfSize:15.0f];
    [backBtn setImageEdgeInsets:UIEdgeInsetsMake(0, -5, 0, 0)];
    [backBtn setTitleEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    [backBtn addTarget:self action:@selector(leftItemAction) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc]initWithCustomView:backBtn];
    self.navigationItem.leftBarButtonItem = backItem;
    
    UIButton * rightItem = [UIButton buttonWithType:UIButtonTypeSystem];
    rightItem.frame = CGRectMake(0, 0, 70, 30);
    rightItem.backgroundColor = UIColorFromRGB(0xFF2064);
    rightItem.layer.masksToBounds = YES;
    rightItem.layer.cornerRadius = 15.f;
    [rightItem setTitle:@"完成" forState:UIControlStateNormal];
    [rightItem setTitleColor:UIColorFromRGB(0xEEEEEE) forState:UIControlStateNormal];
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

- (AVPlayerItem *)audioPlayerItem {
    if (!_audioPlayerItem) {
        _audioPlayerItem = [AVPlayerItem playerItemWithURL:[self getLocalVoicePath]];
    }
    return _audioPlayerItem;
}

- (AVPlayer *)audioPlayer {
    if (!_audioPlayer) {
        _audioPlayer = [[AVPlayer alloc]initWithPlayerItem:self.audioPlayerItem];
    }
    return _audioPlayer;
}

- (UIImageView *)stateImageView {
    if (!_stateImageView) {
        _stateImageView = [[UIImageView alloc] init];
        _stateImageView.image = [UIImage imageNamed:@"play-btn"];
    }
    return _stateImageView;
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

- (XNGVideoEditTabView *)videoEditTabView {
    if (!_videoEditTabView) {
        _videoEditTabView = [[XNGVideoEditTabView alloc] initWithFrame:CGRectMake(0, 0, KScreenWidth, 49)];
    }
    return _videoEditTabView;
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
