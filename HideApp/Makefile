TARGET := iphone:clang:latest:12.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = KelenHideApp

# Khai báo các file của App (Giao diện, quét AppStore, đồng bộ config)
KelenHideApp_FILES = \
    HideAppMain.m \
    AppScanner.m \
    ConfigSync.m

KelenHideApp_FRAMEWORKS = UIKit Foundation
KelenHideApp_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/application.mk
