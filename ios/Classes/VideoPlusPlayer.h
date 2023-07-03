//
//  VideoPlusPlayer.h
//  video_plus
//
//  Created by Will on 3/7/2023.
//

#import <Foundation/Foundation.h>
#import <IJKMediaPlayer/IJKMediaPlayer.h>

#import <Flutter/FlutterPlugin.h>

NS_ASSUME_NONNULL_BEGIN

@interface VideoPlusPlayer : NSObject<FlutterStreamHandler, IJKMPEventHandler,FlutterTexture, IJKCVPBViewProtocol>

@property(atomic, readonly) NSNumber *playerId;

- (instancetype)initWithRegistrar:(id<FlutterPluginRegistrar>)registrar;

- (instancetype)initJustTexture;

- (void)shutdown;
@end

NS_ASSUME_NONNULL_END
