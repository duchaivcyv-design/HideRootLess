TARGET := iphone:clang:latest:14.0
include $(THEOS)/makefiles/common.mk

# Khai báo tất cả các thư mục con (mô-đun) cần build
SUBPROJECTS += HideApp
SUBPROJECTS += HideRL
SUBPROJECTS += Kelencore

include $(THEOS_MAKE_PATH)/aggregate.mk
