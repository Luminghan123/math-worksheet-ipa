//
//  Generated file. Do not edit.
//
// 说明：`flutter pub get` 通常会重新生成本文件（注册 printing /
// shared_preferences）。这里保留一份「条件编译 + 仅注册 printing」的兜底版本：
//   - 不引用任何旧项目插件（MLKit / sqflite / image_picker），避免引用不存在的类
//   - 用 __has_include 保护，头文件不存在时退回 @import，编译一定能过
//   - 万一 pub get 未覆盖，核心的 Printing.sharePdf 仍然可用
//

// clang-format off

#import "GeneratedPluginRegistrant.h"

#if __has_include(<printing/PrintingPlugin.h>)
#import <printing/PrintingPlugin.h>
#else
@import printing;
#endif

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  [PrintingPlugin registerWithRegistrar:[registry registrarForPlugin:@"PrintingPlugin"]];
}

@end
