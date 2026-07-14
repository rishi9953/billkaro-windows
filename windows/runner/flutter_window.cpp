#include "flutter_window.h"

#include <optional>
#include <exception>
#include <string>

#include "flutter/generated_plugin_registrant.h"

namespace {

// Isolated so MSVC can use SEH without conflicting with C++ object unwinding
// in FlutterWindow::OnCreate (error C2712).
void RegisterPluginsSafely(flutter::FlutterEngine* engine) {
#if defined(_MSC_VER)
  __try {
    RegisterPlugins(engine);
  } __except (EXCEPTION_EXECUTE_HANDLER) {
    OutputDebugStringA("Plugin registration failed with SEH exception.\n");
  }
#else
  try {
    RegisterPlugins(engine);
  } catch (const std::exception& e) {
    OutputDebugStringA(
        ("Plugin registration failed: " + std::string(e.what()) + "\n")
            .c_str());
  } catch (...) {
    OutputDebugStringA("Plugin registration failed with unknown exception.\n");
  }
#endif
}

}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  // Some Windows plugins may throw / AV during registration on LTSC / value
  // images (missing BLE radios, COM mismatches, missing runtimes). Guard both
  // C++ exceptions and SEH so the app can still open.
  RegisterPluginsSafely(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
