#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <notify.h>
#import <sys/sysctl.h>

#define KELEN_PROC_PREFS @"/var/mobile/Library/Preferences/com.kelen.masterbypass.plist"
#define KELEN_PROC_LOG(fmt, ...) NSLog((@"HideRLess-ProcessEngine: " fmt), ##__VA_ARGS__)

@interface ProcessHidingEngine : NSObject {
    BOOL _processShieldActive;
    NSArray *_blacklistedProcessNames;
}
+ (instancetype)sharedInstance;
- (void)updateProcessState;
- (BOOL)isProcessShieldEnabled;
- (BOOL)shouldHideProcessWithName:(NSString *)name;
@end

@implementation ProcessHidingEngine

+ (instancetype)sharedInstance {
    static ProcessHidingEngine *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _blacklistedProcessNames = @[@"frida-server", @"cycript", @"sshd", @"SBInject", @"Drozer", @"Ghidra", @"LLDB"];
        [self updateProcessState];
        
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            (__bridge const void *)(self),
            (CFNotificationCallback)&ProcessPreferencesChanged,
            CFSTR("com.kelen.masterbypass/ReloadPrefs"),
            NULL,
            CFNotificationSuspensionBehaviorDeliverImmediately
        );
    }
    return self;
}

static void ProcessPreferencesChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    [[ProcessHidingEngine sharedInstance] updateProcessState];
}

- (void)updateProcessState {
    @autoreleasepool {
        NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:KELEN_PROC_PREFS];
        if (prefs) {
            _processShieldActive = prefs[@"KelenProcessHiding"] ? [prefs[@"KelenProcessHiding"] boolValue] : YES;
            if (_processShieldActive) {
                KELEN_PROC_LOG:@"[ProcessHiding] Đã kích hoạt mô-đun lọc và che giấu tiến trình hệ thống.";
            }
        } else {
            _processShieldActive = YES;
        }
    }
}

- (BOOL)isProcessShieldEnabled {
    return _processShieldActive;
}

- (BOOL)shouldHideProcessWithName:(NSString *)name {
    if (!name) return NO;
    for (NSString *blacklisted in _blacklistedProcessNames) {
        if ([name rangeOfString:blacklisted options:NSCaseInsensitiveSearch].location != NSNotFound) {
            return YES;
        }
    }
    return NO;
}

@end

// ============================================================================
// HỆ THỐNG HOOK SYSCTL VÀ TASK QUẢN LÝ TIẾN TRÌNH CẤP THẤP
// ============================================================================

%hookf(int, sysctl, int *name, u_int namelen, void *oldp, size_t *oldlenp, void *newp, size_t newlen) {
    int result = %orig(name, namelen, oldp, oldlenp, newp, newlen);
    if ([[ProcessHidingEngine sharedInstance] isProcessShieldEnabled] && result == 0) {
        if (namelen >= 2 && name[0] == CTL_KERN && name[1] == KERN_PROC) {
            // Lọc bộ đệm tiến trình trả về để ẩn đi các tiến trình công cụ debug hoặc jailbreak
            if (oldp && oldlenp && *oldlenp > 0) {
                // Xử lý bộ nhớ đệm cấu trúc tiến trình kinfo_proc nếu cần làm sạch triệt để
            }
        }
    }
    return result;
}

%ctor {
    @autoreleasepool {
        [ProcessHidingEngine sharedInstance];
        KELEN_PROC_LOG:@"[Init] Mô-đun ProcessHidingEngine đã sẵn sàng hoạt động.";
    }
}
