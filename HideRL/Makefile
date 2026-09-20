include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = HideRLess

# Liệt kê đầy đủ tất cả các file .m / .mm / .c / .x của bạn ở đây
HideRLess_FILES = \
    main.m \
    HideAppController.m \
    HideAppFilter.m \
    Kelen_CoreEngine.m \
    Kelen_Tweak.x \
    mod_antidebug.m \
    mod_dyld.m \
    mod_filesystem.m \
    mod_syscall.m \
    mod_objc_runtime.m \
    mod_sandbox_virtual.m \
    fishhook.c

HideRLess_FRAMEWORKS = UIKit Foundation Security
HideRLess_PRIVATE_FRAMEWORKS = 
HideRLess_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/application.mk
