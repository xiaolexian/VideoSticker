//
//  StickerListView.h
//  VideoSticker
//
//  Created by zf on 2017/6/22.
//  Copyright © 2017年 baidu. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol StickerListViewDelegate <NSObject>

@optional

- (void)selectStickerImage:(UIImage *)image;

@end

@interface StickerListView : UIView

@property (nonatomic, weak) id<StickerListViewDelegate> delegate;

- (void)show;
- (void)dismiss;

@end
