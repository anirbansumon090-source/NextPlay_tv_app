package com.ottking.nextplay

import android.content.Context
import android.app.UiModeManager
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.view.WindowManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.ottking.ltv/device_info"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

       
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

      
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "isAndroidTV") {
                result.success(checkIsTvReal())
            } else {
                result.notImplemented()
            }
        }
    }

    private fun checkIsTvReal(): Boolean {
       
        val uiModeManager = getSystemService(Context.UI_MODE_SERVICE) as UiModeManager
        if (uiModeManager.currentModeType == Configuration.UI_MODE_TYPE_TELEVISION) {
            return true
        }

        
        if (packageManager.hasSystemFeature(PackageManager.FEATURE_LEANBACK) ||
            packageManager.hasSystemFeature("amazon.hardware.fire_tv")) {
            return true
        }

        
        val hasNoTouchScreen = !packageManager.hasSystemFeature(PackageManager.FEATURE_TOUCHSCREEN)
        
      
        val isTvHardware = Build.HARDWARE.lowercase().contains("tv") || 
                           Build.MODEL.lowercase().contains("tv") || 
                           Build.MODEL.lowercase().contains("box")

        if (hasNoTouchScreen && isTvHardware) {
            return true
        }

        return false
    }
}
