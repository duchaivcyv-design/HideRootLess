TARGET := iphone:clang:latest:14.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = HideRLess

HideRLess_FILES = \
    main.m \
    AntiDebuggingEngine.m \
    BypassCoreEngine.x \
    BypassDashboardController.m \
    DYLDInterceptionEngine.x \
    DeviceIdentifierMaskEngine.x \
    EnvironmentShieldEngine.x \
    HideAppController.m \
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

HideRLess_FRAMEWORKS = UIKit Foundation Security
HideRLess_PRIVATE_FRAMEWORKS = 
HideRLess_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/application.mk
