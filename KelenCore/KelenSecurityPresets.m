#import "KelenSecurityPresets.h"
#import "Kelen_MasterSync.h"

@implementation KelenSecurityPresets

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
        
        // Ghi đè cấu hình vào đường dẫn plist chuẩn thông qua hằng số KELEN_PREFS_PATH
        [prefs writeToFile:KELEN_PREFS_PATH atomically:YES];
        
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
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:KELEN_PREFS_PATH];
    return (prefs != nil && [prefs count] > 0);
}

@end
