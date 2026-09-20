#import "../Kelen_MasterSync.h"

__attribute__((constructor)) static void HideAppProcessFilterEntry(void) {
    @autoreleasepool {
        NSBundle *bundle = [NSBundle mainBundle];
        NSString *bundleID = [bundle bundleIdentifier];
        
        if (bundleID) {
            NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:KELEN_PREFS_PATH];
            if (prefs && [prefs[bundleID] boolValue]) {
                KELEN_LOG:@"[HideApp] Tiến trình mục tiêu [%@] đã được bật cơ chế ẩn hoàn toàn!", bundleID;
                // Thực hiện gắn cờ hoặc kích hoạt các móc nối bảo mật chuyên sâu riêng cho app này
            }
        }
    }
}
