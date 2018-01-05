//
//  ViewController.m
//  QRCodeDemo
//
//  Created by 李朕 on 2018/1/5.
//  Copyright © 2018年 Dan. All rights reserved.
//

#import "ViewController.h"
#import "QRCodeVC.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UILabel *scanResult;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)scanStart:(id)sender {
    QRCodeVC *scanVC = [[QRCodeVC alloc] init];
    scanVC.block = ^(NSString *scanResult) {
        _scanResult.text = scanResult;
    };
    [self presentViewController:scanVC animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
