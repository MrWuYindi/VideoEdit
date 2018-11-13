//
//  XNGVideoEditTabView.m
//  VideoEditDemo
//
//  Created by 吴吟迪 on 2018/11/13.
//  Copyright © 2018 吴吟迪. All rights reserved.
//

#import "XNGVideoEditTabView.h"

@interface XNGVideoEditTabView ()

@property (weak, nonatomic) IBOutlet UIImageView *voiceImage;
@property (weak, nonatomic) IBOutlet UIImageView *videoImage;
@property (weak, nonatomic) IBOutlet UILabel *voiceLabel;
@property (weak, nonatomic) IBOutlet UILabel *videoLabel;

@end
@implementation XNGVideoEditTabView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:self options:nil][0];
        self.frame = frame;
    }
    return self;
}

- (IBAction)tabbarSelectItem:(UIButton *)sender {
    
    if (self.selectHandler) {
        if (sender.tag == 105) {
            self.selectHandler(VideoStateVoiceConfig);
            self.voiceImage.image = [UIImage imageNamed:@"video_edit_intercept"];
            self.voiceLabel.textColor = UIColorFromRGB(0xFF2064);
            self.videoImage.image = [UIImage imageNamed:@"video_edit_music_gray"];
            self.videoLabel.textColor = UIColorFromRGB(0xFFFFFF);
        } else {
            self.selectHandler(VideoStateVideoClip);
            self.voiceImage.image = [UIImage imageNamed:@"video_edit_intercept_gray"];
            self.voiceLabel.textColor = UIColorFromRGB(0xFFFFFF);
            self.videoImage.image = [UIImage imageNamed:@"video_edit_music"];
            self.videoLabel.textColor = UIColorFromRGB(0xFF2064);
        }
    }
}


@end
