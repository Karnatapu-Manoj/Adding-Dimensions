using System.Diagnostics;
using JwtAuthenticationManager;
using JwtAuthenticationManager.Utility;
using Ocelot.DependencyInjection;
using Ocelot.Middleware;

var builder = WebApplication.CreateBuilder(args);
builder.Configuration.AddJsonFile("ocelot.json", optional: false, reloadOnChange: true)
    .AddJsonFile("appsettings.Local.json", optional: true, reloadOnChange: false)
    .AddEnvironmentVariables();
builder.Services.AddPostgreSql(builder.Configuration);
builder.Services.AddCustomJwtAuthentication(builder.Configuration);
builder.Services.AddOcelot(builder.Configuration);
builder.Services.AddCors(options => options.AddDefaultPolicy(policy => policy
    .WithOrigins(builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>() ?? [])
    .AllowAnyMethod().AllowAnyHeader()));
builder.Services.AddProblemDetails();

var app = builder.Build();
app.UseExceptionHandler();
app.UseStatusCodePages(async context =>
{
    int statusCode = context.HttpContext.Response.StatusCode;
    await context.HttpContext.Response.WriteAsJsonAsync(new
    {
        IsSuccess = false,
        StatusCode = statusCode,
        ReturnMessage = statusCode == 401 ? "Authentication is required or the session has expired."
            : statusCode == 403 ? "You do not have permission to perform this operation."
            : "The request could not be completed."
    });
});
if (!app.Environment.IsDevelopment())
{
    app.UseHsts();
    app.UseHttpsRedirection();
}
app.Use(async (context, next) =>
{
    var timer = Stopwatch.StartNew();
    context.Response.Headers.XContentTypeOptions = "nosniff";
    context.Response.Headers["X-Frame-Options"] = "DENY";
    context.Response.Headers.CacheControl = "no-store";
    try { await next(); }
    finally
    {
        app.Logger.LogInformation("{Method} {Path} returned {Status} in {Elapsed} ms; trace {TraceId}",
            context.Request.Method, context.Request.Path, context.Response.StatusCode,
            timer.ElapsedMilliseconds, context.TraceIdentifier);
    }
});
app.UseCors();
app.UseAuthentication();
app.UseAuthorization();
await app.UseOcelot();
app.Run();
