#import "FlutterRadioPlugin.h"
#import <flutter_radio/flutter_radio-Swift.h>

@implementation FlutterRadioPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterRadioPlugin registerWithRegistrar:registrar];
}
@end
