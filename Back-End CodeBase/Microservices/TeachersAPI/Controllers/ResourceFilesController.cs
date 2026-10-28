using System.IdentityModel.Tokens.Jwt;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Newtonsoft.Json.Linq;
using TeachersAPI.Models;
using TeachersAPI.Services;
using TeachersAPI.Utility;

namespace TeachersAPI.Controllers
{
    [ApiController,Route("api/Resources")]
    public class ResourceFilesController : Controller
    {
        private readonly ResourceFileService _files;
        private readonly PortalService _portalService;
        private readonly IConfiguration _configuration;
        public ResourceFilesController(ResourceFileService files,PortalService portalService,IConfiguration configuration)
        { _files=files;_portalService=portalService;_configuration=configuration; }
        [HttpGet,Route("Download"),AllowAnonymous]
        public async Task<IActionResult> Download(string ticket,bool download=false,CancellationToken ct=default)
        {
            try
            {
                var file=await _files.ResolveDownload(ticket,ct);
                if(download)return PhysicalFile(file.Path,file.Mime,file.Name,enableRangeProcessing:true);
                return PhysicalFile(file.Path,file.Mime,enableRangeProcessing:true);
            }
            catch(UnauthorizedAccessException){return Unauthorized(new CustomMessage{StatusCode=401,ReturnMessage="Resource link expired or access denied."});}
            catch(FormatException){return BadRequest();}
            catch(FileNotFoundException){return NotFound();}
        }
        [HttpPost,Route("Upload"),Authorize(Policy="PortalUser",Roles="schoolnet-super-admin,schoolnet-project-admin")]
        [RequestSizeLimit(27000000)]
        public async Task<IActionResult> Upload(IFormFile file,CancellationToken ct)
        {
            string extension=Path.GetExtension(file.FileName).ToLowerInvariant();
            if(!new[]{".pdf",".ppt",".pptx",".docx",".mp4",".webm",".png",".jpg",".jpeg",".json"}.Contains(extension) || file.Length<1 || file.Length>25000000)
                return BadRequest(new CustomMessage{StatusCode=400,ReturnMessage="Choose a supported training resource smaller than 25 MB."});
            string id=Guid.NewGuid().ToString("N");string name=id+extension;
            Directory.CreateDirectory(_files.StorageRoot);
            string path=Path.Combine(_files.StorageRoot,name);
            using(FileStream stream=System.IO.File.Create(path)){await file.CopyToAsync(stream,ct);}
            JObject row=new JObject { ["id"]=id,["title"]=Path.GetFileNameWithoutExtension(file.FileName),["file"]=Path.GetFileName(file.FileName),
                ["format"]=extension[1..].ToUpperInvariant(),["category"]=extension is ".mp4" or ".webm"?"Video":extension is ".ppt" or ".pptx"?"Presentation":"Documents",
                ["size"]=$"{file.Length/1024} KB",["language"]="English",["tags"]=new JArray(),["storagePath"]=name };
            var changes=new PortalChangesRequest{Upserts=new JArray(row)};
            Message<JObject> msg=await _portalService.SaveData(long.Parse(User.FindFirst(JwtRegisteredClaimNames.Sub)!.Value),User.FindFirst("role")!.Value,"teacher-training-learning-resources",changes,ct);
            if(!msg.IsSuccess)System.IO.File.Delete(path);
            return StatusCode(msg.StatusCode,ResponseHelper.Encrypt(msg,_configuration["AESPassword"]!));
        }
    }
}
