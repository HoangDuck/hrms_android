import UIKit
import Flutter
import GoogleMaps
import ZaloSDK
import CommonCrypto
import Foundation

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    let zaloAppId = "3263631662443065836"
    var result: FlutterResult!;

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let userDefaults = UserDefaults.standard
        if !userDefaults.bool(forKey: "hasRunBefore") {
            let secItemClasses =  [kSecClassGenericPassword, kSecClassInternetPassword, kSecClassCertificate, kSecClassKey, kSecClassIdentity]
            for itemClass in secItemClasses {
                let spec: NSDictionary = [kSecClass: itemClass]
                SecItemDelete(spec)
            }
            // Update the flag indicator
            userDefaults.set(true, forKey: "hasRunBefore")
        }
        GMSServices.provideAPIKey("AIzaSyAWAczYFuf-_WiUpNF-_UcIWYE82FmAYLM")
        let controller = window.rootViewController as? FlutterViewController
        let nativeChannel = FlutterMethodChannel(name: "flutter.native/helper", binaryMessenger: controller as! FlutterBinaryMessenger)
        nativeChannel.setMethodCallHandler { (FlutterMethodCall, FlutterResult) in
            self.result = FlutterResult
            if("loginZalo" == FlutterMethodCall.method) {
                self.login()
            } else if ("getZaloProfile" == FlutterMethodCall.method) {
                self.getProfile()
            } else if("encryptTripleDes" == FlutterMethodCall.method) {
                guard let args = FlutterMethodCall.arguments else {
                    return
                }
                if let myArgs = args as? [String: Any],
                    let key = myArgs["key"] as? String,
                    let value = myArgs["string"] as? String {
                    self.result(self.myEncrypt(encryptData: value, key: key))
                }
            } else if("decryptTripleDes" == FlutterMethodCall.method) {
                guard let args = FlutterMethodCall.arguments else {
                    return
                }
                if let myArgs = args as? [String: Any],
                    let key = myArgs["key"] as? String,
                    let value = myArgs["string"] as? String {
                    self.result(self.myDecrypt(decryptData: Data(base64Encoded: value)! as NSData, key: key))
                }
            } else {
                FlutterResult(FlutterMethodNotImplemented)
            }
        }
        if(!UserDefaults.standard.bool(forKey: "Notification")) {
            UIApplication.shared.cancelAllLocalNotifications()
            UserDefaults.standard.set(true, forKey: "Notification")
        }
        GeneratedPluginRegistrant.register(with: self)
        ZaloSDK.sharedInstance().initialize(withAppId: zaloAppId)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    override func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        
        return ZDKApplicationDelegate.sharedInstance().application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
    }
    
    func login() {
        ZaloSDK.sharedInstance().authenticateZalo(with: ZAZaloSDKAuthenTypeViaWebViewOnly, parentController: window.rootViewController) { (response) in
            self.onAuthenticateComplete(with: response)
        }
    }
    
    func getProfile() {
          ZaloSDK.sharedInstance().getZaloUserProfile { (response) in
            self.onLoad(profile: response)
        }
    }
    
    func onLoad(profile: ZOGraphResponseObject?) {
        let data = Profile()
        data.id = (profile?.data["id"])! as! String
        data.name = (profile?.data["name"])! as! String
        let encoder = JSONEncoder()
        let encode = try? encoder.encode(data)
        self.result(String(data: encode!, encoding: .utf8)!)
    }
    
    func onAuthenticateComplete(with response: ZOOauthResponseObject?) {
        if response?.isSucess == true {
            result(response?.oauthCode)
        } else if let response = response,
            response.errorCode != -1001 {
            result(response.errorCode)
        }
    }
    
    func mac_md5(string: String) -> (NSMutableData) {
        let myKeyData : NSData = (string).data(using: String.Encoding.utf8)! as NSData
        var hash = [UInt8](repeating: 0, count: 24)
        CC_MD5(myKeyData.bytes, CC_LONG(myKeyData.length), &hash)
        for jval in 0..<8 {
            var kval = 16
            kval += jval
            hash[kval] = hash[jval]
        }
        
        return NSMutableData(bytes: hash, length: 24)
    }
    
    func myEncrypt(encryptData:String, key: String) -> NSString?{
        let myKeyData : NSData = self.mac_md5(string: key)
        let myRawData : NSData = encryptData.data(using: String.Encoding.utf8)! as NSData
        
        let buffer_size : size_t = myRawData.length + kCCBlockSize3DES
        let buffer = UnsafeMutablePointer<NSData>.allocate(capacity: buffer_size)
        var num_bytes_encrypted : size_t = 0
        let operation: CCOperation = UInt32(kCCEncrypt)
        let algoritm:  CCAlgorithm = UInt32(kCCAlgorithm3DES)
        let options:   CCOptions   = UInt32(kCCOptionECBMode + kCCOptionPKCS7Padding)
        let keyLength        = size_t(kCCKeySize3DES)
        
        let Crypto_status: CCCryptorStatus = CCCrypt(operation, algoritm, options, myKeyData.bytes, keyLength, nil, myRawData.bytes, myRawData.length, buffer, buffer_size, &num_bytes_encrypted)
        
        if UInt32(Crypto_status) == UInt32(kCCSuccess){
            
            let myResult: NSData = NSData(bytes: buffer, length: num_bytes_encrypted)
            free(buffer)
            return myResult.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)) as NSString
        }else{
            free(buffer)
            return nil
        }
    }
    
    func myDecrypt(decryptData : NSData, key: String) -> NSString?{
        let mydata_len : Int = decryptData.length
        let myKeyData : NSData = self.mac_md5(string: key)
        let buffer_size : size_t = mydata_len+kCCBlockSizeAES128
        let buffer = UnsafeMutablePointer<NSData>.allocate(capacity: buffer_size)
        var num_bytes_encrypted : size_t = 0
        let operation: CCOperation = UInt32(kCCDecrypt)
        let algoritm:  CCAlgorithm = UInt32(kCCAlgorithm3DES)
        let options:   CCOptions   = UInt32(kCCOptionECBMode + kCCOptionPKCS7Padding)
        let keyLength        = size_t(kCCKeySize3DES)
        
        let decrypt_status : CCCryptorStatus = CCCrypt(operation, algoritm, options, myKeyData.bytes, keyLength, nil, decryptData.bytes, mydata_len, buffer, buffer_size, &num_bytes_encrypted)
        
        if UInt32(decrypt_status) == UInt32(kCCSuccess){
            let myResult : NSData = NSData(bytes: buffer, length: num_bytes_encrypted)
            free(buffer)
            let stringResult = NSString(data: myResult as Data, encoding:String.Encoding.utf8.rawValue)
            return stringResult
        }else{
            free(buffer)
            return nil
            
        }
    }
}

class Profile: Encodable {
    var id: String = ""
    var name: String = ""
}
