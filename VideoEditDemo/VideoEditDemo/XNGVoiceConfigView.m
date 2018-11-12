//
//  XNGVoiceConfigView.m
//  VideoEditDemo
//
//  Created by 吴吟迪 on 2018/11/12.
//  Copyright © 2018 吴吟迪. All rights reserved.
//

#import "XNGVoiceConfigView.h"

@interface XNGVoiceConfigView()

@property (nonatomic, assign) AudioState state;

@property (weak, nonatomic) IBOutlet UIView *circleView1;
@property (weak, nonatomic) IBOutlet UIView *circleView2;
@property (weak, nonatomic) IBOutlet UIView *circleView3;
@property (weak, nonatomic) IBOutlet UIView * lineView1;
@property (weak, nonatomic) IBOutlet UIView * lineView2;
@property (weak, nonatomic) IBOutlet UILabel * label1;  // 背景音乐
@property (weak, nonatomic) IBOutlet UILabel * label2;  // 混音
@property (weak, nonatomic) IBOutlet UILabel * label3;  // 视频原声

@end

@implementation XNGVoiceConfigView

+ (instancetype)voiceConfigView
{
    // 封装Xib的加载过程
    return [[NSBundle mainBundle] loadNibNamed:@"XNGVoiceConfigView" owner:nil options:nil].firstObject;
}

- (instancetype)initXNGViewWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:self options:nil][0];
        self.frame = frame;
    }
    return self;
}

- (IBAction)clickAction:(UIButton *)sender {
    if (sender.tag == 100) {
        self.state = AudioStateBackground;
    } else if (sender.tag == 101) {
        self.state = AudioStateSoundMixing;
    } else {
        self.state = AudioStateVideoNative;
    }
    [self changeViewAndLabelColor:self.state];
    if (self.voiceConfigHandler) {
        self.voiceConfigHandler(self.state);
    }
}

- (void)changeViewAndLabelColor:(AudioState)state {
    self.circleView1.backgroundColor = UIColorFromRGB(0x404040);
    self.circleView2.backgroundColor = UIColorFromRGB(0x404040);
    self.circleView3.backgroundColor = UIColorFromRGB(0x404040);
    self.label1.textColor = UIColorFromRGB(0x404040);
    self.label2.textColor = UIColorFromRGB(0x404040);
    self.label3.textColor = UIColorFromRGB(0x404040);

    if (state == AudioStateBackground) {
        self.circleView1.backgroundColor = UIColorFromRGB(0xFF2064);
        self.label1.textColor = UIColorFromRGB(0xFF2064);
    } else if (state == AudioStateSoundMixing) {
        self.circleView2.backgroundColor = UIColorFromRGB(0xFF2064);
        self.label2.textColor = UIColorFromRGB(0xFF2064);
    } else {
        self.circleView3.backgroundColor = UIColorFromRGB(0xFF2064);
        self.label3.textColor = UIColorFromRGB(0xFF2064);
    }
}

@end
