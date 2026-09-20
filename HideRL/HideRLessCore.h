#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define KELEN_MASTER_PREFS_PATH @"/var/mobile/Library/Preferences/com.kelen.masterbypass.plist"
#define KELEN_NOTIFICATION_RELOAD CFSTR("com.kelen.masterbypass/ReloadPrefs")

NS_ASSUME_NONNULL_BEGIN

@interface HideRLessCore : NSObject

+ (instancetype)sharedInstance;
- (BOOL)isGlobalBypassEnabled;
- (BOOL)isFeatureActiveForKey:(NSString *)key;
- (void)postReloadNotification;

@end

@protocol HideRLessModuleProtocol <NSObject>
@required
- (BOOL)isModuleEnabled;
- (void)registerHooks;
@optional
- (void)reloadModuleConfiguration;
@end

NS_ASSUME_NONNULL_END
