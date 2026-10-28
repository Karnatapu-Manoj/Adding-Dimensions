using System.IdentityModel.Tokens.Jwt;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Newtonsoft.Json.Linq;
using TeachersAPI.Models;
using TeachersAPI.Services;
using TeachersAPI.Utility;

namespace TeachersAPI.Controllers
{
    [ApiController,Authorize(Policy = "PortalUser"),Route("api/[controller]")]
    public class WorkspaceController : Controller
    {
        private readonly PortalService _portalService;
        private readonly IConfiguration _configuration;
        public WorkspaceController(PortalService portalService,IConfiguration configuration)
        { _portalService=portalService;_configuration=configuration; }
        [HttpPost,Route("GetData")]
        public async Task<IActionResult> GetData(EncryptedRequest request,CancellationToken ct)
        {
            Message<JObject> msg=await _portalService.GetData(long.Parse(User.FindFirst(JwtRegisteredClaimNames.Sub)!.Value),ct);
            return StatusCode(msg.StatusCode,ResponseHelper.Encrypt(msg,_configuration["AESPassword"]!));
        }
    }
    [ApiController,Authorize(Policy = "PortalUser"),Route("api/Settings")]
    public class PortalSettingsController : Controller
    {
        private readonly PortalService _portalService;
        private readonly IConfiguration _configuration;
        public PortalSettingsController(PortalService portalService,IConfiguration configuration)
        { _portalService=portalService;_configuration=configuration; }
        [HttpPost,Route("SaveData")]
        public async Task<IActionResult> SaveData(EncryptedRequest request,CancellationToken ct)
        {
            string json=AesGcmEncryptionDecryption.Decrypt(request.data,request.salt,request.nonce,request.tag,_configuration["AESPassword"]!);
            JObject data=JObject.Parse(json);
            PortalChangesRequest changes=RequestHelper.DeserializeAndValidate<PortalChangesRequest>(json);
            string collection=data.Value<string>("collection") ?? string.Empty;
            if(!collection.StartsWith("teacher-training-") || !PortalCollections.Tables.TryGetValue(collection,out string? table) || table!="portal_setting")
                return BadRequest(new CustomMessage{StatusCode=400,ReturnMessage="Unknown setting."});
            Message<JObject> msg=await _portalService.SaveData(long.Parse(User.FindFirst(JwtRegisteredClaimNames.Sub)!.Value),User.FindFirst("role")!.Value,collection,changes,ct);
            return StatusCode(msg.StatusCode,ResponseHelper.Encrypt(msg,_configuration["AESPassword"]!));
        }
    }
}
