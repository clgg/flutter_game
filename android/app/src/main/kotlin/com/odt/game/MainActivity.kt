package com.odt.game

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.PrintWriter
import java.io.StringWriter
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class MainActivity: FlutterActivity() {
    private val crashLogChannel = "com.odt.game/crash_logs"
    private var previousExceptionHandler: Thread.UncaughtExceptionHandler? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        installNativeCrashHandler()
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            crashLogChannel
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getCrashLogDirectory" -> result.success(crashLogDirectory().absolutePath)
                "shareCrashLog" -> {
                    val path = call.argument<String>("path")
                    if (path.isNullOrBlank()) {
                        result.error("invalid_path", "Crash log path is empty.", null)
                    } else {
                        shareCrashLog(path, result)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun installNativeCrashHandler() {
        if (previousExceptionHandler != null) {
            return
        }
        previousExceptionHandler = Thread.getDefaultUncaughtExceptionHandler()
        Thread.setDefaultUncaughtExceptionHandler { thread, throwable ->
            writeNativeCrashLog(thread, throwable)
            val previousHandler = previousExceptionHandler
            if (previousHandler != null) {
                previousHandler.uncaughtException(thread, throwable)
            } else {
                android.os.Process.killProcess(android.os.Process.myPid())
                kotlin.system.exitProcess(10)
            }
        }
    }

    private fun writeNativeCrashLog(thread: Thread, throwable: Throwable) {
        try {
            val now = Date()
            val file = File(
                crashLogDirectory(),
                "${fileStamp(now)}_android_native_fatal.log"
            )
            val stackWriter = StringWriter()
            throwable.printStackTrace(PrintWriter(stackWriter))
            file.writeText(
                buildString {
                    appendLine("time: ${isoStamp(now)}")
                    appendLine("source: android_native")
                    appendLine("fatal: true")
                    appendLine("thread: ${thread.name}")
                    appendLine("error:")
                    appendLine("${throwable.javaClass.name}: ${throwable.message.orEmpty()}")
                    appendLine()
                    appendLine("stack:")
                    appendLine(stackWriter.toString())
                }
            )
            trimOldCrashLogs()
        } catch (_: Throwable) {
            // Crash logging must never block the original crash handler.
        }
    }

    private fun shareCrashLog(path: String, result: MethodChannel.Result) {
        try {
            val file = File(path)
            val directory = crashLogDirectory().canonicalFile
            if (!file.exists() || !file.canonicalPath.startsWith(directory.canonicalPath)) {
                result.error("missing_file", "Crash log file does not exist.", null)
                return
            }
            val uri: Uri = FileProvider.getUriForFile(
                this,
                "${applicationContext.packageName}.crashlogs.fileprovider",
                file
            )
            val intent = Intent(Intent.ACTION_SEND).apply {
                type = "text/plain"
                putExtra(Intent.EXTRA_STREAM, uri)
                putExtra(Intent.EXTRA_SUBJECT, file.name)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            startActivity(Intent.createChooser(intent, "Share crash log"))
            result.success(null)
        } catch (error: Throwable) {
            result.error("share_failed", error.message, null)
        }
    }

    private fun crashLogDirectory(): File {
        val directory = File(filesDir, "crash_logs")
        if (!directory.exists()) {
            directory.mkdirs()
        }
        return directory
    }

    private fun trimOldCrashLogs() {
        crashLogDirectory()
            .listFiles { file -> file.isFile && file.extension == "log" }
            ?.sortedByDescending { it.lastModified() }
            ?.drop(40)
            ?.forEach { file ->
                try {
                    file.delete()
                } catch (_: Throwable) {
                    // Ignore cleanup failures.
                }
            }
    }

    private fun fileStamp(date: Date): String {
        return SimpleDateFormat("yyyyMMdd_HHmmss_SSS", Locale.US).format(date)
    }

    private fun isoStamp(date: Date): String {
        return SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSZ", Locale.US).format(date)
    }
}
