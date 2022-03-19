package gsot.smarthrms.timekeeping.utils

import java.security.MessageDigest
import java.util.*
import java.util.logging.Level
import java.util.logging.Logger
import javax.crypto.Cipher
import javax.crypto.SecretKey
import javax.crypto.spec.SecretKeySpec

internal class TripleDES(private val key: String) {
    /**
     * Method to encrypt the string
     */
    fun harden(unencryptedString: String?): String {
        return if (unencryptedString == null) {
            ""
        } else try {
            val md = MessageDigest.getInstance("md5")
            val digestOfPassword = md.digest(key.toByteArray(charset("utf-8")))
            val keyBytes = Arrays.copyOf(digestOfPassword, 24)
            var j = 0
            var k = 16
            while (j < 8) {
                keyBytes[k++] = keyBytes[j++]
            }
            val secretKey: SecretKey = SecretKeySpec(keyBytes, "DESede")
            val cipher = Cipher.getInstance("DESede/ECB/PKCS5Padding")
            cipher.init(Cipher.ENCRYPT_MODE, secretKey)
            val plainTextBytes = unencryptedString.toByteArray(charset("utf-8"))
            val buf = cipher.doFinal(plainTextBytes)
            String(android.util.Base64.encode(buf, android.util.Base64.DEFAULT))
        } catch (e: Exception) {
            logger.log(Level.SEVERE, null, e)
            throw RuntimeException(e)
        }
    }

    /**
     * Method to decrypt an encrypted string
     *
     * @param encryptedString
     */
    fun soften(encryptedString: String?): String {
        return if (encryptedString == null) {
            ""
        } else try {
            val message = android.util.Base64.decode(encryptedString.toByteArray(charset("utf-8")), android.util.Base64.DEFAULT)
            val md = MessageDigest.getInstance("MD5")
            val digestOfPassword = md.digest(key.toByteArray(charset("utf-8")))
            val keyBytes = Arrays.copyOf(digestOfPassword, 24)
            var j = 0
            var k = 16
            while (j < 8) {
                keyBytes[k++] = keyBytes[j++]
            }
            val secretKey: SecretKey = SecretKeySpec(keyBytes, "DESede")
            val decipher = Cipher.getInstance("DESede/ECB/PKCS5Padding")
            decipher.init(Cipher.DECRYPT_MODE, secretKey)
            val plainText = decipher.doFinal(message)
            String(plainText, Charsets.UTF_8)
        } catch (e: Exception) {
            logger.log(Level.SEVERE, null, e)
            throw RuntimeException(e)
        }
    }

    companion object {
        private val logger = Logger.getLogger(TripleDES::class.java.name)
    }

}