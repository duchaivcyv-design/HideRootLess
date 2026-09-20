#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <notify.h>

#define KELEN_DEVICE_PREFS @"/var/mobile/Library/Preferences/com.kelen.masterbypass.plist"
#define KELEN_DEVICE_LOG(fmt, ...) NSLog((@"HideRLess-DeviceEngine: " fmt), ##__VA_ARGS__)

@interface DeviceIdentifierMaskEngine : NSObject {
    BOOL _deviceMaskActive;
    NSString *_fakeUDID;
    NSString *_fakeIdentifierForVendor;
}
+ (instancetype)sharedInstance;
- (void)updateDeviceMaskState;
- (BOOL)isDeviceMaskEnabled;
- (NSString *)getFakeUDID;
- (NSString *)getFakeIdentifierForVendor;
@end

@implementation DeviceIdentifierMaskEngine

+ (instancetype)sharedInstance {
    static DeviceIdentifierMaskEngine *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _fakeUDID = @"8F9C4A21-7E3B-4D11-9B5C-6A2F1E8D3C4B";
        _fakeIdentifierForVendor = @"C4B3A21F-8E9C-4D11-9B5C-7F9E2A1D6C8F";
        [self updateDeviceMaskState];
        
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            (__bridge const void *)(self),
            (CFNotificationCallback)&DevicePreferencesChanged,
            CFSTR("com.kelen.masterbypass/ReloadPrefs"),
            NULL,
            CFNotificationSuspensionBehaviorDeliverImmediately
        );
    }
    return self;
}

static void DevicePreferencesChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    [[DeviceIdentifierMaskEngine sharedInstance] updateDeviceMaskState];
}

- (void)updateDeviceMaskState {
    @autoreleasepool {
        NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:KELEN_DEVICE_PREFS];
        if (prefs) {
            _deviceMaskActive = prefs[@"KelenDeviceMask"] ? [prefs[@"KelenDeviceMask"] boolValue] : YES;
            if (_deviceMaskActive) {
                KELEN_DEVICE_LOG:@"[DeviceMask] Đã kích hoạt mô-đun giả mạo thông tin định danh phần cứng.";
            }
        } else {
            _deviceMaskActive = YES;
        }
    }
}

- (BOOL)isDeviceMaskEnabled {
    return _deviceMaskActive;
}

- (NSString *)getFakeUDID {
    return _fakeUDID;
}

- (NSString *)getFakeIdentifierForVendor {
    return _fakeIdentifierForVendor;
}

@end

// ============================================================================
// HỆ THỐNG HOOK UIDVICE VÀ THƯ VIỆN PHẦN CỨNG ĐỂ CHE GIẤU THÔNG TIN THẬT
// ============================================================================

%hook UIDevice

- (NSUUID *)identifierForVendor {
    if ([[DeviceIdentifierMaskEngine sharedInstance] isDeviceMaskEnabled]) {
        NSString *fakeUUIDStr = [[DeviceIdentifierMaskEngine sharedInstance] getFakeIdentifierForVendor];
        NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:fakeUUIDStr];
        if (uuid) {
            return uuid;
        }
    }
    return %orig();
}

- (NSString *)systemName {
    if ([[DeviceIdentifierMaskEngine sharedInstance] isDeviceMaskEnabled]) {
        return @"iPhone OS";
    }
    return %orig();
}

- (NSString *)model {
    if ([[DeviceIdentifierMaskEngine sharedInstance] isDeviceMaskEnabled]) {
        return @"iPhone";
    }
    return %orig();
}

%end

%hook NSBundle

- (id)objectForInfoDictionaryKey:(NSString *)key {
    if (key && [[DeviceIdentifierMaskEngine sharedInstance] isDeviceMaskEnabled]) {
        if ([key isEqualToString:@"CFBundleIdentifier"]) {
            // Có thể xử lý chuyển hướng bundle identifier nếu nằm trong danh sách ngoại lệ
        }
    }
    return %orig(key);
}

%end

%ctor {
    @autoreleasepool {
        [DeviceIdentifierMaskEngine sharedInstance];
        KELEN_DEVICE_LOG:@"[Init] Mô-đun DeviceIdentifierMaskEngine đã được khởi tạo hoàn tất.";
    }
}
