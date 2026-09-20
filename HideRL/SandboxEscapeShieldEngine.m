#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <notify.h>
#import <sys/stat.h>

#define KELEN_SANDBOX_PREFS @"/var/mobile/Library/Preferences/com.kelen.masterbypass.plist"
#define KELEN_SANDBOX_LOG(fmt, ...) NSLog((@"HideRLess-SandboxEngine: " fmt), ##__VA_ARGS__)

@interface SandboxEscapeShieldEngine : NSObject {
    BOOL _sandboxShieldActive;
}
+ (instancetype)sharedInstance;
- (void)updateSandboxState;
- (BOOL)isSandboxShieldEnabled;
@end

@implementation SandboxEscapeShieldEngine

+ (instancetype)sharedInstance {
    static SandboxEscapeShieldEngine *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self updateSandboxState];
        
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            (__bridge const void *)(self),
            (CFNotificationCallback)&SandboxPreferencesChanged,
            CFSTR("com.kelen.masterbypass/ReloadPrefs"),
            NULL,
            CFNotificationSuspensionBehaviorDeliverImmediately
        );
    }
    return self;
}

static void SandboxPreferencesChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    [[SandboxEscapeShieldEngine sharedInstance] updateSandboxState];
}

- (void)updateSandboxState {
    @autoreleasepool {
        NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:KELEN_SANDBOX_PREFS];
        if (prefs) {
            _sandboxShieldActive = prefs[@"KelenSandboxEscapeShield"] ? [prefs[@"KelenSandboxEscapeShield"] boolValue] : YES;
            if (_sandboxShieldActive) {
                KELEN_SANDBOX_LOG:@"[SandboxEscapeShield] Đã kích hoạt cơ chế bảo vệ và kiểm soát ranh giới Sandbox.";
            }
        } else {
            _sandboxShieldActive = YES;
        }
    }
}

- (BOOL)isSandboxShieldEnabled {
    return _sandboxShieldActive;
}

@end

// ============================================================================
// HỆ THỐNG HOOK KIỂM TRA ĐƯỜNG DẪN VÀ TRUY CẬP TỆP NGOÀI SANDBOX
// ============================================================================

%hook NSData

+ (NSData *)dataWithContentsOfFile:(NSString *)path options:(NSDataReadingOptions)readOptionsMask error:(NSError **)error {
    if (path && [[SandboxEscapeShieldEngine sharedInstance] isSandboxShieldEnabled]) {
        if ([path hasPrefix:@"/private/var/mobile/Containers/Data/Application"] == NO && 
            ([path containsString:@"/jb"] || [path containsString:@"/Library/MobileSubstrate"])) {
            KELEN_SANDBOX_LOG:@"[Blocked] Đã chặn yêu cầu đọc tệp ngoài phạm vi Sandbox tại đường dẫn: %@", path];
            if (error) {
                *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadNoSuchFileError userInfo:nil];
            }
            return nil;
        }
    }
    return %orig(path, readOptionsMask, error);
}

%end

%hook NSString

- (BOOL)writeToFile:(NSString *)path atomically:(BOOL)useAuxiliaryFile encoding:(NSStringEncoding)enc error:(NSError **)error {
    if (path && [[SandboxEscapeShieldEngine sharedInstance] isSandboxShieldEnabled]) {
        if ([path containsString:@"/var/jb"] || [path containsString:@"/Library/MobileSubstrate"]) {
            KELEN_SANDBOX_LOG:@"[Blocked] Đã chặn hành vi ghi tệp trái phép ra ngoài vùng Sandbox tại: %@", path];
            return NO;
        }
    }
    return %orig(path, useAuxiliaryFile, enc, error);
}

%end

%ctor {
    @autoreleasepool {
        [SandboxEscapeShieldEngine sharedInstance];
        KELEN_SANDBOX_LOG:@"[Init] Mô-đun SandboxEscapeShieldEngine đã sẵn sàng hoạt động.";
    }
}
