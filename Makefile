TARGET := iphone:clang:latest:14.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = HideRLess

# Khai báo các file ở thư mục gốc và các thư mục con (Subdirectories)
HideRLess_FILES = \
    main.m \
    HideRLessCore.m \
    BypassDashboardController.m \
    BypassCoreEngine.m \
    AntiDebuggingEngine.m \
    EnvironmentShieldEngine.m \
    NetworkInterceptEngine.m \
    MemoryProtectionEngine.m \
    DeviceIdentifierMaskEngine.m \
    KeychainProtectionEngine.m \
    SandboxEscapeShieldEngine.m \
    ProcessHidingEngine.m \
    SymbolicLinkShieldEngine.m \
    HookGuardEngine.xm \
    DYLDInterceptionEngine.xm \
    SandboxViolationShieldEngine.xm

# Nếu bạn có tạo các thư mục con chứa mã nguồn riêng (ví dụ thư mục Engines hoặc Controllers), 
# bạn có thể gom đường dẫn vào đây:
# Subdirectories/EngineFiles.m

HideRLess_FRAMEWORKS = UIKit Foundation Security
HideRLess_PRIVATE_FRAMEWORKS = 
HideRLess_CFLAGS = -fobjc-arc -I$(THEOS_PROJECT_DIR)

# Trỏ đến file entitlements mở rộng nickchan.entitlements mà bạn vừa tạo
HideRLess_ENTITLEMENTS = nickchan.entitlements

include $(THEOS_MAKE_PATH)/application.mk

after-install::
	install.exec "uicache -p /Applications/HideRLess.app"
