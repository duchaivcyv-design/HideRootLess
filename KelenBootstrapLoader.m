#import "KelenCore/Kelen_MasterSync.h"

// Khai báo nguyên mẫu các hàm khởi tạo từ các mô-đun con mà chúng ta đã xây dựng
extern void Init_KelenSearchBypassEngine(void);

__attribute__((constructor)) static void KelenSystemBootstrapExecution(void) {
    @autoreleasepool {
        NSString *processName = [[NSProcessInfo processInfo] processName];
        KELEN_LOG:@"[Bootstrap] Đang khởi chạy tiến trình cốt lõi cho ứng dụng: %@", processName;

        // Kiểm tra xem ứng dụng hiện tại có nằm trong diện kích hoạt bypass hay không
        NSDictionary *masterPrefs = [NSDictionary dictionaryWithContentsOfFile:KELEN_PREFS_PATH];
        if (masterPrefs) {
            // Kích hoạt mô-đun quét ẩn chuỗi và bộ lọc tệp tin hệ thống
            Init_KelenSearchBypassEngine();
            
            KELEN_LOG:@"[Bootstrap] Đã nạp thành công toàn bộ tầng ẩn hệ thống cho: %@", processName;
        } else {
            KELEN_LOG:@"[Bootstrap] Không tìm thấy cấu hình Prefloader, bỏ qua kích hoạt cho: %@", processName;
        }
    }
}
