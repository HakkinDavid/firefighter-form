package mx.cetys.bomberos

import AutoUpdaterManager
import android.os.Environment
import androidx.annotation.NonNull
import androidx.lifecycle.lifecycleScope
import com.example.autoupdater.UpdateFeatures
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class MainActivity : FlutterActivity() {
  private val CHANNEL = "mx.cetys.bomberos/low_level"
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
              val appVersion = packageInfo.versionName

              release =
                withContext(Dispatchers.IO) {
                  autoUpdaterManager.checkForUpdate(
                    JSONfileURL =
                      "https://github.com/HakkinDavid/firefighter-form/releases/latest/download/metadata.json"
                  )
                }

              val releaseData =
                HashMap<String, Any>().apply {
                  put("current_version", appVersion!!)
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

        "deleteOldAPK" -> {
            lifecycleScope.launch {
                try {
                    val count = 0
                    val downloadsDir = Environment.DIRECTORY_DOWNLOADS

                    downloadsDir.walk()
                        .filter { it.isFile && it.name.startsWith("bomberos-") && it.extension == "apk" }
                        .forEach { file ->
                            file.delete()
                            count++
                        }

                    result.success(count)
                } catch (e: Exception) {
                    result.error("DELETION_ERROR", e.localizedMessage, null)
                }
            }
        }

        else -> result.notImplemented()
      }
    }
  }
}
