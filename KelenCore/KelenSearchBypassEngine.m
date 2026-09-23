#import "Kelen_MasterSync.h"
#import <dlfcn.h>
#import <string.h>

// Định nghĩa chuẩn cho macro log chống lỗi label
#ifndef KELEN_LOG
#define KELEN_LOG(fmt, ...) NSLog(@"[KelenCore] " fmt, ##__VA_ARGS__)
#endif

// Danh sách các từ khóa / chuỗi định danh jailbreak cần ẩn khỏi kết quả tìm kiếm
static NSArray *kelenGetForbiddenKeywords(void) {
    return @[
        @"/var/jb",
        @"jb",
        @"cydia",
        @"sileo",
        @"zebra",
        @"substitute",
        @"ellekit",
        @"apt",
        @"dpkg",
        @"sshd"
    ];
}

// Kiểm tra và lọc chuỗi tìm kiếm an toàn dựa trên runtime config
BOOL Kelen_ShouldFilterString(const char *targetStr) {
    if (!targetStr) return NO;
    if (!Kelen_GetRuntimeBool(@"KelenHookFileSystem", YES)) return NO;
    
    @autoreleasepool {
        NSString *str = [NSString stringWithUTF8String:targetStr];
        if (!str) return NO;
        
        NSArray *keywords = kelenGetForbiddenKeywords();
        for (NSString *keyword in keywords) {
            if ([str localizedCaseInsensitiveContainsString:keyword]) {
                return YES; // Phát hiện từ khóa nhạy cảm -> Cần lọc/chặn
            }
        }
    }
    return NO;
}

// Hàm khởi tạo mô-đun lọc tìm kiếm khi tweak được nạp vào tiến trình
void Init_KelenSearchBypassEngine(void) {
    @autoreleasepool {
        KELEN_LOG(@"Đang khởi chạy mô-đun KelenSearchBypassEngine bảo vệ bộ nhớ...");
        
        // Đăng ký giám sát và tinh chỉnh cơ chế lọc chuỗi runtime
        NSDictionary *currentPrefs = [NSDictionary dictionaryWithContentsOfFile:KELEN_PREFS_PATH];
        if (currentPrefs) {
            KELEN_LOG(@"Đã tải cấu hình lọc chuỗi thành công vào tiến trình.");
        }
        
        KELEN_LOG(@"Mô-đun bảo vệ KelenSearchBypassEngine đã sẵn sàng hoạt động!");
    }
}
