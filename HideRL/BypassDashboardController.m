#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#define KELEN_DASHBOARD_PREFS @"/var/mobile/Library/Preferences/com.kelen.masterbypass.plist"
#define KELEN_DASH_LOG(fmt, ...) NSLog((@"HideRLess-Dashboard: " fmt), ##__VA_ARGS__)

@interface BypassDashboardController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
    UITableView *_tableView;
    NSMutableArray *_settingKeysArray;
    NSMutableDictionary *_settingTitlesDict;
    NSMutableDictionary *_settingStatesDict;
}
@end

@implementation BypassDashboardController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"HideRLess - Master Control Panel";
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
    [self setupDataSources];
    [self setupTableView];
    
    // Thêm nút đóng bảng điều khiển
    UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissDashboard)];
    self.navigationItem.rightBarButtonItem = closeButton;
}

- (void)setupDataSources {
    _settingKeysArray = [NSMutableArray arrayWithObjects:
                         @"KelenMasterSwitch",
                         @"KelenHookFileSystem",
                         @"KelenAntiDebugBypass",
                         @"KelenEnvironmentShield",
                         @"KelenNetworkIntercept",
                         @"KelenMemoryProtection",
                         @"KelenDeviceMask",
                         @"KelenKeychainProtection",
                         @"KelenSandboxEscapeShield",
                         @"KelenProcessHiding", nil];
    
    _settingTitlesDict = [NSMutableDictionary dictionaryWithDictionary:@{
        @"KelenMasterSwitch": @"Tổng Công Tắc (Master Bypass)",
        @"KelenHookFileSystem": @"Che Giấu Hệ Thống Tệp (FileSystem)",
        @"KelenAntiDebugBypass": @"Vô Hiệu Hóa Anti-Debugging",
        @"KelenEnvironmentShield": @"Bảo Vệ Môi Trường (Environment)",
        @"KelenNetworkIntercept": @"Chặn & Lọc Luồng Mạng (Network)",
        @"KelenMemoryProtection": @"Bảo Vệ Bộ Nhớ RAM (Memory)",
        @"KelenDeviceMask": @"Giả Mạo Phần Cứng (Device Mask)",
        @"KelenKeychainProtection": @"Cô Lập Khoá Keychain",
        @"KelenSandboxEscapeShield": @"Chặn Thoát Khỏi Sandbox",
        @"KelenProcessHiding": @"Ẩn Danh Tiến Trình (Process)"
    }];
    
    [self loadPreferencesIntoMemory];
}

- (void)loadPreferencesIntoMemory {
    @autoreleasepool {
        NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:KELEN_DASHBOARD_PREFS];
        _settingStatesDict = [NSMutableDictionary dictionary];
        for (NSString *key in _settingKeysArray) {
            id val = prefs ? prefs[key] : nil;
            BOOL state = val ? [val boolValue] : YES;
            _settingStatesDict[key] = @(state);
        }
    }
}

- (void)setupTableView {
    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [self.view addSubview:_tableView];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_settingKeysArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"KelenSwitchCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        UISwitch *switchControl = [[UISwitch alloc] init];
        [switchControl addTarget:self action:@selector(switchStateChanged:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = switchControl;
    }
    
    NSString *key = _settingKeysArray[indexPath.row];
    cell.textLabel.text = _settingTitlesDict[key];
    
    UISwitch *sw = (UISwitch *)cell.accessoryView;
    sw.tag = indexPath.row;
    sw.on = [_settingStatesDict[key] boolValue];
    
    return cell;
}

- (void)switchStateChanged:(UISwitch *)sender {
    NSInteger index = sender.tag;
    if (index >= 0 && index < [_settingKeysArray count]) {
        NSString *key = _settingKeysArray[index];
        _settingStatesDict[key] = @(sender.on);
        
        // Lưu giá trị trực tiếp vào file plist hệ thống
        NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:KELEN_DASHBOARD_PREFS];
        if (!prefs) {
            prefs = [NSMutableDictionary dictionary];
        }
        prefs[key] = @(sender.on);
        [prefs writeToFile:KELEN_DASHBOARD_PREFS atomically:YES];
        
        // Gửi thông báo Darwin Notification để làm mới cấu hình toàn cục ngay lập tức
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFSTR("com.kelen.masterbypass/ReloadPrefs"),
            NULL,
            NULL,
            YES
        );
        
        KELEN_DASHLOG:@"[Dashboard] Đã cập nhật trạng thái công tắc '%@' thành: %@", key, sender.on ? @"Bật" : @"Tắt";
    }
}

- (void)dismissDashboard {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
