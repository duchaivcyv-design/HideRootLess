TARGET := iphone:clang:latest:14.0
include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = KelenCore

KelenCore_FILES = \
    KelenAdvancedSubController.m \
    KelenAppSelectorController.m \
    KelenBridgeSync.m \
    KelenLogMonitorController.m \
    KelenSearchBypassEngine.m \
    KelenSecurityPresets.m \
    ../fishhook.c

KelenCore_CFLAGS = -fobjc-arc -I$(THEOS_PROJECT_DIR) -I$(THEOS_PROJECT_DIR)/..

# Chỉ giữ lại các Public Frameworks cơ bản
KelenCore_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/library.mk
