//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <video_plus/video_plus_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) video_plus_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "VideoPlusPlugin");
  video_plus_plugin_register_with_registrar(video_plus_registrar);
}
