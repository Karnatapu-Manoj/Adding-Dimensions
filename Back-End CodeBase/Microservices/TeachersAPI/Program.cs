using System.Threading.RateLimiting;
using JwtAuthenticationManager;
using JwtAuthenticationManager.Utility;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.RateLimiting;
using TeachersAPI;
using TeachersAPI.Models;
using TeachersAPI.Services;
using TeachersAPI.Utility;
using Microsoft.AspNetCore.Mvc;

var builder = WebApplication.CreateBuilder(args);
builder.Configuration.AddJsonFile("appsettings.Local.json", optional: true, reloadOnChange: false)
    .AddEnvironmentVariables();
builder.Services.AddPostgreSql(builder.Configuration);
builder.Services.AddCustomJwtAuthentication(builder.Configuration);
builder.Services.AddScoped<ITeachersService, TeachersService>();
builder.Services.AddScoped<ILoginService, LoginService>();
builder.Services.AddScoped<IHealthService, HealthService>();
builder.Services.AddScoped<IProjectsService,ProjectsService>();
builder.Services.AddScoped<ITrainingPlansService,TrainingPlansService>();
builder.Services.AddScoped<IProjectPlansService,ProjectPlansService>();
builder.Services.AddScoped<IBatchesService,BatchesService>();
builder.Services.AddScoped<ITrainersService,TrainersService>();
builder.Services.AddScoped<ITrainerAvailabilityService,TrainerAvailabilityService>();
builder.Services.AddScoped<ITraineesService,TraineesService>();
builder.Services.AddScoped<IRegistrationsService,RegistrationsService>();
builder.Services.AddScoped<IAttendanceService,AttendanceService>();
builder.Services.AddScoped<IAttendanceExclusionsService,AttendanceExclusionsService>();
builder.Services.AddScoped<IAssessmentFormsService,AssessmentFormsService>();
builder.Services.AddScoped<IAssessmentsService,AssessmentsService>();
builder.Services.AddScoped<IFeedbackService,FeedbackService>();
builder.Services.AddScoped<ICertificateTemplatesService,CertificateTemplatesService>();
builder.Services.AddScoped<ICertificatesService,CertificatesService>();
builder.Services.AddScoped<IHolidaysService,HolidaysService>();
builder.Services.AddScoped<IUsersService,UsersService>();
builder.Services.AddScoped<IOdooProjectsService,OdooProjectsService>();
builder.Services.AddScoped<ISchoolsService,SchoolsService>();
builder.Services.AddScoped<IResourcesService,ResourcesService>();
builder.Services.AddScoped<IResourceProgressService,ResourceProgressService>();
builder.Services.AddScoped<IExternalCoursesService,ExternalCoursesService>();
builder.Services.AddScoped<IEligibleTeachersService,EligibleTeachersService>();
builder.Services.AddScoped<IEligibleStudentsService,EligibleStudentsService>();
builder.Services.AddScoped<IAuditService,AuditService>();
builder.Services.AddScoped<ITrainerAuditService,TrainerAuditService>();
builder.Services.AddScoped<ICertificateAuditService,CertificateAuditService>();
builder.Services.AddScoped<PortalRepository>();
builder.Services.AddScoped<PortalService>();
builder.Services.AddScoped<PortalRecordMapper>();
builder.Services.AddScoped<PortalBusinessRules>();
builder.Services.AddScoped<PortalAccountService>();
builder.Services.AddScoped<PortalPublicService>();
builder.Services.AddScoped<PortalOtpService>();
builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<ResourceFileService>();
builder.Services.AddScoped<PortalPii>();
builder.Services.AddScoped<IPasswordHasher<PortalUserModel>,PasswordHasher<PortalUserModel>>();

builder.Services.AddScoped<IPasswordHasher<RegistrationModel>, PasswordHasher<RegistrationModel>>();
builder.Services.AddControllers().ConfigureApiBehaviorOptions(options =>
{
    options.InvalidModelStateResponseFactory = context => new BadRequestObjectResult(new Message<object>
    {
        StatusCode = 400,
        IsSuccess = false,
        ReturnMessage = "The encrypted request must contain data, salt, nonce, and tag."
    });
});
builder.Services.AddOptions<EncryptionOptions>().Bind(builder.Configuration)
    .ValidateDataAnnotations().ValidateOnStart();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddProblemDetails();
builder.Services.AddExceptionHandler<AppExceptionHandler>();
builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    options.OnRejected = async (context, cancellationToken) =>
    {
        await context.HttpContext.Response.WriteAsJsonAsync(new Message<object>
        {
            StatusCode = 429,
            ReturnMessage = "Too many requests. Please try again later."
        }, cancellationToken);
    };
    options.AddPolicy("login", context => RateLimitPartition.GetFixedWindowLimiter(
        context.Connection.RemoteIpAddress?.ToString() ?? "unknown",
        _ => new FixedWindowRateLimiterOptions
        {
            PermitLimit = 10, Window = TimeSpan.FromMinutes(1), QueueLimit = 0
        }));
    options.AddPolicy("public", context => RateLimitPartition.GetFixedWindowLimiter(
        context.Connection.RemoteIpAddress?.ToString() ?? "unknown",
        _ => new FixedWindowRateLimiterOptions { PermitLimit = 60, Window = TimeSpan.FromMinutes(1), QueueLimit = 0 }));
});

var app = builder.Build();
if (args.Contains("--seed-portal-demo"))
{
    if (!app.Environment.IsDevelopment()) throw new InvalidOperationException("Demo seeding is available only in Development.");
    using var scope = app.Services.CreateScope();
    string sourcePath = Environment.GetEnvironmentVariable("PORTAL_DEMO_SOURCE") ?? throw new InvalidOperationException("PORTAL_DEMO_SOURCE is required.");
    await PortalDemoSeeder.Seed(scope.ServiceProvider, sourcePath);
    return;
}
if (args.Contains("--seed-admin"))
{
    using var scope = app.Services.CreateScope();
    await AdminBootstrap.SeedAdmin(scope.ServiceProvider, builder.Configuration);
    return;
}
app.UseExceptionHandler();
app.UseStatusCodePages(async context =>
{
    int statusCode = context.HttpContext.Response.StatusCode;
    await context.HttpContext.Response.WriteAsJsonAsync(new Message<object>
    {
        StatusCode = statusCode,
        ReturnMessage = statusCode == 401 ? "Authentication is required or the session has expired."
            : statusCode == 403 ? "You do not have permission to perform this operation."
            : "The request could not be completed."
    });
});
if (app.Environment.IsDevelopment() || app.Environment.IsEnvironment("Local"))
{
    app.UseSwagger();
    app.UseSwaggerUI();
}
else
{
    app.UseHsts();
    app.UseHttpsRedirection();
}
app.UseRouting();
app.UseRateLimiter();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();
app.Run();
