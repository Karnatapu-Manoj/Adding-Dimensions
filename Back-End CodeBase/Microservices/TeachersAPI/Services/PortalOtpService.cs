using System.ComponentModel.DataAnnotations;
using System.Net;
using System.Security.Cryptography;
using System.Text;
using Newtonsoft.Json.Linq;
using Npgsql;
using NpgsqlTypes;
using TeachersAPI.Utility;

namespace TeachersAPI.Services
{
    public class PortalOtpService
    {
        private readonly PortalRepository _repository;
        private readonly IConfiguration _configuration;
        private readonly IWebHostEnvironment _environment;
        public PortalOtpService(PortalRepository repository, IConfiguration configuration, IWebHostEnvironment environment)
        {
            _repository = repository;
            _configuration = configuration;
            _environment = environment;
        }

        public async Task<JObject> Create(string purpose, long? userId, string recipient, JObject payload, CancellationToken ct)
        {
            // The local outbox is deliberately unavailable outside Development.
            if (!_environment.IsDevelopment()) throw new ValidationException("An OTP delivery provider must be configured before enabling sign-in or registration outside local development.");
            Guid id = Guid.NewGuid();
            string otp = RandomNumberGenerator.GetInt32(0, 1000000).ToString("D6");
            var encrypted = AesGcmEncryptionDecryption.Encrypt(payload.ToString(), _configuration["Pii:EncryptionKey"]!);
            JObject protectedPayload = new JObject { ["data"] = encrypted.EncryptedText, ["salt"] = encrypted.Salt,
                ["nonce"] = encrypted.Nonce, ["tag"] = encrypted.Tag };
            var parameters = new List<NpgsqlParameter>
            {
                new NpgsqlParameter("p_id", NpgsqlDbType.Uuid) { Value = id },
                new NpgsqlParameter("p_purpose", NpgsqlDbType.Varchar) { Value = purpose },
                new NpgsqlParameter("p_user_id", NpgsqlDbType.Bigint) { Value = (object?)userId ?? DBNull.Value },
                new NpgsqlParameter("p_recipient_hash", NpgsqlDbType.Varchar) { Value = Hash(recipient.Trim().ToLowerInvariant()) },
                new NpgsqlParameter("p_otp_hash", NpgsqlDbType.Varchar) { Value = Hash(id.ToString()+":"+otp) },
                new NpgsqlParameter("p_payload", NpgsqlDbType.Jsonb) { Value = protectedPayload.ToString() }
            };
            JObject result = await _repository.ExecutePayload("public.usp_portal_create_otp", parameters, ct);
            string folder = OutboxFolder();
            Directory.CreateDirectory(folder);
            await File.WriteAllTextAsync(Path.Combine(folder, id.ToString()+".eml"),
                $"To: {recipient.Replace("\r", "").Replace("\n", "")}\nSubject: {purpose} verification\n\nRequest: {id}\nOTP: {otp}\nExpires in 5 minutes. This code can be used once.\n", ct);
            result["requiresOtp"] = true;
            result["message"] = "Enter the six-digit code from the local email outbox. It expires in 5 minutes.";
            result["outboxPath"] = "/api/Public/LocalOutbox/"+id;
            return result;
        }

        public async Task<JObject> Verify(string purpose, string challengeId, string otp, CancellationToken ct, bool preview = false)
        {
            if (!Guid.TryParse(challengeId, out Guid id) || otp.Length != 6 || !otp.All(char.IsAsciiDigit))
                throw new ValidationException("Enter the six-digit verification code and a valid request.");
            var parameters = new List<NpgsqlParameter>
            {
                new NpgsqlParameter("p_id", NpgsqlDbType.Uuid) { Value = id },
                new NpgsqlParameter("p_purpose", NpgsqlDbType.Varchar) { Value = purpose },
                new NpgsqlParameter("p_otp_hash", NpgsqlDbType.Varchar) { Value = Hash(id.ToString()+":"+otp) }
            };
            JObject result = await _repository.ExecutePayload(preview ? "public.usp_portal_check_registration_otp" : "public.usp_portal_verify_otp", parameters, ct);
            if (!result.Value<bool>("verified")) throw new ValidationException("The code is incorrect, expired, already used, or has reached its three-attempt limit. Request a new code.");
            JObject envelope = (JObject)result["protectedPayload"]!;
            result["payload"] = JObject.Parse(AesGcmEncryptionDecryption.Decrypt(envelope.Value<string>("data")!,
                envelope.Value<string>("salt")!, envelope.Value<string>("nonce")!, envelope.Value<string>("tag")!, _configuration["Pii:EncryptionKey"]!));
            result.Remove("protectedPayload");
            return result;
        }

        public string OutboxFolder() => Path.GetFullPath(Path.Combine(_environment.ContentRootPath, "../../.local/mail-outbox"));

        public bool CanViewLocalOutbox(IPAddress? address) => _environment.IsDevelopment() && address != null && IPAddress.IsLoopback(address);

        private string Hash(string value) => Convert.ToHexString(HMACSHA256.HashData(
            Convert.FromBase64String(_configuration["Pii:BlindIndexKey"]!), Encoding.UTF8.GetBytes(value)));
    }
}
