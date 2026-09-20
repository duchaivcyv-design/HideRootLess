TARGET := iphone:clang:latest:14.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = HideRLess

HideRLess_FILES = \
    main.m[span_1](start_span)[span_1](end_span) \
    AntiDebuggingEngine.m[span_2](start_span)[span_2](end_span) \
    BypassCoreEngine.m[span_3](start_span)[span_3](end_span) \
    BypassDashboardController.m[span_4](start_span)[span_4](end_span) \
    DYLDInterceptionEngine.m[span_5](start_span)[span_5](end_span) \
    DeviceIdentifierMaskEngine.m[span_6](start_span)[span_6](end_span) \
    EnvironmentShieldEngine.m[span_7](start_span)[span_7](end_span) \
    HideAppController.m[span_8](start_span)[span_8](end_span) \
    HideAppManagerEngine.m[span_9](start_span)[span_9](end_span) \
    HideRLessCore.m[span_10](start_span)[span_10](end_span) \
    HookGuardEngine.xm[span_11](start_span)[span_11](end_span) \
    KeychainProtectionEngine.m[span_12](start_span)[span_12](end_span) \
    MemoryProtectionEngine.m[span_13](start_span)[span_13](end_span) \
    NetworkInterceptEngine.m[span_14](start_span)[span_14](end_span) \
    ProcessHidingEngine.m[span_15](start_span)[span_15](end_span) \
    SandboxEscapeShieldEngine.m[span_16](start_span)[span_16](end_span) \
    SandboxViolationShieldEngine.xm[span_17](start_span)[span_17](end_span) \
    SymbolicLinkShieldEngine.m[span_18](start_span)[span_18](end_span)

HideRLess_FRAMEWORKS = UIKit Foundation Security
HideRLess_PRIVATE_FRAMEWORKS = 
HideRLess_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/application.mk
