TARGET := iphone:clang:16.5:12.0
ARCHS := arm64

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME := HideAppManager

HideAppManager_FILES := HideAppController.m HideAppFilter.m
HideAppManager_INSTALL_PATH := /Library/PreferenceLoader/Preferences
HideAppManager_FRAMEWORKS := UIKit Foundation
HideAppManager_PRIVATE_FRAMEWORKS := Preferences
HideAppManager_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk
