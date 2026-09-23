#import "Kelen_MasterSync.h"
#import <dlfcn.h>
#import <string.h>
#import <fishhook/fishhook.h>

// Định nghĩa chuẩn cho macro log chống lỗi label
#ifndef KELEN_LOG
#define KELEN_LOG(fmt, ...) NSLog(@"[KelenCore] " fmt, ##__VA_ARGS__)
#endif

// Khai báo con trỏ hàm gốc cho việc tìm kiếm chuỗi / ký tự hệ thống
static char * (*orig_strstr)(const char *big, const char *little);
static int (*orig_strcmp)(const char *s1, const char *s2);

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

// Hook hàm strstr để chặn app quét tìm chuỗi đường dẫn jailbreak trong bộ nhớ
static char * kelen_hooked_strstr(const char *big, const char *little) {
    if (big && little) {
        // Kiểm tra xem cấu hình ẩn filesystem có đang bật không
        if (Kelen_GetRuntimeBool(@"KelenHookFileSystem", YES)) {
            NSString *littleStr = [NSString stringWithUTF8String:little];
            if (littleStr) {
                NSArray *keywords = kelenGetForbiddenKeywords();
                for (NSString *keyword in keywords) {
                    if ([littleStr localizedCaseInsensitiveContainsString:keyword]) {
                        // Trả về NULL để đánh lừa ứng dụng rằng không tìm thấy chuỗi khai thác
                        return NULL;
                    }
                }
            }
        }
    }
    return orig_strstr(big, little);
}

// Hook hàm strcmp để lọc các so sánh chuỗi trực tiếp
static int kelen_hooked_strcmp(const char *s1, const char *s2) {
    if (s1 && s2) {
        if (Kelen_GetRuntimeBool(@"KelenHookFileSystem", YES)) {
            NSString *s1Str = [NSString stringWithUTF8String:s1];
            NSString *s2Str = [NSString stringWithUTF8String:s2];
            
            NSArray *keywords = kelenGetForbiddenKeywords();
            for (NSString *keyword in keywords) {
                if ((s1Str && [s1Str localizedCaseInsensitiveContainsString:keyword]) ||
                    (s2Str && [s2Str localizedCaseInsensitiveContainsString:keyword])) {
                    // Ép kết quả trả về khác 0 để xem như chuỗi không khớp
                    return -1;
                }
            }
        }
    }
    return orig_strcmp(s1, s2);
}

// Hàm khởi tạo mô-đun lọc tìm kiếm khi tweak được nạp vào tiến trình
void Init_KelenSearchBypassEngine(void) {
    @autoreleasepool {
        KELEN_LOG(@"Đang khởi chạy mô-đun KelenSearchBypassEngine chuyên sâu...");
        
        // Sử dụng fishhook để thay thế hàm tìm kiếm chuỗi
        struct rebinding rebindings[] = {
            {"strstr", (void *)kelen_hooked_strstr, (void **)&orig_strstr},
            {"strcmp", (void *)kelen_hooked_strcmp, (void **)&orig_strcmp}
        };
        
        // Tiến hành gán hook an toàn thông qua fishhook
        if (rebind_symbols(rebindings, 2) < 0) {
            KELEN_LOG(@"Cảnh báo: Không thể hook các hàm tìm kiếm chuỗi hệ thống!");
        } else {
            KELEN_LOG(@"Đã vô hiệu hóa thành công các tiến trình quét tìm chuỗi jailbreak!");
        }
    }
}
