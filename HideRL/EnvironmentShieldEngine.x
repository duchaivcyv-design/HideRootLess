#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <notify.h>
#import <sys/stat.h>
#import <dlfcn.h>

#define KELEN_ENV_PREFS @"/var/mobile/Library/Preferences/com.kelen.masterbypass.plist"
#define KELEN_ENV_LOG(fmt, ...) NSLog(@"HideRLess-EnvironmentShield: " fmt, ##__VA_ARGS__)

@interface EnvironmentShieldEngine : NSObject {
    BOOL _envShieldActive;
}
+ (instancetype)sharedInstance;
- (void)updateEnvironmentState;
- (BOOL)isEnvironmentShieldEnabled;
@end

@implementation EnvironmentShieldEngine

+ (instancetype)sharedInstance {
    static EnvironmentShieldEngine *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self updateEnvironmentState];
        
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            (__bridge const void *)(self),
            (CFNotificationCallback)&EnvPreferencesChanged,
            CFSTR("com.kelen.masterbypass/ReloadPrefs"),
            NULL,
            CFNotificationSuspensionBehaviorDeliverImmediately
        );
    }
    return self;
}

static void EnvPreferencesChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    [[EnvironmentShieldEngine sharedInstance] updateEnvironmentState];
}

- (void)updateEnvironmentState {
    @autoreleasepool {
        NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:KELEN_ENV_PREFS];
        if (prefs) {
            _envShieldActive = prefs[@"KelenEnvironmentShield"] ? [prefs[@"KelenEnvironmentShield"] boolValue] : YES;
            if (_envShieldActive) {
                KELEN_ENV_LOG(@"[EnvironmentShield] Đã kích hoạt bảo vệ môi trường chống phân giải symbolic link hệ thống.");
            }
        } else {
            _envShieldActive = YES;
        }
    }
}

- (BOOL)isEnvironmentShieldEnabled {
    return _envShieldActive;
}

@end

// ============================================================================
// HỆ THỐNG HOOK KIỂM TRA THUỘC TÍNH TỆP TIN VÀ SYMLINK CẤP THẤP
// ============================================================================

// Hook lstat để ngăn chặn việc phát hiện symbolic link trỏ đến các thư mục jailbreak
%hookf(int, lstat, const char *path, struct stat *buf) {
    if (path && [[EnvironmentShieldEngine sharedInstance] isEnvironmentShieldEnabled]) {
        NSString *pathStr = [NSString stringWithUTF8String:path];
        if ([pathStr containsString:@"/Applications"] || 
            [pathStr containsString:@"/Library/Ringtones"] || 
            [pathStr containsString:@"/Library/Wallpaper"] || 
            [pathStr containsString:@"/usr/include"] || 
            [pathStr containsString:@"/usr/libexec"] || 
            [pathStr containsString:@"/usr/share"]) {
            // Giả lập trạng thái tệp thông thường thay vì symlink sang phân vùng rootless
            int result = %orig(path, buf);
            if (result == 0 && S_ISLNK(buf->st_mode)) {
                buf->st_mode = (buf->st_mode & ~S_IFMT) | S_IFDIR;
            }
            return result;
        }
    }
    return %orig(path, buf);
}

// Hook stat tương tự để xử lý các luồng kiểm tra thông thường
%hookf(int, stat, const char *path, struct stat *buf) {
    if (path && [[EnvironmentShieldEngine sharedInstance] isEnvironmentShieldEnabled]) {
        NSString *pathStr = [NSString stringWithUTF8String:path];
        if ([pathStr containsString:@"/var/jb"]) {
            errno = ENOENT;
            return -1;
        }
    }
    return %orig(path, buf);
}

// Hook NSProcessInfo để che giấu các tham số môi trường nghi vấn
%hook NSProcessInfo

- (NSDictionary<NSString *,NSString *> *)environment {
    NSDictionary *env = %orig();
    if ([[EnvironmentShieldEngine sharedInstance] isEnvironmentShieldEnabled]) {
        NSMutableDictionary *mutableEnv = [env mutableCopy];
        // Loại bỏ các biến môi trường có thể bị lợi dụng để phát hiện tweak inject
        [mutableEnv removeObjectForKey:@"DYLD_INSERT_LIBRARIES"];
        [mutableEnv removeObjectForKey:@"_MSSafeMode"];
        return mutableEnv;
    }
    return env;
}

%end

%ctor {
    @autoreleasepool {
        [EnvironmentShieldEngine sharedInstance];
        KELEN_ENV_LOG(@"[Init] Mô-đun EnvironmentShieldEngine đã được nạp thành công.");
    }
}
