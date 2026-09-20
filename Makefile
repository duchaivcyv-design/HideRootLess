TARGET := iphone:clang:latest:12.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = KelenDeepBypass

# Khai báo ĐẦY ĐỦ hơn 10 file cốt lõi ở thư mục gốc để đồng bộ biên dịch
KelenDeepBypass_FILES = \
    Kelen_CoreEngine.m \
    Kelen_Tweak.x \
    mod_syscall_hook.m \
    mod_kernel_bypass.m \
    mod_filesystem_stat.m \
    mod_filesystem_open.m \
    mod_dyld_images.m \
    mod_antidebug_ptrace.m \
    mod_sandbox_virtual.m \
    mod_objc_runtime.m \
    fishhook.c

KelenDeepBypass_CFLAGS = -fobjc-arc -Wno-deprecated-declarations

include $(THEOS_MAKE_PATH)/tweak.mk

# Liên kết thư mục con HideApp để khi gõ make package sẽ build luôn cả App quản lý
SUBPROJECTS += HideApp
include $(THEOS_MAKE_PATH)/aggregate.mk
