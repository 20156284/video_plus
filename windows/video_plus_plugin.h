#ifndef FLUTTER_PLUGIN_VIDEO_PLUS_PLUGIN_H_
#define FLUTTER_PLUGIN_VIDEO_PLUS_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace video_plus {

class VideoPlusPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  VideoPlusPlugin();

  virtual ~VideoPlusPlugin();

  // Disallow copy and assign.
  VideoPlusPlugin(const VideoPlusPlugin&) = delete;
  VideoPlusPlugin& operator=(const VideoPlusPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace video_plus

#endif  // FLUTTER_PLUGIN_VIDEO_PLUS_PLUGIN_H_
