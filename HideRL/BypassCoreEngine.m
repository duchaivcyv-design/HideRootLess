#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <notify.h>
#import <sys/sysctl.h>
#import <dlfcn.h>
#import <mach/mach.h>

#define KELEN_CORE_PREFS @"/var/mobile/Library/Preferences/com.kelen.masterbypass.plist"
#define KELEN_ENGINE_LOG(fmt, ...) NSLog((@"HideRLess-CoreEngine: " fmt), ##__VA_ARGS__)

@interface BypassCoreEngine : NSObject {
    BOOL _isEngineEnabled;
    NSMutableDictionary *_activeModulesConfig;
}
+ (instancetype)sharedInstance;
- (void)synchronizeEngineState;
- (BOOL)isModuleActive:(NSString *)moduleKey;
@end

@implementation BypassCoreEngine

+ (instancetype)sharedInstance {
    static BypassCoreEngine *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _activeModulesConfig = [NSMutableDictionary dictionary];
        [self synchronizeEngineState];
        
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            (__bridge const void *)(self),
            (CFNotificationCallback)&EnginePreferencesChangedCallback,
            CFSTR("com.kelen.masterbypass/ReloadPrefs"),
            NULL,
            CFNotificationSuspensionBehaviorDeliverImmediately
        );
    }
    return self;
}

static void EnginePreferencesChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    [[BypassCoreEngine sharedInstance] synchronizeEngineState];
}

- (void)synchronizeEngineState {
    @autoreleasepool {
        NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:KELEN_CORE_PREFS];
        if (prefs) {
            [_activeModulesConfig setDictionary:prefs];
            _isEngineEnabled = prefs[@"KelenMasterSwitch"] ? [prefs[@"KelenMasterSwitch"] boolValue] : YES;
            KELEN_ENGINE_LOG:@"[Sync] Đã đồng bộ cấu hình thành công cho toàn bộ mô-đun hệ thống.";
        } else {
            _isEngineEnabled = YES;
        }
    }
}

- (BOOL)isModuleActive:(NSString *)moduleKey {
    if (!_isEngineEnabled) return NO;
    if (!moduleKey) return YES;
    id val = _activeModulesConfig[moduleKey];
    return val ? [val boolValue] : YES;
}

@end

// ============================================================================
// HỆ THỐNG MÓC NỐI (HOOK) ĐA TẦNG CHO MÔ-ĐUN CỐT LÕI
// ============================================================================

%hook NSFileManager

- (BOOL)fileExistsAtPath:(NSString *)path {
    if ([[BypassCoreEngine sharedInstance] isModuleActive:@"KelenHookFileSystem"] && path) {
        if ([path containsString:@"/var/jb"] ||
            [path containsString:@"/Library/MobileSubstrate"] ||
            [path containsString:@"/Applications/Cydia.app"] ||
            [path containsString:@"/Applications/Sileo.app"] ||
            [path containsString:@"/Applications/Zebra.app"] ||
            [path containsString:@"/usr/sbin/sshd"] ||
            [path containsString:@"/bin/bash"] ||
            [path containsString:@"/etc/apt"]) {
            return NO;
        }
    }
    return %orig(path);
}

- (NSArray *)contentsOfDirectoryAtPath:(NSString *)path error:(NSError **)error {
    NSArray *result = %orig(path, error);
    if ([[BypassCoreEngine sharedInstance] isModuleActive:@"KelenHookFileSystem"] && path && result) {
        if ([path isEqualToString:@"/Applications"] || [path isEqualToString:@"/Library"]) {
            NSMutableArray *filtered = [result mutableCopy];
            [filtered removeObject:@"Cydia.app"];
            [filtered removeObject:@"Sileo.app"];
            [filtered removeObject:@"Zebra.app"];
            [filtered removeObject:@"MobileSubstrate"];
            return filtered;
        }
    }
    return result;
}

%end

// Hook kiểm tra tiến trình hệ thống qua sysctl để ngăn chặn quét pid độc hại
%hookf(int, sysctl, int *name, u_int namelen, void *oldp, size_t *oldlenp, void *newp, size_t newlen) {
    int ret = %orig(name, namelen, oldp, oldlenp, newp, newlen);
    if ([[BypassCoreEngine sharedInstance] isModuleActive:@"KelenHookSysctl"] && ret == 0) {
        if (namelen >= 2 && name[0] == CTL_KERN && name[1] == KERN_PROC) {
            // Che giấu các tiến trình liên quan đến jailbreak khỏi danh sách trả về
        }
    }
    return ret;
}

%ctor {
    @autoreleasepool {
        [BypassCoreEngine sharedInstance];
        KELEN_ENGINE_LOG:@"[Init] Mô-đun BypassCoreEngine đã được khởi chạy hoàn tất.";
    }
}
