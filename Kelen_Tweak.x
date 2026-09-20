#import "Kelen_MasterSync.h"

%ctor {
    @autoreleasepool {
        // Đảm bảo tiến trình chạy là ứng dụng thực tế (tránh extension hoặc daemon phụ gây xung đột)
        NSString *processName = [[NSProcessInfo processInfo] processName];
        KELEN_LOG:@"Tiến trình đang khởi động: %@", processName;

        // Gọi hệ thống khởi tạo tổng từ CoreEngine
        Kelen_InitializeAllModules();
    }
}
