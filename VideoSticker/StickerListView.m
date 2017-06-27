//
//  StickerListView.m
//  VideoSticker
//
//  Created by zf on 2017/6/22.
//  Copyright © 2017年 baidu. All rights reserved.
//

#import "StickerListView.h"

@interface StickerListView ()

// 背景maskview
@property (nonatomic, strong) UIView *bgMaskView;

// 关闭按钮
@property (nonatomic, strong) UIButton *closeBtn;

// 贴纸滚动列表
@property (nonatomic, strong) UIScrollView *stickersView;

@end


@implementation StickerListView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self setupUI];
    }
    
    return self;
}

#pragma mark - UI相关函数

- (void)setupUI
{
    self.backgroundColor = [UIColor clearColor];
    
    [self setupMaskView];
    [self setupStickersView];
    [self setupCloseBtn];
}

- (void)setupMaskView
{
    if (self.bgMaskView)
    {
        return;
    }
    
    UIView *bgMaskView = [[UIView alloc] initWithFrame:self.bounds];
    bgMaskView.backgroundColor = [UIColor blackColor];
    bgMaskView.alpha = 0.9f;
    [self addSubview:bgMaskView];
    
    self.bgMaskView = bgMaskView;
}

- (void)setupStickersView
{
    if (self.stickersView)
    {
        return;
    }
    
    UIScrollView *listView = [[UIScrollView alloc] initWithFrame:self.bounds];
    listView.showsVerticalScrollIndicator = NO;
    listView.showsHorizontalScrollIndicator = NO;
    listView.alwaysBounceVertical = YES;
    [self addSubview:listView];
    
    // 添加贴纸
    CGFloat edgeMargin = 20.0f;
    CGFloat stickersMargin = 20.0f;
    NSInteger numStickersOneLine = 3;
    NSInteger maxStickerCount = 4;
    
    // 计算贴纸宽高
    CGFloat stickerWidth = (self.bounds.size.width - 2 * edgeMargin - (numStickersOneLine-1) * stickersMargin) / numStickersOneLine;
    CGFloat currentStickerPosX = edgeMargin;
    CGFloat currentStickerPosY = stickersMargin;
    
    for (int i = 1; i <= maxStickerCount; i++)
    {
        NSString *imageName = [NSString stringWithFormat:@"sticker_%d.png", i];
        UIImage *img = [UIImage imageNamed:imageName];
        
        UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(currentStickerPosX, currentStickerPosY, stickerWidth, stickerWidth)];
        imgView.image = img;
        imgView.userInteractionEnabled = YES;
        [listView addSubview:imgView];
        
        UITapGestureRecognizer *clickImageGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectStickerImageView:)];
        [imgView addGestureRecognizer:clickImageGes];
        
        currentStickerPosX += stickerWidth + stickersMargin;
        
        if (i % numStickersOneLine == 0)
        {
            currentStickerPosX = edgeMargin;
            currentStickerPosY += stickerWidth + stickersMargin;
        }
    }
    
    listView.contentSize = CGSizeMake(self.bounds.size.width, currentStickerPosY);
    
    self.stickersView = listView;
}

- (void)setupCloseBtn
{
    if (self.closeBtn != nil)
    {
        return;
    }
    
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    closeBtn.backgroundColor = [UIColor clearColor];
    [closeBtn setFrame:CGRectMake(self.frame.size.width - 50, 30, 30, 30)];
    [closeBtn setImage:[UIImage imageNamed:@"close.png"] forState:UIControlStateNormal];
    [self addSubview:closeBtn];
    
    [closeBtn addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    
    self.closeBtn = closeBtn;
}

#pragma mark - 点击处理

- (void)selectStickerImageView:(UIGestureRecognizer *)tapGes
{
    [self dismiss];
    
    if (self.delegate == nil || ![self.delegate respondsToSelector:@selector(selectStickerImage:)])
    {
        return;
    }
    
    UIImageView *imageView = (UIImageView *)tapGes.view;
    if (![imageView isKindOfClass:[UIImageView class]])
    {
        return;
    }
    
    [self.delegate selectStickerImage:imageView.image];
}

#pragma mark - 显示隐藏相关

- (void)show
{
    self.hidden = NO;
    
    CGFloat posStartY = self.superview.frame.size.height;
    CGFloat posEndY = self.superview.frame.size.height - self.frame.size.height;
    
    self.frame = CGRectMake(self.frame.origin.x, posStartY, self.frame.size.width, self.frame.size.height);
    
    [UIView animateWithDuration:0.2f animations:^{
        
        self.frame = CGRectMake(self.frame.origin.x, posEndY, self.frame.size.width, self.frame.size.height);
        
    } completion:nil];
}

- (void)dismiss
{
    CGFloat posEndY = self.superview.frame.size.height;
    
    [UIView animateWithDuration:0.2f animations:^{
        
        self.frame = CGRectMake(self.frame.origin.x, posEndY, self.frame.size.width, self.frame.size.height);
        
    } completion:^(BOOL finished) {
        self.hidden = YES;
    }];
}

@end
