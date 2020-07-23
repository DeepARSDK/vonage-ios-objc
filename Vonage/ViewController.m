//
//  ViewController.m
//  Vonage
//
//  Created by Luka Mijatovic on 16/07/2020.
//  Copyright © 2020 DeepAR. All rights reserved.
//

#import "ViewController.h"
#import <DeepAR/DeepAR.h>
#import <OpenTok/OpenTok.h>
#import "VideoCapturer.h"

// *** Fill the following variables using your own Project info  ***
// ***          https://dashboard.tokbox.com/projects            ***
// Replace with your OpenTok API key
static NSString* const kApiKey = @"";
// Replace with your generated session ID
static NSString* const kSessionId = @"";
// Replace with your generated token
static NSString* const kToken = @"";

@interface ViewController () <ARViewDelegate, OTSessionDelegate, OTSubscriberKitDelegate, OTPublisherDelegate> {
    OTSession* _session;
    OTPublisher* _publisher;
    OTSubscriber* _subscriber;
    VideoCapturer* _videoCapturer;
}

@property (nonatomic, strong) ARView* arview;
@property (nonatomic, strong) CameraController* cameraController;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _session = [[OTSession alloc] initWithApiKey:kApiKey sessionId:kSessionId delegate:self];

    self.arview = [[ARView alloc] initWithFrame:[UIScreen mainScreen].bounds];

    [self.arview setLicenseKey:@"your_license_key_here"];

    self.arview.delegate = self;
    [self.view insertSubview:self.arview atIndex:0];
    
    self.cameraController = [[CameraController alloc] init];
    self.cameraController.arview = self.arview;

    [self.arview initialize];
    [self.cameraController startCamera];
    
    UIButton* startCall = [[UIButton alloc] init];
    startCall.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:startCall];
    startCall.backgroundColor = UIColor.whiteColor;
    [startCall setTitle:@"Start call" forState:UIControlStateNormal];
    [startCall setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    [startCall.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
    [startCall.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-20].active = YES;
    [startCall.widthAnchor constraintEqualToConstant:100].active = YES;
    [startCall.heightAnchor constraintEqualToConstant:100].active = YES;
    [startCall addTarget:self action:@selector(startCall) forControlEvents:UIControlEventTouchUpInside];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification  object:nil];
}

- (void)orientationChanged:(NSNotification *)notification {
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (orientation == UIInterfaceOrientationLandscapeLeft) {
        self.cameraController.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
    } else if (orientation == UIInterfaceOrientationLandscapeRight) {
        self.cameraController.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
    } else if (orientation == UIInterfaceOrientationPortrait) {
        self.cameraController.videoOrientation = AVCaptureVideoOrientationPortrait;
    } else if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
        self.cameraController.videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
    }
}

- (void)startCall {
    [self doConnect];
}

- (void)doConnect {
    OTError *error = nil;
    [_session connectWithToken:kToken error:&error];
    if (error) {
        NSLog(@"Connect error: %@", error);
    }
}

- (void)doPublishWithARFrame {
    _videoCapturer = [[VideoCapturer alloc] init];
    OTPublisherSettings *settings = [[OTPublisherSettings alloc] init];
    settings.name = [UIDevice currentDevice].name;
    settings.audioTrack = YES;
    settings.videoTrack = YES;
    settings.videoCapture = _videoCapturer;
    _publisher = [[OTPublisher alloc] initWithDelegate:self settings:settings];
    OTError *error = nil;
    [_session publish:_publisher error:&error];
    if (error) {
        NSLog(@"Unable to publish (%@)",
              error.localizedDescription);
    }
}

- (void)doSubscribe:(OTStream*)stream {
    _subscriber = [[OTSubscriber alloc] initWithStream:stream delegate:self];
    OTError *error = nil;
    [_session subscribe:_subscriber error:&error];
    if (error) {
        NSLog(@"Subscribe error: %@", error);
    }
}

- (void)cleanupSubscriber {
    [_subscriber.view removeFromSuperview];
    _subscriber = nil;
}

- (void)cleanupPublisher {
    [_publisher.view removeFromSuperview];
    _publisher = nil;
}


# pragma mark - OTSession delegate callbacks

- (void)sessionDidConnect:(OTSession*)session {
    NSLog(@"sessionDidConnect (%@)", session.sessionId);
    [self doPublishWithARFrame];
}

- (void)sessionDidDisconnect:(OTSession*)session {
    NSString* alertMessage =
    [NSString stringWithFormat:@"Session disconnected: (%@)", session.sessionId];
    NSLog(@"sessionDidDisconnect (%@)", alertMessage);
}

- (void)session:(OTSession*)mySession streamCreated:(OTStream *)stream {
    NSLog(@"session streamCreated (%@)", stream.streamId);
    if (nil == _subscriber) {
        [self doSubscribe:stream];
    }
}

- (void)session:(OTSession*)session streamDestroyed:(OTStream *)stream {
    NSLog(@"session streamDestroyed (%@)", stream.streamId);
    if ([_subscriber.stream.streamId isEqualToString:stream.streamId]) {
        [self cleanupSubscriber];
    }
}

- (void)session:(OTSession *)session connectionCreated:(OTConnection *)connection {
    NSLog(@"session connectionCreated (%@)", connection.connectionId);
}

- (void)session:(OTSession *)session connectionDestroyed:(OTConnection *)connection {
    NSLog(@"session connectionDestroyed (%@)", connection.connectionId);
    if ([_subscriber.stream.connection.connectionId isEqualToString:connection.connectionId]) {
        [self cleanupSubscriber];
    }
}

- (void) session:(OTSession*)session didFailWithError:(OTError*)error {
    NSLog(@"didFailWithError: (%@)", error);
}

# pragma mark - OTSubscriber delegate callbacks

- (void)subscriberDidConnectToStream:(OTSubscriberKit*)subscriber {
     NSLog(@"subscriberDidConnectToStream (%@)", subscriber.stream.connection.connectionId);
    assert(_subscriber == subscriber);
    [_subscriber.view setFrame:CGRectMake(0, 0, 300, 300)];
    [self.view addSubview:_subscriber.view];
}

- (void)subscriber:(OTSubscriberKit*)subscriber didFailWithError:(OTError*)error {
    NSLog(@"subscriber %@ didFailWithError %@", subscriber.stream.streamId, error);
}

# pragma mark - OTPublisher delegate callbacks

- (void)publisher:(OTPublisherKit *)publisher streamCreated:(OTStream *)stream {
    NSLog(@"Publishing");
}

- (void)publisher:(OTPublisherKit*)publisher streamDestroyed:(OTStream *)stream {
    if ([_subscriber.stream.streamId isEqualToString:stream.streamId]) {
        [self cleanupSubscriber];
    }
    [self cleanupPublisher];
}

- (void)publisher:(OTPublisherKit*)publisher didFailWithError:(OTError*)error {
    NSLog(@"publisher didFailWithError %@", error);
    [self cleanupPublisher];
}

# pragma mark - ARViewDelegate

- (void)didFinishPreparingForVideoRecording {
    
}

- (void)didStartVideoRecording {
    
}

- (void)didFinishVideoRecording:(NSString*)videoFilePath {
    
}

- (void)recordingFailedWithError:(NSError*)error {
    
}

- (void)didTakeScreenshot:(UIImage*)screenshot {
    
}

- (void)faceVisiblityDidChange:(BOOL)faceVisible {
    
}

- (void)didInitialize {
    [self.arview switchEffectWithSlot:@"effect" path:[[NSBundle mainBundle] pathForResource:@"lion" ofType:@""]];
    // We use 0 for height which means it will auto calculate height based on the provided width
    [self.arview startFrameOutputWithOutputWidth:640 outputHeight:0 subframe:CGRectMake(0, 0, 1, 1 )];
}

- (void)frameAvailable:(CMSampleBufferRef)sampleBuffer {
    @autoreleasepool {
        CVPixelBufferRef pb = CMSampleBufferGetImageBuffer(sampleBuffer);
        if(_videoCapturer){
            [_videoCapturer pushFrame:pb];
        }
        
        CFRelease(sampleBuffer);
    }
}
@end
