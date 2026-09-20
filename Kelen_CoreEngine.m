#import "Kelen_MasterSync.h"

// Khai báo nguyên mẫu khởi tạo của 6 module con bên ngoài
extern void Init_Mod_FileSystem(void);
extern void Init_Mod_DyldImages(void);
extern void Init_Mod_SyscallCore(void);
extern void Init_Mod_AntiDebug(void);
extern void Init_Mod_SandboxVirtual(void);
extern void Init_Mod_ObjCRuntime(void);

BOOL Kelen_ShouldBypassCurrentApp(void) {
    @autoreleasepool {
        NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
        if (!bundleID) return NO;

        NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:KELEN_PREFS_PATH];
        if (!prefs) return NO;

        NSDictionary *appConfig = prefs[bundleID];
        if (!appConfig) return NO;

        NSNumber *enabledFlag = appConfig[@"Enable"];
        return enabledFlag ? [enabledFlag boolValue] : NO;
    }
}

KelenAppConfig Kelen_GetAppConfig(void) {
    KelenAppConfig config;
    // Khởi tạo giá trị mặc định an toàn chống rác bộ nhớ
    config.isEnabled = NO;
    config.hookFileSystem = YES;
    config.hookDyldImages = YES;
    config.hookSyscallCore = YES;
    config.hookAntiDebug = YES;
    config.hookSandboxVirtual = YES;
    config.hookObjCRuntime = YES;

    @autoreleasepool {
        NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
        if (!bundleID) return config;

        NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:KELEN_PREFS_PATH];
        if (!prefs) return config;

        NSDictionary *appConfig = prefs[bundleID];
        if (!appConfig) return config;

        if (appConfig[@"Enable"]) config.isEnabled = [appConfig[@"Enable"] boolValue];
        if (appConfig[@"HookFS"]) config.hookFileSystem = [appConfig[@"HookFS"] boolValue];
        if (appConfig[@"HookDyld"]) config.hookDyldImages = [appConfig[@"HookDyld"] boolValue];
        if (appConfig[@"HookSys"]) config.hookSyscallCore = [appConfig[@"HookSys"] boolValue];
        if (appConfig[@"HookDebug"]) config.hookAntiDebug = [appConfig[@"HookDebug"] boolValue];
        if (appConfig[@"HookSandbox"]) config.hookSandboxVirtual = [appConfig[@"HookSandboxButton"] boolValue];
        if (appConfig[@"HookObjC"]) config.hookObjCRuntime = [appConfig[@"HookObjC"] boolValue];
    }
    return config;
}

void Kelen_InitializeAllModules(void) {
    @autoreleasepool {
        if (!Kelen_ShouldBypassCurrentApp()) {
            // Đã sửa: Thêm dấu ngoặc đơn cho KELEN_LOG
            KELEN_LOG(@"Ứng dụng này không được kích hoạt chế độ ẩn Jailbreak.");
            return;
        }

        KelenAppConfig config = Kelen_GetAppConfig();
        // Đã sửa: Thêm dấu ngoặc đơn cho KELEN_LOG
        KELEN_LOG(@"Đang kích hoạt hệ thống ẩn Jailbreak cho ứng dụng: %@", [[NSBundle mainBundle] bundleIdentifier]);

        if (config.hookFileSystem) {
            Init_Mod_FileSystem();
        }
        if (config.hookDyldImages) {
            Init_Mod_DyldImages();
        }
        if (config.hookSyscallCore) {
            Init_Mod_SyscallCore();
        }
        if (config.hookAntiDebug) {
            Init_Mod_AntiDebug();
        }
        if (config.hookSandboxVirtual) {
            Init_Mod_SandboxVirtual();
        }
        if (config.hookObjCRuntime) {
            Init_Mod_ObjCRuntime();
        }
        
        // Đã sửa: Thêm dấu ngoặc đơn cho KELEN_LOG
        KELEN_LOG(@"Toàn bộ module lõi đã được khởi tạo và đồng bộ thành công!");
    }
}
