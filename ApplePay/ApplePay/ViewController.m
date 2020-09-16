//
//  ViewController.m
//  ApplePay
//
//  Created by M1-MacPro on 2020/9/11.
//  Copyright © 2020 M1-MacPro. All rights reserved.
//

#import "ViewController.h"
#import "QYIPAPurchase.h"
#import <LocalAuthentication/LocalAuthentication.h>

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextField *textField;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)onClickPay:(id)sender {
    [STTextHudTool showWaitText:@"正在加载" delay:30];
    [[QYIPAPurchase manager] WJbuyProductWithProductID:self.textField.text payResult:^(BOOL isSuccess, NSString *certificate, NSString *errorMsg) {
        if (isSuccess) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [STTextHudTool showSuccessText:certificate withSecond:2];
            });
            NSLog(@"苹果充值成功，通知后台到账");
        }else{
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [STTextHudTool showErrorText:errorMsg withSecond:2];
            });
            NSLog(@"内购失败%@",errorMsg);
        }
    }];
}

- (IBAction)onClickTouchID:(id)sender {
    [self loadAuthentication];
}

/**
 * 指纹登录验证
 */
- (void)loadAuthentication
{
    LAContext *myContext = [[LAContext alloc] init];
    // 这个属性是设置指纹输入失败之后的弹出框的选项
    myContext.localizedFallbackTitle = @"忘记密码";
    NSError *authError = nil;
    NSString *myLocalizedReasonString = @"请按住Home键完成验证";
    // MARK: 判断设备是否支持指纹识别
    if ([myContext canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&authError])
    {
        [myContext evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics localizedReason:myLocalizedReasonString reply:^(BOOL success, NSError * _Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if(success)
                {
                    [STTextHudTool showSuccessText:@"指纹认证成功"];
                }
                else
                {
                    NSLog(@"指纹认证失败，%@", error.description);
                    NSLog(@"%ld", (long)error.code); // 错误码 error.code
                    switch (error.code)
                    {
                        case LAErrorAuthenticationFailed: // Authentication was not successful, because user failed to provide valid credentials
                        {
                            [STTextHudTool showErrorText:@"授权失败"]; // -1 连续三次指纹识别错误
                        }
                            break;
                        case LAErrorUserCancel: // Authentication was canceled by user (e.g. tapped Cancel button)
                        {
                            [STTextHudTool showErrorText:@"用户取消验证Touch ID"]; // -2 在TouchID对话框中点击了取消按钮
                        }
                            break;
                        case LAErrorUserFallback: // Authentication was canceled, because the user tapped the fallback button (Enter Password)
                        {
                            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                [STTextHudTool showErrorText:@"用户选择输入密码，切换主线程处理"]; // -3 在TouchID对话框中点击了输入密码按钮
                            }];
                        }
                            break;
                        case LAErrorSystemCancel: // Authentication was canceled by system (e.g. another application went to foreground)
                        {
                            [STTextHudTool showErrorText:@"取消授权，如其他应用切入，用户自主"]; // -4 TouchID对话框被系统取消，例如按下Home或者电源键
                        }
                            break;
                        case LAErrorPasscodeNotSet: // Authentication could not start, because passcode is not set on the device.
                        {
                            [STTextHudTool showErrorText:@"设备系统未设置密码"]; // -5
                        }
                            break;
                        case LAErrorBiometryNotAvailable: // Authentication could not start, because Touch ID is not available on the device
                        {
                            [STTextHudTool showErrorText:@"设备未设置Touch ID"]; // -6
                        }
                            break;
                        case LAErrorBiometryNotEnrolled: // Authentication could not start, because Touch ID has no enrolled fingers
                        {
                            [STTextHudTool showErrorText:@"用户未录入指纹"]; // -7
                        }
                            break;
                        
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_9_0
                        case LAErrorBiometryLockout: //Authentication was not successful, because there were too many failed Touch ID attempts and Touch ID is now locked. Passcode is required to unlock Touch ID, e.g. evaluating LAPolicyDeviceOwnerAuthenticationWithBiometrics will ask for passcode as a prerequisite 用户连续多次进行Touch ID验证失败，Touch ID被锁，需要用户输入密码解锁，先Touch ID验证密码
                        {
                            [STTextHudTool showErrorText:@"Touch ID被锁，需要用户输入密码解锁"]; // -8 连续五次指纹识别错误，TouchID功能被锁定，下一次需要输入系统密码
                        }
                            break;
                        case LAErrorAppCancel: // Authentication was canceled by application (e.g. invalidate was called while authentication was in progress) 如突然来了电话，电话应用进入前台，APP被挂起啦");
                        {
                            [STTextHudTool showErrorText:@"用户不能控制情况下APP被挂起"]; // -9
                        }
                            break;
                        case LAErrorInvalidContext: // LAContext passed to this call has been previously invalidated.
                        {
                            [STTextHudTool showErrorText:@"LAContext传递给这个调用之前已经失效"]; // -10
                        }
                            break;
#else
#endif
                        default:
                        {
                            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                [STTextHudTool showText:@"其他情况，切换主线程处理"];
                            }];
                            break;
                        }
                    }
                }
            });
        }];
    }
    else
    {
        NSLog(@"%ld",(long)authError.code);
        switch (authError.code)
        {
            case LAErrorBiometryNotEnrolled:
            {
                //Authentication could not start, because Touch ID has no enrolled fingers.
                [STTextHudTool showErrorText:@"认证无法启动，因为TouchID没有注册手指"];
                break;
            }
            case LAErrorPasscodeNotSet:
            {
                //Authentication could not start, because passcode is not set on the device.
                [STTextHudTool showErrorText:@"无法启动身份验证，因为设备上没有设置密码"];
                break;
            }
            default:
            {
                //TouchID not available
                [STTextHudTool showErrorText:@"TouchID不可用"];
                break;
            }
        }
    }
}

@end
