using System.ComponentModel.DataAnnotations;
using System.Security.Cryptography;
using Newtonsoft.Json;
using Newtonsoft.Json.Serialization;
using Npgsql;
using ReportAPI.Models;

namespace ReportAPI.Utility
{
    public static class ResponseHelper
    {
        public static Message<T> Encrypt<T>(Message<T> message, string password)
        {
            string responseData = JsonConvert.SerializeObject(message, new JsonSerializerSettings
            {
                ContractResolver = new CamelCasePropertyNamesContractResolver(),
                Formatting = Formatting.None
            });
            var encryptedResponse = AesGcmEncryptionDecryption.Encrypt(responseData, password);
            // Do not repeat decrypted profiles or bearer tokens in the outer envelope.
            return new Message<T>
            {
                IsSuccess = message.IsSuccess,
                StatusCode = message.StatusCode,
                ReturnMessage = message.ReturnMessage,
                ResponseCode = message.ResponseCode,
                EncryptedData = encryptedResponse.EncryptedText,
                Salt = encryptedResponse.Salt,
                Nonce = encryptedResponse.Nonce,
                Tag = encryptedResponse.Tag
            };
        }

        public static void SetError(CustomMessage message, Exception exception, ILogger logger, string operation)
        {
            message.IsSuccess = false;
            if (exception is ValidationException || exception is JsonException ||
                exception is FormatException || exception is CryptographicException)
            {
                message.StatusCode = 400;
                message.ReturnMessage = exception is ValidationException validationException
                    ? validationException.Message : "Invalid request data or encrypted payload.";
            }
            else if (exception is PostgresException postgresException &&
                postgresException.SqlState == PostgresErrorCodes.UniqueViolation)
            {
                message.StatusCode = 409;
                message.ReturnMessage = "An account with this email already exists.";
            }
            else if (exception is UnauthorizedAccessException || exception is PostgresException { SqlState: "42501" })
            {
                message.StatusCode = 403;
                message.ReturnMessage = "You do not have permission to access or change these records.";
            }
            else if (exception is PostgresException { SqlState: "40001" })
            {
                message.StatusCode = 409;
                message.ReturnMessage = "A record changed in another session. Reload and try again.";
            }
            else if (exception is PostgresException { SqlState: "22023" } businessException)
            {
                message.StatusCode = 400;
                message.ReturnMessage = businessException.MessageText;
            }
            else
            {
                message.StatusCode = exception is NpgsqlException && exception is not PostgresException ? 503 : 500;
                message.ReturnMessage = message.StatusCode == 503
                    ? "Database is unavailable. Please try again."
                    : "There is an error processing your request. Please try again.";
                logger.LogError(exception, "{Operation} failed.", operation);
            }
        }
    }
}
