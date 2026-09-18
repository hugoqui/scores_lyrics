using Serilog;
using Symphony.Cloud.Autenticacion;
using Symphony.Cloud.BaseDeDatos;
using Symphony.Cloud.Configuration;
using Symphony.Cloud.Iglesias;
using Symphony.Cloud.Registro;
using Symphony.Cloud.Usuarios;
using Symphony.Sesiones;
using Symphony.Sesiones.Web;

// Antes de leer la configuración: este comando existe justamente para cuando
// todavía no hay claves que leer.
if (args.Contains("generar-claves"))
{
    GeneracionDeClaves.Imprimir(
        CloudOptions.ClavePrivadaVariable, "SYMPHONY_NODE_CLAVE_PUBLICA_NUBE", Console.Out);
    return;
}

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

// El único camino que ve más allá de una iglesia: el login, antes de saber
// cuál es la suya (docs/operacion/roles-de-base-de-datos.md).
builder.Services.AddSingleton<AccesoComoPropietario>();

// Quien emite las sesiones que la nube firma con su propia clave (ADR 0016).
builder.Services.AddSingleton(new EmisorDeSesiones(cloudOptions.ClaveDeFirma, Emisor.Nube));

// Quien traduce el token de cada petición en una sesión firmada (spec R7).
// De momento solo acepta las que emitió la propia nube: para aceptar además
// las de un nodo hace falta conocer su clave pública por iglesia, y eso se
// reparte en el módulo 008.
builder.Services.AddSingleton(
    VerificadorDeSesiones.ParaLaNube([cloudOptions.ClaveDeFirma.ClavePublica]));

// Add services to the container.
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();

var app = builder.Build();

app.Use((contexto, siguiente) => MiddlewareDeErroresNoAtendidos.Invocar(contexto, siguiente, app.Logger));

app.UsarSesionesFirmadas();

app.MapearAutenticacion();
app.MapearUsuarios();
app.MapearInstrumentos();
app.MapearDispositivos();

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

// `dotnet run -- crear-iglesia ...` (spec R9, fase 7): la primera iglesia sin
// panel. Va después de aplicar migraciones porque necesita el esquema, y usa
// symphony_propietario (docs/operacion/roles-de-base-de-datos.md) porque crea
// la fila de iglesia, que symphony_app solo puede leer.
if (args.Contains(ComandoCrearIglesia.Nombre))
{
    var codigoDeSalida = await ComandoCrearIglesia.Ejecutar(
        args, app.Services.GetRequiredService<AccesoComoPropietario>(), Console.In, Console.Out);
    System.Environment.Exit(codigoDeSalida);
}

app.Run();

// Visible para WebApplicationFactory<Program> en las pruebas de arranque.
public partial class Program;
