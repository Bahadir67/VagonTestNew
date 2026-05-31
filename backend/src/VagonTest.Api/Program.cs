var builder = WebApplication.CreateBuilder(args);

// Tauri sidecar: bind only to localhost on a fixed port.
// Browser/WebView traffic from the Tauri app reaches us via http://127.0.0.1:5050.
builder.WebHost.UseUrls("http://127.0.0.1:5050");

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// CORS — allow Vite dev server (localhost and 127.0.0.1 are different origins)
// and Tauri's webview origin. Tightened in production by build environment check.
builder.Services.AddCors(opts =>
{
    opts.AddDefaultPolicy(p => p
        .WithOrigins(
            "http://localhost:5173",
            "http://127.0.0.1:5173",
            "tauri://localhost",
            "https://tauri.localhost")
        .AllowAnyHeader()
        .AllowAnyMethod());
});

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors();

app.MapGet("/health", () => Results.Ok(new { status = "ok", service = "VagonTest.Api" }));

app.Run();
