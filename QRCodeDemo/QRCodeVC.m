//
//  QRCodeVC.m
//  QRCodeDemo
//
//  Created by 李朕 on 2018/1/5.
//  Copyright © 2018年 Dan. All rights reserved.
//

#import "QRCodeVC.h"
#import <AVFoundation/AVFoundation.h>
#import "NSString+ExtractQRCode.h"

@interface QRCodeVC () <AVCaptureMetadataOutputObjectsDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) AVCaptureDevice *device;
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureDeviceInput *input;
@property (nonatomic, strong) AVCaptureMetadataOutput *output;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
//扫描范围
@property (nonatomic, assign) CGRect scanRect;
//阴影层
@property (nonatomic, strong) CAShapeLayer *shadowLayer;
//需要保留的阴影层
@property (nonatomic, strong) CAShapeLayer *maskLayer;
@property (nonatomic, strong) CAShapeLayer *borderLayer;

@property (nonatomic, strong) UILabel *remindLabel;
@property (nonatomic, strong) UIImageView *scanImageV;
//逐帧转换为图片扫描（辨识度比较低的二维码直接用系统的扫不出来）
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;

@end

@implementation QRCodeVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.view.layer addSublayer:self.previewLayer];
    [self.view.layer addSublayer:self.shadowLayer];
    [self.view.layer addSublayer:self.borderLayer];
    [self.view addSubview:self.remindLabel];
    [self.view addSubview:self.scanImageV];
    //启动会话
    [self.session startRunning];
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    //动画不能放在 viewDidLoad
    [self setupScanLine];
}
- (void)setupScanLine {
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:3.0f delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        [UIView setAnimationRepeatCount:MAXFLOAT];
        weakSelf.scanImageV.frame = CGRectMake(self.scanRect.origin.x, CGRectGetMaxY(self.scanRect)-2, self.scanRect.size.width, 2);
    } completion:^(BOOL finished) {
        weakSelf.scanImageV.frame = CGRectMake(self.scanRect.origin.x, self.scanRect.origin.y, self.scanRect.size.width, 2);
    }];
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)output didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    if (metadataObjects.count > 0) {
        [self.session stopRunning];
        AVMetadataMachineReadableCodeObject *metadataObject = [metadataObjects objectAtIndex:0];
        _block(metadataObject.stringValue);
        [self.navigationController popViewControllerAnimated:YES];
    }
}
#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    //逐帧识别图片
    if ([[NSString extractQRCodeFromImage:[self imageFromSampleBuffer:sampleBuffer]] isEqualToString:NoExtract]) {
        //识别到二维码的时候
        _block([NSString extractQRCodeFromImage:[self imageFromSampleBuffer:sampleBuffer]]);
    }
}

/**
 转换为图片

 @param sampleBuffer sampleBuffer
 @return 图片
 */
- (UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    // Get a CMSampleBuffer's Core Video image buffer for the media data
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    // Get the number of bytes per row for the pixel buffer
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    // Get the number of bytes per row for the pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // Get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    // Create a device-dependent RGB color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    // Create a bitmap graphics context with the sample buffer data
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    // Create a Quartz image from the pixel data in the bitmap graphics context
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    // Free up the context and color space
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    // Create an image object from the Quartz image
    UIImage *image = [UIImage imageWithCGImage:quartzImage];
    // Release the Quartz image
    CGImageRelease(quartzImage);
    return (image);
}
#pragma mark - lazy load
/**
 获取摄像设备

 @return device
 */
- (AVCaptureDevice *)device {
    if (!_device) {
        _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    }
    return _device;
}

/**
 创建输入流

 @return input
 */
- (AVCaptureDeviceInput *)input {
    if (!_input) {
        NSError *inputError = nil;
        _input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:&inputError];
        if (inputError) {
            NSLog(@"AVCaptureDeviceInput error : %@", inputError);
        }
    }
    return _input;
}

/**
 创建输出流

 @return output
 */
- (AVCaptureMetadataOutput *)output {
    if (!_output) {
        _output = [[AVCaptureMetadataOutput alloc] init];
        [_output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
        _output.rectOfInterest = CGRectMake(self.scanRect.origin.y / self.view.bounds.size.height,
                                            self.scanRect.origin.x / self.view.bounds.size.width,
                                            self.scanRect.size.height / self.view.bounds.size.height,
                                            self.scanRect.size.width / self.view.bounds.size.width);
    }
    return _output;
}

/**
 创建会话对象

 @return session
 */
- (AVCaptureSession *)session {
    if (!_session) {
        _session = [[AVCaptureSession alloc] init];
        [_session setSessionPreset:AVCaptureSessionPresetHigh];
        [self setupIODevice];
    }
    return _session;
}

/**
 实例化预览图层

 @return previewLayer
 */
- (AVCaptureVideoPreviewLayer *)previewLayer {
    if (!_previewLayer) {
        //显示session会话
        _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
        _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        _previewLayer.frame = self.view.bounds;
    }
    return _previewLayer;
}

/**
 配置会话输入和输出
 */
- (void)setupIODevice {
    if ([_session canAddInput:self.input]) {
        [_session addInput:self.input];
    }
    //以下二选一
    if ([_session canAddOutput:self.output]) {
        [_session addOutput:self.output];
    }
//    if ([_session canAddOutput:self.videoDataOutput]) {
//        [_session addOutput:self.videoDataOutput];
//    }
    AVAuthorizationStatus authorizationStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authorizationStatus == AVAuthorizationStatusRestricted || authorizationStatus == AVAuthorizationStatusDenied) {
        UIAlertView *alert =[[UIAlertView alloc]initWithTitle:@"XXXX" message:@"请打开相机访问权限" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
        [alert show];
        return;
    }else{
        //设置输出数据类型
        _output.metadataObjectTypes = @[AVMetadataObjectTypeQRCode, AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode128Code];
    }
}

/**
 扫描范围

 @return scanRect
 */
- (CGRect)scanRect {
    if (CGRectEqualToRect(_scanRect, CGRectZero)) {
        CGRect frame = self.view.bounds;
        frame.origin.x += 50;
        frame.origin.y += 120;
        frame.size.width -= 100;
        frame.size.height = frame.size.width;
        _scanRect = frame;
    }
    return _scanRect;
}

/**
 阴影层

 @return shadowLayer
 */
- (CAShapeLayer *)shadowLayer {
    if (!_shadowLayer) {
        _shadowLayer = [CAShapeLayer layer];
        _shadowLayer.path = [UIBezierPath bezierPathWithRect:self.view.bounds].CGPath;
        _shadowLayer.fillColor = [UIColor colorWithWhite:0 alpha:0.6].CGColor;
        _shadowLayer.mask = self.maskLayer;
    }
    return _shadowLayer;
}

/**
 扣掉扫描

 @return maskLayer
 */
- (CAShapeLayer *)maskLayer {
    if (!_maskLayer) {
        _maskLayer = [CAShapeLayer layer];
        _maskLayer = [self subtractMaskRect:self.scanRect fromRect:self.view.bounds];
    }
    return _maskLayer;
}

- (CAShapeLayer *)borderLayer {
    if (!_borderLayer) {
        _borderLayer = [CAShapeLayer layer];
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path moveToPoint:CGPointMake(self.scanRect.origin.x, self.scanRect.origin.y)];
        [path addLineToPoint:CGPointMake(self.scanRect.origin.x + self.scanRect.size.width, self.scanRect.origin.y)];
        [path addLineToPoint:CGPointMake(self.scanRect.origin.x + self.scanRect.size.width, self.scanRect.origin.y + self.scanRect.size.height)];
        [path addLineToPoint:CGPointMake(self.scanRect.origin.x, self.scanRect.origin.y + self.scanRect.size.height)];
        [path closePath];
        _borderLayer.path = path.CGPath;
        _borderLayer.fillColor = [UIColor clearColor].CGColor;
        _borderLayer.strokeColor = [UIColor whiteColor].CGColor;
        _borderLayer.lineWidth = 1.0;
    }
    return _borderLayer;
}

- (UILabel *)remindLabel {
    if (!_remindLabel) {
        _remindLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.scanRect)+20, self.view.bounds.size.width, 15)];
        _remindLabel.text = @"将二维码/条码放入框内，即可自动扫描";
        _remindLabel.textColor = [UIColor whiteColor];
        _remindLabel.textAlignment = NSTextAlignmentCenter;
        
    }
    return _remindLabel;
}

- (UIImageView *)scanImageV {
    if (!_scanImageV) {
        _scanImageV = [[UIImageView alloc] initWithFrame:CGRectMake(self.scanRect.origin.x, self.scanRect.origin.y, self.scanRect.size.width, 2)];
        UIImage *lineImage = [UIImage imageNamed:@"scan_line"];
        _scanImageV.image = lineImage;
    }
    return _scanImageV;
}

/**
 生成扣掉扫描部分的layer

 @param maskRect 扣掉的rect
 @param originalRect 原rect
 @return 扣掉扫描部分的layer
 */
- (CAShapeLayer *)subtractMaskRect:(CGRect)maskRect fromRect:(CGRect)originalRect {
    CAShapeLayer *layer = [CAShapeLayer layer];
    if (CGRectEqualToRect(maskRect, CGRectZero)) {
        return layer;
    }
    if (CGRectEqualToRect(originalRect, CGRectZero)) {
        return nil;
    }
    CGFloat originalMinX = CGRectGetMinX(originalRect);
    CGFloat originalMinY = CGRectGetMinY(originalRect);
    CGFloat originalMaxX = CGRectGetMaxX(originalRect);
    CGFloat originalMaxY = CGRectGetMaxY(originalRect);
    
    CGFloat maskMinX = CGRectGetMinX(maskRect);
    CGFloat maskMinY = CGRectGetMinY(maskRect);
    CGFloat maskMaxX = CGRectGetMaxX(maskRect);
    CGFloat maskMaxY = CGRectGetMaxY(maskRect);
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:CGRectMake(originalMinX, originalMinY, maskMinX - originalMinX, originalMaxY - originalMinY)];
    [path appendPath:[UIBezierPath bezierPathWithRect:CGRectMake(maskMinX, originalMinY, maskMaxX - maskMinX, maskMinY - originalMinY)]];
    [path appendPath:[UIBezierPath bezierPathWithRect:CGRectMake(maskMaxX, originalMinY, originalMaxX - maskMaxX, originalMaxY- originalMinY)]];
    [path appendPath:[UIBezierPath bezierPathWithRect:CGRectMake(maskMinX, maskMaxY, maskMaxX - maskMinX, originalMaxY - maskMaxY)]];
    layer.path = path.CGPath;
    return layer;
}

- (AVCaptureVideoDataOutput *)videoDataOutput {
    if (!_videoDataOutput) {
        _videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
        dispatch_queue_t queue = dispatch_queue_create("scanQueue", NULL);
        [_videoDataOutput setSampleBufferDelegate:self queue:queue];
        _videoDataOutput.videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                          [NSNumber numberWithInt:kCVPixelFormatType_32BGRA], kCVPixelBufferPixelFormatTypeKey,
                                          [NSNumber numberWithInt: 320], (id)kCVPixelBufferWidthKey,
                                          [NSNumber numberWithInt: 240], (id)kCVPixelBufferHeightKey,
                                          nil];
    }
    return _videoDataOutput;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
