#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSSwitchTableCell.h>
#import "Kelen_MasterSync.h"

// Khai báo interface đồng bộ mục con với KelenEngine
@interface KelenAdvancedSubController : PSListController {
    BOOL _isSyncingCache;
}
@property (nonatomic, strong) NSMutableDictionary *masterPreferencesCache;
- (void)syncStateWithMasterEngine;
@end

@implementation KelenAdvancedSubController

- (instancetype)init {
    self = [super init];
    if (self) {
        _isSyncingCache = NO;
        [self syncStateWithMasterEngine];
    }
    return self;
}

- (NSArray *)specifiers {
    if (!_specifiers) {
        NSMutableArray *specs = [array mutableCopy];
        specs = [NSMutableArray array];

        // --- SECTION 1: CẤU HÌNH MÓC NỐI (HOOK ENGINE) ---
        PSSpecifier *group1 = [PSSpecifier preferenceSpecifierNamed:@"Cấu hình Mô-đun Hook & Bypass"
                                                             target:self
                                                                set:nil
                                                                get:nil
                                                             detail:Nil
                                                               cell:PSGroupCell
                                                               edit:Nil];
        [group1 setProperty:@"Đồng bộ trực tiếp trạng thái kiểm soát qua Kelen_MasterSync.h" forKey:@"footerText"];
        [specs addObject:group1];

        // Item 1: Anti-Debugging Hook
        PSSpecifier *item1 = [PSSpecifier preferenceSpecifierNamed:@"Chặn Gỡ lỗi & Phát hiện (Anti-Debug)"
                                                             target:self
                                                                set:@selector(setMasterPrefValue:specifier:)
                                                                get:@selector(getMasterPrefValue:)
                                                             detail:Nil
                                                               cell:PSSwitchCell
                                                               edit:Nil];
        [item1 setProperty:@"KelenHookAntiDebug" forKey:@"identifier"];
        [item1 setProperty:@YES forKey:@"default"];
        [specs addObject:item1];

        // Item 2: Dyld Image Hiding
        PSSpecifier *item2 = [PSSpecifier preferenceSpecifierNamed:@"Ẩn Thư viện Động Dyld & Ellekit"
                                                             target:self
                                                                set:@selector(setMasterPrefValue:specifier:)
                                                                get:@selector(getMasterPrefValue:)
                                                             detail:Nil
                                                               cell:PSSwitchCell
                                                               edit:Nil];
        [item2 setProperty:@"KelenHookDyld" forKey:@"identifier"];
        [item2 setProperty:@YES forKey:@"default"];
        [specs addObject:item2];

        // --- SECTION 2: FILE SYSTEM & KERNEL CHEAT ---
        PSSpecifier *group2 = [PSSpecifier preferenceSpecifierNamed:@"Ảo hóa Hệ thống Tệp tin (File System)"
                                                             target:self
                                                                set:nil
                                                                get:nil
                                                             detail:Nil
                                                               cell:PSGroupCell
                                                               edit:Nil];
        [group2 setProperty:@"Che giấu tuyệt đối các đường dẫn rootless và thông tin kernel" forKey:@"footerText"];
        [specs addObject:group2];

        // Item 3: Rootless Path Hiding
        PSSpecifier *item3 = [PSSpecifier preferenceSpecifierNamed:@"Ẩn Thư mục Rootless (/var/jb)"
                                                             target:self
                                                                set:@selector(setMasterPrefValue:specifier:)
                                                                get:@selector(getMasterPrefValue:)
                                                             detail:Nil
                                                               cell:PSSwitchCell
                                                               edit:Nil];
        [item3 setProperty:@"KelenHookFileSystem" forKey:@"identifier"];
        [item3 setProperty:@YES forKey:@"default"];
        [specs addObject:item3];

        // Item 4: Sysctl Interception
        PSSpecifier *item4 = [PSSpecifier preferenceSpecifierNamed:@"Lọc Lệnh Trạng thái Sysctl"
                                                             target:self
                                                                set:@selector(setMasterPrefValue:specifier:)
                                                                get:@selector(getMasterPrefValue:)
                                                             detail:Nil
                                                               cell:PSSwitchCell
                                                               edit:Nil];
        [item4 setProperty:@"KelenHookSysctl" forKey:@"identifier"];
        [item4 setProperty:@YES forKey:@"default"];
        [specs addObject:item4];

        // Item 5: Stock Device Profile Emulation
        PSSpecifier *item5 = [PSSpecifier preferenceSpecifierNamed:@"Giả lập Hồ sơ Thiết bị Nguyên bản"
                                                             target:self
                                                                set:@selector(setMasterPrefValue:specifier:)
                                                                get:@selector(getMasterPrefValue:)
                                                             detail:Nil
                                                               cell:PSSwitchCell
                                                               edit:Nil];
        [item5 setProperty:@"KelenStockEmulation" forKey:@"identifier"];
        [item5 setProperty:@YES forKey:@"default"];
        [specs addObject:item5];

        // --- SECTION 3: MAINTENANCE ACTIONS ---
        PSSpecifier *group3 = [PSSpecifier preferenceSpecifierNamed:@"Quản trị & Bảo trì Hệ thống"
                                                             target:self
                                                                set:nil
                                                                get:nil
                                                             detail:Nil
                                                               cell:PSGroupCell
                                                               edit:Nil];
        [group3 setProperty:@"Các tác vụ dọn dẹp và áp dụng cấu hình nhanh" forKey:@"footerText"];
        [specs addObject:group3];

        // Item 6: Clear Cache Button
        PSSpecifier *item6 = [PSSpecifier preferenceSpecifierNamed:@"Xóa Sạch Bộ nhớ Tạm (Cache)"
                                                             target:self
                                                           selector:@selector(handleClearCacheAction:)
                                                               cell:PSButtonCell
                                                             edit:Nil];
        [specs addObject:item6];

        // Item 7: Respring SpringBoard Button
        PSSpecifier *item7 = [PSSpecifier preferenceSpecifierNamed:@"Áp dụng & Làm mới (Respring)"
                                                             target:self
                                                           selector:@selector(handleRespringAction:)
                                                               cell:PSButtonCell
                                                             edit:Nil];
        [specs addObject:item7];

        _specifiers = specs;
    }
    return _specifiers;
}

- (void)syncStateWithMasterEngine {
    @autoreleasepool {
        _isSyncingCache = YES;
        NSDictionary *loadedPrefs = [NSDictionary dictionaryWithContentsOfFile:KELEN_PREFS_PATH];
        if (loadedPrefs) {
            self.masterPreferencesCache = [loadedPrefs mutableCopy];
        } else {
            self.masterPreferencesCache = [NSMutableDictionary dictionary];
        }
        _isSyncingCache = NO;
    }
}

- (id)getMasterPrefValue:(PSSpecifier *)specifier {
    NSString *key = [specifier propertyForKey:@"identifier"];
    if (!key) return @YES;

    @autoreleasepool {
        if (self.masterPreferencesCache[key] != nil) {
            return self.masterPreferencesCache[key];
        }
        
        NSDictionary *currentPrefs = [NSDictionary dictionaryWithContentsOfFile:KELEN_PREFS_PATH];
        if (currentPrefs && currentPrefs[key] != nil) {
            self.masterPreferencesCache[key] = currentPrefs[key];
            return currentPrefs[key];
        }
    }
    
    id defaultVal = [specifier propertyForKey:@"default"];
    return defaultVal ? defaultVal : @YES;
}

- (void)setMasterPrefValue:(id)value specifier:(PSSpecifier *)specifier {
    if (_isSyncingCache) return;
    
    NSString *key = [specifier propertyForKey:@"identifier"];
    if (!key) return;

    @autoreleasepool {
        self.masterPreferencesCache[key] = value;
        
        NSMutableDictionary *filePrefs = [[NSDictionary dictionaryWithContentsOfFile:KELEN_PREFS_PATH] mutableCopy];
        if (!filePrefs) {
            filePrefs = [NSMutableDictionary dictionary];
        }
        
        filePrefs[key] = value;
        [filePrefs writeToFile:KELEN_PREFS_PATH atomically:YES];

        // Gửi thông báo Darwin qua MasterSync Center
        CFNotificationCenterRef center = CFNotificationCenterGetDarwinNotifyCenter();
        CFNotificationCenterPostNotification(center, CFSTR("com.kelen.masterbypass/ReloadPrefs"), NULL, NULL, YES);
        
        KELEN_LOG:@"Đã đồng bộ thành công khóa cấu hình: %@ thành giá trị: %@", key, value;
    }
}

- (void)handleClearCacheAction:(PSSpecifier *)specifier {
    @autoreleasepool {
        KELEN_LOG:@"Thực hiện dọn dẹp bộ nhớ cache đồng bộ...";
        
        NSFileManager *fm = [NSFileManager defaultManager];
        NSString *tmpDir = NSTemporaryDirectory();
        NSArray *tmpFiles = [fm contentsOfDirectoryAtPath:tmpDir error:nil];
        for (NSString *file in tmpFiles) {
            [fm removeItemAtPath:[tmpDir stringByAppendingPathComponent:file] error:nil];
        }
        
        [self.masterPreferencesCache removeAllObjects];
        [fm removeItemAtPath:KELEN_PREFS_PATH error:nil];

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Đã đồng bộ & Dọn dẹp"
                                                                       message:@"Toàn bộ cache hệ thống và cấu hình tạm đã được làm sạch!"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Xác nhận" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)handleRespringAction:(PSSpecifier *)specifier {
    @autoreleasepool {
        KELEN_LOG:@"Tiến hành khởi động lại SpringBoard thông qua tiến trình hệ thống...";
        
        pid_t pid;
        const char *args[] = {"killall", "backboardd", NULL};
        posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char *const *)args, NULL);
    }
}

@end
