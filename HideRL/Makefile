TARGET := iphone:clang:latest:14.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = HideRLess

HideRLess_FILES = \
    main.m \
    AntiDebuggingEngine.m \
    BypassCoreEngine.m \
    BypassDashboardController.m \
    DYLDInterceptionEngine.m \
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
    SymbolicLinkShieldEngine.m

HideRLess_FRAMEWORKS = UIKit Foundation Security
HideRLess_PRIVATE_FRAMEWORKS = 
HideRLess_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/application.mk
