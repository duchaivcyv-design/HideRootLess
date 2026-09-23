TARGET := iphone:clang:latest:14.0
include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = KelenCore

KelenCore_FILES = \
    KelenAdvancedSubController.m \
    KelenAppSelectorController.m \
    KelenBridgeSync.m \
    KelenLogMonitorController.m \
    KelenSearchBypassEngine.m

KelenCore_CFLAGS = -fobjc-arc -I$(THEOS_PROJECT_DIR)

# Chỉ giữ lại framework Preferences của hệ thống
KelenCore_EXTRA_FRAMEWORKS += Preferences

include $(THEOS_MAKE_PATH)/library.mk
