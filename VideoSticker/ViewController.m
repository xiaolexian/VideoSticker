//
//  ViewController.m
//  VideoSticker
//
//  Created by zf on 2017/6/21.
//  Copyright © 2017年 baidu. All rights reserved.
//

#import "ViewController.h"
#import "VideoStickerViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self createCenterBtn:@"视频贴纸" posY:240 func:@selector(showVideoStickerViewController)];
}

#pragma mark - Buttons

- (UIButton *)createCenterBtn:(NSString *)title posY:(NSInteger)y func:(SEL)selFunc
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.frame = CGRectMake(0, y, self.view.frame.size.width, 20);
    [button setTitle:title forState:UIControlStateNormal];
    [self.view addSubview:button];
    
    [button addTarget:self action:selFunc forControlEvents:UIControlEventTouchUpInside];
    
    return button;
}

#pragma mark - Show viewController

- (void)showVideoStickerViewController
{
    VideoStickerViewController *vc = [[VideoStickerViewController alloc] init];
    [self presentViewController:vc animated:YES completion:nil];
}


@end
