//
//  VideoCapturer.h
//  Vonage
//
//  Created by Luka Mijatovic on 16/07/2020.
//  Copyright © 2020 DeepAR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenTok/OpenTok.h>

NS_ASSUME_NONNULL_BEGIN

@interface VideoCapturer : NSObject<OTVideoCapture>

-(void)pushFrame:(CVPixelBufferRef)pixelBuffer;

@end

NS_ASSUME_NONNULL_END
