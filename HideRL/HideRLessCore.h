#import "HideRLessCore.h"
#import <notify.h>

#define KELEN_MASTER_PREFS KELEN_MASTER_PREFS_PATH

@implementation HideRLessCore {
    NSMutableDictionary *_cachedPreferences;
}

+ (instancetype)sharedInstance {
    static HideRLessCore *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self loadPreferences];
        
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            (__bridge const void *)(self),
            (CFNotificationCallback)&GlobalPreferencesChangedCallback,
            KELEN_NOTIFICATION_RELOAD,
            NULL,
            CFNotificationSuspensionBehaviorDeliverImmediately
        );
    }
    return self;
}

static void GlobalPreferencesChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    [[HideRLessCore sharedInstance] loadPreferences];
}

- (void)loadPreferences {
    @autoreleasepool {
        NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:KELEN_MASTER_PREFS];
        if (prefs) {
            _cachedPreferences = [prefs mutableCopy];
        } else {
            _cachedPreferences = [NSMutableDictionary dictionary];
        }
    }
}

- (BOOL)isGlobalBypassEnabled {
    @autoreleasepool {
        id val = _cachedPreferences[@"KelenMasterSwitch"];
        return val ? [val boolValue] : YES;
    }
}

- (BOOL)isFeatureActiveForKey:(NSString *)key {
    if (![self isGlobalBypassEnabled]) {
        return NO;
    }
    if (!key) {
        return YES;
    }
    @autoreleasepool {
        id val = _cachedPreferences[key];
        return val ? [val boolValue] : YES;
    }
}

- (void)postReloadNotification {
    CFNotificationCenterPostNotification(
        CFNotificationCenterGetDarwinNotifyCenter(),
        KELEN_NOTIFICATION_RELOAD,
        NULL,
        NULL,
        YES
    );
}

@end
