#import "Kelen_MasterSync.h"
#import "fishhook.h"

// Định nghĩa mã ptrace chống gỡ lỗi chuẩn trên iOS
#ifndef PT_DENY_ATTACH
#define PT_DENY_ATTACH 31
#endif

// Khai báo con trỏ hàm ptrace gốc
static int (*orig_ptrace)(int _request, pid_t _pid, caddr_t _addr, int _data);
static int (*orig_raise)(int sig);
static int (*orig_kill)(pid_t pid, int sig);

// Thay thế hàm ptrace vô hiệu hóa lệnh từ chối kết nối gỡ lỗi
static int kelen_replaced_ptrace(int _request, pid_t _pid, caddr_t _addr, int _data) {
    if (_request == PT_DENY_ATTACH) {
        KELEN_LOG(@"Đã chặn thành công yêu cầu ptrace(PT_DENY_ATTACH) từ ứng dụng mục tiêu.");
        return 0; // Trả về thành công giả lập nhưng không thực hiện hành động chặn
    }
    return orig_ptrace(_request, _pid, _addr, _data);
}

// Vô hiệu hóa tín hiệu tự hủy tiến trình khi gặp nghi vấn
static int kelen_replaced_raise(int sig) {
    if (sig == 5 || sig == 9) { // SIGTRAP hoặc SIGKILL thường dùng trong cơ chế check debug
        KELEN_LOG(@"Đã ngăn chặn tín hiệu tự hủy mã độc/debug SIG: %d", sig);
        return 0;
    }
    return orig_raise(sig);
}

// Thay thế hàm kill kiểm tra tiến trình tự thân
static int kelen_replaced_kill(pid_t pid, int sig) {
    if (pid == getpid() && (sig == 9 || sig == 5)) {
        KELEN_LOG(@"Đã chặn lệnh kill tự thân của ứng dụng.");
        return 0;
    }
    return orig_kill(pid, sig);
}

void Init_Mod_AntiDebug(void) {
    struct rebinding rebindings[] = {
        {"ptrace", (void *)kelen_replaced_ptrace, (void **)&orig_ptrace},
        {"raise", (void *)kelen_replaced_raise, (void **)&orig_raise},
        {"kill", (void *)kelen_replaced_kill, (void **)&orig_kill}
    };
    rebind_symbols(rebindings, 3);
    KELEN_LOG(@"Mod_AntiDebug đã khởi tạo và vô hiệu hóa cơ chế Anti-Debug thành công.");
}
