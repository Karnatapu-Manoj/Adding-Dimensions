using System.Security.Cryptography;
using System.Text;
using Newtonsoft.Json.Linq;

namespace ReportAPI.Utility
{
    public class PortalPii
    {
        private readonly IConfiguration _configuration;
        public PortalPii(IConfiguration configuration) { _configuration=configuration; }
        public string ContactHash(string value)
        {
            string normalized=value.Contains('@')?value.Trim().ToLowerInvariant():new string(value.Where(char.IsDigit).ToArray());
            return Convert.ToHexString(HMACSHA256.HashData(Convert.FromBase64String(_configuration["Pii:BlindIndexKey"]!),
                Encoding.UTF8.GetBytes(normalized))).ToLowerInvariant();
        }
        public JObject Protect(JObject source,JObject? previous)
        {
            JObject result=(JObject)source.DeepClone();
            result.Remove("_contacts");
            JObject contacts=(JObject?)previous?["_contacts"]?.DeepClone() ?? new JObject();
            foreach(string field in new[]{"email","phone","mobile","phoneNumber"})
            {
                string? value=result.Value<string>(field);
                if(value!=null && !value.Contains('*'))
                {
                    string normalized=field=="email"?value.Trim().ToLowerInvariant():new string(value.Where(char.IsDigit).ToArray());
                    var encrypted=AesGcmEncryptionDecryption.Encrypt(value,_configuration["Pii:EncryptionKey"]!);
                    contacts[field]=new JObject
                    {
                        ["data"]=encrypted.EncryptedText,["salt"]=encrypted.Salt,["nonce"]=encrypted.Nonce,["tag"]=encrypted.Tag,
                        ["mask"]=Mask(value,field),["hash"]=Convert.ToHexString(HMACSHA256.HashData(
                            Convert.FromBase64String(_configuration["Pii:BlindIndexKey"]!),Encoding.UTF8.GetBytes(normalized))).ToLowerInvariant()
                    };
                }
                result.Remove(field);
            }
            if(contacts.Count>0) result["_contacts"]=contacts;
            result.Remove("password");result.Remove("passwordHash");
            return result;
        }
        public JObject Reveal(JObject source,bool full)
        {
            JObject result=(JObject)source.DeepClone();
            if(result["_contacts"] is JObject contacts)
            {
                foreach(var contact in contacts.Properties())
                {
                    JObject data=(JObject)contact.Value;
                    result[contact.Name]=full?AesGcmEncryptionDecryption.Decrypt(data.Value<string>("data")!,
                        data.Value<string>("salt")!,data.Value<string>("nonce")!,data.Value<string>("tag")!,_configuration["Pii:EncryptionKey"]!)
                        :data.Value<string>("mask");
                }
                result.Remove("_contacts");
            }
            return result;
        }
        public static string Mask(string value,string field)
        {
            if(string.IsNullOrEmpty(value))return string.Empty;
            int at=value.IndexOf('@');
            if(field=="email" && at>0)return value[0]+"*****"+value[at..];
            return value.Length>4?value[..2]+new string('*',value.Length-4)+value[^2..]:new string('*',value.Length);
        }
    }
}
