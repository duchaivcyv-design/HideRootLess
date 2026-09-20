#ifndef KELEN_SECURITY_PRESETS_H
#define KELEN_SECURITY_PRESETS_H

#import <Foundation/Foundation.h>

// Định nghĩa các mức độ bảo mật sẵn có (Presets) cho hệ thống Kelen Bypass
typedef NS_ENUM(NSInteger, KelenSecurityPresetLevel) {
    KelenSecurityPresetStandard = 0,
    KelenSecurityPresetBalanced = 1,
    KelenSecurityPresetMaximum = 2,
    KelenSecurityPresetStealth = 3
};

@interface KelenSecurityPresets : NSObject

+ (instancetype)sharedPresetManager;

// Áp dụng nhanh một cấu hình mẫu cho toàn bộ hệ thống
- (void)applyPresetLevel:(KelenSecurityPresetLevel)level;

// Lấy tên hiển thị tương ứng của mức bảo mật
- (NSString *)titleForPresetLevel:(KelenSecurityPresetLevel)level;

// Kiểm tra tính toàn vẹn của tệp cấu hình trung tâm
- (BOOL)verifyMasterConfigurationIntegrity;

@end

#implementation KelenSecurityPresets

+ (instancetype)sharedPresetManager {
    static KelenSecurityPresets *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[KelenSecurityPresets alloc] init];
    });
    return sharedInstance;
}

- (NSString *)titleForPresetLevel:(KelenSecurityPresetLevel)level {
    switch (level) {
        case KelenSecurityPresetStandard: return @"Tiêu chuẩn (Standard)";
        case KelenSecurityPresetBalanced: return @"Cân bằng (Balanced)";
        case KelenSecurityPresetMaximum: return @"Tối đa (Maximum Security)";
        case KelenSecurityPresetStealth: return @"Ẩn danh tuyệt đối (Stealth)";
        default: return @"Không xác định";
    }
}

- (void)applyPresetLevel:(KelenSecurityPresetLevel)level {
    @autoreleasepool {
        NSMutableDictionary *prefs = [NSMutableDictionary dictionary];
        
        switch (level) {
            case KelenSecurityPresetStandard:
                prefs[@"KelenHookAntiDebug"] = @YES;
                prefs[@"KelenHookDyld"] = @NO;
                prefs[@"KelenHookFileSystem"] = @YES;
                break;
            case KelenSecurityPresetBalanced:
                prefs[@"KelenHookAntiDebug"] = @YES;
                prefs[@"KelenHookDyld"] = @YES;
                prefs[@"KelenHookFileSystem"] = @YES;
                prefs[@"KelenHookSysctl"] = @YES;
                break;
            case KelenSecurityPresetMaximum:
            case KelenSecurityPresetStealth:
                prefs[@"KelenHookAntiDebug"] = @YES;
                prefs[@"KelenHookDyld"] = @YES;
                prefs[@"KelenHookFileSystem"] = @YES;
                prefs[@"KelenHookSysctl"] = @YES;
                prefs[@"KelenStockEmulation"] = @YES;
                prefs[@"KelenEnableDebugLogs"] = @NO; // Tắt log để tránh bị phát hiện vết
                break;
        }
        
        // Ghi đè cấu hình vào đường dẫn plist chuẩn
        NSString *prefsPath = @"/var/mobile/Library/Preferences/com.kelen.masterbypass.plist";
        [prefs writeToFile:prefsPath atomically:YES];
        
        // Gửi thông báo tải lại cấu hình hệ thống
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFSTR("com.kelen.masterbypass/ReloadPrefs"),
            NULL,
            NULL,
            YES
        );
    }
}

- (BOOL)verifyMasterConfigurationIntegrity {
    NSString *prefsPath = @"/var/mobile/Library/Preferences/com.kelen.masterbypass.plist";
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:prefsPath];
    return (prefs != nil && [prefs count] > 0);
}

@end

#endif /* KELEN_SECURITY_PRESETS_H */
