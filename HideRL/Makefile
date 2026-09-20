TARGET := iphone:clang:16.5:12.0
ARCHS := arm64

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME := HideRLess

HideRLess_FILES := $(wildcard HideRL/*.m HideRL/*.x HideRL/*.xm)
HideRLess_FRAMEWORKS := UIKit Foundation
HideRLess_PRIVATE_FRAMEWORKS := 
HideRLess_CFLAGS = -fobjc-arc -I$(THEOS_PROJECT_DIR)/HideRL

include $(THEOS_MAKE_PATH)/application.mk
