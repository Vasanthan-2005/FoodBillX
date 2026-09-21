package com.example.mobile

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.foodbillx.app/apk_installer"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "canRequestPackageInstalls" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        result.success(packageManager.canRequestPackageInstalls())
                    } else {
                        result.success(true)
                    }
                }
                "openInstallPermissionSettings" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        try {
                            val intent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
                                data = Uri.parse("package:$packageName")
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            val intent = Intent(Settings.ACTION_SECURITY_SETTINGS)
                            startActivity(intent)
                            result.success(true)
                        }
                    } else {
                        result.success(true)
                    }
                }
                "installApk" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath != null) {
                        val file = File(filePath)
                        if (file.exists()) {
                            try {
                                val contentUri: Uri = FileProvider.getUriForFile(
                                    context,
                                    "$packageName.fileProvider",
                                    file
                                )
                                val intent = Intent(Intent.ACTION_VIEW).apply {
                                    setDataAndType(contentUri, "application/vnd.android.package-archive")
                                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION
                                }
                                startActivity(intent)
                                result.success(true)
                            } catch (e: Exception) {
                                result.error("INSTALL_ERROR", e.message, null)
                            }
                        } else {
                            result.error("FILE_NOT_FOUND", "APK file not found: $filePath", null)
                        }
                    } else {
                        result.error("INVALID_PATH", "File path parameter missing", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
