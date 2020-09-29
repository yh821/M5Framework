//
//  QYIPAPurchase.m
//  SDK
//
//  Created by 张文杰 on 2018/6/14.
//  Copyright © 2018年 liuchunjie. All rights reserved.
//

#import "QYIPAPurchase.h"
#import <StoreKit/StoreKit.h>
#import <StoreKit/SKPaymentTransaction.h>

@interface QYIPAPurchase()<SKPaymentTransactionObserver,SKProductsRequestDelegate>
{
    SKProductsRequest *request;
    
}
@end

@implementation QYIPAPurchase

+ (instancetype)manager
{
    static QYIPAPurchase *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!manager) {
            manager = [[QYIPAPurchase alloc] init];
        }
    });
    return manager;
}

-(void)WJbuyProductWithProductID:(NSString *)productID payResult:(PayResult)payResult{
    self.payResultBlock = payResult;
    if (productID==nil || !productID.length) {
        [STTextHudTool showErrorText:@"产品ID不能为空"];
        return;
    }
    if ([SKPaymentQueue canMakePayments]) {
        [self requestProductInfo:productID];
    } else {
        [STTextHudTool showErrorText:@"不支持购买"];
    }
}

-(void)requestProductInfo:(NSString *)productID
{
    NSSet *nsset = [NSSet setWithObject:productID];
    request=[[SKProductsRequest alloc] initWithProductIdentifiers:nsset];
    request.delegate=self;
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    [request start];
}

// 查询成功后的回调
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    NSLog(@"-----------收到产品反馈信息--------------");
    NSArray *myProduct = response.products;
    if (myProduct.count==0) {
        if (self.payResultBlock) {
            self.payResultBlock(NO, nil, @"无法获取产品信息，购买失败");
        }
        return;
    }
    for(SKProduct *product in myProduct){
        NSLog(@"SKProduct描述信息: %@", [product description]);
        NSLog(@"产品标题: %@" , product.localizedTitle);
        NSLog(@"产品描述信息: %@" , product.localizedDescription);
        NSLog(@"价格: %@" , product.price);
        NSLog(@"ProductID: %@" , product.productIdentifier);
    }
    SKPayment *payment = nil;
    payment  = [SKPayment paymentWithProduct:myProduct.firstObject];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

//查询失败后的回调
- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
    NSLog(@"请求苹果服务器失败%@",[error localizedDescription]);
    if (self.payResultBlock) {
        self.payResultBlock(NO, nil, [error localizedDescription]);
    }
}

//如果没有设置监听购买结果将直接跳至反馈结束；
-(void) requestDidFinish:(SKRequest *)request
{
    NSLog(@"您没有设置购买结果监听,结束了");
}

#pragma mark ------------------------- 监听结果
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions
{
    //当用户购买的操作有结果时，就会触发下面的回调函数，
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased://交易成功
            {
                [self completeTransaction:transaction];
                NSLog(@"结束订单了");
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            }
                break;
                
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction];//交易失败方法
                break;
                
            case SKPaymentTransactionStateRestored://已经购买过该商品
            {
                NSLog(@"已经购买过");
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            }
                break;
            case SKPaymentTransactionStatePurchasing:
                NSLog(@"已经在商品列表中");
                break;
            case SKPaymentTransactionStateDeferred:
                NSLog(@"最终状态未确定 ");
                break;
            default:
                break;
        }
    }
}

//完成交易
- (void)completeTransaction:(SKPaymentTransaction *)transaction
{
    NSLog(@"购买成功验证订单");
    NSData *data = [NSData dataWithContentsOfFile:[[[NSBundle mainBundle] appStoreReceiptURL] path]];
    NSString *receipt = [data base64EncodedStringWithOptions:0];
    if (self.payResultBlock) {
        self.payResultBlock(YES, receipt, transaction.transactionIdentifier);
    }
}

//交易失败处理
- (void)failedTransaction:(SKPaymentTransaction *)transaction
{
    NSString *error = nil;
    switch (transaction.error.code) {
        case SKErrorUnknown:
            error = @"无法连接iTunes Store";
            break;
        case SKErrorClientInvalid:
            error = @"客户端验证错误";
            break;
        case SKErrorPaymentCancelled:
            error = @"用户取消交易";
            break;
        case SKErrorPaymentInvalid:
            error = @"商品标识无效";
            break;
        case SKErrorPaymentNotAllowed:
            error = @"设备无法购买商品";
            break;
        case SKErrorStoreProductNotAvailable:
            error = @"商店商品不可购买";
            break;
        case SKErrorCloudServicePermissionDenied:
            error = @"用户不允许访问云服务信息";
            break;
        case SKErrorCloudServiceNetworkConnectionFailed:
            error = @"设备没有联网";
            break;
        case SKErrorCloudServiceRevoked:
            error = @"用户已取消使用云服务的权限";
            break;
        case SKErrorPrivacyAcknowledgementRequired:
            error = @"用户需要承认苹果的隐私政策";
            break;
        case SKErrorUnauthorizedRequestData:
            error = @"应用无SKPayment.requestData权限";
            break;
        case SKErrorInvalidOfferIdentifier:
            error = @"指定的订阅发行标识无效";
            break;
        case SKErrorInvalidSignature:
            error = @"提供的加密签名无效";
            break;
        case SKErrorMissingOfferParams:
            error = @"SKPaymentDiscount中缺少一个或多个参数";
            break;
        case SKErrorInvalidOfferPrice:
            error = @"所选报价的价格无效";
            break;
        default:
            error = @"购买失败";
            break;
    }
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
    if (self.payResultBlock) {
        self.payResultBlock(NO, nil, error);
    }
}

- (void)dealloc{
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}


@end
