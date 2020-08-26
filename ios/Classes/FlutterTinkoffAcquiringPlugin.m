#import "FlutterTinkoffAcquiringPlugin.h"
#if __has_include(<flutter_tinkoff_acquiring/flutter_tinkoff_acquiring-Swift.h>)
#import <flutter_tinkoff_acquiring/flutter_tinkoff_acquiring-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_tinkoff_acquiring-Swift.h"
#endif

@implementation FlutterTinkoffAcquiringPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterTinkoffAcquiringPlugin registerWithRegistrar:registrar];
}
@end
