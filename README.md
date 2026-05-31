# Vagon Test Sistemi

Tren vagonu statik test rig kontrol ve veri toplama uygulaması.

## Mimari

```
Tauri Desktop App (Windows)
├── Frontend: Vite + React + TypeScript
└── Backend: ASP.NET Core (.NET 8) — Tauri sidecar olarak gömülü .exe
    ├── REST API (profiller, testler, ayarlar)
    ├── SignalR hub (live telemetri push)
    ├── OPC UA client (S7-1500'e bağlanır)
    └── SQLite (EF Core) + JSON dosyaları (profiller)

Siemens S7-1500 PLC (OPC UA server)
├── 4× lift silindiri  (vagon kaldırma)
├── 2× tampon silindiri (senkron, kuvvet kontrollü)
└── 1× kanca silindiri  (itme/çekme kuvvet kontrollü)

Her silindir: 1× loadcell + 2× basınç transmitteri (ΔP için)

Kontrol: Cascade PID — tamamı PLC'de
  İç döngü:  basınç,  ~50 Hz (PID_Compact)
  Dış döngü: loadcell, 5-10 Hz (kuvvet setpoint'i iç döngüye)
  Backend rolü: profil setpoint'ini 5-10 Hz'de stream eder
```

## Klasör Yapısı

| Yol | İçerik |
|-----|--------|
| `backend/` | .NET 8 solution — Api, Core, Plc, Data, Profiles + testler |
| `frontend/` | Tauri + Vite + React + TypeScript |
| `docs/` | Mimari, OPC UA tag sözleşmesi, profil formatı |
| `plc/` | TIA Portal kaynakları (export'lar, tag listesi) |
| `scripts/` | dev/build PowerShell scriptleri |

## Geliştirme

> ⚠️ Henüz scaffold aşamasında. Komutlar projeler oluşturulduktan sonra çalışacak.

```powershell
# Geliştirme — backend watch + tauri dev paralel
./scripts/dev.ps1

# Üretim build — backend publish + tauri release bundle
./scripts/build-all.ps1
```

## Gereksinimler

- .NET 8 SDK (LTS)
- Node.js 22+
- Rust + Cargo
- Tauri CLI 2.x
- Siemens TIA Portal (PLC tarafı)

## Lisans

TBD
