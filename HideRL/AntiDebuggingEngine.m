#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <notify.h>
#import <sys/sysctl.h>
#import <dlfcn.h>
#import <mach/mach.h>

#define KELEN_ANTI_PREFS @"/var/mobile/Library/Preferences/com.kelen.masterbypass.plist"
#define KELEN_ANTIDEBUG_LOG(fmt, ...) NSLog((@"HideRLess-AntiDebug: " fmt), ##__VA_ARGS__)

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
                KELEN_ANTIDEBUG_LOG:@"[AntiDebug] Đã kích hoạt cơ chế vô hiệu hóa gỡ lỗi và phân tích tiến trình.";
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
// HỆ THỐNG HOOK CHẶN PTRACE VÀ CÁC HÀM KIỂM TRA DEBUGGER CẤP THẤP
// ============================================================================

// Hook hàm ptrace để ngăn chặn việc ứng dụng tự gắn cờ từ chối debug hoặc phát hiện lldb
%hookf(int, ptrace, int request, pid_t pid, caddr_t addr, int data) {
    if ([[AntiDebuggingEngine sharedInstance] isAntiDebugEnabled]) {
        // PT_DENY_ATTACH (31) là cờ phổ biến dùng để crash app khi có debugger bám vào
        if (request == 31) {
            KELEN_ANTIDEBUG_LOG:@"[Intercepted] Đã vô hiệu hóa thành công yêu cầu PT_DENY_ATTACH từ tiến trình.";
            return 0; // Trả về 0 để giả lập thành công, tránh bị crash
        }
    }
    return %orig(request, pid, addr, data);
}

// Hook hàm syscall để chặn các lệnh gọi trực tiếp xuống kernel kiểm tra cờ tiến trình bị bắt (P_TRACED)
%hookf(int, syscall, int number, ...) {
    va_list args;
    va_start(args, number);
    
    // Kiểm tra mã hệ thống syscall liên quan đến ptrace nếu cần thiết
    if ([[AntiDebuggingEngine sharedInstance] isAntiDebugEnabled]) {
        // SYS_ptrace tương ứng trong kiến trúc kernel darwin
        if (number == 26) { // Mã syscall ptrace trên iOS arm64
            va_end(args);
            return 0;
        }
    }
    
    int result = %orig;
    va_end(args);
    return result;
}

// Hook dlsym để che giấu các hàm kiểm tra debug động
%hookf(void *, dlsym, void *handle, const char *symbol) {
    if (symbol && [[AntiDebuggingEngine sharedInstance] isAntiDebugEnabled]) {
        if (strcmp(symbol, "ptrace") == 0) {
            // Có thể trả về hàm giả hoặc giữ nguyên với điều kiện đã được lọc ở trên
        }
    }
    return %orig(handle, symbol);
}

%ctor {
    @autoreleasepool {
        [AntiDebuggingEngine sharedInstance];
        KELEN_ANTIDEBUG_LOG:@"[Init] Mô-đun AntiDebuggingEngine đã sẵn sàng hoạt động.";
    }
}
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <notify.h>
#import <sys/sysctl.h>
#import <dlfcn.h>
#import <mach/mach.h>

#define KELEN_ANTI_PREFS @"/var/mobile/Library/Preferences/com.kelen.masterbypass.plist"
#define KELEN_ANTIDEBUG_LOG(fmt, ...) NSLog((@"HideRLess-AntiDebug: " fmt), ##__VA_ARGS__)

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
                KELEN_ANTIDEBUG_LOG:@"[AntiDebug] Đã kích hoạt cơ chế vô hiệu hóa gỡ lỗi và phân tích tiến trình.";
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
// HỆ THỐNG HOOK CHẶN PTRACE VÀ CÁC HÀM KIỂM TRA DEBUGGER CẤP THẤP
// ============================================================================

// Hook hàm ptrace để ngăn chặn việc ứng dụng tự gắn cờ từ chối debug hoặc phát hiện lldb
%hookf(int, ptrace, int request, pid_t pid, caddr_t addr, int data) {
    if ([[AntiDebuggingEngine sharedInstance] isAntiDebugEnabled]) {
        // PT_DENY_ATTACH (31) là cờ phổ biến dùng để crash app khi có debugger bám vào
        if (request == 31) {
            KELEN_ANTIDEBUG_LOG:@"[Intercepted] Đã vô hiệu hóa thành công yêu cầu PT_DENY_ATTACH từ tiến trình.";
            return 0; // Trả về 0 để giả lập thành công, tránh bị crash
        }
    }
    return %orig(request, pid, addr, data);
}

// Hook hàm syscall để chặn các lệnh gọi trực tiếp xuống kernel kiểm tra cờ tiến trình bị bắt (P_TRACED)
%hookf(int, syscall, int number, ...) {
    va_list args;
    va_start(args, number);
    
    // Kiểm tra mã hệ thống syscall liên quan đến ptrace nếu cần thiết
    if ([[AntiDebuggingEngine sharedInstance] isAntiDebugEnabled]) {
        // SYS_ptrace tương ứng trong kiến trúc kernel darwin
        if (number == 26) { // Mã syscall ptrace trên iOS arm64
            va_end(args);
            return 0;
        }
    }
    
    int result = %orig;
    va_end(args);
    return result;
}

// Hook dlsym để che giấu các hàm kiểm tra debug động
%hookf(void *, dlsym, void *handle, const char *symbol) {
    if (symbol && [[AntiDebuggingEngine sharedInstance] isAntiDebugEnabled]) {
        if (strcmp(symbol, "ptrace") == 0) {
            // Có thể trả về hàm giả hoặc giữ nguyên với điều kiện đã được lọc ở trên
        }
    }
    return %orig(handle, symbol);
}

%ctor {
    @autoreleasepool {
        [AntiDebuggingEngine sharedInstance];
        KELEN_ANTIDEBUG_LOG:@"[Init] Mô-đun AntiDebuggingEngine đã sẵn sàng hoạt động.";
    }
}
