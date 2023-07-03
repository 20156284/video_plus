#import <Flutter/Flutter.h>

@interface VideoPlusPlugin : NSObject<FlutterPlugin, FlutterStreamHandler>

@property int playingCnt;
@property int playableCnt;

+ (VideoPlusPlugin *)singleInstance;

@end

