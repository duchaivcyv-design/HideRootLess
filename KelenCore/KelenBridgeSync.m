#import "Kelen_MasterSync.h"
#import <notify.h>

// Biến tĩnh lưu cache trạng thái cấu hình trong RAM để tối ưu tốc độ đọc, tránh gọi I/O liên tục
static NSMutableDictionary *g_KelenRuntimeCache = nil;
static BOOL g_KelenIsObserverRegistered = NO;

// Hàm callback xử lý khi nhận được tín hiệu reload từ giao diện cài đặt
static void KelenPreferencesChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    @autoreleasepool {
        KELEN_LOG:@"Nhận được tín hiệu làm mới cấu hình từ hệ thống Preferences!";
        if (g_KelenRuntimeCache) {
            [g_KelenRuntimeCache removeAllObjects];
            NSDictionary *latestPrefs = [NSDictionary dictionaryWithContentsOfFile:KELEN_PREFS_PATH];
            if (latestPrefs) {
                [g_KelenRuntimeCache setDictionary:latestPrefs];
            }
        }
    }
}

__attribute__((constructor)) static void InitializeKelenBridgeSync(void) {
    @autoreleasepool {
        // Khởi tạo bộ nhớ đệm runtime ban đầu
        g_KelenRuntimeCache = [[NSMutableDictionary alloc] init];
        NSDictionary *initialPrefs = [NSDictionary dictionaryWithContentsOfFile:KELEN_PREFS_PATH];
        if (initialPrefs) {
            [g_KelenRuntimeCache setDictionary:initialPrefs];
        }

        // Đăng ký lắng nghe thông báo Darwin Notification toàn cục giữa các tiến trình
        if (!g_KelenIsObserverRegistered) {
            CFNotificationCenterAddObserver(
                CFNotificationCenterGetDarwinNotifyCenter(),
                NULL,
                KelenPreferencesChangedCallback,
                CFSTR("com.kelen.masterbypass/ReloadPrefs"),
                NULL,
                CFNotificationSuspensionBehaviorDeliverImmediately
            );
            g_KelenIsObserverRegistered = YES;
            KELEN_LOG:@"Đã kích hoạt thành công cầu nối đồng bộ tiến trình (Bridge Sync Initialized).";
        }
    }
}

// Hàm hỗ trợ kiểm tra giá trị cấu hình an toàn trực tiếp từ bộ nhớ cache runtime
BOOL Kelen_GetRuntimeBool(NSString *key, BOOL defaultVal) {
    if (!key) return defaultVal;
    
    @autoreleasepool {
        if (g_KelenRuntimeCache && g_KelenRuntimeCache[key] != nil) {
            return [g_KelenRuntimeCache[key] boolValue];
        }
        
        NSDictionary *currentPrefs = [NSDictionary dictionaryWithContentsOfFile:KELEN_PREFS_PATH];
        if (currentPrefs && currentPrefs[key] != nil) {
            BOOL val = [currentPrefs[key] boolValue];
            g_KelenRuntimeCache[key] = @(val);
            return val;
        }
    }
    return defaultVal;
}
