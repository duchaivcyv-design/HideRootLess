#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <notify.h>
#import <mach/mach.h>
#import <mach/vm_map.h>

#define KELEN_MEM_PREFS @"/var/mobile/Library/Preferences/com.kelen.masterbypass.plist"
#define KELEN_MEM_LOG(fmt, ...) NSLog(@"HideRLess-MemoryEngine: " fmt, ##__VA_ARGS__)

@interface MemoryProtectionEngine : NSObject {
    BOOL _memShieldActive;
}
+ (instancetype)sharedInstance;
- (void)updateMemoryState;
- (BOOL)isMemoryShieldEnabled;
@end

@implementation MemoryProtectionEngine

+ (instancetype)sharedInstance {
    static MemoryProtectionEngine *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self updateMemoryState];
        
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            (__bridge const void *)(self),
            (CFNotificationCallback)&MemPreferencesChanged,
            CFSTR("com.kelen.masterbypass/ReloadPrefs"),
            NULL,
            CFNotificationSuspensionBehaviorDeliverImmediately
        );
    }
    return self;
}

static void MemPreferencesChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    [[MemoryProtectionEngine sharedInstance] updateMemoryState];
}

- (void)updateMemoryState {
    @autoreleasepool {
        NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:KELEN_MEM_PREFS];
        if (prefs) {
            _memShieldActive = prefs[@"KelenMemoryProtection"] ? [prefs[@"KelenMemoryProtection"] boolValue] : YES;
            if (_memShieldActive) {
                KELEN_MEM_LOG(@"[MemoryProtection] Đã kích hoạt bảo vệ vùng nhớ và chống quét RAM cấp thấp.");
            }
        } else {
            _memShieldActive = YES;
        }
    }
}

- (BOOL)isMemoryShieldEnabled {
    return _memShieldActive;
}

@end

// ============================================================================
// HỆ THỐNG HOOK VM ĐỂ NGĂN CHẶN ĐỌC VÙNG NHỚ TIẾN TRÌNH
// ============================================================================

%hookf(kern_return_t, vm_read, vm_map_t target_task, vm_address_t address, vm_size_t size, vm_offset_t *data, mach_msg_type_number_t *dataCnt) {
    if ([[MemoryProtectionEngine sharedInstance] isMemoryShieldEnabled]) {
        if (target_task == mach_task_self()) {
            KELEN_MEM_LOG(@"[Blocked] Đã ngăn chặn yêu cầu đọc vùng nhớ tại địa chỉ: %lx", (unsigned long)address);
            return KERN_PROTECTION_FAILURE;
        }
    }
    return %orig(target_task, address, size, data, dataCnt);
}

%ctor {
    @autoreleasepool {
        [MemoryProtectionEngine sharedInstance];
        KELEN_MEM_LOG(@"[Init] Mô-đun MemoryProtectionEngine đã sẵn sàng hoạt động.");
    }
}
