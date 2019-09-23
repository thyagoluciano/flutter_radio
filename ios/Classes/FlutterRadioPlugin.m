#import "FlutterRadioPlugin.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>

@implementation FlutterRadioPlugin{
    NSURL *audioFileURL;
    AVPlayer *audioPlayer;
    AVPlayerItem *playerItem;
    NSMutableDictionary* songInfo;
    NSTimer *timer;
    NSTimer *dbPeakTimer;
    bool _ready;
    bool _isPlaying;
    NSMutableSet* _listeners;
    int _count;
}
double subscriptionDuration = 1;
FlutterMethodChannel* _channel;

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:@"flutter_radio"
                                     binaryMessenger:[registrar messenger]];
    FlutterRadioPlugin* instance = [[FlutterRadioPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
    _channel = channel;
}

- (instancetype)init {
    if (self = [super init]) {
        AVAudioSession *session = [AVAudioSession sharedInstance];
        [session setActive:YES error:nil];
        [session setCategory:AVAudioSessionCategoryPlayback error:nil];
        
        //setup control center and lock screen controls
        MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
        [commandCenter.togglePlayPauseCommand setEnabled:YES];
        [commandCenter.playCommand setEnabled:YES];
        [commandCenter.pauseCommand setEnabled:YES];
        [commandCenter.stopCommand setEnabled:YES];
        [commandCenter.nextTrackCommand setEnabled:NO];
        [commandCenter.previousTrackCommand setEnabled:NO];
        [commandCenter.changePlaybackRateCommand setEnabled:NO];
        
        [commandCenter.togglePlayPauseCommand addTarget:self action:@selector(controlPlayOrPause)];
        [commandCenter.playCommand addTarget:self action:@selector(controlPlayOrPause)];
        [commandCenter.pauseCommand addTarget:self action:@selector(controlPlayOrPause)];
        [commandCenter.stopCommand addTarget:self action:@selector(controlPlayStop)];
        
        //Unused options
        [commandCenter.skipForwardCommand setEnabled:NO];
        [commandCenter.skipBackwardCommand setEnabled:NO];
        if (@available(iOS 9.0, *)) {
            [commandCenter.enableLanguageOptionCommand setEnabled:NO];
            [commandCenter.disableLanguageOptionCommand setEnabled:NO];
        }
        [commandCenter.changeRepeatModeCommand setEnabled:NO];
        [commandCenter.seekForwardCommand setEnabled:NO];
        [commandCenter.seekBackwardCommand setEnabled:NO];
        [commandCenter.changeShuffleModeCommand setEnabled:NO];
        
        // Rating Command
        [commandCenter.ratingCommand setEnabled:NO];
        
        // Feedback Commands
        // These are generalized to three distinct actions. Your application can provide
        // additional context about these actions with the localizedTitle property in
        // MPFeedbackCommand.
        [commandCenter.likeCommand setEnabled:NO];
        [commandCenter.dislikeCommand setEnabled:NO];
        [commandCenter.bookmarkCommand setEnabled:NO];
        
        _isPlaying = NO;
        _ready = NO;
        
        // Able to play in silent mode
        [[AVAudioSession sharedInstance]
         setCategory: AVAudioSessionCategoryPlayback
         error: nil];
        // Able to play in background
        [[AVAudioSession sharedInstance] setActive: YES error: nil];
        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];

        if (!songInfo) {
            songInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                         @"", MPMediaItemPropertyTitle,
                         nil, MPMediaItemPropertyArtwork,
                         @"", MPMediaItemPropertyAlbumTitle,
                         0, MPMediaItemPropertyPlaybackDuration,
                         [NSNumber numberWithDouble:1.0], MPNowPlayingInfoPropertyPlaybackRate, nil];
        }
    }
    
    return self;
}

- (void)deinit {
    NSLog(@"deinit");
}

- (void) addListener:(id <AudioPlayerListener>) listener {
    NSLog(@"Adding listener: %@", listener);
    [_listeners addObject:listener];
    NSLog(@"added listeners: %@", _listeners);
}

- (void) stopTimer{
    NSLog(@"stopTimer");
    if (timer != nil) {
        [timer invalidate];
        timer = nil;
    }
}

- (void) updateProgress:(NSTimer*) timer {
    NSNumber *duration = [NSNumber numberWithDouble:CMTimeGetSeconds(playerItem.duration) * 1000];
    NSNumber *currentTime = [NSNumber numberWithDouble:CMTimeGetSeconds(playerItem.currentTime) * 1000];
    
    if ([duration intValue] == 0 && timer != nil) {
        [self stopTimer];
        return;
    }
    
    NSString* status = [NSString stringWithFormat:@"{\"duration\": \"%@\", \"current_position\": \"%@\"}", [duration stringValue], [currentTime stringValue]];
    
    [_channel invokeMethod:@"updateProgress" arguments:status];
}

- (void) startTimer {
    NSLog(@"stoarTimer");
    dispatch_async(dispatch_get_main_queue(), ^{
        self->timer = [NSTimer scheduledTimerWithTimeInterval:subscriptionDuration
                                                       target:self
                                                     selector:@selector(updateProgress:)
                                                     userInfo:nil
                                                      repeats:YES];
    });
}

// Flutter stuff:

- (void) handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"play" isEqualToString:call.method]) {
        NSString* path = (NSString*)call.arguments[@"url"];
        [self startPlayer:path result:result];
    } else if ([@"stop" isEqualToString:call.method]) {
        [self stopPlayer:result];
    } else if ([@"pause" isEqualToString:call.method]) {
        [self pausePlayer:result];
    } else if ([@"playOrPause" isEqualToString:call.method]) {
        [self playOrPause:result];
    } else if ([@"setVolume" isEqualToString:call.method]) {
        NSNumber* volume = (NSNumber*)call.arguments[@"volume"];
        [self setVolume:[volume doubleValue] result:result];
    } else if ([@"setMeta" isEqualToString:call.method]) {
        NSDictionary* meta = (NSDictionary*)call.arguments[@"meta"];
        [self setMeta:meta result:result];
    } else if ([@"audioStart" isEqualToString:call.method]) {
        NSDictionary* meta = (NSDictionary*)call.arguments[@"meta"];
        [self setMeta:meta result:result];
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (void) playOrPause:(FlutterResult)result {
    if (audioPlayer) {
        [self playerPlayPause];
    } else {
        result([FlutterError
                errorWithCode:@"Audio Player"
                message:@"player is not set"
                details:nil]);
    }
}

- (void) pausePlayer:(FlutterResult)result {
    if (audioPlayer) {
        [self stopTimer];
        [self playerPause];
        result(@"pause play");
    } else {
        result([FlutterError
                errorWithCode:@"Audio Player"
                message:@"player is not set"
                details:nil]);
    }
}

- (void) stopPlayer:(FlutterResult)result {
    if (audioPlayer) {
        [self stopTimer];
        [self playerStop];
        result(@"stop play");
    } else {
        result([FlutterError
                errorWithCode:@"Audio Player"
                message:@"player is not set"
                details:nil]);
    }
}

- (void) startPlayer:(NSString*)path result: (FlutterResult)result {
    NSLog(@"startPlayer");
    audioFileURL = [NSURL URLWithString:path];
    
    [self playerStart];
    
    NSString *filePath = audioFileURL.absoluteString;
    result(filePath);
}

// todo: remove?
- (void) setVolume:(double) volume result: (FlutterResult)result {
    if (audioPlayer) {
        [audioPlayer setVolume: volume];
        result(@"volume set");
    } else {
        result([FlutterError
                errorWithCode:@"Audio Player"
                message:@"player is not set"
                details:nil]);
    }
}

// todo: remove?
- (void) setMeta:(NSDictionary*) meta result: (FlutterResult)result {
    NSLog(@"setMeta");
    
    if(meta == nil){
        return;
    }
    
    NSString* itemTitle = [meta objectForKey:@"title"];
    NSString* itemAlbum = [meta objectForKey:@"album"];
    NSNumber* duration = [meta objectForKey:@"duration"];
    NSNumber* progress = [meta objectForKey:@"progress"];
    NSString* artist = [meta objectForKey:@"artist"];
    NSString* url = [meta objectForKey:@"url"];
    NSString* defaultImage = [meta objectForKey:@"defaultImage"];
    
    
    MPMediaItemArtwork* ControlArtwork;
    if(([url isKindOfClass:NSNull.class] || url.length <= 0) && defaultImage != nil){
        NSMutableString *filePath = [NSMutableString stringWithString:defaultImage];
        NSString *docsPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *imagePath = [docsPath stringByAppendingPathComponent:filePath];
        NSURL *imageUrl = [NSURL fileURLWithPath:imagePath];
        NSData *imageData = [NSData dataWithContentsOfURL:imageUrl];
        UIImage *shareImage = [UIImage imageWithData:imageData];
        if(shareImage != nil){
            ControlArtwork = [[MPMediaItemArtwork alloc]initWithImage:shareImage];
        }
        
    }else if(![url isKindOfClass:NSNull.class]){
        if (@available(iOS 10.0, *)) {
            ControlArtwork = [[MPMediaItemArtwork alloc] initWithBoundsSize:CGSizeMake(600, 600) requestHandler:^UIImage * _Nonnull(CGSize size) {
                return [UIImage imageWithData: [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: [meta objectForKey:@"url"]]]];
            }];
        } else {
            UIImage* image = [UIImage imageWithData: [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: [meta objectForKey:@"url"]]]];
            ControlArtwork = [[MPMediaItemArtwork alloc] initWithImage: image];
        }
    }

    
    
    
    songInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                         itemTitle, MPMediaItemPropertyTitle,
                         ControlArtwork, MPMediaItemPropertyArtwork,
                         itemAlbum, MPMediaItemPropertyAlbumTitle,
                         artist, MPMediaItemPropertyArtist,
                         duration, MPMediaItemPropertyPlaybackDuration,
                         progress, MPNowPlayingInfoPropertyElapsedPlaybackTime,
                         [NSNumber numberWithDouble:1.0], MPNowPlayingInfoPropertyPlaybackRate, nil];
    [self setNowPlaying];
    
    result(@"meta set");
}

// Native stuff

- (BOOL) playerPlayPause{
    NSLog(@"playerPlayPause");
    if (_isPlaying) {
        NSLog(@"playerPlayPause pause");
        [self playerStop];
        return NO;
    }else{
        NSLog(@"playerPlayPause play");
        [self playerStart];
        return YES;
    }
}

- (void)controlPlayOrPause{
    BOOL isPlaying = [self playerPlayPause];
    NSString * status = @"0";
    if(isPlaying == YES){
        status = @"1";
    }
    NSString* statusStr = [NSString stringWithFormat:@"{\"status\": \"%@\"}", status];
    
    [_channel invokeMethod:@"controlPlayChanged" arguments:statusStr];
}

-(void)controlPlayStop{
    [self playerStop];
    NSString* statusStr = @"{\"status\": \"0\"}";
    
    [_channel invokeMethod:@"controlPlayChanged" arguments:statusStr];
}

- (void) playerStart {
    NSLog(@"playerStart");
    _ready = NO;
    
    AVURLAsset* avAsset = [AVURLAsset URLAssetWithURL:audioFileURL options:nil];
    playerItem = [AVPlayerItem playerItemWithAsset:avAsset];
    audioPlayer = [AVPlayer playerWithPlayerItem:playerItem];
    
    //get audio state and call listeners
    [audioPlayer addObserver:self forKeyPath:@"status" options:0 context:nil];
    [audioPlayer addObserver:self forKeyPath:@"rate" options:0 context:nil];
    
    [self setNowPlaying];
}

- (void) playerPause {
    NSLog(@"playerPause");
    
    if (audioPlayer.currentItem != nil){
        [audioPlayer pause];
    }
    
    for (id<AudioPlayerListener> listener in [_listeners allObjects]) {
        [listener onPlayerPaused];
    }
}

- (void) playerStop {
    NSLog(@"playerStop");
    
    if (audioPlayer.currentItem != nil){
        [audioPlayer pause];
        [audioPlayer removeObserver:self forKeyPath:@"status"];
        [audioPlayer removeObserver:self forKeyPath:@"rate"];
        audioPlayer = nil;
    }
    
    for (id<AudioPlayerListener> listener in [_listeners allObjects]) {
        [listener onPlayerStopped];
    }
    
//    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = nil;
}

- (void) setNowPlaying {
    NSLog(@"setNowPlaying  %@",songInfo);
    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = songInfo;
//    [self startTimer];
}

//region: Observables

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*) context {
    NSLog(@"observeValueForKeyPath: %@", keyPath);
    if ([keyPath isEqualToString:@"status"]) {
        if (audioPlayer.status == AVPlayerStatusReadyToPlay) {
            // Note: we look for the AVPlayerItem's status ready rather than the AVPlayer because this
            // way we know that the duration will be available.
            NSLog(@"observableStatus: AVPlayerStatusReadyToPlay");
            [self _onAudioReady];
        } else if (audioPlayer.status == AVPlayerStatusFailed) {
            NSLog(@"observableStatus: AVPlayerStatusFailed");
            [self _onFailedToPrepareAudio];
        } else {
            NSLog(@"observableStatus: AVPlayerStatusUnknown");
        }
    } else if ([keyPath isEqualToString:@"rate"]) {
        [self _onPlaybackRateChange];
    }
}

- (void) _onAudioReady {
    NSLog(@"_onAudioReady ready: %d", _ready);
    // NSLog(@"_onAudioReady listeners: %@", _listeners);
    if (!_ready) {
        _ready = YES;
        
        for (id<AudioPlayerListener> listener in [_listeners allObjects]) {
            [listener onAudioReady];
        }
        
        [audioPlayer play];
        [self startTimer];
    }
}

- (void) _onFailedToPrepareAudio {
    NSLog(@"AVPlayer failed to load audio");
    
    for (id<AudioPlayerListener> listener in [_listeners allObjects]) {
        [listener onFailedPrepare];
    }
    
}

- (void) _onPlaybackRateChange {
    NSLog(@"Rate just changed to %f", audioPlayer.rate);
    if (audioPlayer.rate > 0 && !_isPlaying) {
        // Just started playing.
        NSLog(@"AVPlayer started playing.");
        for (id<AudioPlayerListener> listener in [_listeners allObjects]) {
            [listener onPlayerPlaying];
        }
        _isPlaying = YES;
    } else if (audioPlayer.rate == 0 && _isPlaying) {
        // Just paused playing.
        NSLog(@"AVPlayer paused playback.");
        for (id<AudioPlayerListener> listener in [_listeners allObjects]) {
            [listener onPlayerPaused];
        }
        _isPlaying = NO;
    }
}

@end
