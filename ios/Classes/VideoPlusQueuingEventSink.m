//
//  VideoPlusQueuingEventSink.m
//  video_plus
//
//  Created by Will on 3/7/2023.
//

#import "VideoPlusQueuingEventSink.h"

@implementation VideoPlusQueuingEventSink {
    NSMutableArray *_eventQueue;
    BOOL _done;
    FlutterEventSink _delegate;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _delegate = nil;
        _done = false;
        _eventQueue = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)maybeFlush {
    if (_delegate == nil)
        return;

    for (NSObject *event in _eventQueue) {
        _delegate(event);
    }
    [_eventQueue removeAllObjects];
}

- (void)enqueue:(const NSObject *)event {
    if (_done)
        return;
    [_eventQueue addObject:event];
}

- (void)setDelegate:(FlutterEventSink)sink {
    _delegate = sink;
    [self maybeFlush];
}

- (void)endOfStream {
    [self enqueue:FlutterEndOfEventStream];
    [self maybeFlush];
    _done = TRUE;
}

- (void)error:(NSString *)code
      message:(NSString *_Nullable)message
      details:(id _Nullable)details {
    [self enqueue:[FlutterError errorWithCode:code
                                      message:message
                                      details:details]];
    [self maybeFlush];
}

- (void)success:(NSObject *)event {
    [self enqueue:event];
    [self maybeFlush];
}

- (void)dealloc {
    if (_eventQueue) {
        [_eventQueue removeAllObjects];
        _eventQueue = nil;
    }
}

@end
