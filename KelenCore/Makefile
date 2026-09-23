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

# Sử dụng PRIVATE_FRAMEWORKS để liên kết chính xác Preferences framework
KelenCore_PRIVATE_FRAMEWORKS = Preferences

# Khai báo liên kết thư viện fishhook
KelenCore_LIBRARIES += fishhook

include $(THEOS_MAKE_PATH)/library.mk
