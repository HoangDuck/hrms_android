package gsot.smarthrms.timekeeping

import android.app.AppOpsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.nfc.NfcAdapter
import android.os.Build
import android.provider.Settings
import android.text.TextUtils
import android.util.Base64
import android.widget.Toast
import androidx.annotation.NonNull
import com.zing.zalo.zalosdk.oauth.LoginVia
import com.zing.zalo.zalosdk.oauth.OAuthCompleteListener
import com.zing.zalo.zalosdk.oauth.OauthResponse
import com.zing.zalo.zalosdk.oauth.ZaloSDK
import gsot.smarthrms.timekeeping.utils.TripleDES
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import org.json.JSONObject
import java.security.MessageDigest

class MainActivity : FlutterFragmentActivity() {
    private lateinit var resultMethod: MethodChannel.Result
    private val CHANNEL = "flutter.native/helper"


    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        ZaloSDK.Instance.onActivityResult(this, requestCode, resultCode, data)
    }

    private fun deviceHasNfc(): Int {
        return try {
            val nfcAdapter: NfcAdapter = NfcAdapter.getDefaultAdapter(this)
            if (!nfcAdapter.isEnabled) {
                1
            } else {
                2
            }
        } catch (e: java.lang.Exception) {
            0
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            resultMethod = result
            when (call.method) {
                "loginZalo" -> {
                    loginZalo()
                }
                "getZaloProfile" -> {
                    getZaloProfile()
                }
                "encryptTripleDes" -> {
                    val key = call.argument<String>("key")
                    val value = call.argument<String>("string")
                    result.success(TripleDES(key!!).harden(value))
                }
                "decryptTripleDes" -> {
                    val key = call.argument<String>("key")
                    val value = call.argument<String>("string")
                    result.success(TripleDES(key!!).soften(value))
                }
                "getHashKey" -> {
                    result.success(getApplicationHashKey(applicationContext))
                }
                "checkPermission" -> {
                    result.success(checkPermissionGPSAndroid())
                }
                "checkNFCPermission" -> {
                    result.success(deviceHasNfc())
                }
                "startNFCSettings" -> {
                    startActivity(Intent(android.provider.Settings.ACTION_NFC_SETTINGS))
                }
                "checkAutoDateTime" -> {
                    result.success(isTimeAutomatic(applicationContext))
                }
                "startAutoDateTimeSettings" -> {
                    startActivity(Intent(android.provider.Settings.ACTION_DATE_SETTINGS))
                }
            }
        }
    }

    fun isTimeAutomatic(c: Context): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
            Settings.Global.getInt(c.contentResolver, Settings.Global.AUTO_TIME, 0) == 1
        } else {
            Settings.System.getInt(c.contentResolver, Settings.System.AUTO_TIME, 0) == 1
        }
    }

    private fun loginZalo() {
        ZaloSDK.Instance.authenticate(this, LoginVia.APP_OR_WEB, listener)
    }

    private fun getZaloProfile() {
        ZaloSDK.Instance.getProfile(this, { data: JSONObject ->
            resultMethod.success(data.toString())
        }, arrayOf("id", "name", "picture"))
    }

    fun onLoginError(code: Int, message: String) {
        Toast.makeText(this, "[$code] $message", Toast.LENGTH_LONG).show()
    }

    private val listener = object : OAuthCompleteListener() {
        override fun onGetOAuthComplete(response: OauthResponse?) {
            if (TextUtils.isEmpty(response?.oauthCode)) {
                onLoginError(response?.errorCode ?: -1, response?.errorMessage ?: "Unknown error")
            } else {
                resultMethod.success(response!!.oauthCode)
            }
        }

        override fun onAuthenError(errorCode: Int, message: String?) {
            onLoginError(errorCode, message ?: "Unknown error")
        }
    }

    @Throws(Exception::class)
    fun getApplicationHashKey(ctx: Context): String {
        val info = ctx.packageManager.getPackageInfo(ctx.packageName, PackageManager.GET_SIGNATURES)
        for (signature in info.signatures) {
            val md = MessageDigest.getInstance("SHA")
            md.update(signature.toByteArray())
            val sig = Base64.encodeToString(md.digest(), Base64.DEFAULT).trim { it <= ' ' }
            if (sig.trim { it <= ' ' }.isNotEmpty()) {
                return sig
            }
        }
        return "null"
    }

    private fun checkPermissionGPSAndroid(): Boolean {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
            val appOps: AppOpsManager = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
            val mode = appOps.checkOpNoThrow(AppOpsManager.OPSTR_FINE_LOCATION, android.os.Process.myUid(), packageName)
            val granted = mode == AppOpsManager.MODE_ALLOWED
            if (!granted) {
                return false
            }
        }
        return true
    }
}
