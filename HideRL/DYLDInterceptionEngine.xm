#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <notify.h>
#import <mach-o/dyld.h>

#define KELEN_DYLD_PREFS @"/var/mobile/Library/Preferences/com.kelen.masterbypass.plist"
#define KELEN_DYLD_LOG(fmt, ...) NSLog(@"HideRLess-DYLDEngine: " fmt, ##__VA_ARGS__)

@interface DYLDInterceptionEngine : NSObject {
    BOOL _dyldShieldActive;
}
+ (instancetype)sharedInstance;
- (void)updateDYLDState;
- (BOOL)isDYLDShieldEnabled;
- (BOOL)shouldHideImagePath:(const char *)imagePath;
@end

@implementation DYLDInterceptionEngine

+ (instancetype)sharedInstance {
    static DYLDInterceptionEngine *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self updateDYLDState];
        
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            (__bridge const void *)(self),
            (CFNotificationCallback)&DYLDPreferencesChanged,
            CFSTR("com.kelen.masterbypass/ReloadPrefs"),
            NULL,
            CFNotificationSuspensionBehaviorDeliverImmediately
        );
    }
    return self;
}

static void DYLDPreferencesChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    [[DYLDInterceptionEngine sharedInstance] updateDYLDState];
}

- (void)updateDYLDState {
    @autoreleasepool {
        NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:KELEN_DYLD_PREFS];
        if (prefs) {
            _dyldShieldActive = prefs[@"KelenDYLDInterception"] ? [prefs[@"KelenDYLDInterception"] boolValue] : YES;
            if (_dyldShieldActive) {
                KELEN_DYLD_LOG(@"[DYLDInterception] Đã kích hoạt mô-đun kiểm soát và che giấu hình ảnh thư viện động.");
            }
        } else {
            _dyldShieldActive = YES;
        }
    }
}

- (BOOL)isDYLDShieldEnabled {
    return _dyldShieldActive;
}

- (BOOL)shouldHideImagePath:(const char *)imagePath {
    if (!imagePath) return NO;
    NSString *path = [NSString stringWithUTF8String:imagePath];
    if ([path containsString:@"MobileSubstrate"] ||
        [path containsString:@"TweakInject"] ||
        [path containsString:@"SafeMode"] ||
        [path containsString:@"CydiaSubstrate"] ||
        [path containsString:@"SubstrateLoader"] ||
        [path containsString:@"libhooker"] ||
        [path containsString:@"elleKit"]) {
        return YES;
    }
    return NO;
}

@end

// ============================================================================
// HỆ THỐNG HOOK DYLD API ĐỂ LỌC HÌNH ẢNH ĐÃ NẠP TRONG TIẾN TRÌNH
// ============================================================================

// Hook _dyld_get_image_name để ẩn danh các dylib tweak khỏi danh sách quét của app
%hookf(const char *, _dyld_get_image_name, uint32_t image_index) {
    const char *name = %orig(image_index);
    if (name && [[DYLDInterceptionEngine sharedInstance] isDYLDShieldEnabled]) {
        if ([[DYLDInterceptionEngine sharedInstance] shouldHideImagePath:name]) {
            // Chuyển hướng trả về một đường dẫn hệ thống an toàn thay vì lộ tên dylib tweak
            return "/usr/lib/libobjc.A.dylib";
        }
    }
    return name;
}

// Hook _dyld_image_count để điều chỉnh số lượng hình ảnh trả về nếu cần thiết
%hookf(uint32_t, _dyld_image_count) {
    uint32_t count = %orig();
    if ([[DYLDInterceptionEngine sharedInstance] isDYLDShieldEnabled]) {
        // Có thể tinh chỉnh bộ đếm nếu ứng dụng thực hiện so khớp chỉ mục nghiêm ngặt
    }
    return count;
}

%ctor {
    @autoreleasepool {
        [DYLDInterceptionEngine sharedInstance];
        KELEN_DYLD_LOG(@"[Init] Mô-đun DYLDInterceptionEngine đã sẵn sàng hoạt động.");
    }
}
