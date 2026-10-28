using System.Security.Cryptography;
using System.Text;

namespace TeachersAPI.Utility
{
    public static class AesGcmEncryptionDecryption
    {
        // Match the NISM wire format: AES-256-GCM, PBKDF2-SHA256 (1000 iterations),
        // 16-byte salt, 12-byte nonce, 16-byte tag, each encoded as Base64.
        public static (string EncryptedText, string Nonce, string Tag, string Salt) Encrypt(string plainText, string password)
        {
            byte[] salt = RandomNumberGenerator.GetBytes(16);
            byte[] nonce = RandomNumberGenerator.GetBytes(12);
            byte[] key = AesDeriveKey(password, salt);
            byte[] plainBytes = Encoding.UTF8.GetBytes(plainText);
            byte[] cipherBytes = new byte[plainBytes.Length];
            byte[] tag = new byte[16];
            try
            {
                using (AesGcm aes = new AesGcm(key, 16))
                {
                    aes.Encrypt(nonce, plainBytes, cipherBytes, tag);
                }
                return (Convert.ToBase64String(cipherBytes), Convert.ToBase64String(nonce),
                    Convert.ToBase64String(tag), Convert.ToBase64String(salt));
            }
            finally
            {
                CryptographicOperations.ZeroMemory(key);
                CryptographicOperations.ZeroMemory(plainBytes);
            }
        }

        public static string Decrypt(string encryptedText, string base64Salt, string base64Nonce, string base64Tag, string password)
        {
            byte[] cipherBytes = Convert.FromBase64String(encryptedText);
            byte[] salt = Convert.FromBase64String(base64Salt);
            byte[] nonce = Convert.FromBase64String(base64Nonce);
            byte[] tag = Convert.FromBase64String(base64Tag);
            if (salt.Length != 16 || nonce.Length != 12 || tag.Length != 16)
            {
                throw new CryptographicException("Invalid encrypted request.");
            }
            byte[] key = AesDeriveKey(password, salt);
            byte[] plainBytes = new byte[cipherBytes.Length];
            try
            {
                using (AesGcm aes = new AesGcm(key, 16))
                {
                    aes.Decrypt(nonce, cipherBytes, tag, plainBytes);
                }
                return Encoding.UTF8.GetString(plainBytes);
            }
            finally
            {
                CryptographicOperations.ZeroMemory(key);
                CryptographicOperations.ZeroMemory(plainBytes);
            }
        }

        private static byte[] AesDeriveKey(string password, byte[] salt)
        {
            return Rfc2898DeriveBytes.Pbkdf2(password, salt, 1000, HashAlgorithmName.SHA256, 32);
        }
    }
}
