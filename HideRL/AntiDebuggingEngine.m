#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <notify.h>
#import <sys/sysctl.h>
#import <dlfcn.h>
#import <mach/mach.h>

#define KELEN_ANTI_PREFS @"/var/mobile/Library/Preferences/com.kelen.masterbypass.plist"
#define KELEN_ANTIDEBUG_LOG(fmt, ...) NSLog((@"HideRLess-AntiDebug: " fmt), ##__VA_ARGS__)

// Khai báo nguyên mẫu hàm ptrace hệ thống để sử dụng khi hook/thay thế
int ptrace(int _request, pid_t _pid, caddr_t _addr, int _data);

@interface AntiDebuggingEngine : NSObject {
    BOOL _antiDebugActive;
}
+ (instancetype)sharedInstance;
- (void)updateAntiDebugState;
- (BOOL)isAntiDebugEnabled;
@end

@implementation AntiDebuggingEngine

+ (instancetype)sharedInstance {
    static AntiDebuggingEngine *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self updateAntiDebugState];
        
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            (__bridge const void *)(self),
            (CFNotificationCallback)&AntiDebugPreferencesChanged,
            CFSTR("com.kelen.masterbypass/ReloadPrefs"),
            NULL,
            CFNotificationSuspensionBehaviorDeliverImmediately
        );
    }
    return self;
}

static void AntiDebugPreferencesChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    [[AntiDebuggingEngine sharedInstance] updateAntiDebugState];
}

- (void)updateAntiDebugState {
    @autoreleasepool {
        NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:KELEN_ANTI_PREFS];
        if (prefs) {
            _antiDebugActive = prefs[@"KelenAntiDebugBypass"] ? [prefs[@"KelenAntiDebugBypass"] boolValue] : YES;
            if (_antiDebugActive) {
                KELEN_ANTIDEBUG_LOG(@"[AntiDebug] Đã kích hoạt cơ chế vô hiệu hóa gỡ lỗi và phân tích tiến trình.");
            }
        } else {
            _antiDebugActive = YES;
        }
    }
}

- (BOOL)isAntiDebugEnabled {
    return _antiDebugActive;
}

@end

// ============================================================================
// HỆ THỐNG CHẶN PTRACE VÀ CÁC HÀM KIỂM TRA DEBUGGER CẤP THẤP CHO FILE .M
// ============================================================================

// Thay thế hàm ptrace nguyên thủy để vô hiệu hóa PT_DENY_ATTACH (request = 31)
int hooked_ptrace(int request, pid_t pid, caddr_t addr, int data) {
    if ([[AntiDebuggingEngine sharedInstance] isAntiDebugEnabled]) {
        if (request == 31) { // PT_DENY_ATTACH
            KELEN_ANTIDEBUG_LOG(@"[Intercepted] Đã vô hiệu hóa thành công yêu cầu PT_DENY_ATTACH từ tiến trình.");
            return 0; 
        }
    }
    return ptrace(request, pid, addr, data);
}

// Constructor khởi tạo tự động khi load dylib/tệp thực thi
__attribute__((constructor)) static void kelen_antidebug_ctor(void) {
    @autoreleasepool {
        [AntiDebuggingEngine sharedInstance];
        KELEN_ANTIDEBUG_LOG(@"[Init] Mô-đun AntiDebuggingEngine (.m) đã sẵn sàng hoạt động.");
    }
}
