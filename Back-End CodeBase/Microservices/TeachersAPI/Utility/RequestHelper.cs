using System.ComponentModel.DataAnnotations;
using Newtonsoft.Json;

namespace TeachersAPI.Utility
{
    public static class RequestHelper
    {
        public static T DeserializeAndValidate<T>(string decryptedData) where T : class
        {
            T data = JsonConvert.DeserializeObject<T>(decryptedData)
                ?? throw new ValidationException("Request data is required.");
            Validator.ValidateObject(data, new ValidationContext(data), true);
            return data;
        }
    }
}
