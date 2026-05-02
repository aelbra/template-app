# Adaptar template pra .NET

Esse template vem com Node por padrão. Pra .NET (8/9/10):

## 1. Trocar Dockerfile

```Dockerfile
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY *.sln Directory.Build.props Directory.Packages.props ./
COPY src/ src/
RUN dotnet restore
RUN dotnet publish src/MeuApp.Api/MeuApp.Api.csproj -c Release -o /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:10.0
WORKDIR /app
COPY --from=build /app/publish .
EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080
ENTRYPOINT ["dotnet", "MeuApp.Api.dll"]
```

## 2. Trocar package.json por csproj + adicionar pacotes OTel

Em `Directory.Packages.props` (ou no `.csproj` se não usar central package management):

```xml
<PackageVersion Include="OpenTelemetry.Extensions.Hosting" Version="1.15.3" />
<PackageVersion Include="OpenTelemetry.Exporter.OpenTelemetryProtocol" Version="1.15.3" />
<PackageVersion Include="OpenTelemetry.Instrumentation.AspNetCore" Version="1.15.2" />
<PackageVersion Include="OpenTelemetry.Instrumentation.Http" Version="1.15.1" />
<PackageVersion Include="OpenTelemetry.Instrumentation.Runtime" Version="1.15.1" />
```

## 3. Configurar OTel no `Program.cs`

```csharp
using OpenTelemetry.Logs;
using OpenTelemetry.Metrics;
using OpenTelemetry.Resources;
using OpenTelemetry.Trace;

var builder = WebApplication.CreateBuilder(args);

var otelServiceName = builder.Configuration["OTEL_SERVICE_NAME"] ?? "meu-app-api";
builder.Services.AddOpenTelemetry()
    .ConfigureResource(r => r.AddService(otelServiceName))
    .WithTracing(t => t
        .AddAspNetCoreInstrumentation()
        .AddHttpClientInstrumentation()
        .AddOtlpExporter())
    .WithMetrics(m => m
        .AddAspNetCoreInstrumentation()
        .AddHttpClientInstrumentation()
        .AddRuntimeInstrumentation()
        .AddOtlpExporter());

builder.Logging.AddOpenTelemetry(o =>
{
    o.IncludeFormattedMessage = true;
    o.IncludeScopes = true;
    o.SetResourceBuilder(ResourceBuilder.CreateDefault().AddService(otelServiceName));
    o.AddOtlpExporter();
});

var app = builder.Build();
app.MapHealthChecks("/health");
// ... resto da app
app.Run();
```

As envvars `OTEL_EXPORTER_OTLP_ENDPOINT`, `OTEL_SERVICE_NAME`, `OTEL_RESOURCE_ATTRIBUTES` já vêm do compose — o SDK lê automaticamente.

## 4. Compose: ajustar porta

No `deploy/docker-compose.swarm.yml`, a porta padrão do template é 3000. .NET costuma rodar em 8080:

```yaml
environment:
  - ASPNETCORE_URLS=http://+:8080
labels:
  - "traefik.http.services.${APP_NAME}-api-${ENV_SLUG}.loadbalancer.server.port=8080"
healthcheck:
  test: ["CMD", "wget", "--spider", "-q", "http://localhost:8080/health"]
```

Ou define `API_PORT=8080` no GitHub Variables.

## 5. CI: trocar setup-node por setup-dotnet

Em `.github/workflows/ci.yml`:

```yaml
- uses: actions/setup-dotnet@v4
  with:
    dotnet-version: "10.0.x"
- run: dotnet restore
- run: dotnet build --no-restore
- run: dotnet test --no-build
```

## Referência

O `aelbra/ulbra-sau` é a referência completa de uma app .NET seguindo esse padrão.
