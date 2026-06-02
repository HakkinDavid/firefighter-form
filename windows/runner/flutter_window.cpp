#include "flutter_window.h"

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <shellapi.h>
#include <urlmon.h>
#include <windows.h>

#include <filesystem>
#include <fstream>
#include <optional>
#include <regex>
#include <sstream>
#include <string>

#include "flutter/generated_plugin_registrant.h"

namespace {

constexpr char kLowLevelChannel[] = "mx.cetys.bomberos/low_level";
constexpr wchar_t kMetadataUrl[] =
    L"https://github.com/HakkinDavid/firefighter-form/releases/latest/download/metadata.json";

std::wstring Utf16FromUtf8(const std::string& utf8_string) {
  if (utf8_string.empty()) {
    return std::wstring();
  }
  int target_length = ::MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS,
                                            utf8_string.c_str(),
                                            (int)utf8_string.size(), nullptr,
                                            0);
  if (target_length <= 0) {
    return std::wstring();
  }
  std::wstring utf16_string;
  utf16_string.resize(target_length);
  ::MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, utf8_string.c_str(),
                        (int)utf8_string.size(), utf16_string.data(),
                        target_length);
  return utf16_string;
}

std::wstring GetTempPathForFile(const std::wstring& filename) {
  wchar_t temp_path[MAX_PATH];
  DWORD length = ::GetTempPathW(MAX_PATH, temp_path);
  if (length == 0 || length > MAX_PATH) {
    return filename;
  }
  return std::filesystem::path(temp_path).append(filename).wstring();
}

std::string ReadFileUtf8(const std::wstring& path) {
  std::ifstream file(path, std::ios::binary);
  if (!file) {
    return std::string();
  }
  std::ostringstream contents;
  contents << file.rdbuf();
  return contents.str();
}

std::string JsonStringValue(const std::string& json, const std::string& key) {
  std::regex pattern("\"" + key + "\"\\s*:\\s*\"((?:\\\\.|[^\"])*)\"");
  std::smatch match;
  if (!std::regex_search(json, match, pattern)) {
    return std::string();
  }

  std::string value = match[1].str();
  std::string unescaped;
  unescaped.reserve(value.size());
  for (size_t i = 0; i < value.size(); ++i) {
    if (value[i] != '\\' || i + 1 >= value.size()) {
      unescaped.push_back(value[i]);
      continue;
    }

    char escaped = value[++i];
    switch (escaped) {
      case 'n':
        unescaped.push_back('\n');
        break;
      case 'r':
        unescaped.push_back('\r');
        break;
      case 't':
        unescaped.push_back('\t');
        break;
      default:
        unescaped.push_back(escaped);
        break;
    }
  }
  return unescaped;
}

std::string FirstJsonStringValue(const std::string& json,
                                 std::initializer_list<const char*> keys) {
  for (const char* key : keys) {
    std::string value = JsonStringValue(json, key);
    if (!value.empty()) {
      return value;
    }
  }
  return std::string();
}

std::string CurrentAppVersion() {
  return FLUTTER_VERSION;
}

std::filesystem::path CurrentExecutablePath() {
  wchar_t path[MAX_PATH];
  DWORD length = ::GetModuleFileNameW(nullptr, path, MAX_PATH);
  if (length == 0 || length == MAX_PATH) {
    return std::filesystem::path();
  }
  return std::filesystem::path(path);
}

bool DownloadFile(const std::wstring& url, const std::wstring& destination) {
  ::DeleteFileW(destination.c_str());
  HRESULT result =
      ::URLDownloadToFileW(nullptr, url.c_str(), destination.c_str(), 0, nullptr);
  return SUCCEEDED(result);
}

std::wstring PowerShellSingleQuoted(const std::wstring& value) {
  std::wstring quoted = L"'";
  for (wchar_t character : value) {
    quoted.push_back(character);
    if (character == L'\'') {
      quoted.push_back(L'\'');
    }
  }
  quoted.push_back(L'\'');
  return quoted;
}

bool WriteUpdaterScript(const std::wstring& script_path,
                        const std::filesystem::path& app_directory,
                        const std::filesystem::path& executable_path,
                        const std::wstring& zip_path,
                        DWORD current_pid) {
  std::wofstream script(script_path.c_str(), std::ios::binary);
  if (!script) {
    return false;
  }

  std::wstring extract_path =
      GetTempPathForFile(L"bomberos-windows-update-extracted");

  script << L"$ErrorActionPreference = 'Stop'\n"
         << L"$zip = " << PowerShellSingleQuoted(zip_path) << L"\n"
         << L"$extract = " << PowerShellSingleQuoted(extract_path) << L"\n"
         << L"$target = " << PowerShellSingleQuoted(app_directory.wstring())
         << L"\n"
         << L"$exe = " << PowerShellSingleQuoted(executable_path.wstring())
         << L"\n"
         << L"Wait-Process -Id " << current_pid << L"\n"
         << L"Remove-Item $extract -Recurse -Force -ErrorAction SilentlyContinue\n"
         << L"New-Item -ItemType Directory -Path $extract -Force | Out-Null\n"
         << L"Expand-Archive -Path $zip -DestinationPath $extract -Force\n"
         << L"Copy-Item -Path (Join-Path $extract '*') -Destination $target "
            L"-Recurse -Force\n"
         << L"Start-Process -FilePath $exe\n";

  return true;
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
  RegisterPlugins(flutter_controller_->engine());

  flutter::MethodChannel<flutter::EncodableValue> channel(
      flutter_controller_->engine()->messenger(), kLowLevelChannel,
      &flutter::StandardMethodCodec::GetInstance());

  channel.SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                 result) {
        if (call.method_name() == "isUpdateAvailable") {
          std::wstring metadata_path =
              GetTempPathForFile(L"bomberos-update-metadata.json");

          if (!DownloadFile(kMetadataUrl, metadata_path)) {
            result->Error("UPDATE_ERROR", "No se pudo descargar metadata.json.");
            return;
          }

          std::string metadata = ReadFileUtf8(metadata_path);
          latest_version_ =
              FirstJsonStringValue(metadata, {"latest_version", "latestversion"});
          latest_changelog_ = JsonStringValue(metadata, "changelog");
          latest_windows_url_ = FirstJsonStringValue(
              metadata, {"windows_url", "installer_url", "exe_url", "msi_url"});

          flutter::EncodableMap release_data;
          release_data[flutter::EncodableValue("current_version")] =
              flutter::EncodableValue(CurrentAppVersion());

          if (latest_version_.empty() || latest_windows_url_.empty()) {
            latest_version_.clear();
            latest_changelog_.clear();
            latest_windows_url_.clear();
            release_data[flutter::EncodableValue("available")] =
                flutter::EncodableValue(false);
          } else {
            release_data[flutter::EncodableValue("available")] =
                flutter::EncodableValue(true);
            release_data[flutter::EncodableValue("latest_version")] =
                flutter::EncodableValue(latest_version_);
            release_data[flutter::EncodableValue("changelog")] =
                flutter::EncodableValue(latest_changelog_);
            release_data[flutter::EncodableValue("windows_url")] =
                flutter::EncodableValue(latest_windows_url_);
          }

          result->Success(flutter::EncodableValue(release_data));
          return;
        }

        if (call.method_name() == "updateApp") {
          if (latest_windows_url_.empty() || latest_version_.empty()) {
            result->Error(
                "NO_RELEASE",
                "No se ha verificado una actualización previamente.");
            return;
          }

          std::wstring zip_path = GetTempPathForFile(
              Utf16FromUtf8("bomberos-windows-release-v" + latest_version_ +
                            ".zip"));
          if (!DownloadFile(Utf16FromUtf8(latest_windows_url_), zip_path)) {
            result->Error("DOWNLOAD_ERROR",
                          "No se pudo descargar la actualización de Windows.");
            return;
          }

          std::filesystem::path executable_path = CurrentExecutablePath();
          if (executable_path.empty()) {
            result->Error("UPDATE_ERROR",
                          "No se pudo ubicar el ejecutable actual.");
            return;
          }

          std::wstring script_path =
              GetTempPathForFile(L"bomberos-windows-update.ps1");
          if (!WriteUpdaterScript(script_path, executable_path.parent_path(),
                                  executable_path, zip_path,
                                  ::GetCurrentProcessId())) {
            result->Error("UPDATE_ERROR",
                          "No se pudo preparar el instalador de Windows.");
            return;
          }

          std::wstring parameters =
              L"-NoProfile -ExecutionPolicy Bypass -File " +
              PowerShellSingleQuoted(script_path);
          HINSTANCE shell_result = ::ShellExecuteW(
              nullptr, L"open", L"powershell.exe", parameters.c_str(), nullptr,
              SW_HIDE);

          if (reinterpret_cast<intptr_t>(shell_result) <= 32) {
            result->Error("UPDATE_ERROR",
                          "No se pudo iniciar el instalador de Windows.");
            return;
          }

          result->Success(flutter::EncodableValue(true));
          ::PostMessage(GetHandle(), WM_CLOSE, 0, 0);
          return;
        }

        result->NotImplemented();
      });

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
