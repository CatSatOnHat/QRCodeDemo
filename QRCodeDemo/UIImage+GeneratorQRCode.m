//
//  UIImage+GeneratorQRCode.m
//  QRCodeDemo
//
//  Created by 李朕 on 2018/1/12.
//  Copyright © 2018年 Dan. All rights reserved.
//

#import "UIImage+GeneratorQRCode.h"

@implementation UIImage (GeneratorQRCode)

+ (UIImage *)generatorQRCodeWithContent:(NSString *)content
                             QRCodeSize:(CGSize)QRCodeSize
                                   logo:(UIImage *)logo
                               logoRect:(CGRect)logoRect
                                  color:(UIColor *)color {
    //生成清晰的二维码
    UIImage *QRCodeImage = [self createNonInterpolatedUIImageFormCIImage:[self generatorOrinalQRCodeWithContent:content] size:QRCodeSize];
    if (color) {
        //修改颜色
        QRCodeImage = [self changeQRCodeColorWithQRCode:QRCodeImage color:color];
    }
    if (logo) {
        //有logo
        return [self addLogowithQRCode:QRCodeImage logo:logo logoRect:logoRect];
    } else {
        //没有logo
        return QRCodeImage;
    }
}

/**
 生成最原始的二维码

 @param content 内容
 @return 二维码
 */
+ (CIImage *)generatorOrinalQRCodeWithContent:(NSString *)content {
    //实例化二维码滤镜
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    [filter setDefaults];
    NSData *data = [content dataUsingEncoding:NSUTF8StringEncoding];
    //设置滤镜,传入data,将来滤镜会通过传入的数据生成二维码
    [filter setValue:data forKey:@"inputMessage"];
    //设置容错等级
    [filter setValue:@"H" forKey:@"inputCorrectionLevel"];
    //生成二维码 此时生成的图片较模糊需要进一步处理
    CIImage *outputImage = [filter outputImage];
    return outputImage;
}

/**
 改变二维码的尺寸

 @param ciImage ciImage
 @param size size
 @return 改变尺寸后的二维码
 */
+ (UIImage *)createNonInterpolatedUIImageFormCIImage:(CIImage *)ciImage size:(CGSize)size {
    //获取原图像rect
    CGRect extent = CGRectIntegral(ciImage.extent);
    //需要的size与原图的比例
    CGFloat scale = MIN(size.width/CGRectGetWidth(extent), size.height/CGRectGetHeight(extent));
    // 创建bitmap;
    size_t width = CGRectGetWidth(extent) * scale;
    size_t height = CGRectGetHeight(extent) * scale;
    //
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();
    /*
     CGBitmapContextCreate(void * _Nullable data, size_t width, size_t height, size_t bitsPerComponent, size_t bytesPerRow, CGColorSpaceRef  _Nullable space, uint32_t bitmapInfo)
     data   指向要渲染的绘制内存的地址。这个内存块的大小至少是（bytesPerRow*height）个字节
     width  bitmap的宽度,单位为像素
     height bitmap的高度,单位为像素
     bitsPerComponent   内存中像素的每个组件的位数.例如，对于32位像素格式和RGB 颜色空间，你应该将这个值设为8.
     bytesPerRow    bitmap的每一行在内存所占的比特数
     colorspace bitmap上下文使用的颜色空间。
     bitmapInfo 指定bitmap是否包含alpha通道，像素中alpha通道的相对位置，像素组件是整形还是浮点型等信息的字符串。
     */
    CGContextRef bitmapRef = CGBitmapContextCreate(nil, width, height, 8, 0, cs, (CGBitmapInfo)kCGImageAlphaNone);
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef bitmapImage = [context createCGImage:ciImage fromRect:extent];
    CGContextSetInterpolationQuality(bitmapRef, kCGInterpolationNone);
    CGContextScaleCTM(bitmapRef, scale, scale);
    CGContextDrawImage(bitmapRef, extent, bitmapImage);
    // 保存bitmap到图片
    CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapRef);
    CGContextRelease(bitmapRef);
    CGImageRelease(bitmapImage);
    return [UIImage imageWithCGImage:scaledImage];
}

/**
 修改二维码颜色

 @param image 二维码
 @param color 颜色
 @return 修改后的二维码
 */
+ (UIImage *)changeQRCodeColorWithQRCode:(UIImage *)image color:(UIColor *)color {
    //获取颜色的RGB red 0  green 1 blue 2
    const CGFloat *components = CGColorGetComponents(color.CGColor);
    
    CGFloat imageWidth = image.size.width;
    CGFloat imageHeight = image.size.height;
    size_t bytesPerRow = imageWidth * 4;
    uint32_t *rgbImageBuf = (uint32_t *)malloc(bytesPerRow * imageHeight);
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(rgbImageBuf, imageWidth, imageHeight, 8, bytesPerRow, colorSpaceRef, kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipLast);
    CGContextDrawImage(context, CGRectMake(0, 0, imageWidth, imageHeight), image.CGImage);
    //遍历像素, 改变像素点颜色
    int pixelNum = imageWidth * imageHeight;
    uint32_t *pCurPtr = rgbImageBuf;
    for (int i = 0; i<pixelNum; i++, pCurPtr++) {
        if ((*pCurPtr & 0xFFFFFF00) < 0x99999900) {
            uint8_t* ptr = (uint8_t *)pCurPtr;
            ptr[3] = components[0] * 255;
            ptr[2] = components[1] * 255;
            ptr[1] = components[2] * 255;
        }else{
            uint8_t* ptr = (uint8_t*)pCurPtr;
            ptr[0] = 0;
        }
    }
    //取出图片
    CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, rgbImageBuf, bytesPerRow * imageHeight, ProviderReleaseData);
    CGImageRef imageRef = CGImageCreate(imageWidth, imageHeight, 8, 32, bytesPerRow, colorSpaceRef, kCGImageAlphaLast | kCGBitmapByteOrder32Little, dataProvider, NULL, true, kCGRenderingIntentDefault);
    CGDataProviderRelease(dataProvider);
    UIImage *resultImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpaceRef);
    
    return resultImage;
}

/**
 添加logo

 @param QRCodeImage 二维码
 @param logo logo图片
 @param logoRect logo frame
 @return 添加logo后的二维码
 */
+ (UIImage *)addLogowithQRCode:(UIImage *)QRCodeImage logo:(UIImage *)logo logoRect:(CGRect)logoRect {
    UIGraphicsBeginImageContext(QRCodeImage.size);
    [QRCodeImage drawInRect:CGRectMake(0, 0, QRCodeImage.size.width, QRCodeImage.size.height)];
    [logo drawInRect:logoRect];
    UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resultImage;
}

void ProviderReleaseData (void *info, const void *data, size_t size){
    free((void*)data);
}

@end
