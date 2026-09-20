TARGET := iphone:clang:latest:14.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = HideRLess

# Giữ main.m ở gốc và tự động quét sạch mọi file code bên trong thư mục HideRL
HideRLess_FILES = main.m \
                  $(wildcard HideRL/*.m) \
                  $(wildcard HideRL/*.mm) \
                  $(wildcard HideRL/*.xm) \
                  $(wildcard HideRL/*.c) \
                  $(wildcard HideRL/*.cpp)

HideRLess_FRAMEWORKS = UIKit Foundation Security
HideRLess_PRIVATE_FRAMEWORKS = 

# Thêm đường dẫn -IHideRL để các file trong thư mục đó có thể #import header của nhau
HideRLess_CFLAGS = -fobjc-arc -I$(THEOS_PROJECT_DIR) -IHideRL

HideRLess_ENTITLEMENTS = nickchan.entitlements

include $(THEOS_MAKE_PATH)/application.mk

after-install::
	install.exec "uicache -p /Applications/HideRLess.app"
