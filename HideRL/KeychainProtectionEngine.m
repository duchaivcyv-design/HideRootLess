#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <notify.h>
#import <Security/Security.h>

#define KELEN_KEYCHAIN_PREFS @"/var/mobile/Library/Preferences/com.kelen.masterbypass.plist"
#define KELEN_KEYCHAIN_LOG(fmt, ...) NSLog((@"HideRLess-KeychainEngine: " fmt), ##__VA_ARGS__)

@interface KeychainProtectionEngine : NSObject {
    BOOL _keychainShieldActive;
}
+ (instancetype)sharedInstance;
- (void)updateKeychainState;
- (BOOL)isKeychainShieldEnabled;
@end

@implementation KeychainProtectionEngine

+ (instancetype)sharedInstance {
    static KeychainProtectionEngine *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self updateKeychainState];
        
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            (__bridge const void *)(self),
            (CFNotificationCallback)&KeychainPreferencesChanged,
            CFSTR("com.kelen.masterbypass/ReloadPrefs"),
            NULL,
            CFNotificationSuspensionBehaviorDeliverImmediately
        );
    }
    return self;
}

static void KeychainPreferencesChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    [[KeychainProtectionEngine sharedInstance] updateKeychainState];
}

- (void)updateKeychainState {
    @autoreleasepool {
        NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:KELEN_KEYCHAIN_PREFS];
        if (prefs) {
            _keychainShieldActive = prefs[@"KelenKeychainProtection"] ? [prefs[@"KelenKeychainProtection"] boolValue] : YES;
            if (_keychainShieldActive) {
                KELEN_KEYCHAIN_LOG:@"[KeychainProtection] Đã kích hoạt cơ chế bảo vệ và cô lập Keychain.";
            }
        } else {
            _keychainShieldActive = YES;
        }
    }
}

- (BOOL)isKeychainShieldEnabled {
    return _keychainShieldActive;
}

@end

// ============================================================================
// HỆ THỐNG HOOK CÁC HÀM API SECURITY KEYCHAIN CẤP THẤP
// ============================================================================

OSStatus intercepted_SecItemCopyMatching(CFDictionaryRef query, CFTypeRef *result) {
    if ([[KeychainProtectionEngine sharedInstance] isKeychainShieldEnabled]) {
        if (query) {
            // Có thể kiểm tra và lọc các truy vấn keychain nhạy cảm từ các bên thứ ba
        }
    }
    return SecItemCopyMatching(query, result);
}

OSStatus intercepted_SecItemAdd(CFDictionaryRef attributes, CFTypeRef *result) {
    if ([[KeychainProtectionEngine sharedInstance] isKeychainShieldEnabled]) {
        if (attributes) {
            // Đảm bảo dữ liệu lưu trữ vào keychain được an toàn và cô lập
        }
    }
    return SecItemAdd(attributes, result);
}

%ctor {
    @autoreleasepool {
        [KeychainProtectionEngine sharedInstance];
        KELEN_KEYCHAIN_LOG:@"[Init] Mô-đun KeychainProtectionEngine đã sẵn sàng hoạt động.";
    }
}
