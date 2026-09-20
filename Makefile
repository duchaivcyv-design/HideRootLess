TARGET := iphone:clang:latest:14.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = HideRLess

# Khai báo các file mã nguồn ở thư mục gốc
HideRLess_FILES = \
    Kelen_CoreEngine.m \
    Kelen_Tweak.x \
    mod_antidebug.m \
    mod_dyld.m \
    mod_filesystem.m \
    mod_syscall.m

# Khai báo các thư mục con
SUBPROJECTS += HideApp
SUBPROJECTS += HideRL
SUBPROJECTS += KelenCore
SUBPROJECTS += KelenBootstrapLoader

HideRLess_FRAMEWORKS = UIKit Foundation Security
HideRLess_PRIVATE_FRAMEWORKS = 

# Khai báo đường dẫn include (-I) quét qua toàn bộ các thư mục con trong dự án
HideRLess_CFLAGS = -fobjc-arc -I$(THEOS_PROJECT_DIR) -I$(THEOS_PROJECT_DIR)/KelenCore -I$(THEOS_PROJECT_DIR)/HideApp -I$(THEOS_PROJECT_DIR)/HideRL -I$(THEOS_PROJECT_DIR)/KelenBootstrapLoader

# Trỏ đến file entitlements
HideRLess_ENTITLEMENTS = nickchan.entitlements

include $(THEOS_MAKE_PATH)/application.mk

after-install::
	install.exec "uicache -p /Applications/HideRLess.app"
