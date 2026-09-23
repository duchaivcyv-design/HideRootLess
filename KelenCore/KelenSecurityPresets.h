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

#endif /* KELEN_SECURITY_PRESETS_H */
