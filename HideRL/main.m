#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <notify.h>

#define KELEN_MAIN_PREFS @"/var/mobile/Library/Preferences/com.kelen.masterbypass.plist"
#define KELEN_MAIN_LOG(fmt, ...) NSLog((@"HideRLess-MainApp: " fmt), ##__VA_ARGS__)

// ============================================================================
// GIAO DIỆN CHÍNH VÀ ĐIỀU KHIỂN CÔNG TẮC BẢO MẬT (DASHBOARD CONTROLLER)
// ============================================================================

@interface HideRLessMainController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
    UITableView *_mainTableView;
    NSMutableArray *_keysArray;
    NSMutableDictionary *_titlesDict;
    NSMutableDictionary *_statesDict;
}
@end

@implementation HideRLessMainController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"HideRLess - Master Security Suite";
    
    if (@available(iOS 13.0, *)) {
        self.view.backgroundColor = [UIColor systemBackgroundColor];
        [self.navigationController.navigationBar setPrefersLargeTitles:YES];
    } else {
        self.view.backgroundColor = [UIColor whiteColor];
    }
    
    [self initializeDataSources];
    [self setupInterfaceComponents];
    [self registerSystemNotifications];
}

- (void)initializeDataSources {
    _keysArray = [NSMutableArray arrayWithObjects:
                  @"KelenMasterSwitch",
                  @"KelenHookFileSystem",
                  @"KelenAntiDebugBypass",
                  @"KelenEnvironmentShield",
                  @"KelenNetworkIntercept",
                  @"KelenMemoryProtection",
                  @"KelenDeviceMask",
                  @"KelenKeychainProtection",
                  @"KelenSandboxEscapeShield",
                  @"KelenProcessHiding",
                  @"KelenSymbolicLinkShield",
                  @"KelenHookGuard",
                  @"KelenDYLDInterception",
                  @"KelenViolationShield", nil];
    
    _titlesDict = [NSMutableDictionary dictionaryWithDictionary:@{
        @"KelenMasterSwitch": @"Công Tắc Tổng (Master Bypass)",
        @"KelenHookFileSystem": @"Che Giấu Hệ Thống Tệp (FileSystem)",
        @"KelenAntiDebugBypass": @"Vô Hiệu Hóa Anti-Debugging",
        @"KelenEnvironmentShield": @"Bảo Vệ Môi Trường Thực Thi",
        @"KelenNetworkIntercept": @"Chặn & Lọc Luồng Mạng (Network)",
        @"KelenMemoryProtection": @"Bảo Vệ Vùng Nhớ RAM (Memory)",
        @"KelenDeviceMask": @"Giả Mạo Thông Tin Phần Cứng",
        @"KelenKeychainProtection": @"Cô Lập & Bảo Vệ Keychain",
        @"KelenSandboxEscapeShield": @"Chặn Thoát Khỏi Không Gian Sandbox",
        @"KelenProcessHiding": @"Ẩn Danh Tiến Trình Hệ Thống",
        @"KelenSymbolicLinkShield": @"Bảo Vệ Liên Kết Tượng Trưng",
        @"KelenHookGuard": @"Giám Sát Tính Toàn Vẹn Hook",
        @"KelenDYLDInterception": @"Kiểm Soát Nạp Thư Viện DYLD",
        @"KelenViolationShield": @"Chặn Ghi Nhật Ký Vi Phạm"
    }];
    
    [self reloadPreferencesFromFile];
}

- (void)reloadPreferencesFromFile {
    @autoreleasepool {
        NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:KELEN_MAIN_PREFS];
        _statesDict = [NSMutableDictionary dictionary];
        for (NSString *key in _keysArray) {
            id val = prefs ? prefs[key] : nil;
            BOOL state = val ? [val boolValue] : YES;
            _statesDict[key] = @(state);
        }
    }
}

- (void)setupInterfaceComponents {
    _mainTableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    _mainTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _mainTableView.delegate = self;
    _mainTableView.dataSource = self;
    [self.view addSubview:_mainTableView];
}

- (void)registerSystemNotifications {
    CFNotificationCenterAddObserver(
        CFNotificationCenterGetDarwinNotifyCenter(),
        (__bridge const void *)(self),
        (CFNotificationCallback)&OnMasterPrefsChanged,
        CFSTR("com.kelen.masterbypass/ReloadPrefs"),
        NULL,
        CFNotificationSuspensionBehaviorDeliverImmediately
    );
}

static void OnMasterPrefsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    HideRLessMainController *controller = (__bridge HideRLessMainController *)observer;
    if (controller && [controller isKindOfClass:[HideRLessMainController class]]) {
        [controller reloadPreferencesFromFile];
        [controller->_mainTableView reloadData];
        KELEN_MAIN_LOG(@"[Dashboard] Đã làm mới trạng thái giao diện thành công từ thông báo hệ thống.");
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_keysArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"KelenCellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        UISwitch *sw = [[UISwitch alloc] init];
        [sw addTarget:self action:@selector(switchActionChanged:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = sw;
    }
    
    NSString *key = _keysArray[indexPath.row];
    cell.textLabel.text = _titlesDict[key];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"Trạng thái khóa: %@", key];
    cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
    
    UISwitch *switchControl = (UISwitch *)cell.accessoryView;
    switchControl.tag = indexPath.row;
    switchControl.on = [_statesDict[key] boolValue];
    
    return cell;
}

- (void)switchActionChanged:(UISwitch *)sender {
    NSInteger index = sender.tag;
    if (index >= 0 && index < [_keysArray count]) {
        NSString *key = _keysArray[index];
        _statesDict[key] = @(sender.on);
        
        NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:KELEN_MAIN_PREFS];
        if (!prefs) {
            prefs = [NSMutableDictionary dictionary];
        }
        prefs[key] = @(sender.on);
        [prefs writeToFile:KELEN_MAIN_PREFS atomically:YES];
        
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFSTR("com.kelen.masterbypass/ReloadPrefs"),
            NULL,
            NULL,
            YES
        );
        
        KELEN_MAIN_LOG(@"[Config] Đã thay đổi tùy chọn %@ thành: %@", key, sender.on ? @"BẬT" : @"TẮT");
    }
}

- (void)dealloc {
    CFNotificationCenterRemoveEveryObserver(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge const void *)(self));
}

@end

// ============================================================================
// QUẢN LÝ APP DELEGATE VÀ ĐIỂM KHỞI CHẠY (ENTRY POINT)
// ============================================================================

@interface HideRLessAppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
@end

@implementation HideRLessAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    @autoreleasepool {
        self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        
        HideRLessMainController *mainController = [[HideRLessMainController alloc] init];
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:mainController];
        
        self.window.rootViewController = navController;
        [self.window makeKeyAndVisible];
        
        KELEN_MAIN_LOG(@"[Init] Ứng dụng HideRLess đã khởi chạy hoàn tất và sẵn sàng hoạt động.");
    }
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    KELEN_MAIN_LOG(@"[State] Ứng dụng sắp chuyển sang trạng thái ẩn (Resign Active).");
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    KELEN_MAIN_LOG:@"[State] Ứng dụng đã đi vào chế độ nền (Background).";
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    KELEN_MAIN_LOG:@"[State] Ứng dụng quay trở lại giao diện phía trước (Foreground).";
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    KELEN_MAIN_LOG:@"[State] Ứng dụng đang hoạt động bình thường (Active).";
}

@end

// ============================================================================
// HÀM MAIN TOÀN CỤC CỦA TIẾN TRÌNH
// ============================================================================

int main(int argc, char *argv[]) {
    @autoreleasepool {
        KELEN_MAIN_LOG(@"[Bootstrap] Đang khởi tạo tiến trình thực thi chính của ứng dụng...");
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([HideRLessAppDelegate class]));
    }
}
