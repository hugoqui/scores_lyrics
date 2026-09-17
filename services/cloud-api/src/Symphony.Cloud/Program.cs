using Serilog;
using Symphony.Cloud.BaseDeDatos;
using Symphony.Cloud.Configuration;
using Symphony.Cloud.Registro;

var builder = WebApplication.CreateBuilder(args);

// spec R7: registro estructurado, con nivel y marca de tiempo, a consola —
// que es lo que el VPS recoge. Los secretos se filtran antes de escribirse
// (EnriquecedorDeSecretos).
builder.Host.UseSerilog((contexto, configuracion) => configuracion
    .MinimumLevel.Information()
    .Enrich.FromLogContext()
    .Enrich.With<EnriquecedorDeSecretos>()
    .WriteTo.Console(outputTemplate:
        "{Timestamp:yyyy-MM-dd HH:mm:ss.fff zzz} [{Level:u3}] {Message:lj}{NewLine}{Exception}"));

var cloudOptions = CloudOptions.FromEnvironment(builder.Environment.EnvironmentName);
builder.Services.AddSingleton(cloudOptions);

// La única puerta a la base ([ADR 0017]): el dominio no recibe conexiones.
builder.Services.AddSingleton<AccesoALaNube>();

// Add services to the container.
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();

var app = builder.Build();

app.Use((contexto, siguiente) => MiddlewareDeErroresNoAtendidos.Invocar(contexto, siguiente, app.Logger));

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

// Migraciones antes de atender la primera petición (spec R1, ADR 0010).
// Si fallan, el proceso muere: un esquema del que no se sabe nada es peor
// que un servicio apagado. Antes de morir, se registra completo (spec R7).
try
{
    MigracionesDeLaNube.Aplicar(cloudOptions, app.Logger);
}
catch (Exception excepcion)
{
    app.Logger.LogCritical(excepcion, "La nube no pudo aplicar las migraciones al arrancar");
    throw;
}

// `dotnet run -- migrar` aplica las migraciones y sale, sin levantar el servidor.
if (args.Contains("migrar"))
{
    return;
}

app.Run();

// Visible para WebApplicationFactory<Program> en las pruebas de arranque.
public partial class Program;
