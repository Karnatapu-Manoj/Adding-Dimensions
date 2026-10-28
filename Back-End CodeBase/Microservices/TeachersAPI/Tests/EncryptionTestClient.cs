using System.Security.Cryptography;
using System.Text;
using System.Text.Json;

// Independent client implementation of the reference project's encryption contract.
// SmokeTest.ps1 compiles this in a temporary .NET console project, outside the API.
string password = Environment.GetEnvironmentVariable("AESPassword")!;
string input = Console.In.ReadToEnd();
if (args[0] == "encrypt")
{
    byte[] salt = RandomNumberGenerator.GetBytes(16);
    byte[] nonce = RandomNumberGenerator.GetBytes(12);
    using var kdf = new Rfc2898DeriveBytes(password, salt, 1000, HashAlgorithmName.SHA256);
    byte[] key = kdf.GetBytes(32);
    byte[] plain = Encoding.UTF8.GetBytes(input);
    byte[] cipher = new byte[plain.Length];
    byte[] tag = new byte[16];
    using var aes = new AesGcm(key, 16);
    aes.Encrypt(nonce, plain, cipher, tag);
    Console.Write(JsonSerializer.Serialize(new
    {
        data = Convert.ToBase64String(cipher), salt = Convert.ToBase64String(salt),
        nonce = Convert.ToBase64String(nonce), tag = Convert.ToBase64String(tag)
    }));
}
else
{
    using var document = JsonDocument.Parse(input);
    var envelope = document.RootElement;
    byte[] salt = Convert.FromBase64String(envelope.GetProperty("salt").GetString()!);
    byte[] nonce = Convert.FromBase64String(envelope.GetProperty("nonce").GetString()!);
    byte[] tag = Convert.FromBase64String(envelope.GetProperty("tag").GetString()!);
    byte[] cipher = Convert.FromBase64String(envelope.GetProperty("encryptedData").GetString()!);
    using var kdf = new Rfc2898DeriveBytes(password, salt, 1000, HashAlgorithmName.SHA256);
    byte[] key = kdf.GetBytes(32);
    byte[] plain = new byte[cipher.Length];
    using var aes = new AesGcm(key, 16);
    aes.Decrypt(nonce, cipher, tag, plain);
    Console.Write(Encoding.UTF8.GetString(plain));
}
