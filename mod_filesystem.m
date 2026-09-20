#import "Kelen_MasterSync.h"
#import "fishhook.h"

// Khai báo con trỏ hàm gốc
static int (*orig_stat)(const char *restrict path, struct stat *restrict buf);
static int (*orig_lstat)(const char *restrict path, struct stat *restrict buf);
static int (*orig_access)(const char *path, int amode);
static FILE * (*orig_fopen)(const char *restrict filename, const char *restrict mode);
static int (*orig_open)(const char *path, int oflag, ...);

// Hàm kiểm tra đường dẫn nhạy cảm cần ẩn
static BOOL kelen_is_forbidden_path(const char *path) {
    if (path == NULL) return NO;
    
    // Chuyển đổi an toàn sang NSString để kiểm tra chuỗi linh hoạt
    NSString *pathStr = [NSString stringWithUTF8String:path];
    if (!pathStr) return NO;

    // Danh sách các từ khóa đặc trưng của Jailbreak Rootless và Rootful cần che giấu
    NSArray *forbiddenKeywords = @[
        @"/var/jb",
        @"/usr/bin/su",
        @"/etc/apt",
        @"/Library/MobileSubstrate",
        @"/Applications/Cydia.app",
        @"/Applications/Sileo.app",
        @"/Applications/Zebra.app",
        @"/var/lib/dpkg",
        @"/var/stash",
        @".paralell",
        @"palera1n",
        @"dopamine"
    ];

    for (NSString *keyword in forbiddenKeywords) {
        if ([pathStr containsString:keyword]) {
            return YES;
        }
    }
    return NO;
}

// Thay thế hàm stat
static int kelen_replaced_stat(const char *restrict path, struct stat *restrict buf) {
    if (kelen_is_forbidden_path(path)) {
        errno = ENOENT; // Báo lỗi file không tồn tại
        return -1;
    }
    return orig_stat(path, buf);
}

// Thay thế hàm lstat
static int kelen_replaced_lstat(const char *restrict path, struct stat *restrict buf) {
    if (kelen_is_forbidden_path(path)) {
        errno = ENOENT;
        return -1;
    }
    return orig_lstat(path, buf);
}

// Thay thế hàm access
static int kelen_replaced_access(const char *path, int amode) {
    if (kelen_is_forbidden_path(path)) {
        errno = ENOENT;
        return -1;
    }
    return orig_access(path, amode);
}

// Thay thế hàm fopen
static FILE * kelen_replaced_fopen(const char *restrict filename, const char *restrict mode) {
    if (kelen_is_forbidden_path(filename)) {
        errno = ENOENT;
        return NULL;
    }
    return orig_fopen(filename, mode);
}

// Thay thế hàm open
static int kelen_replaced_open(const char *path, int oflag, ...) {
    if (kelen_is_forbidden_path(path)) {
        errno = ENOENT;
        return -1;
    }
    
    // Xử lý biến động (variadic arguments) cho hàm open
    va_list args;
    va_start(args, oflag);
    int mode = 0;
    if (oflag & O_CREAT) {
        mode = va_arg(args, int);
    }
    va_end(args);
    
    return orig_open(path, oflag, mode);
}

void Init_Mod_FileSystem(void) {
    struct rebinding rebindings[] = {
        {"stat", (void *)kelen_replaced_stat, (void **)&orig_stat},
        {"lstat", (void *)kelen_replaced_lstat, (void **)&orig_lstat},
        {"access", (void *)kelen_replaced_access, (void **)&orig_access},
        {"fopen", (void *)kelen_replaced_fopen, (void **)&orig_fopen},
        {"open", (void *)kelen_replaced_open, (void **)&orig_open}
    };
    rebind_symbols(rebindings, 5);
    KELEN_LOG:@"Mod_FileSystem đã khởi tạo và hook thành công 5 hàm quan trọng.";
}
