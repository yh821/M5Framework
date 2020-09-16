//
//  QYIPAPurchase.h
//  SDK
//
//  Created by 张文杰 on 2018/6/14.
//  Copyright © 2018年 liuchunjie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <M5HUD/STTextHudTool.h>

/**
 block
 
 @param isSuccess 是否支付成功
 @param certificate 支付成功得到的凭证（用于在自己服务器验证）
 @param errorMsg 错误信息
 */
typedef void(^PayResult)(BOOL isSuccess,NSString *certificate,NSString *errorMsg);

@interface QYIPAPurchase : NSObject

@property (nonatomic, copy)PayResult payResultBlock;

+ (instancetype)manager;

/**
 内购支付
 
 @param productID 内购商品ID
 @param payResult 结果
 */
-(void)WJbuyProductWithProductID:(NSString *)productID payResult:(PayResult)payResult;

@end
