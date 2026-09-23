#import <Foundation/Foundation.h>

#define KELEN_PREFS_PATH @"/var/mobile/Library/Preferences/com.kelen.masterbypass.plist"

#ifndef KELEN_LOG
#define KELEN_LOG(fmt, ...) NSLog(@"[KelenCore] " fmt, ##__VA_ARGS__)
#endif

// Khai báo nguyên mẫu hàm runtime bool để các tệp .m khác gọi không bị lỗi undeclared function
BOOL Kelen_GetRuntimeBool(NSString *key, BOOL defaultVal);
