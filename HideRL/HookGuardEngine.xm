#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <notify.h>
#import <dlfcn.h>

#define KELEN_GUARD_PREFS @"/var/mobile/Library/Preferences/com.kelen.masterbypass.plist"
#define KELEN_GUARD_LOG(fmt, ...) NSLog(@"HideRLess-HookGuard: " fmt, ##__VA_ARGS__)

@interface HookGuardEngine : NSObject {
    BOOL _hookGuardActive;
}
+ (instancetype)sharedInstance;
- (void)updateGuardState;
- (BOOL)isHookGuardEnabled;
@end

@implementation HookGuardEngine

+ (instancetype)sharedInstance {
    static HookGuardEngine *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self updateGuardState];
        
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            (__bridge const void *)(self),
            (CFNotificationCallback)&GuardPreferencesChanged,
            CFSTR("com.kelen.masterbypass/ReloadPrefs"),
            NULL,
            CFNotificationSuspensionBehaviorDeliverImmediately
        );
    }
    return self;
}

static void GuardPreferencesChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    [[HookGuardEngine sharedInstance] updateGuardState];
}

- (void)updateGuardState {
    @autoreleasepool {
        NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:KELEN_GUARD_PREFS];
        if (prefs) {
            _hookGuardActive = prefs[@"KelenHookGuard"] ? [prefs[@"KelenHookGuard"] boolValue] : YES;
            if (_hookGuardActive) {
                KELEN_GUARD_LOG(@"[HookGuard] Đã kích hoạt mô-đun giám sát và bảo vệ tính toàn vẹn hook.");
            }
        } else {
            _hookGuardActive = YES;
        }
    }
}

- (BOOL)isHookGuardEnabled {
    return _hookGuardActive;
}

@end

// ============================================================================
// HỆ THỐNG KIỂM SOÁT VÀ BẢO VỆ ĐỊA CHỈ HÀM RUNTIME
// ============================================================================

%hookf(void *, dlsym, void *handle, const char *symbol) {
    void *orig_symbol = %orig(handle, symbol);
    if (symbol && [[HookGuardEngine sharedInstance] isHookGuardEnabled]) {
        // Giám sát các truy vấn hàm hệ thống nhạy cảm để tránh bị dò quét bảng chỉ mục
        NSString *symStr = [NSString stringWithUTF8String:symbol];
        if ([symStr containsString:@"ptrace"] || [symStr containsString:@"sysctl"] || [symStr containsString:@"syscall"]) {
            KELEN_GUARD_LOG(@"[HookGuard] Phát hiện tiến trình truy vấn biểu tượng nhạy cảm: %@", symStr);
        }
    }
    return orig_symbol;
}

%ctor {
    @autoreleasepool {
        [HookGuardEngine sharedInstance];
        KELEN_GUARD_LOG(@"[Init] Mô-đun HookGuardEngine đã sẵn sàng hoạt động.");
    }
}
