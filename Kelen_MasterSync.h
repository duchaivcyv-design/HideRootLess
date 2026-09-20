#import <Foundation/Foundation.h>
#import <dlfcn.h>
#import <sys/stat.h>
#import <sys/sysctl.h>
#import <mach-o/dyld.h>
#import <errno.h>
#import <spawn.h>
#import <objc/runtime.h>

#define KELEN_PREFS_PATH @"/var/mobile/Library/Preferences/com.kelen.deepbypass.plist"
#define KELEN_LOG(fmt, ...) NSLog(@"[KelenDeepBypass] " fmt, ##__VA_ARGS__)

// Cấu trúc cấu hình đồng bộ cho từng ứng dụng mục tiêu
typedef struct {
    BOOL isEnabled;
    BOOL hookFileSystem;
    BOOL hookDyldImages;
    BOOL hookSyscallCore;
    BOOL hookAntiDebug;
    BOOL hookSandboxVirtual;
    BOOL hookObjCRuntime;
} KelenAppConfig;

// Khai báo các hàm đồng bộ trung tâm (Đã sửa #cplusplus thành chuẩn __cplusplus)
#ifdef __cplusplus
extern "C" {
#endif

    BOOL Kelen_ShouldBypassCurrentApp(void);
    KelenAppConfig Kelen_GetAppConfig(void);
    void Kelen_InitializeAllModules(void);

#ifdef __cplusplus
}
#endif
