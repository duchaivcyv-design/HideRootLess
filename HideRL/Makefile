TARGET := iphone:clang:latest:14.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = HideRLess

HideRLess_FILES = \
    main.m \
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

HideRLess_FRAMEWORKS = UIKit Foundation Security
HideRLess_PRIVATE_FRAMEWORKS = 
HideRLess_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/application.mk

after-install::
	install.exec "uicache -p /Applications/HideRLess.app"
