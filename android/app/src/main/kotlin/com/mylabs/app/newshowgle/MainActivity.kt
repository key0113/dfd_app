package com.newdfd.membership

import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Bundle
import android.os.Environment
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import java.io.File

class MainActivity: FlutterActivity() {

    private val APP_CHANNEL = "com.flutter.showgle/plugins"


    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        GeneratedPluginRegistrant.registerWith(flutterEngine!!)
        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, APP_CHANNEL).setMethodCallHandler { call, result ->
            when {
                // Intent 스킴 URL을 안드로이드 웹뷰에서 접근가능하도록 변환
                call.method.equals("getAppUrl") -> {
                    val url: String = call.argument("url")!!
                    val intent = Intent.parseUri(url, Intent.URI_INTENT_SCHEME)
                    result.success(intent.dataString)
                }

                // Intent 스킴 URL을 playStore Market URL로 변환
                call.method.equals("getMarketUrl") -> {
                    val url: String = call.argument("url")!!
                    val packageName = Intent.parseUri(url, Intent.URI_INTENT_SCHEME).getPackage()
                    val marketUrl = Intent(
                        Intent.ACTION_VIEW,
                        Uri.parse("market://details?id=$packageName")
                    )
                    result.success(marketUrl.dataString)
                }

                call.method.equals("getDownloadPath") -> {
                    var savingPath: String? = null
                    val fileName = call.argument<String>("fileName")
                    fileName?.let {
                        val spited = it.split(".")
                        val prefix = spited[0]
                        val suffix = if (spited.size > 1) ".${spited[1]}" else ".tmp"

                        var storageDir = Environment.getExternalStoragePublicDirectory(
                            Environment.DIRECTORY_DOWNLOADS
                        )
                        if (storageDir.canWrite()) {
                            savingPath = File.createTempFile(
                                prefix,  /* prefix */
                                suffix,  /* suffix */
                                storageDir /* directory */
                            ).absolutePath
                        } else {
                            storageDir = context.getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS)
                            if (storageDir.canWrite()) {
                                savingPath = File.createTempFile(
                                    prefix,  /* prefix */
                                    suffix,  /* suffix */
                                    storageDir /* directory */
                                ).absolutePath
                            } else {
                                storageDir = context.filesDir
                                if (storageDir.canWrite()) {
                                    savingPath = File.createTempFile(
                                        prefix,  /* prefix */
                                        suffix,  /* suffix */
                                        storageDir /* directory */
                                    ).absolutePath
                                }
                            }
                        }
                    }
                    result.success(savingPath)
                }
            }
        }
    }
}
