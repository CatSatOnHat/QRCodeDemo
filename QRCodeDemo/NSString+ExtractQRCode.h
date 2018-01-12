//
//  NSString+ExtractQRCode.h
//  QRCodeDemo
//
//  Created by 李朕 on 2018/1/12.
//  Copyright © 2018年 Dan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface NSString (ExtractQRCode)

/**
 从图片中识别二维码
 
 @param image 二维码图片
 @return 内容
 */
+ (NSString *)extractQRCodeFromImage:(UIImage *)image;

@end
