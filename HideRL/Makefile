TARGET := iphone:clang:latest:14.0
include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = HideRLess

# Đã liệt kê chính xác 100% các file .m và .xm dựa theo hình ảnh thư mục HideApp của bạn
HideRLess_FILES = \
    AntiDebuggingEngine.m \
    BypassCoreEngine.m \
    BypassDashboardController.m \
    DYLDInterceptionEngine.xm \
    DeviceIdentifierMaskEngine.m \
    EnvironmentShieldEngine.m \
    HideAppController.m \
    HideAppManagerEngine.m \
    HideRLessCore.m \
    HookGuardEngine.xm \
    KeychainProtectionEngine.m \
    MemoryProtectionEngine.m \
    NetworkInterceptEngine.m \
    ProcessHidingEngine.m \
    SandboxEscapeShieldEngine.m \
    SandboxViolationShieldEngine.xm \
    SymbolicLinkShieldEngine.m \
    main.m

HideRLess_FRAMEWORKS = UIKit Foundation Security
HideRLess_CFLAGS = -fobjc-arc -I$(THEOS_PROJECT_DIR)

# Vì file nickchan.entitlements của bạn nằm ở thư mục gốc, 
# ta cần thêm "../" để Theos lùi ra ngoài 1 cấp và lấy file đó
HideRLess_ENTITLEMENTS = ../nickchan.entitlements

include $(THEOS_MAKE_PATH)/application.mk

after-install::
	install.exec "uicache -p /Applications/HideRLess.app"
