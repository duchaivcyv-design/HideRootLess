#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <notify.h>

#define KELEN_NET_PREFS @"/var/mobile/Library/Preferences/com.kelen.masterbypass.plist"
#define KELEN_NET_LOG(fmt, ...) NSLog((@"HideRLess-NetworkEngine: " fmt), ##__VA_ARGS__)

@interface NetworkInterceptEngine : NSObject {
    BOOL _netShieldActive;
}
+ (instancetype)sharedInstance;
- (void)updateNetworkState;
- (BOOL)isNetworkShieldEnabled;
@end

@implementation NetworkInterceptEngine

+ (instancetype)sharedInstance {
    static NetworkInterceptEngine *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self updateNetworkState];
        
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            (__bridge const void *)(self),
            (CFNotificationCallback)&NetPreferencesChanged,
            CFSTR("com.kelen.masterbypass/ReloadPrefs"),
            NULL,
            CFNotificationSuspensionBehaviorDeliverImmediately
        );
    }
    return self;
}

static void NetPreferencesChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    [[NetworkInterceptEngine sharedInstance] updateNetworkState];
}

- (void)updateNetworkState {
    @autoreleasepool {
        NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:KELEN_NET_PREFS];
        if (prefs) {
            _netShieldActive = prefs[@"KelenNetworkIntercept"] ? [prefs[@"KelenNetworkIntercept"] boolValue] : YES;
            if (_netShieldActive) {
                KELEN_NET_LOG:@"[NetworkIntercept] Đã kích hoạt cơ chế lọc và bảo vệ luồng dữ liệu mạng.";
            }
        } else {
            _netShieldActive = YES;
        }
    }
}

- (BOOL)isNetworkShieldEnabled {
    return _netShieldActive;
}

@end

// ============================================================================
// HỆ THỐNG HOOK NSURLSESSION VÀ URL CONNECTION ĐỂ LỌC GIAO THỨC MẠNG
// ============================================================================

%hook NSURLSession

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    if (request && [[NetworkInterceptEngine sharedInstance] isNetworkShieldEnabled]) {
        NSString *urlString = [[request URL] absoluteString];
        if (urlString && ([urlString containsString:@"jailbreak"] || [urlString containsString:@"detect"] || [urlString containsString:@"security_check"])) {
            KELEN_NET_LOG:@"[Intercepted Request] Đã chặn luồng yêu cầu mạng đáng ngờ tới: %@", urlString];
            // Tạo block phản hồi giả lập an toàn để ứng dụng không phát hiện lỗi mạng
            void (^safeHandler)(NSData *, NSURLResponse *, NSError *) = ^(NSData *data, NSURLResponse *response, NSError *error) {
                NSDictionary *dummyDict = @{@"status": @(0), @"jailbroken": @(NO), @"message": @"secure"};
                NSData *dummyData = [NSJSONSerialization dataWithJSONObject:dummyDict options:0 error:nil];
                NSHTTPURLResponse *dummyResponse = [[NSHTTPURLResponse alloc] initWithURL:[request URL] statusCode:200 HTTPVersion:@"HTTP/1.1" headerFields:@{}] ;
                completionHandler(dummyData, dummyResponse, nil);
            };
            return %orig(request, safeHandler);
        }
    }
    return %orig(request, completionHandler);
}

%end

// Hook kiểm tra URL Connection truyền thống
%hook NSURLConnection

+ (NSData *)sendSynchronousRequest:(NSURLRequest *)request returningResponse:(NSURLResponse **)response error:(NSError **)error {
    if (request && [[NetworkInterceptEngine sharedInstance] isNetworkShieldEnabled]) {
        NSString *urlString = [[request URL] absoluteString];
        if (urlString && [urlString containsString:@"jailbreak"]) {
            if (error) *error = nil;
            NSDictionary *dummyDict = @{@"jailbroken": @(NO)};
            return [NSJSONSerialization dataWithJSONObject:dummyDict options:0 error:nil];
        }
    }
    return %orig(request, response, error);
}

%end

%ctor {
    @autoreleasepool {
        [NetworkInterceptEngine sharedInstance];
        KELEN_NET_LOG:@"[Init] Mô-đun NetworkInterceptEngine đã sẵn sàng hoạt động.";
    }
}
