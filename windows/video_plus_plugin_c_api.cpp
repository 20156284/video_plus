#include "include/video_plus/video_plus_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "video_plus_plugin.h"

void VideoPlusPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  video_plus::VideoPlusPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
