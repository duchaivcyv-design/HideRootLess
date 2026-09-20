#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <notify.h>

#define KELEN_PREFS_PATH @"/var/mobile/Library/Preferences/com.kelen.masterbypass.plist"

@interface LSApplicationWorkspace : NSObject
+ (id)defaultWorkspace;
- (NSArray *)allInstalledApplications;
@end

@interface LSApplicationProxy : NSObject
@property (nonatomic, readonly) NSString *applicationIdentifier;
@property (nonatomic, readonly) NSString *localizedName;
@property (nonatomic, readonly) NSURL *bundleURL;
@end

@interface HideAppController : PSListController {
    BOOL _isSearching;
}
@property (nonatomic, strong) NSMutableArray *cachedAppSpecifiers;
@end

@implementation HideAppController

- (instancetype)init {
    self = [super init];
    if (self) {
        _cachedAppSpecifiers = [NSMutableArray array];
    }
    return self;
}

- (NSArray *)specifiers {
    if (!_specifiers) {
        NSMutableArray *specs = [NSMutableArray array];

        // Group 1: Hướng dẫn sử dụng HideApp
        PSSpecifier *group1 = [PSSpecifier preferenceSpecifierNamed:@"Quản lý Ứng dụng Ẩn Jailbreak"
                                                             target:self
                                                                set:nil
                                                                get:nil
                                                             detail:Nil
                                                               cell:PSGroupCell
                                                               edit:Nil];
        [group1 setProperty:@"Bật công tắc bên dưới để áp dụng chế độ che giấu tệp hệ thống và tiến trình cho từng ứng dụng riêng biệt." forKey:@"footerText"];
        [specs addObject:group1];

        // Tải danh sách ứng dụng thực tế từ hệ thống
        @autoreleasepool {
            Class workspaceClass = objc_getClass("LSApplicationWorkspace");
            if (workspaceClass) {
                id workspace = [workspaceClass performSelector:@selector(defaultWorkspace)];
                NSArray *apps = [workspace performSelector:@selector(allInstalledApplications)];
                
                // Sắp xếp danh sách ứng dụng theo tên bảng chữ cái
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
                                                                               set:@selector(setAppHideState:specifier:)
                                                                               get:@selector(getAppHideState:)
                                                                            detail:Nil
                                                                              cell:PSSwitchCell
                                                                              edit:Nil];
                        [appSpec setProperty:bundleID forKey:@"identifier"];
                        [appSpec setProperty:bundleID forKey:@"key"];
                        [specs addObject:appSpec];
                        [_cachedAppSpecifiers addObject:appSpec];
                    }
                }
            }
        }

        _specifiers = specs;
    }
    return _specifiers;
}

- (id)getAppHideState:(PSSpecifier *)specifier {
    NSString *bundleID = [specifier propertyForKey:@"identifier"];
    if (!bundleID) return @NO;

    @autoreleasepool {
        NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:KELEN_PREFS_PATH];
        if (prefs && prefs[bundleID] != nil) {
            return prefs[bundleID];
        }
    }
    return @NO;
}

- (void)setAppHideState:(id)value specifier:(PSSpecifier *)specifier {
    NSString *bundleID = [specifier propertyForKey:@"identifier"];
    if (!bundleID) return;

    @autoreleasepool {
        NSMutableDictionary *prefs = [[NSDictionary dictionaryWithContentsOfFile:KELEN_PREFS_PATH] mutableCopy];
        if (!prefs) {
            prefs = [NSMutableDictionary dictionary];
        }

        prefs[bundleID] = value;
        [prefs writeToFile:KELEN_PREFS_PATH atomically:YES];

        // Gửi thông báo Darwin để cập nhật ngay lập tức vào tiến trình app mục tiêu
        CFNotificationCenterRef center = CFNotificationCenterGetDarwinNotifyCenter();
        CFNotificationCenterPostNotification(center, CFSTR("com.kelen.masterbypass/ReloadPrefs"), NULL, NULL, YES);
        
        NSLog(@"[HideApp] Đã cập nhật trạng thái ẩn cho app [%@]: %@", bundleID, value);
    }
}

@end
