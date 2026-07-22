package com.mobile.pilahapp

import android.media.MediaScannerConnection
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val mediaScannerChannel = "com.mobile.pilahapp/media_scanner"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Writing a file into the public Download directory creates it on disk,
        // but MediaStore does not pick it up on its own — and file manager apps
        // enumerate MediaStore, not the filesystem. Without this the exported
        // report exists at a path nobody can reach: even `ls` on the directory
        // does not list it, because the shell's view of external storage is
        // filtered through the same index.
        //
        // Scanning a file the app itself created needs no permission at any API
        // level, which is what keeps the export prompt-free.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, mediaScannerChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "scan" -> {
                        val path = call.argument<String>("path")
                        if (path == null) {
                            result.error("InvalidArgument", "path was null", null)
                        } else {
                            // mimeTypes is deliberately null: letting the
                            // scanner infer the type from the .xlsx extension
                            // files the entry under MediaStore's Downloads
                            // collection, which is what the Files app lists.
                            // Handing it an explicit type instead lands the row
                            // in the generic files table only, where no file
                            // manager surfaces it.
                            MediaScannerConnection.scanFile(
                                applicationContext,
                                arrayOf(path),
                                null,
                            ) { _, _ ->
                                // Fires on a binder thread once the index holds
                                // the file. The Dart side only waits for the
                                // scan to finish, so the uri goes unused.
                                result.success(null)
                            }
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }
}
