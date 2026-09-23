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

# Thêm đường dẫn PrivateFrameworks của SDK để linker tìm thấy Preferences
KelenCore_LDFLAGS += -F$(SDKROOT)/System/Library/PrivateFrameworks
KelenCore_FRAMEWORKS = Preferences UIKit Foundation

include $(THEOS_MAKE_PATH)/library.mk
