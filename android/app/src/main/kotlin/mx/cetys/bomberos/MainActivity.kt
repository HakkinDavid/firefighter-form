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

class MainActivity : FlutterActivity() {
  private val CHANNEL = "mx.cetys.bomberos/low_level"
  private var release: UpdateFeatures? = null
  private val autoUpdaterManager = AutoUpdaterManager(this)

  override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
      call,
      result ->
      if (call.method == "isUpdateAvailable") {
        val packageInfo = packageManager.getPackageInfo(packageName, 0)
        val appVersion = packageInfo.versionName
        val releaseData = HashMap<String, Any>()
        lifecycleScope.launch {
          withContext(Dispatchers.IO) {
            release =
              autoUpdaterManager.checkForUpdate(
                JSONfileURL =
                  "https://github.com/HakkinDavid/firefighter-form/releases/latest/download/metadata.json"
              )
            if (release == null) {
              releaseData["available"] = false
              releaseData["current_version"] = appVersion!!
            } else {
              releaseData["available"] = true
              releaseData["current_version"] = appVersion!!
              releaseData["latest_version"] = release!!.latestversion
              releaseData["changelog"] = release!!.changelog
              releaseData["apk_url"] = release!!.apk_url
            }
            result.success(releaseData)
          }
        }
      } else if (call.method == "updateApp") {
        lifecycleScope.launch {
          withContext(Dispatchers.IO) {
            autoUpdaterManager.downloadapk(
              this@MainActivity,
              release!!.apk_url,
              "bomberos-android-release-v${release!!.latestversion}",
            ) {}
            result.success(true)
          }
        }
      } else {
        result.notImplemented()
      }
    }
  }
}
