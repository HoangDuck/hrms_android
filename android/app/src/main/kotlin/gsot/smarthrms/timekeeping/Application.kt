package gsot.smarthrms.timekeeping

import android.app.Activity
import com.zing.zalo.zalosdk.oauth.ZaloSDKApplication
import io.flutter.app.FlutterApplication
import io.flutter.plugin.common.PluginRegistry
//import io.flutter.plugins.firebasemessaging.FlutterFirebaseMessagingService

class Application : FlutterApplication(), PluginRegistry.PluginRegistrantCallback {
    override fun onCreate() {
        super.onCreate()
        ZaloSDKApplication.wrap(this)
//        FlutterFirebaseMessagingService.setPluginRegistrant(this)
    }
    

    private var mCurrentActivity: Activity? = null

    override fun getCurrentActivity(): Activity? {
        return mCurrentActivity
    }

    override fun setCurrentActivity(mCurrentActivity: Activity?) {
        this.mCurrentActivity = mCurrentActivity
    }

    override fun registerWith(registry: PluginRegistry) {
//        FirebaseCloudMessagingPluginRegistrant().registerWith(registry)
    }
}