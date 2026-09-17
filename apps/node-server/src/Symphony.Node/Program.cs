using Serilog;
using Symphony.Node.BaseDeDatos;
using Symphony.Node.Configuration;
using Symphony.Node.Registro;
using Symphony.Sesiones;
using Symphony.Sesiones.Web;

// Antes de leer la configuración: este comando existe justamente para cuando
// todavía no hay claves que leer. La pública es la que hay que entregarle a la
// nube para que pueda verificar lo que este nodo emita.
if (args.Contains("generar-claves"))
{
    GeneracionDeClaves.Imprimir(
        NodeOptions.ClavePrivadaVariable, "SYMPHONY_CLOUD_CLAVE_PUBLICA_DEL_NODO", Console.Out);
    return;
}

var builder = WebApplication.CreateBuilder(args);

// spec R7: registro estructurado, con nivel y marca de tiempo, a consola y a
// archivo rotado — en el nodo no hay nadie mirando una terminal el domingo.
// Los secretos se filtran antes de escribirse (EnriquecedorDeSecretos).
builder.Host.UseSerilog((contexto, configuracion) => configuracion
    .MinimumLevel.Information()
    .Enrich.FromLogContext()
    .Enrich.With<EnriquecedorDeSecretos>()
    .WriteTo.Console(outputTemplate:
        "{Timestamp:yyyy-MM-dd HH:mm:ss.fff zzz} [{Level:u3}] {Message:lj}{NewLine}{Exception}")
    .WriteTo.File(
        Path.Combine(AppContext.BaseDirectory, "logs", "nodo-.log"),
        rollingInterval: RollingInterval.Day,
        retainedFileCountLimit: 14,
        outputTemplate:
            "{Timestamp:yyyy-MM-dd HH:mm:ss.fff zzz} [{Level:u3}] {Message:lj}{NewLine}{Exception}"));

var nodeOptions = NodeOptions.FromEnvironment(builder.Environment.EnvironmentName);
builder.Services.AddSingleton(nodeOptions);

// El nodo acepta las dos firmas y ninguna de las dos consulta a nadie
// ([ADR 0016]): la de la nube, para las sesiones emitidas desde fuera, y la
// suya, para las que emitió él mismo el domingo sin internet. Y solo de su
// iglesia: un token de otra congregación se cae aquí (spec R1).
builder.Services.AddSingleton(VerificadorDeSesiones.ParaUnNodo(
    nodeOptions.IglesiaId,
    [nodeOptions.ClavePublicaDeLaNube, nodeOptions.ClaveDeFirma.ClavePublica]));

// Add services to the container.
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();

var app = builder.Build();

app.Use((contexto, siguiente) => MiddlewareDeErroresNoAtendidos.Invocar(contexto, siguiente, app.Logger));

app.UsarSesionesFirmadas();

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
    MigracionesDelNodo.Aplicar(nodeOptions, app.Logger);

    // Y con el esquema ya al día, que la base sea la de esta iglesia (spec R1).
    IdentidadDelNodo.Verificar(nodeOptions, app.Logger);
}
catch (Exception excepcion)
{
    app.Logger.LogCritical(excepcion, "El nodo no pudo arrancar contra su base de datos");
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
