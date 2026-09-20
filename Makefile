TARGET := iphone:clang:latest:14.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = HideRLess

# Thay 'main.m' bằng tên file thực tế có chứa hàm main() của bạn (ví dụ: HideRLessCore.m)
# Và tự động quét toàn bộ file bên trong thư mục HideRL
HideRLess_FILES = \
    HideRLessCore.m \
    $(wildcard HideRL/*.m) \
    $(wildcard HideRL/*.mm) \
    $(wildcard HideRL/*.xm) \
    $(wildcard HideRL/*.c) \
    $(wildcard HideRL/*.cpp)

HideRLess_FRAMEWORKS = UIKit Foundation Security
HideRLess_PRIVATE_FRAMEWORKS = 

# Khai báo đường dẫn include để các file nhận diện lẫn nhau
HideRLess_CFLAGS = -fobjc-arc -I$(THEOS_PROJECT_DIR) -IHideRL

HideRLess_ENTITLEMENTS = nickchan.entitlements

include $(THEOS_MAKE_PATH)/application.mk

after-install::
	install.exec "uicache -p /Applications/HideRLess.app"
