//
//  SecondViewController.m
//  firstapp
//
//  Created by yuanhuan on 2018/10/24.
//  Copyright © 2018年 yuanhuan. All rights reserved.
//

#import "SecondViewController.h"
#import <LocalAuthentication/LocalAuthentication.h>

@interface SecondViewController ()

@property (weak, nonatomic) IBOutlet UILabel *labelLog;
@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

@implementation SecondViewController

- (IBAction)onClickTouchID:(id)sender {
    [self loadAuthentication];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
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
                    [self setLog:@"指纹认证成功"];
                }
                else
                {
                    [self setLog:[NSString stringWithFormat:@"指纹认证失败，%@", error.description]];
                    [self setLog:[NSString stringWithFormat:@"%ld", (long)error.code]]; // 错误码 error.code
                    switch (error.code)
                    {
                        case LAErrorAuthenticationFailed: // Authentication was not successful, because user failed to provide valid credentials
                        {
                            [self setLog:@"授权失败"]; // -1 连续三次指纹识别错误
                        }
                            break;
                        case LAErrorUserCancel: // Authentication was canceled by user (e.g. tapped Cancel button)
                        {
                            [self setLog:@"用户取消验证Touch ID"]; // -2 在TouchID对话框中点击了取消按钮
                        }
                            break;
                        case LAErrorUserFallback: // Authentication was canceled, because the user tapped the fallback button (Enter Password)
                        {
                            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                [self setLog:@"用户选择输入密码，切换主线程处理"]; // -3 在TouchID对话框中点击了输入密码按钮
                            }];
                        }
                            break;
                        case LAErrorSystemCancel: // Authentication was canceled by system (e.g. another application went to foreground)
                        {
                            [self setLog:@"取消授权，如其他应用切入，用户自主"]; // -4 TouchID对话框被系统取消，例如按下Home或者电源键
                        }
                            break;
                        case LAErrorPasscodeNotSet: // Authentication could not start, because passcode is not set on the device.
                        {
                            [self setLog:@"设备系统未设置密码"]; // -5
                        }
                            break;
                        case LAErrorBiometryNotAvailable: // Authentication could not start, because Touch ID is not available on the device
                        {
                            [self setLog:@"设备未设置Touch ID"]; // -6
                        }
                            break;
                        case LAErrorBiometryNotEnrolled: // Authentication could not start, because Touch ID has no enrolled fingers
                        {
                            [self setLog:@"用户未录入指纹"]; // -7
                        }
                            break;
                        
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_9_0
                        case LAErrorBiometryLockout: //Authentication was not successful, because there were too many failed Touch ID attempts and Touch ID is now locked. Passcode is required to unlock Touch ID, e.g. evaluating LAPolicyDeviceOwnerAuthenticationWithBiometrics will ask for passcode as a prerequisite 用户连续多次进行Touch ID验证失败，Touch ID被锁，需要用户输入密码解锁，先Touch ID验证密码
                        {
                            [self setLog:@"Touch ID被锁，需要用户输入密码解锁"]; // -8 连续五次指纹识别错误，TouchID功能被锁定，下一次需要输入系统密码
                        }
                            break;
                        case LAErrorAppCancel: // Authentication was canceled by application (e.g. invalidate was called while authentication was in progress) 如突然来了电话，电话应用进入前台，APP被挂起啦");
                        {
                            [self setLog:@"用户不能控制情况下APP被挂起"]; // -9
                        }
                            break;
                        case LAErrorInvalidContext: // LAContext passed to this call has been previously invalidated.
                        {
                            [self setLog:@"LAContext传递给这个调用之前已经失效"]; // -10
                        }
                            break;
#else
#endif
                        default:
                        {
                            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                [self setLog:@"其他情况，切换主线程处理"];
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
        [self setLog:@"设备不支持指纹"];
        [self setLog:[NSString stringWithFormat:@"%ld", (long)authError.code]];
        switch (authError.code)
        {
            case LAErrorBiometryNotEnrolled:
            {
                [self setLog:@"Authentication could not start, because Touch ID has no enrolled fingers"];
                break;
            }
            case LAErrorPasscodeNotSet:
            {
                [self setLog:@"Authentication could not start, because passcode is not set on the device"];
                break;
            }
            default:
            {
                [self setLog:@"TouchID not available"];
                break;
            }
        }
    }
}

- (void)setLog:(NSString*)msg
{
    //[_labelLog setText:[NSString stringWithFormat:@"%@%@\n",_labelLog.text,msg]];
    _textView.text = [NSString stringWithFormat:@"%@%@\n",_textView.text,msg];
}

@end
