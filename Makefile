TARGET := iphone:clang:latest:14.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = HideRLess

# Khai báo các file ở thư mục gốc
HideRLess_FILES = \
    Kelen_CoreEngine.m \
    Kelen_Tweak.x \
    mod_antidebug.m \
    mod_dyld.m \
    mod_filesystem.m \
    mod_syscall.m

# Khai báo đủ toàn bộ các thư mục con có trong kho lưu trữ
SUBPROJECTS += HideApp
SUBPROJECTS += HideRL
SUBPROJECTS += KelenCore
SUBPROJECTS += KelenBootstrapLoader

HideRLess_FRAMEWORKS = UIKit Foundation Security
HideRLess_PRIVATE_FRAMEWORKS = 

# Bổ sung thêm các đường dẫn trỏ tới thư mục chứa header phụ (như KelenCore chứa fishhook.h)
HideRLess_CFLAGS = -fobjc-arc -I$(THEOS_PROJECT_DIR) -I$(THEOS_PROJECT_DIR)/KelenCore

# Trỏ đến file entitlements mở rộng nickchan.entitlements
HideRLess_ENTITLEMENTS = nickchan.entitlements

include $(THEOS_MAKE_PATH)/application.mk

after-install::
	install.exec "uicache -p /Applications/HideRLess.app"
