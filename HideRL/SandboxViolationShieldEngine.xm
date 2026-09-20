#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <notify.h>
#import <syslog.h>

#define KELEN_VIOLATION_PREFS @"/var/mobile/Library/Preferences/com.kelen.masterbypass.plist"
#define KELEN_VIOLATION_LOG(fmt, ...) NSLog(@"HideRLess-ViolationEngine: " fmt, ##__VA_ARGS__)

@interface SandboxViolationShieldEngine : NSObject {
    BOOL _violationShieldActive;
}
+ (instancetype)sharedInstance;
- (void)updateViolationState;
- (BOOL)isViolationShieldEnabled;
@end

@implementation SandboxViolationShieldEngine

+ (instancetype)sharedInstance {
    static SandboxViolationShieldEngine *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self updateViolationState];
        
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            (__bridge const void *)(self),
            (CFNotificationCallback)&ViolationPreferencesChanged,
            CFSTR("com.kelen.masterbypass/ReloadPrefs"),
            NULL,
            CFNotificationSuspensionBehaviorDeliverImmediately
        );
    }
    return self;
}

static void ViolationPreferencesChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    [[SandboxViolationShieldEngine sharedInstance] updateViolationState];
}

- (void)updateViolationState {
    @autoreleasepool {
        NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:KELEN_VIOLATION_PREFS];
        if (prefs) {
            _violationShieldActive = prefs[@"KelenViolationShield"] ? [prefs[@"KelenViolationShield"] boolValue] : YES;
            if (_violationShieldActive) {
                KELEN_VIOLATION_LOG(@"[ViolationShield] Đã kích hoạt mô-đun chặn ghi nhật ký lỗi vi phạm hệ thống.");
            }
        } else {
            _violationShieldActive = YES;
        }
    }
}

- (BOOL)isViolationShieldEnabled {
    return _violationShieldActive;
}

@end

// ============================================================================
// HỆ THỐNG HOOK SYSLOG VÀ CÁC HÀM GHI NHẬT KÝ ĐỂ VÔ HIỆU HÓA LOG CẢNH BÁO
// ============================================================================

%hookf(void, syslog, int priority, const char *format, ...) {
    if (format && [[SandboxViolationShieldEngine sharedInstance] isViolationShieldEnabled]) {
        NSString *fmtStr = [NSString stringWithUTF8String:format];
        if ([fmtStr containsString:@"jailbreak"] || 
            [fmtStr containsString:@"sandbox"] || 
            [fmtStr containsString:@"hook"] || 
            [fmtStr containsString:@"substrate"] || 
            [fmtStr containsString:@"cycript"]) {
            // Chặn không cho hệ thống ghi log các từ khóa nhạy cảm này ra ngoài
            return;
        }
    }
    
    va_list args;
    va_start(args, format);
    // Sử dụng vsyslog để truyền tải chính xác các đối số biến đổi (variadic arguments)
    vsyslog(priority, format, args);
    va_end(args);
}

%ctor {
    @autoreleasepool {
        [SandboxViolationShieldEngine sharedInstance];
        KELEN_VIOLATION_LOG(@"[Init] Mô-đun SandboxViolationShieldEngine đã sẵn sàng hoạt động.");
    }
}
