//
//  ViewController.m
//  QRCodeDemo
//
//  Created by 李朕 on 2018/1/5.
//  Copyright © 2018年 Dan. All rights reserved.
//

#import "ViewController.h"
#import "QRCodeVC.h"
#import "UIImage+GeneratorQRCode.h"
#import "NSString+ExtractQRCode.h"

@interface ViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *scanResult;
@property (weak, nonatomic) IBOutlet UIImageView *QRCodeImageV;
@property (weak, nonatomic) IBOutlet UITextField *QRCodeTextField;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _QRCodeImageV.layer.magnificationFilter = kCAFilterNearest;
}

- (IBAction)scanStart:(id)sender {
    QRCodeVC *scanVC = [[QRCodeVC alloc] init];
    __weak typeof(self) weakSelf = self;
    scanVC.block = ^(NSString *scanResult) {
        NSLog(@"%@", scanResult);
        weakSelf.scanResult.text = scanResult;
    };
    [self.navigationController pushViewController:scanVC animated:YES];
}
- (IBAction)GetQRCodeInfoFromImage:(id)sender {
    UIImagePickerController *pickController = [[UIImagePickerController alloc] init];
    pickController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    pickController.delegate = self;
    [self presentViewController:pickController animated:YES completion:nil];
}
- (IBAction)generatorQRCode:(id)sender {
    CGSize QRCodeSize = CGSizeMake([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.width);
    CGSize logoSize = CGSizeMake(50, 50);
    _QRCodeImageV.image = [UIImage generatorQRCodeWithContent:_QRCodeTextField.text QRCodeSize:QRCodeSize logo:[UIImage imageNamed:@"icon"] logoRect:CGRectMake((QRCodeSize.width-logoSize.width)/2, (QRCodeSize.height-logoSize.height)/2, logoSize.width, logoSize.height) color:[UIColor cyanColor]];
}
#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    NSString *type = [info objectForKey:UIImagePickerControllerMediaType];
    if ([type isEqualToString:@"public.image"]) {
        UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
        __weak typeof(self) weakSelf = self;
        [picker dismissViewControllerAnimated:YES completion:^{
            weakSelf.scanResult.text = [NSString extractQRCodeFromImage:image];
        }];
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
