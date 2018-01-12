//
//  UIImage+GeneratorQRCode.h
//  QRCodeDemo
//
//  Created by 李朕 on 2018/1/12.
//  Copyright © 2018年 Dan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (GeneratorQRCode)

/**
 生成二维码图片

 @param content 二维码内容
 @param QRCodeSize 二维码size
 @param logo logo图片
 @param logoRect logo frame
 @param color 二维码颜色
 @return 二维码
 */
+ (UIImage *)generatorQRCodeWithContent:(NSString *)content QRCodeSize:(CGSize)QRCodeSize logo:(UIImage *)logo logoRect:(CGRect)logoRect color:(UIColor *)color;

@end
