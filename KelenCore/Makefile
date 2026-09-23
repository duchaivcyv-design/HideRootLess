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

# Sử dụng PRIVATE_FRAMEWORKS để liên kết chính xác Preferences framework
KelenCore_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/library.mk
