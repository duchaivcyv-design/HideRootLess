#import "Kelen_MasterSync.h"
#import "fishhook.h"

static int (*orig_stat)(const char *restrict path, struct stat *restrict buf);
static int (*orig_lstat)(const char *restrict path, struct stat *restrict buf);
static int (*orig_access)(const char *path, int amode);
static FILE * (*orig_fopen)(const char *restrict filename, const char *restrict mode);
static int (*orig_open)(const char *path, int oflag, ...);

static BOOL kelen_is_forbidden_path(const char *path) {
    if (path == NULL) return NO;
    
    NSString *pathStr = [NSString stringWithUTF8String:path];
    if (!pathStr) return NO;

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

static int kelen_replaced_stat(const char *restrict path, struct stat *restrict buf) {
    if (kelen_is_forbidden_path(path)) {
        errno = ENOENT;
        return -1;
    }
    return orig_stat(path, buf);
}

static int kelen_replaced_lstat(const char *restrict path, struct stat *restrict buf) {
    if (kelen_is_forbidden_path(path)) {
        errno = ENOENT;
        return -1;
    }
    return orig_lstat(path, buf);
}

static int kelen_replaced_access(const char *path, int amode) {
    if (kelen_is_forbidden_path(path)) {
        errno = ENOENT;
        return -1;
    }
    return orig_access(path, amode);
}

static FILE * kelen_replaced_fopen(const char *restrict filename, const char *restrict mode) {
    if (kelen_is_forbidden_path(filename)) {
        errno = ENOENT;
        return NULL;
    }
    return orig_fopen(filename, mode);
}

static int kelen_replaced_open(const char *path, int oflag, ...) {
    if (kelen_is_forbidden_path(path)) {
        errno = ENOENT;
        return -1;
    }
    
    va_list args;
    va_start(args, oflag);
    int result;
    if (oflag & O_CREAT) {
        mode_t mode = va_arg(args, int);
        result = orig_open(path, oflag, mode);
    } else {
        result = orig_open(path, oflag);
    }
    va_end(args);
    
    return result;
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
