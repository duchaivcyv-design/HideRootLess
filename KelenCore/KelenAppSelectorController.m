#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "Kelen_MasterSync.h"

// --- KHAI BÁO GIẢ (FORWARD DECLARATION) CHO PREFERENCES FRAMEWORK ---
@interface PSSpecifier : NSObject
+ (instancetype)preferenceSpecifierNamed:(NSString *)title target:(id)target set:(SEL)set get:(SEL)get detail:(Class)detail cell:(int)cell edit:(Class)edit;
- (void)setProperty:(id)value forKey:(NSString *)key;
- (id)propertyForKey:(NSString *)key;
@end

@interface PSListController : UIViewController {
    NSArray *_specifiers;
}
@property (nonatomic, strong) NSArray *specifiers;
@end

static const int PSGroupCell = 0;
static const int PSSwitchCell = 2;
// -------------------------------------------------------------------

// Đảm bảo macro log chuẩn xác chống lỗi biên dịch
#ifndef KELEN_LOG
#define KELEN_LOG(fmt, ...) NSLog(@"[KelenCore] " fmt, ##__VA_ARGS__)
#endif

// Khai báo giao diện ẩn cho LaunchServices để lấy danh sách ứng dụng đã cài đặt
@interface LSApplicationWorkspace : NSObject
+ (id)sharedInstance;
- (NSArray *)allInstalledApplications;
@end

@interface LSApplicationProxy : NSObject
@property (nonatomic, readonly) NSString *applicationIdentifier;
@property (nonatomic, readonly) NSString *localizedName;
@property (nonatomic, readonly) NSURL *bundleURL;
@end

@interface KelenAppSelectorController : PSListController {
    NSArray *_installedAppsCache;
}
@end

@implementation KelenAppSelectorController

- (NSArray *)specifiers {
    if (!_specifiers) {
        NSMutableArray *specs = [NSMutableArray array];

        // Nhóm hướng dẫn
        PSSpecifier *group = [PSSpecifier preferenceSpecifierNamed:@"Chọn Ứng dụng Mục tiêu Bypass"
                                                            target:self
                                                               set:nil
                                                               get:nil
                                                            detail:Nil
                                                              cell:PSGroupCell
                                                              edit:Nil];
        [group setProperty:@"Bật công tắc bên cạnh ứng dụng bạn muốn áp dụng cơ chế che giấu Jailbreak cấp thấp." forKey:@"footerText"];
        [specs addObject:group];

        // Lấy danh sách ứng dụng thực tế trên thiết bị
        @autoreleasepool {
            Class LSWorkspaceClass = objc_getClass("LSApplicationWorkspace");
            if (LSWorkspaceClass) {
                id workspace = [LSWorkspaceClass performSelector:@selector(sharedInstance)];
                NSArray *apps = [workspace performSelector:@selector(allInstalledApplications)];
                
                // Sắp xếp ứng dụng theo tên hiển thị
                NSArray *sortedApps = [apps sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                    NSString *name1 = [obj1 performSelector:@selector(localizedName)];
                    NSString *name2 = [obj2 performSelector:@selector(localizedName)];
                    return [name1 compare:name2 options:NSCaseInsensitiveSearch];
                }];

                for (id app in sortedApps) {
                    NSString *bundleID = [app performSelector:@selector(applicationIdentifier)];
                    NSString *appName = [app performSelector:@selector(localizedName)];
                    
                    if (bundleID && appName) {
                        PSSpecifier *appSpec = [PSSpecifier preferenceSpecifierNamed:appName
                                                                            target:self
                                                                               set:@selector(setAppActiveState:specifier:)
                                                                               get:@selector(getAppActiveState:)
                                                                            detail:Nil
                                                                              cell:PSSwitchCell
                                                                              edit:Nil];
                        [appSpec setProperty:bundleID forKey:@"identifier"];
                        [appSpec setProperty:bundleID forKey:@"key"];
                        [specs addObject:appSpec];
                    }
                }
            }
        }

        _specifiers = specs;
    }
    return _specifiers;
}

// Đọc trạng thái kích hoạt riêng cho từng ứng dụng từ file cấu hình trung tâm
- (id)getAppActiveState:(PSSpecifier *)specifier {
    NSString *bundleID = [specifier propertyForKey:@"identifier"];
    if (!bundleID) return @NO;

    @autoreleasepool {
        NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:KELEN_PREFS_PATH];
        if (prefs && prefs[bundleID]) {
            return prefs[bundleID];
        }
    }
    return @NO;
}

// Ghi trạng thái khi người dùng gạt công tắc cho từng app
- (void)setAppActiveState:(id)value specifier:(PSSpecifier *)specifier {
    NSString *bundleID = [specifier propertyForKey:@"identifier"];
    if (!bundleID) return;

    @autoreleasepool {
        NSMutableDictionary *prefs = [[NSDictionary dictionaryWithContentsOfFile:KELEN_PREFS_PATH] mutableCopy];
        if (!prefs) {
            prefs = [NSMutableDictionary dictionary];
        }

        prefs[bundleID] = value;
        [prefs writeToFile:KELEN_PREFS_PATH atomically:YES];

        // Phát tín hiệu đồng bộ Darwin Notification để Tweak trong app mục tiêu nhận diện tức thì
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFSTR("com.kelen.masterbypass/ReloadPrefs"),
            NULL,
            NULL,
            YES
        );
        
        KELEN_LOG(@"Đã cập nhật trạng thái bypass cho ứng dụng [%@]: %@", bundleID, value);
    }
}

@end
