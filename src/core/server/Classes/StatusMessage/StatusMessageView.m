// -*- Mode: objc -*-

#import "PreferencesKeys.h"
#import "StatusMessageView.h"

@implementation StatusMessageView

- (void)updateMessage:(NSString*)message {
  [self.message setStringValue:message];
  [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
  NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
  NSInteger theme = [defaults integerForKey:kStatusWindowTheme];

  // Background
  [NSGraphicsContext saveGraphicsState];
  {
    NSRect bounds = [self bounds];
    switch (theme) {
    case 1:
      // Black
      [self.message setTextColor:[NSColor whiteColor]];
      [[NSColor blackColor] set];
      break;

    case 3:
      // Blue
      [self.message setTextColor:[NSColor whiteColor]];
      [[NSColor blueColor] set];
      break;

    case 4:
      // Brown
      [self.message setTextColor:[NSColor whiteColor]];
      [[NSColor brownColor] set];
      break;

    case 5:
      // Cyan
      [self.message setTextColor:[NSColor blackColor]];
      [[NSColor cyanColor] set];
      break;

    case 6:
      // Green
      [self.message setTextColor:[NSColor blackColor]];
      [[NSColor greenColor] set];
      break;

    case 7:
      // Magenta
      [self.message setTextColor:[NSColor whiteColor]];
      [[NSColor magentaColor] set];
      break;

    case 8:
      // Orange
      [self.message setTextColor:[NSColor blackColor]];
      [[NSColor orangeColor] set];
      break;

    case 9:
      // Purple
      [self.message setTextColor:[NSColor whiteColor]];
      [[NSColor purpleColor] set];
      break;

    case 10:
      // Red
      [self.message setTextColor:[NSColor whiteColor]];
      [[NSColor redColor] set];
      break;

    case 11:
      // Yellow
      [self.message setTextColor:[NSColor blackColor]];
      [[NSColor yellowColor] set];
      break;

    default:
      // White
      [self.message setTextColor:[NSColor blackColor]];
      [[NSColor whiteColor] set];
      break;
    }
    [[NSBezierPath bezierPathWithRoundedRect:bounds xRadius:10 yRadius:10] fill];
  }
  [NSGraphicsContext restoreGraphicsState];
}

- (void)updateWindowFrame:(NSScreen*)screen {
  NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
  NSInteger position = [defaults integerForKey:kStatusWindowPosition];

  NSRect screenFrame = [screen visibleFrame];
  NSRect windowFrame = [[self window] frame];
  int margin = 10;
  NSPoint point;

  switch (position) {
  case 0:
    // Top left
    point.x = screenFrame.origin.x + margin;
    point.y = screenFrame.origin.y + screenFrame.size.height - windowFrame.size.height - margin;
    break;
  case 1:
    // Top right
    point.x = screenFrame.origin.x + screenFrame.size.width - windowFrame.size.width - margin;
    point.y = screenFrame.origin.y + screenFrame.size.height - windowFrame.size.height - margin;
    break;
  case 2:
    // Bottom left
    point.x = screenFrame.origin.x + margin;
    point.y = screenFrame.origin.y + margin;
    break;
  case 3:
  default:
    // Bottom right
    point.x = screenFrame.origin.x + screenFrame.size.width - windowFrame.size.width - margin;
    point.y = screenFrame.origin.y + margin;
    break;
  }

  [[self window] setFrameOrigin:point];
}

@end
