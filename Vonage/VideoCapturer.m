//
//  VideoCapturer.m
//  Vonage
//
//  Created by Luka Mijatovic on 16/07/2020.
//  Copyright © 2020 DeepAR. All rights reserved.
//

#import "VideoCapturer.h"

@interface VideoCapturer ()

@property (nonatomic, assign) BOOL captureStarted;
@property (nonatomic, strong) OTVideoFormat *format;

@end

@implementation VideoCapturer

@synthesize videoCaptureConsumer;

- (void)initCapture {
}

- (void)releaseCapture {
    self.format = nil;
}

- (int32_t)startCapture {
    self.captureStarted = YES;
    return 0;
}

- (int32_t)stopCapture {
    self.captureStarted = NO;
    return 0;
}

- (BOOL)isCaptureStarted {
    return self.captureStarted;
}

- (int32_t)captureSettings:(OTVideoFormat*)videoFormat {
    return 0;
}

- (void)pushFrame:(CVPixelBufferRef)pixelBuffer {
    if (!self.format) {
        size_t width = CVPixelBufferGetWidth(pixelBuffer);
        size_t height = CVPixelBufferGetHeight(pixelBuffer);
        size_t bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
        self.format = [[OTVideoFormat alloc] init];
        self.format.pixelFormat = OTPixelFormatARGB;
        self.format.bytesPerRow = [@[@(bytesPerRow)] mutableCopy];
        self.format.imageHeight = (uint32_t)height;
        self.format.imageWidth = (uint32_t)width;
    }

    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    uint8_t* frameData = (uint8_t*)CVPixelBufferGetBaseAddress(pixelBuffer);
    OTVideoFrame *frame = [[OTVideoFrame alloc] initWithFormat:self.format];
    frame.orientation = OTVideoOrientationUp;
    [frame setPlanesWithPointers:&frameData numPlanes:1];
    [self.videoCaptureConsumer consumeFrame:frame];
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
}
@end
