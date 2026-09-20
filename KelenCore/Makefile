TARGET := iphone:clang:latest:14.0
include $(THEOS)/makefiles/common.mk

# Khai báo các thư mục con theo thứ tự: Build KelenCore trước, sau đó build HideApp
SUBPROJECTS += KelenCore HideApp

include $(THEOS_MAKE_PATH)/aggregate.mk
