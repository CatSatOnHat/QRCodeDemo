//
//  ViewController.m
//  QRCodeDemo
//
//  Created by 李朕 on 2018/1/5.
//  Copyright © 2018年 Dan. All rights reserved.
//

#import "ViewController.h"
#import "QRCodeVC.h"

@interface ViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

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

- (IBAction)GetQRCodeInfoFromImage:(id)sender {
    UIImagePickerController *pickController = [[UIImagePickerController alloc] init];
    pickController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    pickController.delegate = self;
    [self presentViewController:pickController animated:YES completion:nil];
}
#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    NSString *type = [info objectForKey:UIImagePickerControllerMediaType];
    if ([type isEqualToString:@"public.image"]) {
        UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
        [picker dismissViewControllerAnimated:YES completion:^{
            
            CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{CIDetectorAccuracy:CIDetectorAccuracyHigh}];
            CIImage *QRCodeImage = [[CIImage alloc] initWithImage:image];
            NSArray *features = [detector featuresInImage:QRCodeImage];
            if (features.count > 0) {
                _scanResult.text = [[features firstObject] messageString];
            } else {
                _scanResult.text = @"照片中未识别到二维码";
            }
        }];
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
