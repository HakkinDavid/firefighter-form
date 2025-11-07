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
  private var update: UpdateFeatures? = null
  private val autoUpdaterManager = AutoUpdaterManager(this)

  override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
      call,
      result ->
      if (call.method == "isUpdateAvailable") {
        val updateData = HashMap<String, Any>()
        lifecycleScope.launch {
          withContext(Dispatchers.IO) {
            update =
              autoUpdaterManager.checkForUpdate(
                JSONfileURL =
                  "https://github.com/HakkinDavid/firefighter-form/releases/latest/download/metadata.json"
              )
          }
        }
        if (update == null) {
          updateData["available"] = false
        } else {
          updateData["available"] = true
          updateData["latest_version"] = update!!.latestversion
          updateData["changelog"] = update!!.changelog
          updateData["apk_url"] = update!!.apk_url
        }
        result.success(updateData)
      } else if (call.method == "updateNow") {
        lifecycleScope.launch {
          withContext(Dispatchers.IO) {
            autoUpdaterManager.downloadapk(this@MainActivity, update!!.apk_url, "bomberos") {
                
            }
          }
        }
        result.success(true)
      } else {
        result.notImplemented()
      }
    }
  }
}
