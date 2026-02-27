package mx.cetys.bomberos

import AutoUpdaterManager
import androidx.annotation.NonNull
import androidx.lifecycle.lifecycleScope
import com.example.autoupdater.UpdateFeatures
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.net.URL

class MainActivity : FlutterActivity() {
  private val CHANNEL = "mx.cetys.bomberos/low_level"
  private val METADATA_URL =
    "https://github.com/HakkinDavid/firefighter-form/releases/latest/download/metadata.json"
  private var release: UpdateFeatures? = null
  private val autoUpdaterManager = AutoUpdaterManager(this)

  override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)

    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
      call,
      result ->
      when (call.method) {
        "isUpdateAvailable" -> {
          lifecycleScope.launch {
            try {
              val packageInfo = packageManager.getPackageInfo(packageName, 0)
              val appVersion = packageInfo.versionName ?: ""

              release =
                withContext(Dispatchers.IO) {
                  autoUpdaterManager.checkForUpdate(JSONfileURL = METADATA_URL)
                    ?: fallbackCheckForUpdate(appVersion)
                }

              val releaseData =
                HashMap<String, Any>().apply {
                  put("current_version", appVersion)
                  if (release == null) {
                    put("available", false)
                  } else {
                    put("available", true)
                    put("latest_version", release!!.latestversion)
                    put("changelog", release!!.changelog)
                    put("apk_url", release!!.apk_url)
                  }
                }

              result.success(releaseData)
            } catch (e: Exception) {
              result.error("UPDATE_ERROR", e.localizedMessage, null)
            }
          }
        }

        "updateApp" -> {
          lifecycleScope.launch {
            try {
              val rel = release
              if (rel == null) {
                result.error(
                  "NO_RELEASE",
                  "No se ha verificado una actualización previamente.",
                  null,
                )
                return@launch
              }

              withContext(Dispatchers.IO) {
                autoUpdaterManager.downloadapk(
                  this@MainActivity,
                  rel.apk_url,
                  "bomberos-android-release-v${rel.latestversion}",
                ) {}
              }

              result.success(true)
            } catch (e: Exception) {
              result.error("DOWNLOAD_ERROR", e.localizedMessage, null)
            }
          }
        }

        else -> result.notImplemented()
      }
    }
  }

  private fun fallbackCheckForUpdate(currentVersion: String): UpdateFeatures? {
    return try {
      val metadataBody = URL(METADATA_URL).readText()
      val metadata = JSONObject(metadataBody)
      val latestVersion =
        metadata.optString("latest_version").ifBlank { metadata.optString("latestversion") }
      val apkUrl = metadata.optString("apk_url")
      if (latestVersion.isBlank() || apkUrl.isBlank() || latestVersion == currentVersion) {
        return null
      }

      val changelog = metadata.optString("changelog")
      UpdateFeatures(changelog, apkUrl, latestVersion)
    } catch (_: Exception) {
      null
    }
  }
}
