using System.IdentityModel.Tokens.Jwt;
using System.Security.Cryptography;
using System.Text;
using JwtAuthenticationManager;
using JwtAuthenticationManager.Utility;
using Microsoft.AspNetCore.StaticFiles;
using Microsoft.IdentityModel.Tokens;
using Newtonsoft.Json.Linq;
using Npgsql;
using NpgsqlTypes;
using static TeachersAPI.Services.PortalRecordMapper;

namespace TeachersAPI.Services
{
    public class ResourceFileService
    {
        private readonly IConfiguration _configuration;
        private readonly IWebHostEnvironment _environment;
        private readonly IHttpContextAccessor _httpContext;
        private readonly PortalRepository _repository;
        private readonly PortalSessionStore _sessions;
        public ResourceFileService(IConfiguration configuration,IWebHostEnvironment environment,
            IHttpContextAccessor httpContext,PortalRepository repository,PortalSessionStore sessions)
        { _configuration=configuration;_environment=environment;_httpContext=httpContext;_repository=repository;_sessions=sessions; }

        public string StorageRoot { get { return Path.GetFullPath(Path.Combine(_environment.ContentRootPath,"../../.local/resources")); } }
        public void AddDownloadUrls(JObject snapshot)
        {
            string? tokenId=_httpContext.HttpContext?.User.FindFirst(JwtRegisteredClaimNames.Jti)?.Value;
            if(tokenId==null)return;
            long userId=snapshot["_current"]!.Value<long>("id");
            foreach(JObject resource in Rows(snapshot,"learning-resources"))
            {
                var payload=new JObject { ["userId"]=userId,["tokenId"]=tokenId,["resourceId"]=resource["id"],
                    ["expires"]=DateTimeOffset.UtcNow.AddMinutes(30).ToUnixTimeSeconds() };
                string body=Base64UrlEncoder.Encode(payload.ToString());
                string ticket=body+"."+Base64UrlEncoder.Encode(HMACSHA256.HashData(Encoding.UTF8.GetBytes(_configuration["Jwt:SecurityKey"]!),Encoding.UTF8.GetBytes(body)));
                resource["url"]=(_configuration["GatewayBaseUrl"] ?? "http://localhost:5100")+"/api/Resources/Download?ticket="+ticket;
            }
        }
        public async Task<(string Path,string Name,string Mime)> ResolveDownload(string ticket,CancellationToken ct)
        {
            string[] parts=ticket.Split('.');
            if(parts.Length!=2)throw new UnauthorizedAccessException("Invalid resource ticket.");
            byte[] expected=HMACSHA256.HashData(Encoding.UTF8.GetBytes(_configuration["Jwt:SecurityKey"]!),Encoding.UTF8.GetBytes(parts[0]));
            if(!CryptographicOperations.FixedTimeEquals(expected,Base64UrlEncoder.DecodeBytes(parts[1])))throw new UnauthorizedAccessException("Invalid resource ticket.");
            JObject payload=JObject.Parse(Base64UrlEncoder.Decode(parts[0]));
            long userId=payload.Value<long>("userId");
            if(payload.Value<long>("expires")<DateTimeOffset.UtcNow.ToUnixTimeSeconds() || !await _sessions.IsActive(userId,payload.Value<string>("tokenId")!,ct))
                throw new UnauthorizedAccessException("This resource link has expired.");
            JObject snapshot=await _repository.GetSnapshot(userId,ct);
            JObject resource=Find(snapshot,"learning-resources",payload.Value<string>("resourceId")) ?? throw new UnauthorizedAccessException("Resource access denied.");
            string path=Path.GetFullPath(Path.Combine(StorageRoot,Text(resource,"storagePath")));
            if(!path.StartsWith(StorageRoot+Path.DirectorySeparatorChar,StringComparison.OrdinalIgnoreCase) || !File.Exists(path))throw new FileNotFoundException();
            var parameters=new List<NpgsqlParameter>
            {
                new NpgsqlParameter("p_user_id",NpgsqlDbType.Bigint){Value=userId},
                new NpgsqlParameter("p_resource_id",NpgsqlDbType.Bigint){Value=resource.Value<long>("_dbId")}
            };
            await SqlHelper.ExecuteNonQuery(parameters,"public.usp_portal_resource_access",_configuration.GetConnectionString("DBConnection")!,ct);
            new FileExtensionContentTypeProvider().TryGetContentType(path,out string? mime);
            return(path,Text(resource,"file",Path.GetFileName(path)),mime ?? "application/octet-stream");
        }
    }
}
