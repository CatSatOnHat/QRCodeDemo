//
//  QRCodeVC.h
//  QRCodeDemo
//
//  Created by 李朕 on 2018/1/5.
//  Copyright © 2018年 Dan. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^ScanBlock)(NSString *scanResult);

@interface QRCodeVC : UIViewController

@property (nonatomic, copy) ScanBlock block;

@end
