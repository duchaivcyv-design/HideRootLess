TARGET := iphone:clang:16.5:12.0
ARCHS := arm64

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME := HideRLess

# Liệt kê tường minh tất cả các tệp .m, .x, .xm có trong thư mục HideRL
HideRLess_FILES := main.m \
                   AntiDebuggingEngine.m \
                   BypassCoreEngine.x \
                   BypassDashboardController.m \
                   DYLDInterceptionEngine.xm \
                   DeviceIdentifierMaskEngine.x \
                   EnvironmentShieldEngine.x \
                   HideAppManagerEngine.x \
                   HideRLessCore.m \
                   HookGuardEngine.xm \
                   KeychainProtectionEngine.x \
                   MemoryProtectionEngine.x \
                   NetworkInterceptEngine.x \
                   ProcessHidingEngine.x \
                   SandboxEscapeShieldEngine.x \
                   SandboxViolationShieldEngine.xm \
                   SymbolicLinkShieldEngine.x

HideRLess_FRAMEWORKS := UIKit Foundation
HideRLess_PRIVATE_FRAMEWORKS := 
HideRLess_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/application.mk
