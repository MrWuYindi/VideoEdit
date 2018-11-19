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
#import "XNGNewVideoClipView.h"
#import "XNGVideoEditTabView.h"
#import "Masonry.h"
#import "MBProgressHUD.h"

#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>

@interface XNGVideoEditVC ()<XNGNewVideoClipViewDelegate>

@property (nonatomic ,strong) XNGPlayerView *playerView;
@property (nonatomic ,strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) AVURLAsset * playerAsset;
@property (nonatomic ,strong) AVPlayer *player;             //  视频播放器

@property (nonatomic ,strong) id playbackTimeObserver;

@property (nonatomic, strong) UIImageView *stateImageView;  // 状态播放按钮

@property (nonatomic, strong) XNGVoiceConfigView *voiceConfigView;
@property (nonatomic, strong) XNGNewVideoClipView *videoClipView;
@property (nonatomic, strong) XNGVideoEditTabView * videoEditTabView;

@property (nonatomic, assign) NSTimeInterval startInterval; // 开始播放时间
@property (nonatomic, assign) NSTimeInterval totalTime; // 视频总播放时间
@property (nonatomic, assign) NSTimeInterval startToEndDuration; // 截取后BMT与EMT的差值

@property (nonatomic, assign) CGFloat leftValue;
@property (nonatomic, assign) CGFloat rightValue;
@property (nonatomic, assign) AudioState audioState;

@end

@implementation XNGVideoEditVC

#pragma mark XNGNewVideoClipViewDelegate
- (void)videoClipView:(XNGNewVideoClipView *)videoClipView sliderValueDidChangedOfLeft:(double)left right:(double)right {
    DLOG(@"--L:%f--R:%f", left, right);
    self.leftValue = left;
    self.rightValue = right;
    
    CMTime videoPointTime = CMTimeMake(left*self.playerItem.currentTime.timescale, self.playerItem.currentTime.timescale);
    [self.playerItem seekToTime:videoPointTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:nil];
}

#pragma mark Lift-Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    [self navigationBarConfigure];
    [self layoutItemViews];
    [self getAssetWithURL:[self getNetVideoUrl]];
//    [self getAssetWithURL:[NSURL URLWithString:self.videoUrl]];
}

- (void)dealloc {
    [self.playerItem removeObserver:self forKeyPath:@"status" context:nil];
    [self.playerItem removeObserver:self forKeyPath:@"loadedTimeRanges" context:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
    [self.playerView.player removeTimeObserver:self.playbackTimeObserver];
}

- (void)getAssetWithURL:(NSURL *)url {
    NSDictionary *options = @{ AVURLAssetPreferPreciseDurationAndTimingKey : @YES };
    self.playerAsset = [[AVURLAsset alloc]initWithURL:url options:options];
    NSArray *keys = @[@"duration"];
    
    [self.playerAsset loadValuesAsynchronouslyForKeys:keys completionHandler:^{
        NSError *error = nil;
        AVKeyValueStatus tracksStatus = [self.playerAsset statusOfValueForKey:@"duration" error:&error];
        switch (tracksStatus) {
            case AVKeyValueStatusLoaded:
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (!CMTIME_IS_INDEFINITE(self.playerAsset.duration)) {

                    }
                });
            }
                break;
            case AVKeyValueStatusFailed:
            {
                DLOG(@"AVKeyValueStatusFailed失败,请检查网络,或查看plist中是否添加App Transport Security Settings");
            }
                break;
            case AVKeyValueStatusCancelled:
            {
                DLOG(@"AVKeyValueStatusCancelled取消");
            }
                break;
            case AVKeyValueStatusUnknown:
            {
                DLOG(@"AVKeyValueStatusUnknown未知");
            }
                break;
            case AVKeyValueStatusLoading:
            {
                DLOG(@"AVKeyValueStatusLoading正在加载");
            }
                break;
        }
    }];
    [self setupPlayerWithAsset:self.playerAsset];
    
}

-(void)setupPlayerWithAsset:(AVURLAsset *)asset{
    self.playerItem = [[AVPlayerItem alloc]initWithAsset:asset];
    self.player = [[AVPlayer alloc]initWithPlayerItem:self.playerItem];
    self.playerView.player = self.player;
    [self.playerView.player setVolume:0];
    [self.videoClipView addFrames:asset];
    //添加KVO
    [self observerConfigure];
}

#pragma mark 本地监听配置:KVO/Notification
- (void)observerConfigure {
    [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil]; // 监听status属性
    [self.playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil]; // 监听loadedTimeRanges属性
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayDidEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];  // 监听播放结束
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
    
    [self.voiceConfigView mas_remakeConstraints:^(MASConstraintMaker *make) {
        __weak typeof(self) strongSelf = weakSelf;
        make.bottom.equalTo(strongSelf.view).with.offset(-49);
        make.width.mas_equalTo(KScreenWidth);
        make.height.mas_equalTo(85.f);
    }];
    
    [self.videoClipView mas_remakeConstraints:^(MASConstraintMaker *make) {
        __weak typeof(self) strongSelf = weakSelf;
        make.bottom.equalTo(strongSelf.view).with.offset(-49);
        make.width.mas_equalTo(KScreenWidth);
        make.height.mas_equalTo(85.f);
    }];
    
    [self.videoEditTabView mas_remakeConstraints:^(MASConstraintMaker *make) {
        __weak typeof(self) strongSelf = weakSelf;
        make.bottom.mas_equalTo(strongSelf.view);
        make.left.right.mas_equalTo(0);
        make.height.mas_equalTo(49);
    }];
    
    self.playerView.playerViewClickHandler = ^(PlayerState state) {
        __weak typeof(self) strongSelf = weakSelf;
        // 点击播放器的回调
        [strongSelf playerStateConfig:state];
    };
    
    self.voiceConfigView.voiceConfigHandler = ^(AudioState state) {
        // 点击：背景音乐、混音、视频原生 的回调
        __weak typeof(self) strongSelf = weakSelf;
        [strongSelf voiceStateConfig:state];
    };
    
    self.startInterval = self.beginMusicTime/1000;
    self.startToEndDuration = self.endMusicTime/1000 - self.startInterval;
    
    self.videoClipView.delegate = self;
    
    self.voiceConfigView.hidden = NO;
    self.videoClipView.hidden = YES;
    
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
        [UIView animateWithDuration:0.5 animations:^{
            self.stateImageView.alpha = 0;
        }];
        [self.videoClipView beginTimerAction];
    } else {
        [self.playerView.player pause];
        [UIView animateWithDuration:0.5 animations:^{
            self.stateImageView.alpha = 1;
        }];
        [self.videoClipView endTimerAction];
    }
}

- (void)voiceStateConfig:(AudioState)state {
    
    self.audioState = state;
    
    // 预览视频播放，不涉及制作，将用户选项记录到本地
    if (state == AudioStateBackground) {    // 背景音乐
        [self.playerView.player setVolume:0];
    } else if (state == AudioStateSoundMixing) {    // 混音
        [self.playerView.player setVolume:0.7];
    } else {    // 视频原声
        [self.playerView.player setVolume:1];
    }
}

#pragma mark Private-Method

#pragma mark >>> KVO方法
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    AVPlayerItem *playerItem = (AVPlayerItem *)object;
    if ([keyPath isEqualToString:@"status"]) {
        if ([playerItem status] == AVPlayerStatusReadyToPlay) {
            DLOG(@"AVPlayerStatusReadyToPlay");
            CMTime duration = self.playerItem.duration;// 获取视频总长度
            DLOG(@"movie total duration:%f",CMTimeGetSeconds(duration));
            self.totalTime = CMTimeGetSeconds(duration); // 转换成播放时间
            [self monitoringPlayback:self.playerItem];// 监听播放状态
        } else if ([playerItem status] == AVPlayerStatusFailed) {
            DLOG(@"AVPlayerStatusFailed");
        }
    } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        NSTimeInterval timeInterval = [self availableDuration];// 计算缓冲进度
        DLOG(@"Time Interval:%f",timeInterval);
//        CMTime duration = _playerItem.duration;
//        CGFloat totalDuration = CMTimeGetSeconds(duration);
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
        DLOG(@"%@", [NSString stringWithFormat:@"监听播放状态：%f",currentSecond]);
        if (currentSecond > weakSelf.rightValue) {
            CMTime videoPointTime = CMTimeMake(weakSelf.leftValue*weakSelf.playerItem.currentTime.timescale, weakSelf.playerItem.currentTime.timescale);
            [weakSelf.playerItem seekToTime:videoPointTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:nil];
            [weakSelf.videoClipView sliderInitialStatus];
        }
//        [weakSelf.videoClipView setCenterCursorPosition:currentSecond];
    }];
}

#pragma mark >>> 视频播放结束回调
- (void)moviePlayDidEnd:(NSNotification *)notification {
    DLOG(@"Play end");
    __weak typeof(self) weakSelf = self;
    [self.playerView.player seekToTime:kCMTimeZero completionHandler:^(BOOL finished) { // 跳转到相应的播放位置
        [UIView animateWithDuration:0.5 animations:^{
            weakSelf.stateImageView.alpha = 1;
        }];
    }];
}

- (NSURL *)getNetVideoUrl {
//    NSURL * url = [NSURL URLWithString:@"http://cdn-xalbum2.xiaoniangao.cn/1621069829?OSSAccessKeyId=E0RxDv7MIOlE5f1V&Expires=1543593605&Signature=RNzOJeZe8hptD136dHnSPJ71bb4%3D"];
    NSURL * url = [NSURL URLWithString:@"https://cdn-xalbum2.xiaoniangao.cn/1602467354?OSSAccessKeyId=E0RxDv7MIOlE5f1V&Expires=1543593605&Signature=vmI06Icw%2Fnr5RXtjtdNgab6ah5o%3D"];
    return url;
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

}

- (void)rightItemAction {    
    if (self.audioState == AudioStateBackground) {  // 视频原生
        // 0
    } else if (self.audioState == AudioStateSoundMixing) {  // 混音
        // 0.7
    } else {    // AudioStateVideoNative: 视频原生
        // 1
    }
//    self.leftValue
//    self.rightValue
    
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

- (XNGNewVideoClipView *)videoClipView {
    if (!_videoClipView) {
//        _videoClipView = [[XNGNewVideoClipView alloc] initWithFrame:CGRectMake(0, 0, KScreenWidth, 105.f) bmt:self.beginMusicTime/1000.f emt:self.endMusicTime/1000.f];
        _videoClipView = [[XNGNewVideoClipView alloc] initWithFrame:CGRectMake(0, 0, KScreenWidth, 105.f) bmt:2.f emt:9.f];
    }
    return _videoClipView;
}

- (XNGVideoEditTabView *)videoEditTabView {
    if (!_videoEditTabView) {
        _videoEditTabView = [[XNGVideoEditTabView alloc] initWithFrame:CGRectMake(0, 0, KScreenWidth, 49)];
    }
    return _videoEditTabView;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
