#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import "Kelen_MasterSync.h"

// Khai báo giao diện trang con quản lý chi tiết các mục con (5-7 mục nâng cao)
@interface KelenAdvancedSubController : PSListController
@property (nonatomic, strong) NSMutableDictionary *cachedPreferences;
@end

@implementation KelenAdvancedSubController

- (NSArray *)specifiers {
    if (!_specifiers) {
        NSMutableArray *specifiers = [NSMutableArray array];

        // --- NHÓM 1: CẤU HÌNH TỔNG QUAN & BẢO MẬT ---
        PSSpecifier *group1 = [PSSpecifier preferenceSpecifierNamed:@"Bảo mật Hệ thống Nâng cao"
                                                             target:self
                                                                set:nil
                                                                get:nil
                                                             detail:Nil
                                                               cell:PSGroupCell
                                                               edit:Nil];
        [group1 setProperty:@"Quản lý các mô-đun móc nối (hook) cấp thấp và đồng bộ trực tiếp qua Kelen_MasterSync.h" forKey:@"footerText"];
        [specifiers addObject:group1];

        // Mục con 1: Công tắc bật tắt kiểm tra tiến trình hệ thống
        PSSpecifier *item1 = [PSSpecifier preferenceSpecifierNamed:@"Chặn Phát hiện Tiến trình (Anti-Debugging)"
                                                             target:self
                                                                set:@selector(setPrefValue:specifier:)
                                                                get:@selector(getPrefValue:)
                                                             detail:Nil
                                                               cell:PSSwitchCell
                                                               edit:Nil];
        [item1 setProperty:@"KelenHookAntiDebug" forKey:@"identifier"];
        [item1 setProperty:@YES forKey:@"default"];
        [specifiers addObject:item1];

        // Mục con 2: Công tắc ẩn danh sách thư viện Dylib / Ellekit
        PSSpecifier *item2 = [PSSpecifier preferenceSpecifierNamed:@"Ẩn Thư viện Dylib / Ellekit"
                                                             target:self
                                                                set:@selector(setPrefValue:specifier:)
                                                                get:@selector(getPrefValue:)
                                                             detail:Nil
                                                               cell:PSSwitchCell
                                                               edit:Nil];
        [item2 setProperty:@"KelenHookDyld" forKey:@"identifier"];
        [item2 setProperty:@YES forKey:@"default"];
        [specifiers addObject:item2];


        // --- NHÓM 2: MÔ-ĐUN FILE SYSTEM & ĐƯỜNG DẪN ---
        PSSpecifier *group2 = [PSSpecifier preferenceSpecifierNamed:@"Bộ lọc Tệp tin & Đường dẫn Ảo hóa"
                                                             target:self
                                                                set:nil
                                                                get:nil
                                                             detail:Nil
                                                               cell:PSGroupCell
                                                               edit:Nil];
        [group2 setProperty:@"Che giấu triệt để các đường dẫn rootless, thư mục jailbreak và tệp cấu hình hệ thống" forKey:@"footerText"];
        [specifiers addObject:group2];

        // Mục con 3: Công tắc ẩn đường dẫn Rootless /var/jb
        PSSpecifier *item3 = [PSSpecifier preferenceSpecifierNamed:@"Ẩn Đường dẫn Rootless (/var/jb)"
                                                             target:self
                                                                set:@selector(setPrefValue:specifier:)
                                                                get:@selector(getPrefValue:)
                                                             detail:Nil
                                                               cell:PSSwitchCell
                                                               edit:Nil];
        [item3 setProperty:@"KelenHookFileSystem" forKey:@"identifier"];
        [item3 setProperty:@YES forKey:@"default"];
        [specifiers addObject:item3];

        // Mục con 4: Công tắc chặn gọi hàm Sysctl hệ thống
        PSSpecifier *item4 = [PSSpecifier preferenceSpecifierNamed:@"Chặn Lệnh Sysctl & Trạng thái Kernel"
                                                             target:self
                                                                set:@selector(setPrefValue:specifier:)
                                                                get:@selector(getPrefValue:)
                                                             detail:Nil
                                                               cell:PSSwitchCell
                                                               edit:Nil];
        [item4 setProperty:@"KelenHookSysctl" forKey:@"identifier"];
        [item4 setProperty:@YES forKey:@"default"];
        [specifiers addObject:item4];

        // Mục con 5: Công tắc giả lập trạng thái thiết bị nguyên bản (Stock Device)
        PSSpecifier *item5 = [PSSpecifier preferenceSpecifierNamed:@"Giả lập Trạng thái Máy Nguyên bản"
                                                             target:self
                                                                set:@selector(setPrefValue:specifier:)
                                                                get:@selector(getPrefValue:)
                                                             detail:Nil
                                                               cell:PSSwitchCell
                                                               edit:Nil];
        [item5 setProperty:@"KelenStockEmulation" forKey:@"identifier"];
        [item5 setProperty:@YES forKey:@"default"];
        [specifiers addObject:item5];


        // --- NHÓM 3: THAO TÁC HỆ THỐNG & DỌN DẸP ---
        PSSpecifier *group3 = [PSSpecifier preferenceSpecifierNamed:@"Công cụ Quản trị & Bảo trì"
                                                             target:self
                                                                set:nil
                                                                get:nil
                                                             detail:Nil
                                                               cell:PSGroupCell
                                                               edit:Nil];
        [group3 setProperty:@"Thực hiện dọn dẹp bộ nhớ đệm và làm mới SpringBoard ngay lập tức" forKey:@"footerText"];
        [specifiers addObject:group3];

        // Mục con 6: Nút xóa toàn bộ Cache hệ thống bypass (Button Cell)
        PSSpecifier *item6 = [PSSpecifier preferenceSpecifierNamed:@"Xóa Sạch Bộ nhớ đệm (Cache)"
                                                             target:self
                                                           selector:@selector(executeClearCacheAction:)
                                                               cell:PSButtonCell
                                                             edit:Nil];
        [specifiers addObject:item6];

        // Mục con 7: Nút khởi động lại SpringBoard / Respring (Button Cell)
        PSSpecifier *item7 = [PSSpecifier preferenceSpecifierNamed:@"Làm mới SpringBoard (Respring)"
                                                             target:self
                                                           selector:@selector(executeRespringAction:)
                                                               cell:PSButtonCell
                                                             edit:Nil];
        [specifiers addObject:item7];

        _specifiers = specifiers;
    }
    return _specifiers;
}

// Phương thức đọc giá trị cấu hình đồng bộ chuẩn từ file .plist thông qua macro
- (id)getPrefValue:(PSSpecifier *)specifier {
    NSString *key = [specifier propertyForKey:@"identifier"];
    if (!key) return @YES;

    @autoreleasepool {
        NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:KELEN_PREFS_PATH];
        if (prefs && prefs[key]) {
            return prefs[key];
        }
    }
    
    id defaultValue = [specifier propertyForKey:@"default"];
    return defaultValue ? defaultValue : @YES;
}

// Phương thức ghi giá trị cấu hình khi người dùng thay đổi trạng thái Switch
- (void)setPrefValue:(id)value specifier:(PSSpecifier *)specifier {
    NSString *key = [specifier propertyForKey:@"identifier"];
    if (!key) return;

    @autoreleasepool {
        NSMutableDictionary *prefs = [[NSDictionary dictionaryWithContentsOfFile:KELEN_PREFS_PATH] mutableCopy];
        if (!prefs) {
            prefs = [NSMutableDictionary dictionary];
        }

        prefs[key] = value;
        [prefs writeToFile:KELEN_PREFS_PATH atomically:YES];

        // Gửi thông báo đồng bộ Darwin Notification để Tweak nhận diện thay đổi tức thì
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFSTR("com.kelen.masterbypass/ReloadPrefs"),
            NULL,
            NULL,
            YES
        );
        
        KELEN_LOG:@"Đã cập nhật cấu hình thành công cho khóa: %@ = %@", key, value;
    }
}

// Hành động thực thi của Mục con 6: Xóa Cache
- (void)executeClearCacheAction:(PSSpecifier *)specifier {
    @autoreleasepool {
        KELEN_LOG:@"Đang tiến hành dọn dẹp bộ nhớ đệm hệ thống bypass...";
        
        // Thêm logic xóa cache thư mục tạm nếu cần thiết
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *tempPath = NSTemporaryDirectory();
        NSArray *tempFiles = [fileManager contentsOfDirectoryAtPath:tempPath error:nil];
        for (NSString *file in tempFiles) {
            [fileManager removeItemAtPath:[tempPath stringByAppendingPathComponent:file] error:nil];
        }
        
        // Hiển thị thông báo xác nhận thành công đơn giản
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Thành công"
                                                                       message:@"Đã xóa sạch toàn bộ bộ nhớ đệm cache hệ thống!"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Đồng ý" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

// Hành động thực thi của Mục con 7: Respring máy
- (void)executeRespringAction:(PSSpecifier *)specifier {
    @autoreleasepool {
        KELEN_LOG:@"Thực thi tiến trình làm mới SpringBoard (Respring)...";
        
        pid_t pid;
        const char *args[] = {"killall", "backboardd", NULL};
        posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char *const *)args, NULL);
    }
}

@end
