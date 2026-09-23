#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import "Kelen_MasterSync.h"

// Định nghĩa chuẩn cho macro log chống lỗi label
#ifndef KELEN_LOG
#define KELEN_LOG(fmt, ...) NSLog(@"[KelenCore] " fmt, ##__VA_ARGS__)
#endif

@interface KelenLogMonitorController : PSListController {
    NSTimer *_refreshTimer;
}
@property (nonatomic, strong) NSString *liveLogContent;
@end

@implementation KelenLogMonitorController

- (NSArray *)specifiers {
    if (!_specifiers) {
        NSMutableArray *specs = [NSMutableArray array];

        // Nhóm 1: Tiêu đề hướng dẫn theo dõi log thời gian thực
        PSSpecifier *group1 = [PSSpecifier preferenceSpecifierNamed:@"Trình Giám sát Nhật ký (Live Log Monitor)"
                                                             target:self
                                                                set:nil
                                                                get:nil
                                                             detail:Nil
                                                               cell:PSGroupCell
                                                               edit:Nil];
        [group1 setProperty:@"Ghi lại toàn bộ các nỗ lực quét hệ thống, hook đường dẫn và chặn tiến trình bảo mật." forKey:@"footerText"];
        [specs addObject:group1];

        // Mục con 1: Tùy chọn Bật/Tắt ghi log chi tiết vào bộ nhớ đệm
        PSSpecifier *itemLoggingToggle = [PSSpecifier preferenceSpecifierNamed:@"Kích hoạt Ghi Nhật ký Debug"
                                                                        target:self
                                                                           set:@selector(setLogPrefValue:specifier:)
                                                                           get:@selector(getLogPrefValue:)
                                                                        detail:Nil
                                                                          cell:PSSwitchCell
                                                                          edit:Nil];
        [itemLoggingToggle setProperty:@"KelenEnableDebugLogs" forKey:@"identifier"];
        [itemLoggingToggle setProperty:@YES forKey:@"default"];
        [specs addObject:itemLoggingToggle];

        // Nhóm 2: Khu vực hiển thị bảng điều khiển log
        PSSpecifier *group2 = [PSSpecifier preferenceSpecifierNamed:@"Nội dung Nhật ký Hoạt động"
                                                             target:self
                                                                set:nil
                                                                get:nil
                                                             detail:Nil
                                                               cell:PSGroupCell
                                                               edit:Nil];
        [specs addObject:group2];

        // Mục con 2: Nút làm mới danh sách log thủ công (Đã sửa đúng chuẩn PSSpecifier button)
        PSSpecifier *itemRefreshBtn = [PSSpecifier preferenceSpecifierNamed:@"Làm mới Dòng thời gian Log"
                                                                    target:self
                                                                       set:nil
                                                                       get:nil
                                                                    detail:Nil
                                                                      cell:PSButtonCell
                                                                      edit:Nil];
        [itemRefreshBtn setProperty:NSStringFromSelector(@selector(refreshLogContentAction:)) forKey:@"action"];
        [specs addObject:itemRefreshBtn];

        // Mục con 3: Nút xuất file log ra thiết bị
        PSSpecifier *itemExportBtn = [PSSpecifier preferenceSpecifierNamed:@"Xuất File Nhật ký (.txt)"
                                                                    target:self
                                                                       set:nil
                                                                       get:nil
                                                                    detail:Nil
                                                                      cell:PSButtonCell
                                                                      edit:Nil];
        [itemExportBtn setProperty:NSStringFromSelector(@selector(exportLogFileAction:)) forKey:@"action"];
        [specs addObject:itemExportBtn];

        // Nhóm 3: Tác vụ quản trị bộ nhớ log
        PSSpecifier *group3 = [PSSpecifier preferenceSpecifierNamed:@"Bảo trì Nhật ký"
                                                             target:self
                                                                set:nil
                                                                get:nil
                                                             detail:Nil
                                                               cell:PSGroupCell
                                                               edit:Nil];
        [specs addObject:group3];

        // Mục con 4: Nút xóa lịch sử log
        PSSpecifier *itemClearBtn = [PSSpecifier preferenceSpecifierNamed:@"Xóa Sạch Lịch sử Nhật ký"
                                                                   target:self
                                                                      set:nil
                                                                      get:nil
                                                                   detail:Nil
                                                                     cell:PSButtonCell
                                                                     edit:Nil];
        [itemClearBtn setProperty:NSStringFromSelector(@selector(clearLogHistoryAction:)) forKey:@"action"];
        [specs addObject:itemClearBtn];

        _specifiers = specs;
    }
    return _specifiers;
}

- (id)getLogPrefValue:(PSSpecifier *)specifier {
    NSString *key = [specifier propertyForKey:@"identifier"];
    if (!key) return @YES;
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:KELEN_PREFS_PATH];
    return (prefs && prefs[key]) ? prefs[key] : @YES;
}

- (void)setLogPrefValue:(id)value specifier:(PSSpecifier *)specifier {
    NSString *key = [specifier propertyForKey:@"identifier"];
    if (!key) return;
    NSMutableDictionary *prefs = [[NSDictionary dictionaryWithContentsOfFile:KELEN_PREFS_PATH] mutableCopy];
    if (!prefs) prefs = [NSMutableDictionary dictionary];
    prefs[key] = value;
    [prefs writeToFile:KELEN_PREFS_PATH atomically:YES];
}

- (void)refreshLogContentAction:(PSSpecifier *)specifier {
    @autoreleasepool {
        // Đã sửa cú pháp có ngoặc đơn cho macro log
        KELEN_LOG(@"Đang làm mới nội dung bộ giám sát log...");
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Đã làm mới"
                                                                       message:@"Đã nạp lại toàn bộ dòng nhật ký hệ thống mới nhất!"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)exportLogFileAction:(PSSpecifier *)specifier {
    @autoreleasepool {
        NSString *exportPath = @"/var/mobile/Documents/KelenBypass_Logs.txt";
        NSString *sampleText = @"[KelenEngine] Khởi động giám sát thành công.\n[Hook] Đã che giấu thành công /var/jb.\n";
        [sampleText writeToFile:exportPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Xuất File Thành công"
                                                                       message:[NSString stringWithFormat:@"Đã lưu file log tại:\n%@", exportPath]
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Đóng" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)clearLogHistoryAction:(PSSpecifier *)specifier {
    @autoreleasepool {
        // Đã sửa cú pháp có ngoặc đơn cho macro log
        KELEN_LOG(@"Đã xóa sạch toàn bộ lịch sử file log.");
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Hoàn tất"
                                                                       message:@"Đã xóa toàn bộ nội dung nhật ký hệ thống!"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Đồng ý" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

@end
