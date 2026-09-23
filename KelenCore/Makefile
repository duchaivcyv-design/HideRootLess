include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = KelenCore

KelenCore_FILES = \
    KelenAdvancedSubController.m \
    KelenAppSelectorController.m \
    KelenBridgeSync.m \
    KelenLogMonitorController.m \
    KelenSearchBypassEngine.m \
    KelenSecurityPresets.m \
    fishhook.c

# Thêm dòng này để liên kết Preferences framework
KelenCore_FRAMEWORKS = Preferences UIKit

KelenCore_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/library.mk
