using System.IdentityModel.Tokens.Jwt;
using System.Text;
using JwtAuthenticationManager.Utility;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;

namespace JwtAuthenticationManager;

public static class CustomJwtAuthExtension
{
    public static IServiceCollection AddCustomJwtAuthentication(this IServiceCollection services,
        IConfiguration configuration)
    {
        services.AddOptions<JwtOptions>().Bind(configuration.GetSection(JwtOptions.SectionName))
            .ValidateDataAnnotations().ValidateOnStart();
        services.AddSingleton<PostgreSqlTokenStore>();
        services.AddSingleton<JwtTokenHandler>();
        services.AddSingleton<PortalSessionStore>();
        services.AddSingleton<PortalJwtTokenHandler>();
        services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme).AddJwtBearer();
        services.AddOptions<JwtBearerOptions>(JwtBearerDefaults.AuthenticationScheme)
            .Configure<IOptions<JwtOptions>>((options, settings) =>
            {
                var jwt = settings.Value;
                options.MapInboundClaims = false;
                options.TokenValidationParameters = new TokenValidationParameters
                {
                    ValidateIssuer = true, ValidIssuer = jwt.Issuer,
                    ValidateAudience = true, ValidAudience = jwt.Audience,
                    ValidateLifetime = true, RequireExpirationTime = true,
                    ValidateIssuerSigningKey = true, RequireSignedTokens = true,
                    IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwt.SecurityKey)),
                    ValidAlgorithms = [SecurityAlgorithms.HmacSha256],
                    NameClaimType = JwtRegisteredClaimNames.Name, RoleClaimType = "role",
                    ClockSkew = TimeSpan.FromSeconds(30)
                };
                options.Events = new JwtBearerEvents
                {
                    OnTokenValidated = async context =>
                    {
                        var subject = context.Principal?.FindFirst(JwtRegisteredClaimNames.Sub)?.Value;
                        var tokenId = context.Principal?.FindFirst(JwtRegisteredClaimNames.Jti)?.Value;
                        if (context.Principal?.FindFirst("identity_kind")?.Value == "app_user")
                        {
                            if (!long.TryParse(subject, out long portalUserId) || tokenId is null ||
                                !await context.HttpContext.RequestServices.GetRequiredService<PortalSessionStore>()
                                    .IsActive(portalUserId, tokenId, context.HttpContext.RequestAborted))
                            {
                                context.Fail("This session has expired or has been invalidated.");
                            }
                            return;
                        }
                        if (!int.TryParse(subject, out var id) || tokenId is null ||
                            !await context.HttpContext.RequestServices.GetRequiredService<PostgreSqlTokenStore>()
                                .IsActiveAsync(id, tokenId, context.HttpContext.RequestAborted))
                            context.Fail("This session has expired or has been invalidated.");
                    }
                };
            });
        services.AddAuthorization(options =>
        {
            options.AddPolicy("PortalUser", policy => policy.RequireAuthenticatedUser().RequireClaim("identity_kind", "app_user"));
            options.AddPolicy("LegacyTeacher", policy => policy.RequireAuthenticatedUser().RequireAssertion(context => !context.User.HasClaim("identity_kind", "app_user")));
        });
        return services;
    }
}
