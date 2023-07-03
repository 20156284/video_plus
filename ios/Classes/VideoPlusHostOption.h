//
//  VideoPlusHostOption.h
//  video_plus
//
//  Created by Will on 3/7/2023.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
#define FIJK_HOST_OPTION_REQUEST_SCREENON @"request-screen-on"
#define FIJK_HOST_OPTION_ENABLE_SNAPSHOT  @"enable-snapshot"

@interface VideoPlusHostOption : NSObject
- (void)setIntValue:(NSNumber *)value forKey:(NSString *)key;

- (void)setStrValue:(NSString *)value forKey:(NSString *)key;

- (NSNumber *)getIntValue:(NSString *)kay defalt:(NSNumber *)defalt;

- (NSString *)getStrValue:(NSString *)key defalt:(NSString *)defalt;
@end

NS_ASSUME_NONNULL_END
