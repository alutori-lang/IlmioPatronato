package com.docflow.docflow_immigrati

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.MediaStore
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Native bridge for capturing a photo via the system camera intent.
 *
 * The Flutter image_picker plugin returns null silently on some OEM Android
 * builds (HONOR/Magic OS, Huawei EMUI, etc.) because the camera app sends
 * back a non-standard activity result. We bypass image_picker entirely and
 * launch the camera intent ourselves, then surface the resulting file path
 * back to Dart.
 */
class MainActivity : FlutterActivity() {
    private val channelName = "com.docflow.docflow_immigrati/camera_capture"
    private val requestCode = 4242

    private var pendingResult: MethodChannel.Result? = null
    private var pendingFile: File? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
                when (call.method) {
                    "captureImage" -> startCameraCapture(result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun startCameraCapture(result: MethodChannel.Result) {
        if (pendingResult != null) {
            result.error("BUSY", "Another capture is already in progress", null)
            return
        }
        try {
            val outDir = File(cacheDir, "captures").apply { mkdirs() }
            val file = File(outDir, "capture_${System.currentTimeMillis()}.jpg")
            val authority = "$packageName.fileprovider"
            val uri: Uri = FileProvider.getUriForFile(this, authority, file)

            val intent = Intent(MediaStore.ACTION_IMAGE_CAPTURE).apply {
                putExtra(MediaStore.EXTRA_OUTPUT, uri)
                addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            if (intent.resolveActivity(packageManager) == null) {
                result.error("NO_CAMERA_APP", "No camera app available", null)
                return
            }
            pendingResult = result
            pendingFile = file
            startActivityForResult(intent, this.requestCode)
        } catch (e: Exception) {
            result.error("CAPTURE_ERROR", e.message ?: "Unknown error", null)
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == this.requestCode) {
            val res = pendingResult
            val file = pendingFile
            pendingResult = null
            pendingFile = null
            if (res == null) return
            if (resultCode == Activity.RESULT_OK && file != null && file.exists() && file.length() > 0) {
                res.success(file.absolutePath)
            } else {
                res.success(null)
            }
        }
    }
}
