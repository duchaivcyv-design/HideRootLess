#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import "../Kelen_MasterSync.h"

@interface LSApplicationWorkspace : NSObject
+ (id)defaultWorkspace;
- (NSArray *)allInstalledApplications;
@end

@interface LSApplicationProxy : NSObject
@property (nonatomic, readonly) NSString *applicationIdentifier;
@property (nonatomic, readonly) NSString *localizedName;
@end

@interface HideAppController : PSListController
@end

@implementation HideAppController

- (NSArray *)specifiers {
    if (!_specifiers) {
        NSMutableArray *specs = [NSMutableArray array];

        PSSpecifier *group = [PSSpecifier preferenceSpecifierNamed:@"Chọn Ứng dụng Cần Ẩn Jailbreak"
                                                            target:self set:nil get:nil detail:Nil cell:PSGroupCell edit:Nil];
        [group setProperty:@"Bật công tắc để áp dụng cơ chế ẩn hoàn toàn dấu vết jailbreak cho ứng dụng được chọn." forKey:@"footerText"];
        [specs addObject:group];

        @autoreleasepool {
            Class workspaceClass = objc_getClass("LSApplicationWorkspace");
            if (workspaceClass) {
                id workspace = [workspaceClass performSelector:@selector(defaultWorkspace)];
                NSArray *apps = [workspace performSelector:@selector(allInstalledApplications)];
                
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
                                                                               set:@selector(setHideAppPref:specifier:)
                                                                               get:@selector(getHideAppPref:)
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

- (id)getHideAppPref:(PSSpecifier *)specifier {
    NSString *bundleID = [specifier propertyForKey:@"identifier"];
    if (!bundleID) return @NO;
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:KELEN_PREFS_PATH];
    return (prefs && prefs[bundleID]) ? prefs[bundleID] : @NO;
}

- (void)setHideAppPref:(id)value specifier:(PSSpecifier *)specifier {
    NSString *bundleID = [specifier propertyForKey:@"identifier"];
    if (!bundleID) return;
    
    NSMutableDictionary *prefs = [[NSDictionary dictionaryWithContentsOfFile:KELEN_PREFS_PATH] mutableCopy];
    if (!prefs) prefs = [NSMutableDictionary dictionary];
    
    prefs[bundleID] = value;
    [prefs writeToFile:KELEN_PREFS_PATH atomically:YES];
    
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.kelen.masterbypass/ReloadPrefs"), NULL, NULL, YES);
    KELEN_LOG:@"Đã cập nhật ẩn app [%@]: %@", bundleID, value;
}

@end
