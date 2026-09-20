#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HideRLessManager : NSObject {
    NSMutableDictionary *_configurationCache;
    BOOL _isMasterEnabled;
}

+ (instancetype)sharedInstance;
- (nullable id)preferenceValueForKey:(NSString *)key;
- (BOOL)boolPreferenceForKey:(NSString *)key defaultValue:(BOOL)defaultValue;
- (void)refreshCache;

@end

NS_ASSUME_NONNULL_END
