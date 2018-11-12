//
//  XNGVideoEditTabVC.m
//  VideoEditDemo
//
//  Created by 吴吟迪 on 2018/11/12.
//  Copyright © 2018 吴吟迪. All rights reserved.
//

#import "XNGVideoEditTabVC.h"
#import "XNGVideoEditNavVC.h"
#import "XNGVideoEditVC.h"

@interface XNGVideoEditTabVC ()

@end

@implementation XNGVideoEditTabVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupItem];
    [self addChildViewControllers];
}

/**
 * 设置item属性
 */
- (void)setupItem {
    
    [[UITabBar appearance] setBarTintColor:UIColorFromRGB(0x1c1b20)];
    
    // 设置文字的样式
    NSMutableDictionary *selectTextAttrs = [NSMutableDictionary dictionary];
    selectTextAttrs[NSForegroundColorAttributeName] = UIColorFromRGB(0xFF2064);
    
    // 统一给所有的UITabBarItem设置文字属性
    // 只有后面带有UI_APPEARANCE_SELECTOR的属性或方法, 才可以通过appearance对象来统一设置
    UITabBarItem *item = [UITabBarItem appearance];
    [item setTitleTextAttributes:selectTextAttrs forState:UIControlStateSelected];
}

- (void)addChildViewControllers {
    XNGVideoEditVC * vc1 = [XNGVideoEditVC new];
    vc1.videoState = VideoStateVoiceConfig;
    XNGVideoEditVC * vc2 = [XNGVideoEditVC new];
    vc2.videoState = VideoStateVideoClip;
    
    [self addChildVc:vc1 title:@"混音设置" image:@"video_edit_intercept_gray" selectedImage:@"video_edit_intercept"];
    [self addChildVc:vc2 title:@"裁剪影片" image:@"video_edit_music_gray" selectedImage:@"video_edit_music"];
}

/**
 *  添加一个子控制器
 *
 *  @param childVc       子控制器
 *  @param title         标题
 *  @param image         图片
 *  @param selectedImage 选中的图片
 */
- (void)addChildVc:(UIViewController *)childVc title:(NSString *)title image:(NSString *)image selectedImage:(NSString *)selectedImage
{
    // 设置子控制器的文字
    childVc.title = title; // 同时设置tabbar和navigationBar的文字
    // 设置子控制器的图片
    childVc.tabBarItem.image = [UIImage imageNamed:image];
    childVc.tabBarItem.image = [childVc.tabBarItem.image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    childVc.tabBarItem.selectedImage =[[UIImage imageNamed:selectedImage] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    
    childVc.tabBarItem.imageInsets = UIEdgeInsetsMake(-2, 0, 2, 0);
    childVc.tabBarItem.titlePositionAdjustment = UIOffsetMake(0, -2);
    
    // 先给外面传进来的小控制器 包装 一个导航控制器
    XNGVideoEditNavVC *nav = [[XNGVideoEditNavVC alloc] initWithRootViewController:childVc];
    nav.extendedLayoutIncludesOpaqueBars = NO;
    nav.edgesForExtendedLayout = UIRectEdgeNone;
    
    // 添加为子控制器
    [self addChildViewController:nav];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
