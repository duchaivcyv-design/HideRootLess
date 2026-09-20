#import "Kelen_MasterSync.h"
#import "fishhook.h"

// Khai báo con trỏ hàm gốc cho DYLD
static const char * (*orig_dyld_get_image_name)(uint32_t image_index);
static uint32_t (*orig_dyld_image_count)(void);
static int (*orig_NSIsSymbolNameDefined)(const char *symbolName);

// Kiểm tra tên dylib có chứa thành phần jailbreak cần ẩn không
static BOOL kelen_is_forbidden_dylib(const char *imageName) {
    if (imageName == NULL) return NO;
    
    NSString *nameStr = [NSString stringWithUTF8String:imageName];
    if (!nameStr) return NO;

    // Các dylib nhạy cảm cần loại bỏ khỏi tầm nhìn ứng dụng
    NSArray *forbiddenDylibs = @[
        @"KelenDeepBypass",
        @"ellekit",
        @"MobileSubstrate",
        @"SubstrateLoader",
        @"TweakInject",
        @"libhooker",
        @"Cephei",
        @"rocketbootstrap"
    ];

    for (NSString *dylib in forbiddenDylibs) {
        if ([nameStr containsString:dylib]) {
            return YES;
        }
    }
    return NO;
}

// Thay thế hàm lấy tên ảnh dyld
static const char * kelen_replaced_dyld_get_image_name(uint32_t image_index) {
    const char *name = orig_dyld_get_image_name(image_index);
    if (kelen_is_forbidden_dylib(name)) {
        // Trả về chuỗi trống thay vì lộ diện dylib ẩn
        return "";
    }
    return name;
}

// Tùy chỉnh đếm số lượng image nếu cần thiết để khớp với danh sách đã lọc
static uint32_t kelen_replaced_dyld_image_count(void) {
    uint32_t count = orig_dyld_image_count();
    return count;
}

// Chặn kiểm tra tên symbol nhạy cảm
static int kelen_replaced_NSIsSymbolNameDefined(const char *symbolName) {
    if (symbolName != NULL) {
        NSString *sym = [NSString stringWithUTF8String:symbolName];
        if ([sym containsString:@"MSHookMessageEx"] || [sym containsString:@"LHHookSymbol"]) {
            return 0; // Báo là không tồn tại symbol của công cụ can thiệp
        }
    }
    return orig_NSIsSymbolNameDefined(symbolName);
}

void Init_Mod_DyldImages(void) {
    struct rebinding rebindings[] = {
        {"_dyld_get_image_name", (void *)kelen_replaced_dyld_get_image_name, (void **)&orig_dyld_get_image_name},
        {"_dyld_image_count", (void *)kelen_replaced_dyld_image_count, (void **)&orig_dyld_image_count},
        {"NSIsSymbolNameDefined", (void *)kelen_replaced_NSIsSymbolNameDefined, (void **)&orig_NSIsSymbolNameDefined}
    };
    rebind_symbols(rebindings, 3);
    KELEN_LOG:@"Mod_DyldImages đã khởi tạo và ẩn thành công các dylib nhạy cảm.";
}
