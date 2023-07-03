//
//  VideoPlusHostOption.m
//  video_plus
//
//  Created by Will on 3/7/2023.
//

#import "VideoPlusHostOption.h"

@implementation VideoPlusHostOption{
    NSMutableDictionary<NSString *, NSNumber *> *_intOption;

    NSMutableDictionary<NSString *, NSString *> *_strOption;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _intOption = [[NSMutableDictionary alloc] init];
        _strOption = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)setIntValue:(NSNumber *)value forKey:(NSString *)key {
    _intOption[key] = value;
}

- (void)setStrValue:(NSString *)value forKey:(NSString *)key {
    _strOption[key] = value;
}

- (NSNumber *)getIntValue:(NSString *)key defalt:(NSNumber *)defalt {
    NSNumber *value = defalt;
    if ([_intOption objectForKey:key] != nil) {
        value = [_intOption objectForKey:key];
    }
    return value;
}

- (NSString *)getStrValue:(NSString *)key defalt:(NSString *)defalt {
    NSString *value = defalt;
    if ([_strOption objectForKey:key] != nil) {
        value = [_strOption objectForKey:key];
    }
    return value;
}

@end
