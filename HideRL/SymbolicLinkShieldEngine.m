#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <notify.h>
#import <sys/stat.h>
#import <fcntl.h>

#define KELEN_SYMLINK_PREFS @"/var/mobile/Library/Preferences/com.kelen.masterbypass.plist"
#define KELEN_SYMLINK_LOG(fmt, ...) NSLog((@"HideRLess-SymlinkEngine: " fmt), ##__VA_ARGS__)

@interface SymbolicLinkShieldEngine : NSObject {
    BOOL _symlinkShieldActive;
}
+ (instancetype)sharedInstance;
- (void)updateSymlinkState;
- (BOOL)isSymlinkShieldEnabled;
@end

@implementation SymbolicLinkShieldEngine

+ (instancetype)sharedInstance {
    static SymbolicLinkShieldEngine *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self updateSymlinkState];
        
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            (__bridge const void *)(self),
            (CFNotificationCallback)&SymlinkPreferencesChanged,
            CFSTR("com.kelen.masterbypass/ReloadPrefs"),
            NULL,
            CFNotificationSuspensionBehaviorDeliverImmediately
        );
    }
    return self;
}

static void SymlinkPreferencesChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    [[SymbolicLinkShieldEngine sharedInstance] updateSymlinkState];
}

- (void)updateSymlinkState {
    @autoreleasepool {
        NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:KELEN_SYMLINK_PREFS];
        if (prefs) {
            _symlinkShieldActive = prefs[@"KelenSymbolicLinkShield"] ? [prefs[@"KelenSymbolicLinkShield"] boolValue] : YES;
            if (_symlinkShieldActive) {
                KELEN_SYMLINK_LOG:@"[SymbolicLinkShield] Đã kích hoạt mô-đun kiểm soát và ẩn danh symbolic link.";
            }
        } else {
            _symlinkShieldActive = YES;
        }
    }
}

- (BOOL)isSymlinkShieldEnabled {
    return _symlinkShieldActive;
}

@end

// ============================================================================
// HỆ THỐNG HOOK ĐỌC LIÊN KẾT SYMLINK CẤP KERNEL / C POSIX
// ============================================================================

%hookf(ssize_t, readlink, const char *path, char *buf, size_t bufsiz) {
    if (path && [[SymbolicLinkShieldEngine sharedInstance] isSymlinkShieldEnabled]) {
        NSString *pathStr = [NSString stringWithUTF8String:path];
        if ([pathStr containsString:@"/var/jb"] || [pathStr containsString:@"/Library/MobileSubstrate"]) {
            KELEN_SYMLINK_LOG:@"[Intercepted] Đã chặn luồng đọc symlink tại đường dẫn: %@", pathStr];
            errno = ENOENT;
            return -1;
        }
    }
    return %orig(path, buf, bufsiz);
}

%hookf(int, open, const char *path, int oflag, ...) {
    va_list args;
    va_start(args, oflag);
    mode_t mode = 0;
    if (oflag & O_CREAT) {
        mode = va_arg(args, int);
    }
    va_end(args);

    if (path && [[SymbolicLinkShieldEngine sharedInstance] isSymlinkShieldEnabled]) {
        NSString *pathStr = [NSString stringWithUTF8String:path];
        if ([pathStr containsString:@"/var/jb/bin"] || [pathStr containsString:@"/var/jb/usr"]) {
            errno = ENOENT;
            return -1;
        }
    }
    return %orig;
}

%ctor {
    @autoreleasepool {
        [SymbolicLinkShieldEngine sharedInstance];
        KELEN_SYMLINK_LOG:@"[Init] Mô-đun SymbolicLinkShieldEngine đã sẵn sàng hoạt động.";
    }
}
