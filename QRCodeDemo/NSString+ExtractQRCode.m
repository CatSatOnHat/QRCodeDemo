//
//  NSString+ExtractQRCode.m
//  QRCodeDemo
//
//  Created by 李朕 on 2018/1/12.
//  Copyright © 2018年 Dan. All rights reserved.
//

#import "NSString+ExtractQRCode.h"

NSString *const NoExtract = @"照片中未识别到二维码";

@implementation NSString (ExtractQRCode)

+ (NSString *)extractQRCodeFromImage:(UIImage *)image {
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{CIDetectorAccuracy:CIDetectorAccuracyHigh}];
    CIImage *QRCodeImage = [[CIImage alloc] initWithImage:image];
    NSArray *features = [detector featuresInImage:QRCodeImage];
    if (features.count > 0) {
        return [[features firstObject] messageString];
    } else {
        return NoExtract;
    }
}

@end
