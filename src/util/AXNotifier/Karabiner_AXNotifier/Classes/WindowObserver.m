#import "NotificationKeys.h"
#import "WindowObserver.h"

#define kTargetWindowLaunchpad @"Launchpad"
#define kTargetWindowSpotlight @"Spotlight"
#define kTargetWindowQuicksilver @"Quicksilver"
#define kTargetWindowAlfred @"Alfred"
#define kTargetWindowOmniFocus @"OmniFocus"

@interface WindowObserver ()

@property NSTimer* timer;
@property NSTimer* refreshWindowIDsTimer;
@property NSMutableDictionary* shown;

// targetWindows = { windowID: application type }
//
// For example, { 1234: "Spotlight" }
@property NSMutableDictionary* targetWindows;

// rawWindowIDs should be pointer sized type in order to pass CFArrayCreate.
// (We need to manage long[] in order to put non-object-pointer into CFArray.)
@property long* rawWindowIDs;
@property CFArrayRef cfWindowIDs;

@end

@implementation WindowObserver : NSObject

- (instancetype)init {
  self = [super init];

  if (self) {
    self.shown = [NSMutableDictionary new];
    self.targetWindows = [NSMutableDictionary new];

    self.refreshWindowIDsTimer = [NSTimer scheduledTimerWithTimeInterval:10
                                                                  target:self
                                                                selector:@selector(refreshWindowIDsTimerFireMethod:)
                                                                userInfo:nil
                                                                 repeats:YES];

    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                  target:self
                                                selector:@selector(timerFireMethod:)
                                                userInfo:nil
                                                 repeats:YES];

    [self.refreshWindowIDsTimer fire];
    [self.timer fire];
  }

  return self;
}

- (void)dealloc {
  [self.timer invalidate];

  [self.targetWindows removeAllObjects];
  [self updateCfWindowIDs];
}

- (void)updateCfWindowIDs {
  if (self.cfWindowIDs) {
    CFRelease(self.cfWindowIDs);
    self.cfWindowIDs = NULL;
  }
  if (self.rawWindowIDs) {
    free(self.rawWindowIDs);
    self.rawWindowIDs = NULL;
  }

  NSArray* keys = [self.targetWindows allKeys];
  NSUInteger count = [keys count];
  if (count > 0) {
    self.rawWindowIDs = (long*)(malloc(sizeof(long) * count));
    if (self.rawWindowIDs) {
      for (NSUInteger i = 0; i < count; ++i) {
        self.rawWindowIDs[i] = [keys[i] integerValue];
      }
    }
    self.cfWindowIDs = CFArrayCreate(NULL, (const void**)(self.rawWindowIDs), count, NULL);
  }
}

- (BOOL)isLaunchpad:(NSString*)windowOwnerName
         windowName:(NSString*)windowName
        windowLayer:(NSInteger)windowLayer {
  // For OS X 10.9.
  if ([windowOwnerName isEqualToString:@"Dock"] &&
      [windowName isEqualToString:@"Launchpad"]) {
    return YES;
  }

  // For OS X 10.10.
  //
  // Dock has at least two windows (Dock and Launchpad).
  // When Launchpad is hidden, there is no reliable way to find Launchpad window.
  //
  // The only difference between the Dock window and the Launchpad window is that
  // Dock has kCGWindowName and Launchpad does not have that.
  //
  // But it is not robust way.
  // If we treat windows that does not have kCGWindowName as the Launchpad window,
  // isLaunchpad will always return YES if other window does not have kCGWindowName and is always shown.
  //
  // --------------------------------------------------
  //
  // When Launchpad is shown:
  //
  // com.apple.dock
  // {
  //     kCGWindowAlpha = 1;
  //     kCGWindowBounds =     {
  //         Height = 1200;
  //         Width = 1920;
  //         X = 0;
  //         Y = 0;
  //     };
  //     kCGWindowIsOnscreen = 1;
  //     kCGWindowLayer = 27;
  //     kCGWindowMemoryUsage = 1008;
  //     kCGWindowNumber = 54;
  //     kCGWindowOwnerName = Dock;
  //     kCGWindowOwnerPID = 300;
  //     kCGWindowSharingState = 1;
  //     kCGWindowStoreType = 1;
  // }
  //
  // --------------------------------------------------
  //
  // When Launchpad is hidden:
  //
  // com.apple.dock
  // {
  //     kCGWindowAlpha = 1;
  //     kCGWindowBounds =     {
  //         Height = 1200;
  //         Width = 1920;
  //         X = 0;
  //         Y = 0;
  //     };
  //     kCGWindowLayer = 20;
  //     kCGWindowMemoryUsage = 1008;
  //     kCGWindowNumber = 54;
  //     kCGWindowOwnerName = Dock;
  //     kCGWindowOwnerPID = 300;
  //     kCGWindowSharingState = 1;
  //     kCGWindowStoreType = 1;
  // }
  //
  // --------------------------------------------------
  //
  // The Dock window
  //
  // com.apple.dock
  // {
  //     kCGWindowAlpha = 1;
  //     kCGWindowBounds =     {
  //         Height = 1200;
  //         Width = 1920;
  //         X = 0;
  //         Y = 0;
  //     };
  //     kCGWindowIsOnscreen = 1;
  //     kCGWindowLayer = 20;
  //     kCGWindowMemoryUsage = 1008;
  //     kCGWindowName = Dock;
  //     kCGWindowNumber = 55;
  //     kCGWindowOwnerName = Dock;
  //     kCGWindowOwnerPID = 300;
  //     kCGWindowSharingState = 1;
  //     kCGWindowStoreType = 1;
  // }

  return NO;
}

- (BOOL)isSpotlight:(NSString*)windowOwnerName
         windowName:(NSString*)windowName
        windowLayer:(NSInteger)windowLayer {
  if ([windowOwnerName isEqualToString:@"Spotlight"] &&
      [windowName isEqualToString:@"Spotlight"]) {

    // There is no reliable public specifications for kCGWindowLayer.
    // So, we use magic numbers that are confirmed by "warp-mouse-cursor-position".

    // Ignore Spotlight in statusbar.
    if (0 < windowLayer && windowLayer < 25) {
      return YES;
    }
  }

  return NO;
}

- (BOOL)isQuicksilver:(NSString*)windowOwnerName
           windowName:(NSString*)windowName
          windowLayer:(NSInteger)windowLayer {
  // Ignore Quicksilver in statusbar.
  if ([windowOwnerName isEqualToString:@"Quicksilver"] &&
      windowLayer == 101) {
    return YES;
  }

  return NO;
}

- (BOOL)isAlfred:(NSString*)windowOwnerName
      windowName:(NSString*)windowName
     windowLayer:(NSInteger)windowLayer {
  // Ignore Alfred in statusbar.
  if ([windowOwnerName isEqualToString:@"Alfred 2"] &&
      windowLayer == 27) {
    return YES;
  }

  return NO;
}

- (BOOL)isOmniFocus:(NSString*)windowOwnerName
         windowName:(NSString*)windowName
        windowLayer:(NSInteger)windowLayer {
  if ([windowOwnerName isEqualToString:@"OmniFocus"] &&
      windowLayer == 8) {
    return YES;
  }

  return NO;
}

- (void)refreshWindowIDsTimerFireMethod:(NSTimer*)timer {
  dispatch_async(dispatch_get_main_queue(), ^{
    @synchronized(self) {
      // ----------------------------------------
      // update targetWindows_.
      [self.targetWindows removeAllObjects];

      NSArray* windows = (__bridge_transfer NSArray*)(CGWindowListCopyWindowInfo(kCGWindowListOptionAll,
                                                                                 kCGNullWindowID));
      for (NSDictionary* window in windows) {
        NSString* windowOwnerName = window[(__bridge NSString*)(kCGWindowOwnerName)];
        NSString* windowName = window[(__bridge NSString*)(kCGWindowName)];
        NSInteger windowLayer = [window[(__bridge NSString*)(kCGWindowLayer)] integerValue];

        if ([self isLaunchpad:windowOwnerName
                   windowName:windowName
                  windowLayer:windowLayer]) {
          NSInteger windowNumber = [window[(__bridge NSString*)(kCGWindowNumber)] unsignedIntValue];
          self.targetWindows[@(windowNumber)] = kTargetWindowLaunchpad;
        }

        if ([self isSpotlight:windowOwnerName
                   windowName:windowName
                  windowLayer:windowLayer]) {
          NSInteger windowNumber = [window[(__bridge NSString*)(kCGWindowNumber)] unsignedIntValue];
          self.targetWindows[@(windowNumber)] = kTargetWindowSpotlight;
        }

        if ([self isQuicksilver:windowOwnerName
                     windowName:windowName
                    windowLayer:windowLayer]) {
          NSInteger windowNumber = [window[(__bridge NSString*)(kCGWindowNumber)] unsignedIntValue];
          self.targetWindows[@(windowNumber)] = kTargetWindowQuicksilver;
        }

        if ([self isAlfred:windowOwnerName
                 windowName:windowName
                windowLayer:windowLayer]) {
          NSInteger windowNumber = [window[(__bridge NSString*)(kCGWindowNumber)] unsignedIntValue];
          self.targetWindows[@(windowNumber)] = kTargetWindowAlfred;
        }

        if ([self isOmniFocus:windowOwnerName
                   windowName:windowName
                  windowLayer:windowLayer]) {
          NSInteger windowNumber = [window[(__bridge NSString*)(kCGWindowNumber)] unsignedIntValue];
          self.targetWindows[@(windowNumber)] = kTargetWindowOmniFocus;
        }
      }

      // ----------------------------------------
      [self updateCfWindowIDs];
    }
  });
}

- (void)timerFireMethod:(NSTimer*)timer {
  dispatch_async(dispatch_get_main_queue(), ^{
    @synchronized(self) {
      if (self.cfWindowIDs) {
        NSArray* windows = (__bridge_transfer NSArray*)(CGWindowListCreateDescriptionFromArray(self.cfWindowIDs));
        for (NSDictionary* window in windows) {
          pid_t windowOwnerPID = [window[(__bridge NSString*)(kCGWindowOwnerPID)] intValue];
          long windowNumber = [window[(__bridge NSString*)(kCGWindowNumber)] unsignedIntValue];
          BOOL isOnScreen = [window[(__bridge NSString*)(kCGWindowIsOnscreen)] boolValue];

          NSString* key = self.targetWindows[@(windowNumber)];
          if (key) {
            if (isOnScreen) {
              if (!self.shown[key]) {
                NSString* bundleIdentifier = [[NSRunningApplication runningApplicationWithProcessIdentifier:windowOwnerPID] bundleIdentifier];
                if (bundleIdentifier) {
                  self.shown[key] = bundleIdentifier;
                  [self postNotification:key bundleIdentifier:self.shown[key] visibility:YES];
                }
              }
              return;
            }
          }
        }
      }

      // ----------------------------------------
      // There is no target window in screen.

      for (NSString* key in self.shown) {
        if (self.shown[key]) {
          [self postNotification:key bundleIdentifier:self.shown[key] visibility:NO];
        }
      }
      [self.shown removeAllObjects];
    }
  });
}

- (void)postNotification:(NSString*)windowName bundleIdentifier:(NSString*)bundleIdentifier visibility:(BOOL)visibility {
  NSDictionary* userInfo = @{
    @"bundleIdentifier" : bundleIdentifier,
    @"windowName" : windowName,
    @"role" : @"",
    @"visibility" : @(visibility),
  };
  [[NSNotificationCenter defaultCenter] postNotificationName:kWindowVisibilityChanged object:self userInfo:userInfo];
}

@end
