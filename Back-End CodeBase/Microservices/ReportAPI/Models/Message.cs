namespace ReportAPI.Models
{
    public class CustomMessage
    {
        public bool IsSuccess { get; set; }
        public string ReturnMessage { get; set; } = string.Empty;
        public int StatusCode { get; set; } = 500;
    }

    public class Message<T> : CustomMessage
    {
        public T? Data { get; set; }
        public List<T>? DataList { get; set; }
        public string? JWTToken { get; set; }
        public int UserId { get; set; }
        public string? UserName { get; set; }
        public string? EncryptedData { get; set; }
        public string? Salt { get; set; }
        public string? Nonce { get; set; }
        public string? Tag { get; set; }
        public string? ResponseCode { get; set; }
    }
}
