#import "HideRLessCore.h"

@implementation HideRLessCore

+ (instancetype)sharedInstance {
    static HideRLessCore *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (BOOL)isMasterSwitchEnabled {
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:KELEN_MASTER_PREFS];
    if (prefs && prefs[@"KelenMasterSwitch"]) {
        return [prefs[@"KelenMasterSwitch"] boolValue];
    }
    return YES;
}

@end
