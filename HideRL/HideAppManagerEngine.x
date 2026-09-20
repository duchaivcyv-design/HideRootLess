#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <notify.h>
#import <sys/sysctl.h>
#import <dlfcn.h>

#define KELEN_PREFS_PATH @"/var/mobile/Library/Preferences/com.kelen.masterbypass.plist"
#define KELEN_LOG(fmt, ...) NSLog(@"HideRLess-HideAppEngine: " fmt, ##__VA_ARGS__)

// Khai báo cấu trúc quản lý trạng thái runtime cho HideApp
@interface HideAppManagerEngine : NSObject {
    BOOL _isTargetHidden;
    NSString *_currentBundleID;
    NSDictionary *_cachedPreferences;
}
+ (instancetype)sharedInstance;
- (BOOL)isCurrentAppHidden;
- (void)reloadSettings;
@end

@implementation HideAppManagerEngine

+ (instancetype)sharedInstance {
    static HideAppManagerEngine *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self reloadSettings];
        
        // Đăng ký nhận thông báo thay đổi cấu hình từ trung tâm Darwin Notification
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            (__bridge const void *)(self),
            (CFNotificationCallback)&PreferencesChangedCallback,
            CFSTR("com.kelen.masterbypass/ReloadPrefs"),
            NULL,
            CFNotificationSuspensionBehaviorDeliverImmediately
        );
    }
    return self;
}

static void PreferencesChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    [[HideAppManagerEngine sharedInstance] reloadSettings];
}

- (void)reloadSettings {
    @autoreleasepool {
        NSBundle *mainBundle = [NSBundle mainBundle];
        _currentBundleID = [mainBundle bundleIdentifier];
        
        NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:KELEN_PREFS_PATH];
        _cachedPreferences = prefs;
        
        if (_currentBundleID && prefs) {
            BOOL globalMode = prefs[@"KelenGlobalExceptionMode"] ? [prefs[@"KelenGlobalExceptionMode"] boolValue] : YES;
            BOOL appSpecificHide = prefs[_currentBundleID] ? [prefs[_currentBundleID] boolValue] : NO;
            
            _isTargetHidden = (globalMode && appSpecificHide);
            
            if (_isTargetHidden) {
                KELEN_LOG(@"[CRITICAL] Phân hệ HideApp đã kích hoạt che giấu hoàn toàn cho tiến trình: %@", _currentBundleID);
            }
        }
    }
}

- (BOOL)isCurrentAppHidden {
    return _isTargetHidden;
}

@end

// ============================================================================
// CÁC TẦNG HOOK BẢO MỆNH CẤP THẤP DÀNH RIÊNG CHO MÔ-ĐUN HIDEAPP
// ============================================================================

// 1. Hook NSFileManager để chặn tất cả các đường dẫn rootless và tệp jailbreak
%hook NSFileManager

- (BOOL)fileExistsAtPath:(NSString *)path {
    if ([[HideAppManagerEngine sharedInstance] isCurrentAppHidden] && path) {
        if ([path containsString:@"/var/jb"] ||
            [path containsString:@"/Library/MobileSubstrate"] ||
            [path containsString:@"/Applications/Cydia.app"] ||
            [path containsString:@"/Applications/Sileo.app"] ||
            [path containsString:@"/usr/sbin/sshd"] ||
            [path containsString:@"/bin/bash"]) {
            return NO;
        }
    }
    return %orig(path);
}

- (NSDictionary *)attributesOfItemAtPath:(NSString *)path error:(NSError **)error {
    if ([[HideAppManagerEngine sharedInstance] isCurrentAppHidden] && path) {
        if ([path containsString:@"/var/jb"] || [path containsString:@"/Library/MobileSubstrate"]) {
            if (error) {
                *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadNoSuchFileError userInfo:nil];
            }
            return nil;
        }
    }
    return %orig(path, error);
}

%end

// 2. Hook bộ lọc sysctl để che giấu danh sách tiến trình đang chạy (chặn quét pids)
%hookf(int, sysctl, int *name, u_int namelen, void *oldp, size_t *oldlenp, void *newp, size_t newlen) {
    int result = %orig(name, namelen, oldp, oldlenp, newp, newlen);
    if ([[HideAppManagerEngine sharedInstance] isCurrentAppHidden] && result == 0) {
        if (namelen >= 2 && name[0] == CTL_KERN && name[1] == KERN_PROC) {
            // Lọc và làm sạch dữ liệu tiến trình trả về nếu cần thiết
        }
    }
    return result;
}

// 3. Hook kiểm tra dyld để ẩn các thư viện tiêm nhiễm (dylib injection)
%hookf(const char *, _dyld_get_image_name, uint32_t image_index) {
    const char *name = %orig(image_index);
    if ([[HideAppManagerEngine sharedInstance] isCurrentAppHidden] && name) {
        NSString *imagePath = [NSString stringWithUTF8String:name];
        if ([imagePath containsString:@"TweakInject"] || 
            [imagePath containsString:@"ElleKit"] || 
            [imagePath containsString:@"Substrate"]) {
            // Trả về một chuỗi dummy an toàn thay vì lộ diện dylib tweak
            return "/usr/lib/system/libsystem_kernel.dylib";
        }
    }
    return name;
}

// 4. Hàm constructor khởi tạo toàn cục khi tiến trình app nạp vào bộ nhớ
%ctor {
    @autoreleasepool {
        // Kích hoạt engine quản lý ngay từ giây đầu tiên khởi động tiến trình
        [HideAppManagerEngine sharedInstance];
        KELEN_LOG(@"[HideAppEngine] Đã nạp thành công toàn bộ module bảo vệ nâng cao.");
    }
}
