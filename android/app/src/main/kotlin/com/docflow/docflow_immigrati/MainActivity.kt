package com.docflow.docflow_immigrati

import android.app.Activity
import android.content.ActivityNotFoundException
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
    private val shareChannelName = "com.docflow.docflow_immigrati/share"
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

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, shareChannelName)
            .setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
                when (call.method) {
                    "shareToWhatsApp" -> shareToWhatsApp(call, result)
                    "shareToEmail" -> shareToEmail(call, result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun fileUri(file: File): Uri {
        val authority = "$packageName.fileprovider"
        return FileProvider.getUriForFile(this, authority, file)
    }

    private fun mimeFor(path: String): String =
        if (path.lowercase().endsWith(".pdf")) "application/pdf" else "image/*"

    private fun shareToWhatsApp(call: MethodCall, result: MethodChannel.Result) {
        val path = call.argument<String>("filePath")
        val text = call.argument<String>("text") ?: ""
        if (path.isNullOrEmpty()) {
            result.error("MISSING_ARG", "filePath required", null); return
        }
        val file = File(path)
        if (!file.exists()) {
            result.error("FILE_NOT_FOUND", "File not found: $path", null); return
        }
        val uri = fileUri(file)
        val candidates = listOf("com.whatsapp", "com.whatsapp.w4b")
        for (pkg in candidates) {
            val intent = Intent(Intent.ACTION_SEND).apply {
                type = mimeFor(path)
                putExtra(Intent.EXTRA_STREAM, uri)
                if (text.isNotEmpty()) putExtra(Intent.EXTRA_TEXT, text)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                setPackage(pkg)
            }
            try {
                startActivity(intent)
                result.success(true); return
            } catch (_: ActivityNotFoundException) {
                continue
            } catch (e: Exception) {
                result.error("SHARE_ERROR", e.message ?: "Unknown error", null); return
            }
        }
        result.error("NOT_INSTALLED", "WhatsApp non è installato su questo dispositivo", null)
    }

    private fun shareToEmail(call: MethodCall, result: MethodChannel.Result) {
        val path = call.argument<String>("filePath")
        val subject = call.argument<String>("subject") ?: ""
        val body = call.argument<String>("body") ?: ""
        if (path.isNullOrEmpty()) {
            result.error("MISSING_ARG", "filePath required", null); return
        }
        val file = File(path)
        if (!file.exists()) {
            result.error("FILE_NOT_FOUND", "File not found: $path", null); return
        }
        val uri = fileUri(file)
        val send = Intent(Intent.ACTION_SEND).apply {
            type = mimeFor(path)
            putExtra(Intent.EXTRA_STREAM, uri)
            if (subject.isNotEmpty()) putExtra(Intent.EXTRA_SUBJECT, subject)
            if (body.isNotEmpty()) putExtra(Intent.EXTRA_TEXT, body)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            selector = Intent(Intent.ACTION_SENDTO).apply { data = Uri.parse("mailto:") }
        }
        try {
            startActivity(Intent.createChooser(send, "Invia via Email"))
            result.success(true)
        } catch (e: ActivityNotFoundException) {
            result.error("NO_EMAIL_APP", "Nessuna app email installata", null)
        } catch (e: Exception) {
            result.error("SHARE_ERROR", e.message ?: "Unknown error", null)
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
