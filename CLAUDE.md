# Vagon Test Sistemi — Proje Anayasası

Bu dosya projenin sabit referans noktasıdır. **Buradaki kararlar oturumdan oturuma değişmez** — değişiklik gerekirse önce buraya yazıp sonra kod uygulanır. Yeni bir Claude Code oturumu açıldığında ilk okunacak dosya budur.

---

## 1. Proje Amacı

Tren vagonlarının **statik** mekanik testlerini yapan bir test rig'inin kontrol ve veri toplama yazılımı.

- **Kullanım yeri:** Endüstriyel ortam, tek operatör, tek bilgisayar (Windows)
- **Statik testler:** Yavaş yükleme profilleri (saniyeler/dakikalar). Dinamik/yorulma testi değil.
- **Test türleri:**
  - **Tampon testi** — 2× tampon silindiri **senkron**, kuvvet kontrollü
  - **Kanca testi** — 1× silindir, itme ve çekme yönünde kuvvet kontrollü
  - **Lift** — 4× silindir, vagonu test yüksekliğine kaldırır (kuvvet kritik değil, pozisyon kritik)

### Köken — kanıtlanmış sistemin modernizasyonu

Bu **sıfırdan bir sistem değil.** Aynı test rig'i daha önce **B&R PLC (Automation Studio) + Delphi HMI** ile yazıldı ve **üretimde çalıştı/kanıtlandı**. Yani bilgi mimarisi, ekran düzeni ve test mantığı sahada doğrulanmış.

Bu proje o sistemin **modern stack'e taşınması + zenginleştirilmesi**:
- **PLC**: B&R → **Siemens S7-1500** (mantık port edilir, sıfırdan tasarım değil — bkz. Faz 3)
- **HMI**: Delphi → **Tauri + React + .NET** (Bölüm 4)
- **Yeni katmanlar**: cloud sync, AI yorum, çoklu site, raporlama, multi-tenant SaaS (Faz 6-7)
- **UX**: modernizasyon (ayarlanabilir tema + birim sistemi — Bölüm 4/6)

**Strateji**: önce **parite-çekirdek** (Delphi'nin yaptığını modern stack'te birebir) → sonra aşamalı zenginleştirme. Scope creep'ten kaçın. Delphi referans ekranları memory'de (`project-origin-delphi-br`).

### Ürün bağlamı — SaaS prototipi

Bu sistem **diğer firmalara satılacak SaaS ürününün prototipi** olarak geliştiriliyor. Mimari şu şekilde ikiye ayrılır:

- **Local (saha)**: PLC kontrolü, profil execution, test çalıştırma, telemetri toplama — **internete tamamen bağımsız** çalışır. Operatör kabloyu çekse bile testler durmaz.
- **Cloud (Berlin sunucusu)**: Kullanıcı/auth, test geçmişi merkezi depo, AI yorum, raporlama, çoklu site/operatör dashboard'u.

Şu an **single-tenant** olarak ilerliyoruz (prototip, tek müşteri varsayımı). Ama kod ve şema **multi-tenant migration'ı acısız** olacak şekilde yazılacak (bkz. Bölüm 9). Bu, "sonra refactor ederiz" tuzağına düşmemek için baştan disiplin gerektirir — 1 saat şimdi, haftalarca acı yok.

**Test–internet bağımsızlığı HARD CONSTRAINT'tir** (bkz. Bölüm 12 — Asla Yapma).

### Ürün bağlamı — SaaS prototipi

Bu sistem **diğer firmalara satılacak SaaS ürününün prototipi** olarak geliştiriliyor. Mimari şu şekilde ikiye ayrılır:

- **Local (saha)**: PLC kontrolü, profil execution, test çalıştırma, telemetri toplama — **internete tamamen bağımsız** çalışır. Operatör kabloyu çekse bile testler durmaz.
- **Cloud (Berlin sunucusu)**: Kullanıcı/auth, test geçmişi merkezi depo, AI yorum, raporlama, çoklu site/operatör dashboard'u.

Şu an **single-tenant** olarak ilerliyoruz (prototip, tek müşteri varsayımı). Ama kod ve şema **multi-tenant migration'ı acısız** olacak şekilde yazılacak (bkz. Bölüm 9). Bu, "sonra refactor ederiz" tuzağına düşmemek için baştan disiplin gerektirir — 1 saat şimdi, haftalarca acı yok.

**Test–internet bağımsızlığı HARD CONSTRAINT'tir** (bkz. Bölüm 12 — Asla Yapma).

---

## 2. Donanım Mimarisi

```
Operatör PC (Windows) ──Ethernet/OPC UA──► Siemens S7-1500 PLC
                                                  │
                                                  ▼
                                          ┌───────────────┐
                                          │ Hidrolik güç  │
                                          │   ünitesi     │
                                          └───────┬───────┘
                                                  ▼
                            ┌─────────────────────┼─────────────────────┐
                            ▼                     ▼                     ▼
                       4× Lift Cyl          2× Tampon Cyl          1× Kanca Cyl
                       (her birinde:        (senkron, kuvvet        (itme+çekme,
                        loadcell +          kontrollü +             kuvvet kontrollü
                        ΔP için 2 bsnç      her birinde              + loadcell)
                        transmitteri)       loadcell)
                                                  │                     │
                                                  ▼                     ▼
                                      [Vagonun karşı ucu]    [Vagonun karşı ucu]
                                      2× Reaksiyon Loadcell   1× Reaksiyon Loadcell
                                      (silindirsiz, sadece    (silindirsiz, sadece
                                       sensör)                 sensör)
```

**Sayım:**
- **7 hidrolik silindir** (4 lift + 2 tampon + 1 kanca)
- **10 loadcell**:
  - 4× lift silindirine bağlı (her birinde 1)
  - 2× tampon silindirine bağlı (her birinde 1)
  - **2× tampon reaksiyon loadcell** — vagonun simetrik karşı ucunda, silindir yok, sadece sensör
  - 1× kanca silindirine bağlı
  - **1× kanca reaksiyon loadcell** — karşı uçta, silindirsiz
- **14 basınç transmitteri** (7 silindir × 2 port — giriş ve çıkış, ΔP için)

**Resmi terminoloji (Delphi/PLC ile birebir — UI bunları kullanır):**

| Rol | Resmi ad | Kapasite | Komponent ID |
|-----|----------|----------|--------------|
| Lift krikoları | **Kriko Silindir 1-4** | (TBD) | `cyl_lift_1..4` |
| Tampon silindirleri | **120T Test Silindir 1-2** | 120 ton (120.000 kgF) | `cyl_buffer_l`, `cyl_buffer_r` |
| Kanca silindiri | **200T Test Silindir** | 200 ton (200.000 kgF) | `cyl_hook` |
| Reaksiyon loadcell'ler | **Reflect Loadcell 1-3** | — (sensör) | `lc_buffer_l/r_reaction`, `lc_hook_reaction` |

Operatör test "tampon/kanca/lift" der; HMI "120T/200T/Kriko" gösterir. Eski Delphi sisteminde "Test Silindir" = tampon+kanca grubu; lift = "Kriko Silindir".

**Reaksiyon loadcell'in amacı:**
Tampon ve kanca testlerinde silindir vagonun bir ucundan kuvvet uygular; reaksiyon loadcell karşı uçtaki transmisyon kuvvetini ölçer. **Vagon yapısının kuvveti taşıdığını doğrular** — testin ana çıktısı. Lift'te reaksiyon yok çünkü krikolar simetrik olarak kaldırır, karşılaması gereken bir karşı kuvvet yok.

**Sensör rolleri:**
- **Loadcell (silindirde)** — uygulanan kuvvet, slow + hassas, **kontrol döngüsünün dış geri beslemesi**
- **Loadcell (reaksiyon)** — karşı uçta ölçülen transmisyon, **kontrol döngüsünde değil**, sadece test sonucu/safety ölçümü
- **Basınç transmitterleri (2× silindirde)** — silindir giriş ve çıkış portları, ΔP'den anlık kuvvet türevi, fast + iç kontrol döngüsü için

---

## 3. Kontrol Mimarisi — Cascade PID (PLC'de)

```
            ┌──────────────────────────────────────────────────┐
            │  PLC (Siemens S7-1500) — TÜM kontrol burada      │
Profil      │                                                  │
setpoint ──►│  Dış döngü (loadcell, 5-10 Hz)                  │
(5-10 Hz)   │      │                                           │
            │      ▼                                           │
            │  İç döngü (basınç ΔP, ~50 Hz)                   │
            │      │                                           │
            │      ▼                                           │
            │  Hidrolik valf çıkışı                            │
            └──────────────────────────────────────────────────┘
```

**KESİN KURAL:** PID Windows'ta **çalışmaz**. Windows real-time değil; OPC UA latency'si öngörülemez; özellikle senkron tampon kontrolünde latency tehlikeli. Backend rolü **sadece** profil setpoint'ini 5-10 Hz'de PLC'ye streamlemektir.

**Dış döngü loadcell hangisi:** Silindire bağlı olan (komuta veren taraf). **Reaksiyon loadcell kontrolde değildir** — sadece ölçüm ve safety. Eğer reaksiyon loadcell kontrole alınırsa, silindirin loadcell'iyle reaksiyon arasındaki vagon yapısı zayıflık gösterse bile sistem buna kapatmaya çalışır, gerçek kuvveti maskeler.

**Lift safety — max force limit:** Lift krikoları **pozisyon kontrolü** ile çalışır (vagonu istenen yüksekliğe kaldırır). Ama kuvvet `maxForceLimit` değerine ulaşırsa **pozisyon hareketi durdurulur + uyarı verilir**. Sebep: vagon takıldıysa / dengesizse / bir tekeri raya kilitlenmişse kriko zorlanır → mekanik hasarı önle. PLC'de inner force-cap'li outer position loop olarak uygulanır. Operatör manuel müdahale ile devam eder.

### Operasyonel model — temas tespiti → relatif/senkron (KRİTİK)

Her silindirin vagona değme (temas) noktası **farklı kotta** olabilir (jacking noktaları, vagon geometrisi). Bu yüzden mutlak stroke yerine **kendi temas noktasından relatif** çalışılır. Otomatik senaryolarda faz makinesi:

```
Hazır → Yaklaşma → Temas → Uygulama → (Tutma) → Geri Çekme → Tamamlandı
                                                          (+ E-stop/fault her an)
```

- **Temas tespiti:** Silindir yavaş ilerler; `|kuvvet| > contactThreshold` aşılınca o pozisyonu **referans sıfır** alır. (Eşik değeri açık soru — bkz. Bölüm 10.)
- **Lift senaryosu:** Operatör **katılımcı krikoları seçer** (Hepsi / Ön 1-2 / Arka 3-4 / Sol 1-3 / Sağ 2-4 / özel). Seçililer temas bulur → **eşit relatif +X mm SENKRON** yükselir. (Eşit relatif = temas anındaki duruş korunur. Mutlak tesviye doğrulaması ayrı eğim sensörü ister — Bölüm 10.)
- **Tampon senaryosu:** 2 silindir temas bulur → kuvvet profilini **kilitli senkron** uygular; Reflect LC transmisyonu izler.
- **Kanca senaryosu:** Temas → itme **veya** çekme kuvvet profili; Reflect izler.

**Manuel mod** bundan ayrıdır — temas tespiti YOK, operatör doğrudan pozisyon/kuvvet komutu verir (sorumluluk operatörde), her silindir bağımsız.

**Katmanlar:** Temas tespiti + senkron + relatif hareket **PLC'de** koşar (gerçek-zaman, güvenlik). Backend profili 5-10 Hz stream'ler. Frontend senaryoyu **seçer + başlatır + izler**. **Faz 1 mock'ta** bu faz makinesi simülatörde modellenir (UX doğrulaması) — sonra PLC'ye birebir map'lenir.

**Frekanslar:**
- İç döngü (basınç PID): ~50 Hz (PLC scan cycle'da)
- Dış döngü (loadcell PID): 5-10 Hz (PLC içinde)
- Backend → PLC setpoint stream: 5-10 Hz (dış döngünün dış setpoint'i)
- UI telemetri (SignalR): 10 Hz hedef (gerekirse düşürürüz)

---

## 4. Yazılım Yığını (sabit)

### Local taraf (saha bilgisayarı)
| Katman | Teknoloji | Versiyon |
|--------|-----------|----------|
| Frontend | Tauri + Vite + React + TypeScript | Tauri 2.11, React 19, Vite 8 |
| Backend | ASP.NET Core | **.NET 8 LTS** (8.0.421) |
| PLC iletişimi | OPC UA | OPCFoundation.NetStandard.Opc.Ua |
| Persistence | SQLite (EF Core) + JSON dosyaları | EF Core 8.x |
| Real-time push | SignalR | AspNetCore 8 |
| State (frontend) | Zustand | 5.x |
| Grafikler | Recharts (genel), saf SVG (profil editörü) | Recharts 3.x |
| İkonlar | lucide-react | 1.x |
| Rust toolchain | rustup stable | ≥ 1.88 |

> **3D KALDIRILDI.** Önce Three.js ile 3D vagon sahnesi denendi, **terk edildi**: (1) operatör aracında 3D operasyonel değil, data-first gerekir; (2) silindir stroke'undan türetilen vagon pozu fiziksel olarak yanıltıcı (gerçek eğim ayrı sensör ister). Yön: Delphi'deki gibi **data-first kart + canlı grafik** düzeni. Detay memory `project-origin-delphi-br`.

### Birim sistemi (ayarlanabilir)
- **Base birim: kgF** (Delphi/PLC ile aynı). Tüm kuvvet verisi kgF tutulur.
- UI'da gösterim Settings'ten seçilir: **kgF · tF (ton-force) · N · kN**. Dönüşüm `frontend/src/lib/units.ts`'te tek yerde; gösterim katmanı `formatForce(value, unit)`'ten geçer.
- Seçim `useSettingsStore`'da, localStorage'da kalıcı.

### Tema sistemi (ayarlanabilir)
- Renkler **CSS custom properties** (`:root` / `[data-theme]`) ile; hard-coded hex yok.
- Settings'ten **tema (dark/light) + accent/renk bileşenleri** değiştirilebilir, localStorage'da kalıcı.
- Varsayılan: koyu endüstriyel. `useThemeStore` yönetir.

### Ekran tasarım katmanı (görsel editör) — Serbest canvas (Delphi tarzı)
Operatör/mühendis ekranları **sürükle-bırak** dizilir. Kullanıcı kararı: **tam serbest yerleşim** (mutlak x/y, üst üste gelebilir, piksel kontrol) — Delphi form designer'ı gibi. Puck (akış-DnD) bunu temiz yapamadığı için **kendi mutlak-konum canvas'ımız** yazıldı.
- **Aktif model**: `frontend/src/designer/` — `FreeCanvasPage.tsx` (editör), `FreeScreenPage.tsx` (operatör runtime, salt-okuma + fit-scale), `freeStore.ts` (Zustand+persist, widget = `{id,type,x,y,w,h,props}`, çıktı JSON), `FreeWidget.tsx` (pointer drag+resize, 8px snap), `widgetRegistry.tsx` (widget tanımları + alan/property şeması).
- **Konum**: izole modül, **ayrı repo DEĞİL** — enstrümanları (`components/instruments/` via `designer/live.tsx`), `lib/units.ts`, tema token'larını operatör runtime ile **paylaşır** (tek doğruluk kaynağı). `/designer` + `/screen` route'ları `React.lazy` → editör/Mantine **operatör kontrol bundle'ına girmez**.
- **Palet iki aile**: (1) PHOSPHOR enstrümanlarımız, `cylinderId` ile **canlı telemetriye bağlı**; (2) **Mantine** (`@mantine/core` 9.x) form/chrome atomları. `<MantineProvider forceColorScheme={theme}>` ile sarılı; tema dark/light token'ları takip eder.
- **Sabit tuval**: hedef çözünürlük (1920×1080 / 1366×768 / 1280×1024); operatör tarafı pencereye fit-scale. Layout JSON `freeStore` localStorage (POC) → Faz 2'de backend/SQLite → cloud sync.
- Mantine, **operatör SCADA enstrümanlarının yerine değil**; enstrümanlar özel SVG bileşenlerimiz kalır.
- **Puck** (`@puckeditor/core`) alternatif olarak repo'da duruyor (`DesignerPage.tsx`/`ScreenPage.tsx`/`puck.config.tsx`, route'a bağlı DEĞİL) — akış-tabanlı düzen gerekirse diye. Serbest yerleşim tercih edildiği için pasif.

### Cloud taraf (Berlin sunucusu)
| Katman | Teknoloji | Versiyon |
|--------|-----------|----------|
| Cloud API | ASP.NET Core (local'den ayrı solution) | **.NET 8 LTS** |
| Cloud DB | PostgreSQL (Docker container) | 16-alpine |
| Auth | **ASP.NET Core Identity + JWT** | bundled with .NET 8 |
| Cloud Frontend | React + Vite (web build, Tauri YOK) | React 19, Vite 8 |
| Frontend serving | nginx (alpine, container içi) | latest stable |
| AI worker | .NET 8 (BackgroundService) + Anthropic SDK | Anthropic.SDK NuGet |
| Reverse proxy | nginx (host'ta, Docker dışında) | sistem nginx |
| SSL | certbot + Let's Encrypt | sistem certbot |
| Orchestration | Docker Compose plugin v5+ | Docker 29.x |

### Neden bu seçimler
- **.NET 8 LTS:** Kasım 2026'ya kadar destek. .NET 9 STS bitti (Mayıs 2026). .NET 10 LTS Kasım'da çıkacak — o zaman migrasyon kolay.
- **OPC UA:** S7-1500'ün dahili sunucusu var. Endüstri standardı, tip güvenli. S7.NET/Sharp7'ye göre daha overhead ama daha güvenli.
- **Tauri sidecar:** Backend self-contained .exe olarak bundle'lanır, tek tıkla launch. ASP.NET'in tüm gücü + native pencere.
- **Cascade PID PLC'de:** Yukarıda gerekçe.
- **SQLite + JSON (local) + PostgreSQL (cloud):** Local single-process — SQLite ideal. Cloud multi-connection + ileride büyüyecek — Postgres standart seçim. Profiller JSON çünkü insan-okunabilir ve dış sistemlere taşıması kolay.
- **ASP.NET Core Identity + JWT (auth):** Veri tamamen kendi sunucumuzda kalır (data sovereignty). Supabase/Auth0'a göre vendor lock-in yok, ücretsiz, kalıcı. Sosyal OAuth gerekirse 1 NuGet paketi ile eklenir.
- **Local frontend = Tauri (desktop), cloud frontend = web React:** Aynı React komponentlerinin büyük kısmı paylaşılabilir ama farklı build hedefleri. Cloud frontend tarayıcıdan açılır (Tauri'ye gerek yok).
- **AI worker .NET 8:** API ile aynı runtime — ekstra Python ortamı yok, deploy basit. Anthropic/OpenAI SDK'ları .NET'te yeterli.

---

## 5. Repo Yapısı

```
C:\Project1\VagonTestSistemi_Yeni\
├── CLAUDE.md                         ← bu dosya (yön belirleyici)
├── README.md                         ← geliştirici giriş
├── .gitignore
│
├── backend/                          ← .NET 8 solution
│   ├── global.json                   ← .NET 8.0.421'e pin
│   ├── VagonTest.sln
│   ├── src/
│   │   ├── VagonTest.Api/            ← Web API + SignalR hub + Program.cs
│   │   ├── VagonTest.Core/           ← Domain (Cylinder, ForceProfile, TestRun, …)
│   │   ├── VagonTest.Plc/            ← OPC UA client + tag wrapper'ları
│   │   ├── VagonTest.Data/           ← EF Core DbContext + SQLite + JSON repo
│   │   └── VagonTest.Profiles/       ← Profile executor / setpoint streamer
│   └── tests/
│       ├── VagonTest.Core.Tests/
│       └── VagonTest.Plc.Tests/      ← OPC UA mock'a karşı
│
├── frontend/                         ← Tauri 2 + Vite + React 19 + TS
│   ├── src-tauri/                    ← Rust shell + sidecar config
│   │   ├── tauri.conf.json           ← identifier: com.vagontest.app, port 5173
│   │   ├── Cargo.toml                ← tauri, tauri-plugin-log, tauri-plugin-shell
│   │   ├── binaries/                 ← publish edilmiş backend exe (gitignore'da)
│   │   └── src/lib.rs                ← release'de sidecar spawn eder
│   ├── vite.config.ts                ← React plugin, port 5173 strict
│   ├── tsconfig.json                 ← jsx: react-jsx, strict: true
│   ├── package.json
│   └── src/
│       ├── main.tsx, App.tsx, App.css, global.css
│       └── components/
│           └── ProfileEditor/        ← mouse ile profil çizim
│               ├── ProfileEditor.tsx
│               ├── ProfileEditor.module.css
│               ├── types.ts          ← ProfilePoint, ForceProfile, EditorConfig
│               ├── coords.ts         ← pixel↔data dönüşümleri
│               ├── useProfileEditor.ts  ← state hook (undo/redo)
│               └── io.ts             ← JSON save/load
│
├── docs/                             ← mimari dökümanlar (YAZILACAK)
│   ├── opcua-tags.md                 ← TBD: PLC tag sözleşmesi (Faz 3)
│   ├── force-profile-format.md       ← TBD: JSON şema (Faz 2)
│   ├── plc-program-spec.md           ← TBD: TIA Portal STL/SCL tasarımı (Faz 3, Claude yazar)
│   ├── saas-architecture.md          ← TBD: sync protokolü, JWT lifecycle (Faz 6)
│   └── safety-design.md              ← TBD: E-stop, watchdog, failsafe (Faz 5)
│
├── plc/                              ← TIA Portal kaynakları (kullanıcı yazar, Faz 3)
│   └── (TIA Portal proje export'u — STL/SCL kaynak dosyaları)
│
└── scripts/
    ├── dev.ps1                       ← dotnet watch + tauri dev paralel
    ├── publish-backend.ps1           ← self-contained .exe → sidecar konumuna
    └── build-all.ps1                 ← publish + tauri build (installer üretir)
```

---

## 6. Sabit Sözleşmeler (değiştirme!)

### Birimler
- **Kuvvet:** ton (saha pratiği). Backend hesaplarda gerekirse kN'e dönüştürülür ama dış arayüzde her zaman ton.
- **Zaman:** saniye (s), profillerde ondalık destekli.
- **Basınç:** bar (saha pratiği).
- **Pozisyon:** mm (lift için).

### Ağ portları (sabit, çakışmasın)

**Local (saha PC):**
- Local backend HTTP+SignalR: `http://127.0.0.1:5050` (sadece localhost)
- Vite dev server: `http://127.0.0.1:5173`
- OPC UA (PLC): `opc.tcp://<plc-ip>:4840` (default)

**Cloud (Berlin sunucusu, 144.91.112.223):**
- vagontest-db (postgres 16): `127.0.0.1:5440` → container 5432
- vagontest-api (REST + SignalR): `127.0.0.1:8110` → container 8080
- vagontest-frontend (nginx static): `127.0.0.1:3210` → container 80
- vagontest-ai-worker: internal-only (no host port; container ağında konuşur)
- Host nginx reverse proxy: `vagontest.mihanbase.com` → 80→443 redirect → location'lar
  - `/` → 127.0.0.1:3210 (frontend)
  - `/api/` → 127.0.0.1:8110 (REST)
  - `/hub/` → 127.0.0.1:8110 (SignalR WebSocket, Upgrade header'lı)

**Önemli**: Berlin sunucusunda bu port'lar başka projelerin port'larıyla çakışmıyor (telematics, b2b, portal, vs.). Yeni port eklemeden önce sunucuya `ss -tlnp` ile bak.

### Naming
- Backend namespace: `VagonTest.<Layer>`
- Frontend tip dosyaları: `kebab-case.ts`, komponentler `PascalCase.tsx`
- CSS modules: `Component.module.css`
- OPC UA tag isimleri: TBD (`docs/opcua-tags.md` yazıldığında bağla)
- Komponent ID'ler (DB):
  - **Silindirler**: `cyl_lift_1..4`, `cyl_buffer_l`, `cyl_buffer_r`, `cyl_hook`
  - **Loadcell'ler**: silindire bağlı olan `cyl_X.force` field'ında, **reaksiyon** loadcell ise `cyl_X.forceReaction` (sadece tampon ve kanca için). Reaksiyon loadcell **kontrol döngüsünde değil** — ayrı bir entity'ye çıkarmak Faz 3'te PLC tag tablosu netleşince değerlendirilir.

### Dil
- **UI metinleri:** Türkçe (operatör Türk)
- **Kod, comment, log mesajları:** İngilizce
- **Commit mesajları:** İngilizce

### Hata yaklaşımı
- **Backend:** Fail fast — silindir komutu PLC'ye gitmezse exception fırlat, log'la, UI'a göster. Sessiz başarısızlık yok.
- **Frontend:** Backend bağlantısı kopunca header'daki badge kırmızı (`/health` 5 sn'de bir ping). Kullanıcı durumu görmeden işlem yapamaz.
- **PLC bağlantı kaybı:** Backend yeniden bağlanma denesin (exponential backoff, max 30 sn), her denemeyi log'la. Bu sırada otomatik test çalışıyorsa PLC'ye **STOP** komutu gönderilir (önceki bağlantıdan kalmış olabilir).

### Safety (TBD ama prensip net)
- E-stop fiziksel buton **her zaman** PLC'de donanım katmanında. Yazılım katmanı E-stop'u sadece raporlar, üretmez.
- Watchdog: PLC, backend'den 2 sn boyunca heartbeat almazsa otomatik testi durdurur (failsafe).
- Otomatik test sırasında manuel komutlar bloklu.

---

## 7. Geliştirme Komutları

```powershell
# İlk clone'dan sonra (bir kere):
.\scripts\publish-backend.ps1     # sidecar binary'i üretir (cargo check için gerekli)

# Günlük geliştirme:
.\scripts\dev.ps1                 # dotnet watch + tauri dev paralel
# Backend: 127.0.0.1:5050, Frontend HMR: 127.0.0.1:5173

# Production bundle (MSI/NSIS installer):
.\scripts\build-all.ps1
# Çıktı: frontend\src-tauri\target\release\bundle\
```

**Dev modu davranışı:**
- Tauri release build'de bundle'lı sidecar'ı kendi spawn eder.
- **Dev'de spawn etmez** (`cfg!(debug_assertions)` kontrolü). Backend ayrıca `dotnet watch` ile koşar — hot reload için.

---

## 8. Mimari Akış — Veri Yolu

```
[Operatör tıklar "Test Başlat"]
        │
        ▼ HTTP POST /api/tests
[VagonTest.Api]
        │
        ▼ profil setpoint'ini 5-10 Hz'de stream
[VagonTest.Plc.OpcUaClient.WriteSetpoint(value)]
        │
        ▼ OPC UA write
[S7-1500 PLC]
        │ Cascade PID koşar (içeride)
        ▼
[Hidrolik valf] → [Silindir] → [Loadcell + ΔP] → [PLC okur]
                                                       │
                                                       ▼ OPC UA subscription
[VagonTest.Plc.OpcUaClient.OnTelemetry(point)]
        │
        ▼ SignalR push
[Frontend: TelemetryChart]
        │
        ▼ Aynı zamanda kaydet
[VagonTest.Data → SQLite tablosu: TelemetryPoint]
```

---

## 9. Yol Haritası — 7 Faz

### Faz 0 — Scaffold ✅ (tamamlandı)
Repo iskeleti, .NET 8 backend solution, Tauri 2 + React 19 + TS frontend, sidecar config, dev/build scriptleri, profil editörü prototipi.

### Faz 1 — UI iskeleti + mock veri (devam ediyor — 29 Mayıs: Delphi-paritesi yeniden tasarım)
Tüm ekranlar mock data ile çalışır. PLC/DB yok. UX'i erken doğrula.

**Karar:** Routing = React Router 7 (HashRouter, Tauri uyumlu). Mock veri = `src/mocks/`. Sidebar = daralıp genişleyebilen.

**Yön (29 Mayıs):** 3D-merkezli kokpit **terk edildi** (Bölüm 4 nedeni). Yerine **Delphi sisteminin kanıtlanmış data-first düzeni**: kart-tabanlı canlı izleme + profil tablo/grafik + PID + sensör/alarm ekranları. Referans: Delphi ekran görüntüleri (memory `project-origin-delphi-br`).

**Sayfa yapısı (Delphi paritesi + zenginleştirme):**

| Route | Sayfa | Delphi karşılığı |
|-------|-------|------------------|
| `/` (index) | **Test Kontrol** — canlı silindir kartları + 3 basınç + motor + Reflect LC + valf durumu + canlı Kuvvet/Zaman grafiği + E-stop | Test Kontrol |
| `/manual` | **Manuel Kontrol** — her silindir **bağımsız**: pozisyon setpoint (hepsi) + kuvvet setpoint (tampon/kanca, itme+çekme) + jog + git/sıfırla. Temas tespiti YOK (ham kontrol). Otomatik test çalışırken kilitli | (Delphi'de manuel) |
| `/auto` | **Otomatik Test** — senaryo seç (katılımcı seçimi + relatif değer / profil) → temas tespitli faz makinesi → senkron yürütme + faz timeline. Senaryolar: Senkron Kaldırma (seçili krikolar), Tampon Senkron Profil, Kanca İtme/Çekme | (Delphi'de oto) |
| `/profiles` | **Test Profil** — profil tablosu + mouse-çizim editör (mevcut) + grafik önizleme. Profiller burada tanımlanır, Otomatik Test'te tüketilir | Test Profil |
| `/controller` | **Kontrolcü Ayarları** — silindir başına PID (kuvvet/pozisyon/sistem) + AutoTune | Kontrolcü Ayarları |
| `/sensors` | **Sensörler** — sensör listesi/durumu | Sensörler |
| `/alarms` | **Arızalar & Uyarılar** — alarm/fault listesi | Arızalar |
| `/history` | **Test Geçmişi** — arama + drill-down *(zenginleştirme)* | (zayıf) |
| `/settings` | **Ayarlar** — PLC bağlantı + tag binding + **birim seçimi (kgF/tF/N/kN)** + **tema/renk** | (kısmen) |

> **Tasarım dili (29 Mayıs):** Operatör arayüzü tasarım dili `operator-ui-design` workflow'u ile (4 paralel yön → jüri → sentez) kilitlendi. Hedef: özgün (generic değil, Delphi klonu değil) + zengin (radyal gösterge, sparkline, senkron sapma bandı, transmisyon, faz timeline) + okunabilir + tüm ekranlara tutarlı ölçeklenen. Bir daha baştan yapılmaz. Sentez spec'i implementasyona temel.

**Test Kontrol düzeni (data-first, Delphi'den):**
- Sol: motor on/off + 3 basınç göstergesi (Pompa/Kriko Hattı/Test Hattı) + yerel/uzak
- Orta: silindir kartları — 4× Kriko Silindir, 2× 120T Test Silindir, 1× 200T Test Silindir (pozisyon mm + kuvvet birim-cinsinden + ΔP + limit bar)
- Sağ: 3× Reflect Loadcell + valf durumları (renk kodlu)
- Alt: canlı Kuvvet/Zaman grafiği
- Üst: durum şeridi (operatör/uzak, soğutucu fan, birim seçici)
- E-stop: her an erişilebilir, büyük

**Altyapı (baştan kurulur):**
- **Birim**: `lib/units.ts` (kgF base) + `useSettingsStore.forceUnit` → tüm kuvvet `formatForce()`'tan
- **Tema**: CSS custom properties + `useThemeStore` (dark/light + accent), localStorage persist
- **Mock**: `cylinders.ts` (gerçek isim/kapasite, kgF), `telemetry.ts` (kgF base + basınç/motor/valf), `profiles.ts`, `testHistory.ts`

**Operating mode lifecycle** (Zustand): idle → manual (Test Kontrol açık) → auto (test başladı, manuel kilitli) → manual (bitti) → idle (çıkış).

### Faz 2 — Backend domain + REST + SQLite
- `VagonTest.Core` domain: `Cylinder`, `ForceProfile`, `TestRun`, `TelemetryPoint`
- `VagonTest.Data` EF Core `DbContext` + ilk migration
- REST endpoint'leri: Profiles CRUD, Tests CRUD, Cylinders read
- Frontend mock layer'ı gerçek API'ye geçirir (mock modülleri tek dosya değiştirmeyle)
- `docs/force-profile-format.md` — JSON şema

### Faz 3 — OPC UA entegrasyonu + PLC programı (TIA Portal)

**Windows tarafı** (Claude uygular):
- `VagonTest.Plc` client (OPCFoundation.NetStandard.Opc.Ua)
- Mock OPC UA server'a karşı `VagonTest.Plc.Tests` (PLC olmadan dev mümkün olsun)
- Tag binding configuration (`appsettings.json` + DB)
- Bağlantı lifecycle: reconnect, watchdog, bağlantı kaybında auto-STOP

**PLC tarafı** (Claude spec yazar — TIA Portal'a erişimi yok; kullanıcı uygular):

> **PORT, sıfırdan tasarım değil.** Mevcut sistemin PLC mantığı **B&R (Automation Studio)** üzerinde yazılı ve üretimde kanıtlanmış. Faz 3 PLC işi = bu kanıtlanmış mantığı **S7-1500 / TIA Portal'a port etmek**. Kullanıcı B&R kaynağını paylaşırsa Claude spec'i ona göre yazar (cascade PID katsayıları, safety state machine, profil execution mantığı zaten doğrulanmış — platform/dil çevirisi). B&R ST → Siemens SCL en yakın eşleme.

- `docs/opcua-tags.md` — tag listesi + data block layout sözleşmesi (Windows ve PLC ortak referansı)
- `docs/plc-program-spec.md` — TIA Portal STL/SCL için tasarım (B&R mantığından port edilir):
  - **Cascade PID**: iç döngü (pressure ΔP, ~50 Hz scan cycle'da) + dış döngü (loadcell, 5-10 Hz)
  - **Safety state machine**: idle / manual / auto / e-stop / fault — geçiş kuralları + watchdog
  - **Per-cylinder valve drive logic** — 4× lift + 2× tampon (senkron) + 1× kanca
  - **Manual mode handler** — jog komutları, hız limitleri
  - **Auto mode handler** — Windows'tan gelen setpoint stream'i tüketme
  - **E-stop & watchdog** — donanım E-stop loop'u + backend heartbeat timeout failsafe
- Kullanıcı TIA Portal'da uygulayıp test rig'de doğrular. Paste edilen STL/SCL'yi Claude review eder, öneri verir.

**Çıktı**: PLC kodu + Windows OPC UA client + mock server karşılıklı çalışır durumda. Faz 4'e zemin hazır.

### Faz 4 — Real-time telemetri + profil executor
- SignalR hub
- Frontend canlı telemetri grafikleri (Recharts)
- `VagonTest.Profiles` setpoint streamer (5-10 Hz'de PLC'ye)
- Profil interpolasyonu (noktalar arası lineer)

### Faz 5 — Safety + raporlama + production polish (local)
- Watchdog (backend ↔ PLC heartbeat, kayıpta failsafe)
- E-stop state machine (yazılım katmanı sadece raporlar)
- Test sonucu raporu (PDF veya Excel — format kararı Faz 5'te)
- Installer cilası, otomatik update, hata raporlama

### Faz 6 — Cloud backend + Auth + Sync (Berlin sunucusu)
- **Cloud solution** (`cloud/` klasörü, local backend'den ayrı):
  - `VagonTest.Cloud.Api` — ASP.NET Core REST + SignalR
  - `VagonTest.Cloud.Data` — EF Core PostgreSQL DbContext + migrations
  - `VagonTest.Cloud.Domain` — TestRun, User, Organization (multi-tenant hazırlık), TelemetryTrace
  - `VagonTest.Cloud.Auth` — ASP.NET Core Identity + JWT issuance/refresh
- **Multi-tenant migration hazırlığı** (single-tenant başla ama):
  - Tüm domain entity'lerde `TenantId` (Guid, default = `Tenants.Default`)
  - `ITenantContext` interface ile data access her zaman tenant bilir (şimdilik default döner)
  - JWT claim'inde `tenant_id` baştan var (şimdilik default)
  - Migration `ALTER TABLE ADD COLUMN` ile değil, baştan tabloda
- **Docker stack** (`/opt/vagontest/` sunucuda):
  - `docker-compose.yml`: vagontest-db + vagontest-api + vagontest-frontend
  - `.env`: POSTGRES_*, JWT_SECRET, JWT_ISSUER, JWT_AUDIENCE
- **Host nginx config**: `/etc/nginx/sites-available/vagontest.mihanbase.com` (HTTP→HTTPS, `/api/`, `/hub/`, `/` location'ları)
- **SSL**: `certbot --nginx -d vagontest.mihanbase.com`
- **Local backend sync**:
  - `VagonTest.Sync` background service — test bittiğinde cloud'a push
  - Offline-capable: internet yokken `PendingSync` SQLite tablosunda bekler, bağlantı gelince push
  - JWT token local'de cache'lenir (30 gün geçerli, refresh online'a geçince)
  - **Test çalıştırmayı internete bağımlı kılmaz** (HARD CONSTRAINT, Bölüm 12)
- **Cloud frontend** (`cloud-frontend/`, ayrı Vite projesi):
  - React 19 + TypeScript + Zustand + Recharts (local frontend ile ortak komponent yaklaşımı, ama Tauri YOK)
  - Login + Test history + Test detail + (sonra) Multi-site dashboard
  - `npm run build` → static dist → `cloud-frontend/dist/` → docker image'a kopyalanır
- **Deploy**: `git push` (lokal) → SSH (Berlin) → `cd /opt/vagontest && git pull && docker compose up -d --build`
- **docs/saas-architecture.md** — sync protokolü, JWT lifecycle, multi-tenant migration path

### Faz 7 — AI yorum servisi
- `VagonTest.Cloud.AiWorker` — BackgroundService, SQL queue tüketici
- Yeni test cloud'a geldiğinde otomatik job: trace + metadata → Anthropic API → narrative comment
- Saklanan yorum: `TestRun.AiComment` (text), `TestRun.AiAnomalies` (JSON: anomali listesi)
- Cloud frontend ve local frontend yorumu okur ve gösterir (read-only)
- İlk PoC kapsamı:
  - **Test sonu narrative**: "Tampon testi başarılı. Sol/sağ senkron %99.2. Tepe kuvvet 195t (hedef 200t, %2.5 sapma)."
  - **Anomali tespiti**: Trace'te beklenmedik osilasyon, ani düşüş, silindirler arası gecikme
- Bekleyen kapsam (Faz 7+ değil, sonra): profil tavsiyesi (geçmiş'ten öğrenme), doğal dil sorgu, otomatik rapor metni
- Anthropic API key `.env`'de, **asla repo'da değil**
- Cost guard: günlük çağrı tavanı `.env`'de — aşılırsa job sıraya alınır ama API çağrılmaz
- **Local frontend internet yoksa AI yorumu görünmez** ama test çalıştırma etkilenmez (cached yorumlar görünür)

---

## 10. Açık Tasarım Soruları (henüz karar verilmedi)

Bu sorular ilgili komponentin implementasyonuna gelince sorulacak — şimdiden tahmin yürütülmeyecek:

**Local taraf:**
1. **OPC UA tag isimlendirme şeması** — PLC programcısı ile anlaşılacak (`Cylinder_Lift_1_Setpoint` mı, `cyl.lift[1].sp` mı, vs.). Loadcell ve reaksiyon loadcell tag'leri ayrı entity mi olacak (`Sensor.Loadcell_Buffer_L_Reaction`) yoksa silindirin altında mı (`Cylinder.Buffer_L.LoadcellReaction`)?
2. **Test sonuçları raporu formatı** — PDF mi Excel mi her ikisi mi? Hangi alanlar?
3. **Profil snap-to-grid varsayılan** — şu an kapalı, açık mı olsun?
4. **Birden çok eşzamanlı profil** — tampon + kanca + lift için ayrı profiller mi, bütünleşik mi?
5. **Test geçmişi saklama süresi (local SQLite)** — sınırsız mı, eski testler arşivlensin mi? Cloud'a sync olduktan sonra local'den silinsin mi?
6. **Reaksiyon loadcell delta threshold** — tampon/kanca testinde silindir loadcell ile reaksiyon loadcell arasındaki fark ne kadarsa "vagon transmisyon kabul edilemez" sayılır? Şu an mock'ta 2t; gerçek değer test standardına göre belirlenecek.
7. **Lift maxForceLimit default** — varsayılan kaç kgF? Şu an mock'ta 40000 kgF; vagon ağırlığına göre operatör değiştirebilmeli mi yoksa donanım bazlı sabit mi?
8. **Temas tespiti eşiği (contactThreshold)** — silindir vagona değdi sayması için kuvvet eşiği ne? Kapasitenin %'si mi (örn. %2), sabit kgF mi, silindir başına ayarlanabilir mi? Yaklaşma hızı?
9. **Lift tesviye doğrulaması** — eşit relatif kaldırma temas anındaki duruşu korur; vagonun gerçekten yatay olduğunu doğrulamak için eğim sensörü (inclinometer) / köşe yükseklik sensörü gerekir mi, yoksa relatif yeterli mi?

**Cloud/SaaS taraf (Faz 6+):**
10. **Kullanıcı/yetki rolleri** — Operator, Engineer, Admin? Operator sadece test çalıştırır, Engineer profil düzenler, Admin kullanıcı yönetir? Yoksa basit 2 rol (User/Admin) yeter mi?
11. **Sync veri kapsamı** — Test özeti + raporlar yeter mi, yoksa full telemetri trace'leri (downsample edilmiş, gzip'li) de cloud'a gitsin mi? Drill-down cloud'da yapılsın mı yoksa sadece local'de mi?
12. **Multi-tenant migration tetikleyici** — İlk ikinci müşteri imzalanınca mı, yoksa belli bir kullanıcı eşiği aşılınca mı? Hangi data backfill stratejisi?
13. **Test PDF rapor üretimi** — Local'de mi (offline-capable), cloud'da mı (gotenberg/QuestPDF), ikisinde de mi?
14. **AI yorum dili** — Türkçe mi, İngilizce mi, kullanıcı dili tercihine göre mi? Anthropic'ten dönecek yanıtı saklı mı tutalım yoksa sadece son üretileni mi?
15. **AI cost guard threshold** — Günlük kaç API çağrısı/token? Aşılınca operatöre uyarı mı, sessiz queue mu?
16. **Prod domain** — `vagontest.mihanbase.com` test ortamı, prod için ayrı domain alınacak mı (örn. `app.vagontest.com`) yoksa test domain'i prod'a mı yükseltilir?
17. **Çoklu site/saha** — Tek müşterinin birden çok atölyesi olursa her atölye ayrı sahiplik mi, organizasyon altında site hiyerarşisi mi?

---

## 11. Asla Yapma Listesi

**Local taraf:**
- ❌ PID kodunu Windows'ta çalıştırma (PLC'de kalsın)
- ❌ Local backend'i `0.0.0.0`'a bind etme — sadece `127.0.0.1` (uzak erişim yok)
- ❌ `dotnet publish`'i `PublishTrimmed=true` ile yapma (EF Core ve reflection-heavy kodlarla risk)
- ❌ Tauri WebView'a shell-execute izni verme (sidecar Rust'tan spawn ediliyor, frontend'in shell'e ihtiyacı yok)
- ❌ Profil noktalarında zamanı eşit veya geri tıklamasına izin verme (monoton artan zaman zorunlu)
- ❌ SQLite dosyasını commit'leme (`.gitignore`'da)
- ❌ FluentAssertions 8+ (ücretli) — 7.2.0'a pinli kal
- ❌ EF Core 9+ (.NET 9 gerekir) — 8.* pin'inde kal
- ❌ Kullanıcı PATH'ini onayı olmadan değiştirme

**Donanım/kontrol mantığı:**
- ❌ **Reaksiyon loadcell'i kontrol döngüsünde kullanma.** Tampon/kanca testlerinde dış PID döngüsü silindire bağlı loadcell'i okur. Reaksiyon loadcell sadece **ölçüm + safety/test sonucu** içindir. Reaksiyon kontrole alınırsa vagon yapısı zayıflık gösterse bile sistem buna kapatmaya çalışır, gerçek transmisyon kuvvetini maskeler.
- ❌ **Lift krikolarda maxForceLimit'i 0'a veya çok yüksek değere bırakma.** maxForceLimit lift'in safety bound'u — pozisyon kontrolü yaparken kuvvet bunu aşarsa hareket durur + uyarı. 0 → kriko hiç kalkmaz; çok yüksek → vagonu kırma riski. Varsayılan değer Faz 5 safety design'da netleşecek.
- ❌ **Otomatik test sırasında manuel komut gönderme.** Operating mode "auto" iken UI blok olur, backend de blok olur (PLC'ye giden komutları reddeder). Tek istisna: STOP/E-stop.

**SaaS / cloud / offline-first:**
- ❌ **Test çalıştırmayı internete bağımlı kılma — HARD CONSTRAINT.** Login, profil seçimi, test başlatma, telemetri kaydetme, test bitirme adımlarının hiçbiri online check yapmamalı. Cloud sync ve AI yorum **opsiyonel katman**; internet yokken sessizce sıraya alınır.
- ❌ Cloud API'yi `0.0.0.0`'a bind etme — Docker içinde `0.0.0.0:8080` OK (container internal) ama host port mapping `127.0.0.1:8110:8080` olmalı (sadece host nginx erişsin)
- ❌ JWT secret'ı, Anthropic API key'i, postgres şifresini repo'ya commit'leme — sadece `.env` ve `.env` `.gitignore`'da
- ❌ Mevcut Berlin sunucusu port'larından birini alma (bkz. Bölüm 6 — sunucu üzerinde `ss -tlnp` ile teyit et)
- ❌ Supabase / Auth0 / 3rd-party auth servisine geçme — ASP.NET Core Identity + JWT sabit (data sovereignty kararı, Bölüm 4)
- ❌ Multi-tenant migration tedbirlerini ertelemek — `TenantId` kolon ve `ITenantContext` interface'i **baştan** olacak, "sonra ekleriz" deme
- ❌ Cloud frontend'i Tauri'ye bundle'lama — cloud frontend tarayıcıdan açılan saf web app
- ❌ AI yorum servisini local'e koyma — API key güvenliği ve cost tracking için cloud-only
- ❌ Test trace'ini ham (raw) 100Hz cloud'a gönderme — önce downsample (10Hz) + gzip
- ❌ Production'da PostgreSQL veri volume'ünü `docker compose down -v` ile silme

---

## 12. Bilinen Tuzaklar

- **Tauri sidecar `externalBin` dev'de bile binary'nin varlığını ister.** Yeni clone'da önce `publish-backend.ps1` çalıştırılmalı yoksa `cargo check` / `tauri dev` fail eder.
- **Rust 1.85 yetersiz** — Tauri 2.11 deps en az 1.88 ister. `rustup update stable` ile düzeltilir.
- **Sistem `dotnet` (`C:\Program Files\dotnet`) ile user `dotnet` (`%USERPROFILE%\.dotnet`)** ikisi birden kuruluysa hangisi PATH'te önce ise o görünür. Bu projede sistem dotnet (8.0.421) önce — `.\backend\global.json` ile ayrıca pinli.
- **React 19 JSX namespace global değil** — TSX'te `JSX.Element` yerine `import type { JSX } from "react"` lazım.

---

## 13. SaaS Mimarisi — Local + Cloud (detay)

### 13.1 Topoloji

```
┌─ SAHA (her vagon/atölye için bir kurulum) ─────────────────────────┐
│                                                                     │
│  Tauri Desktop App ──HTTP──► VagonTest.Api (local 127.0.0.1:5050)  │
│         │                            │                              │
│         │                            ▼                              │
│         │                  OPC UA ──► S7-1500 PLC                  │
│         │                            │                              │
│         │                            ▼                              │
│         │                  Local SQLite (PRIMARY, offline-capable)  │
│         │                            │                              │
│         │                            ▼  test bitince / periodik    │
│         │                  VagonTest.Sync (BackgroundService)       │
│         │                            │                              │
│         │       JWT cache (30g)      │ PendingSync kuyruğu          │
└─────────┼────────────────────────────┼──────────────────────────────┘
          │ (login + AI yorum okuma)   │ HTTPS (JWT)
          │                            │
          ▼                            ▼
┌─ BERLIN SERVER (144.91.112.223, /opt/vagontest/) ──────────────────┐
│                                                                     │
│  Host nginx ──► HTTPS termination + reverse proxy                  │
│       │                                                             │
│       ├─► /        → vagontest-frontend (127.0.0.1:3210)           │
│       ├─► /api/    → vagontest-api      (127.0.0.1:8110)           │
│       └─► /hub/    → vagontest-api      (127.0.0.1:8110, WS)       │
│                              │                                      │
│                              ▼                                      │
│                    PostgreSQL (vagontest-db, 127.0.0.1:5440)       │
│                              │                                      │
│                              ▼  yeni test geldiğinde job            │
│                    vagontest-ai-worker ──► Anthropic API           │
│                                            (narrative + anomalies) │
└─────────────────────────────────────────────────────────────────────┘
```

### 13.2 Sync protokolü (özet)

- **Tetik**: Local'de bir test tamamlanır (state = completed). `VagonTest.Sync` background service `PendingSync` tablosuna kayıt ekler.
- **Push**: Internet varsa derhal, yoksa ilk fırsatta. POST `/api/sync/test-runs` — JSON: test run metadata + downsample'lı trace + raporu. JWT header'da.
- **Idempotency**: Local'in ürettiği UUID server-side primary key olur. Aynı UUID iki kez gelirse 200 OK + no-op. Re-try güvenli.
- **Conflict**: Cloud "source of truth" değil — local primary. Çakışma olmaz çünkü test run'lar immutable (bitince değişmez).
- **AI yorum**: Server cloud'da üretir, local pull eder (`GET /api/test-runs/{id}/ai-comment`). Yoksa null döner.

### 13.3 Auth lifecycle

1. **İlk login**: Local app açılır, hiç token yok → kullanıcı internet üzerinden login → JWT alır (30 gün geçerli) + refresh token (90 gün geçerli) → her ikisi de **local SQLite'da şifreli** saklanır (DPAPI, Windows kullanıcı bazlı).
2. **Sonraki açılışlar**: JWT cache'den okunur, expire değilse direkt kullanılır → internet check YOK, offline çalışılabilir.
3. **JWT expire**: Refresh token ile yenilenir (internet gerekir, en fazla 90 günde bir).
4. **Refresh token expire (90 gün)**: Yeniden tam login gerekir. Bu süre içinde operatör hiç internet kullanmadan çalışmış olabilir.
5. **Saha senaryosu**: Yıllık 1-2 ziyarette internet → JWT yenilenir → arada offline çalışır.

### 13.4 Multi-tenant migration path

Tüm cloud entity'ler (TestRun, Profile, User, vs.) baştan `TenantId Guid` kolonuna sahip olur. Şu an tüm satırlar tek bir default tenant'a (`Tenants.Default = 00000000-0000-0000-0000-000000000001`) işaret eder.

```csharp
// Baştan böyle yazılır (Faz 6'da):
public interface ITenantContext
{
    Guid CurrentTenantId { get; }
}

// Şu an default döndüren implementation, sonra JWT claim'den okuyacak şekilde değişecek:
public class SingleTenantContext : ITenantContext
{
    public Guid CurrentTenantId => Tenants.Default;
}

// Repository'ler her query'de WHERE tenant_id = @currentTenantId ekler.
// Şu an gereksiz görünebilir ama "sonra" eklemek = haftalarca acı.
```

Multi-tenant'a geçiş (Faz 6+ ileride):
1. `SingleTenantContext` yerine `JwtTenantContext` swap edilir
2. Yeni `Tenants` tablosu doldurulur (var olan default tenant kalır)
3. Yeni müşteri için tenant create endpoint + UI eklenir
4. **Hiçbir mevcut data backfill gerekmez** çünkü zaten `TenantId` doluydu

### 13.5 Local vs cloud sorumluluk paylaşımı

| Sorumluluk | Local | Cloud |
|------------|-------|-------|
| PLC ile haberleşme | ✅ tek başına | ❌ |
| Profil execution | ✅ tek başına | ❌ |
| Test çalıştırma | ✅ tek başına | ❌ |
| Telemetri kaydetme | ✅ primary | 🔄 sync sonrası kopya |
| Manuel kontrol | ✅ tek başına | ❌ |
| Profil düzenleme (editor) | ✅ tek başına | 🔄 ileride cloud editor da olabilir |
| Test geçmişi görüntüleme | ✅ son N test | ✅ tüm geçmiş, çoklu site |
| Raporlama | ✅ tek test için PDF | ✅ aggregate raporlar |
| AI yorum üretme | ❌ | ✅ tek başına |
| AI yorum gösterme | ✅ cached + pull | ✅ |
| Kullanıcı yönetimi | ❌ (login UI hariç) | ✅ tek başına |
| Çoklu site dashboard'u | ❌ | ✅ tek başına |
| E-stop / safety | ✅ tek başına (PLC zaten donanım) | ❌ |

**Altın kural**: Local olmazsa cloud da olmaz (sync gönderecek veri yok). Cloud olmazsa local çalışır (sadece sync ve AI yorum geç gelir).

---

## 14. Memory ve CLAUDE.md ilişkisi

- **CLAUDE.md (bu dosya):** Projenin nesnel/sabit gerçekleri. Kim okursa okusun aynı anlamı çıkarır.
- **`~/.claude/projects/.../memory/`:** Kullanıcı tercihleri, geçmiş kararlar, agy delegasyon kuralı, Berlin sunucusu referansı, vb. **Bu dosyaya değil oraya yaz.**
- Çakışma olursa **bu dosya kazanır**. Memory güncellenir.
