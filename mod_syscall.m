#import "Kelen_MasterSync.h"
#import "fishhook.h"

// Khai báo con trỏ hàm sysctl gốc
static int (*orig_sysctl)(int *name, u_int namelen, void *oldp, size_t *oldlenp, void *newp, size_t newlen);
static int (*orig_sysctlbyname)(const char *sname, void *oldp, size_t *oldlenp, void *newp, size_t newlen);

// Thay thế hàm sysctl cốt lõi
static int kelen_replaced_sysctl(int *name, u_int namelen, void *oldp, size_t *oldlenp, void *newp, size_t newlen) {
    // Kiểm tra nếu ứng dụng cố gắng truy vấn thông tin tiến trình (KERN_PROC, KERN_PROC_PID)
    if (namelen >= 2 && name[0] == CTL_KERN && name[1] == KERN_PROC) {
        int result = orig_sysctl(name, namelen, oldp, oldlenp, newp, newlen);
        if (oldp != NULL && oldlenp != null && *oldlenp >= sizeof(struct kinfo_proc)) {
            struct kinfo_proc *myProc = (struct kinfo_proc *)oldp;
            // Xóa sạch cờ P_TRACED (đang bị debug hoặc giám sát) để lừa ứng dụng
            myProc->kp_proc.p_flag &= ~P_TRACED;
        }
        return result;
    }

    // Chặn truy vấn kiểm tra debugger hoặc cờ hạn chế sandbox qua sysctl
    if (namelen >= 1 && name[0] == CTL_KERN) {
        // Có thể bổ sung lọc các mảng cấu trúc kernel tại đây
    }

    return orig_sysctl(name, namelen, oldp, oldlenp, newp, newlen);
}

// Thay thế hàm sysctlbyname
static int kelen_replaced_sysctlbyname(const char *sname, void *oldp, size_t *oldlenp, void *newp, size_t newlen) {
    if (sname != NULL) {
        NSString *nameStr = [NSString stringWithUTF8String:sname];
        // Nếu app kiểm tra các thông số bảo mật liên quan đến kernel hoặc boot args
        if ([nameStr isEqualToString:@"kern.bootargs"] || [nameStr isEqualToString:@"kern.secure_kernel"]) {
            int ret = orig_sysctlbyname(sname, oldp, oldlenp, newp, newlen);
            if (oldp != NULL) {
                // Xóa sạch từ khóa rootless hoặc jailbreak xuất hiện trong bootargs giả lập
                char *bootargs = (char *)oldp;
                NSString *argsStr = [NSString stringWithUTF8String:bootargs];
                if ([argsStr containsString:@"rootless"] || [argsStr containsString:@"jailbreak"]) {
                    // Trả về chuỗi an toàn không có dấu vết
                    strcpy(bootargs, "debug=0");
                }
            }
            return ret;
        }
    }
    return orig_sysctlbyname(sname, oldp, oldlenp, newp, newlen);
}

void Init_Mod_SyscallCore(void) {
    struct rebinding rebindings[] = {
        {"sysctl", (void *)kelen_replaced_sysctl, (void **)&orig_sysctl},
        {"sysctlbyname", (void *)kelen_replaced_sysctlbyname, (void **)&orig_sysctlbyname}
    };
    rebind_symbols(rebindings, 2);
    KELEN_LOG:@"Mod_SyscallCore đã khởi tạo thành công.";
}
