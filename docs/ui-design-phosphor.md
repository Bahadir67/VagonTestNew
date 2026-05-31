# KILITLI TASARIM: PHOSPHOR — Laboratuvar Sınıfı Ölçüm Konsolu (Precision Instrument Console)

## Distinctive Signature
- TEK DEĞİŞMEZ RENK GRAMERİ — 'accent = fosfor sinyali; kırmızı/sarı yalnızca alarm/limit; limit aşımında accent warn/err'e DEVRİLİR'. Kullanıcı accent'i turkuaz/amber yapsa bile alarm dili sabit kalır. Bu tek kural generic dashboard'un 'her kart farklı renk + gradient' kalabalığını öldürür, 9 ekrana taşınan tek gramer olur, güvenliği temalardan bağımsız kılar. Kartlar nötr grafit kalır; renk yalnızca CANLI ÖLÇÜM ve ALARM taşır.
- GÖMÜLÜ CAM ENSTRÜMAN YÜZEYİ — her silindir kartı bir ölçüm aletinin önyüzü: sol dikey strok cetveli (LinearStroke) + merkezde limit-bölgeli radyal manometre (RadialGauge) + setpoint hedef imleci aynı yayda + alt fosfor sparkline (TrendStrip). Kart = renkli istatistik kutusu DEĞİL, fiziksel cihaz çukuru (instrument-face inset gölge + bezel halka). Delphi'nin 7-segment LED/3D kabartma kutularından da, Grafana yumuşak-yüzeyinden de ayrışır.
- DOMAİNE ORGANİK ÜÇ ÖLÇÜM GÖRSELİ — (1) Lift senkronunu yan yana HİZALI LinearStroke dolgularıyla çıplak gözle okutma; (2) Tampon L/R SyncBand: merkez-0 sapma çubuğu + canlı 'SENKRON %99.2'; (3) Silindir↔Reflect TransmissionMeter: üst aktif bar (accent) + alt PASİF/etkileşimsiz reflect bar (bronz, input içermez) — testin ana çıktısını tek görselde. Kanca için 0-merkezli iki yönlü yay (çekme − / itme +).
- DİJİTAL CİHAZ OKUMASI — tüm sayılar var(--mono) + tabular-nums + slashed-zero, sağa hizalı (hane sola büyür); 10 Hz'de hane zıplamaz, gerçek kalibratör davranışı. Sakin arayüz: silindir sabitken ekran neredeyse hareketsiz, sadece sparkline mikro-titrer; >%95 limitte TEK alarm hareketi (1.5 s nabız, prefers-reduced-motion'da statik err).

## TOKENS
/* ============================================================
   PHOSPHOR instrument tokens — global.css içindeki MEVCUT
   :root / [data-theme="dark"] / [data-theme="light"] bloklarına
   EKLENİR (override DEĞİL). Tümü var()/color-mix referanslı —
   accent runtime değişince türevler otomatik güncellenir.
   HARD-CODED HEX YOK (reflect-trace dahil token).
   ============================================================ */

/* ---- :root (tema-bağımsız, accent türevleri) ---- */
:root {
  /* accent + accent-dim zaten var. Eklenenler: */
  --accent-faint: color-mix(in srgb, var(--accent) 22%, transparent);
  --trace: var(--accent);                 /* canlı ölçüm izi = fosfor */
  --setpoint-line: var(--text-dim);       /* hedef referans (kesik) */
  --tick: var(--text-faint);              /* skala minor çentik */
  --tick-major: var(--text-dim);          /* skala major çentik + sayı */

  /* Radius/spacing enstrüman gramerı (mevcut .card radius 4px korunur) */
  --radius-instrument: 4px;
  --radius-readout: 3px;

  /* Hareket süreleri — tek kaynak */
  --t-smooth: 120ms;   /* gösterge/iz takibi */
  --t-snap: 200ms;     /* setpoint imleç sıçraması */
}

/* ---- [data-theme="dark"] (varsayılan) ---- */
:root,
[data-theme="dark"] {
  --instrument-face: #070d11;             /* gösterge çukuru, karttan koyu */
  --instrument-bezel: #141d24;            /* gösterge çevresi metal halka */
  --grid-line: color-mix(in srgb, var(--border) 60%, transparent);
  --grid-line-major: var(--border);
  --track: #14202a;                       /* radyal/bar boş kanal */
  --trace-glow: color-mix(in srgb, var(--accent) 32%, transparent);
  --spark-fill: color-mix(in srgb, var(--accent) 14%, transparent);
  --reflect-trace: #b08968;               /* reflect izi — bronz, ALARM DEĞİL */
  --reflect-track: color-mix(in srgb, #b08968 22%, transparent);
  --flow-idle: color-mix(in srgb, var(--text-faint) 55%, transparent);
  /* Yarı saydam alarm bölgeleri (yay/grid arka ipucu) */
  --zone-ok:   color-mix(in srgb, var(--ok)   12%, transparent);
  --zone-warn: color-mix(in srgb, var(--warn) 16%, transparent);
  --zone-err:  color-mix(in srgb, var(--err)  18%, transparent);
  /* Enstrüman yüzeyi gömülü cam iç-gölge */
  --face-inset: inset 0 1px 3px color-mix(in srgb, #000 40%, transparent);
  --readout-glow: 0 0 6px var(--trace-glow);  /* aktif okuma fosfor parıltısı */
}

/* ---- [data-theme="light"] (matte-LCD, glow zayıf) ---- */
[data-theme="light"] {
  --instrument-face: #f7fafd;
  --instrument-bezel: #e9eef4;
  --grid-line: color-mix(in srgb, var(--border) 70%, transparent);
  --grid-line-major: var(--border);
  --track: #e1e8f0;
  --trace-glow: color-mix(in srgb, var(--accent) 20%, transparent);
  --spark-fill: color-mix(in srgb, var(--accent) 12%, transparent);
  --reflect-trace: #9c6b43;
  --reflect-track: color-mix(in srgb, #9c6b43 18%, transparent);
  --flow-idle: color-mix(in srgb, var(--text-faint) 60%, transparent);
  --zone-ok:   color-mix(in srgb, var(--ok)   14%, transparent);
  --zone-warn: color-mix(in srgb, var(--warn) 18%, transparent);
  --zone-err:  color-mix(in srgb, var(--err)  20%, transparent);
  --face-inset: inset 0 1px 3px color-mix(in srgb, var(--text) 8%, transparent);
  --readout-glow: none;                    /* gün ışığında glow yok */
}

/* ---- prefers-reduced-motion: tek alarm hareketi + sparkline akışı durur ---- */
@media (prefers-reduced-motion: reduce) {
  :root { --t-smooth: 0ms; --t-snap: 0ms; }
}

/* ============================================================
   ÇÖZÜLEN MEVCUT BORÇLAR (uygulamadan önce):
   1) Control.module.css .estop: #c0392b/#7a1f17/#ffd9d4
      → border var(--err); background var(--err-bg); color var(--err).
   2) LiftControlPanel.tsx: style={{accentColor:"#d4a857"}}
      → CSS class'a taşı, accent-color: var(--warn) (safety = uyarı dili).
   3) LiveChart <Line> stroke #2f7fd4/#5ec2a8/#e0a52e ve
      AutoTestRunner tüm hex (#1c2730/#7b8a94/#0e151b/#2a3640/#5eaaff/#6dd49a)
      → useThemeColors() hook'undan gelen değerlerle değiştir.
   ============================================================ */

## TYPOGRAPHY
İki aile, kesin görev ayrımı (her ikisi de mevcut token). Etiket/başlık/buton: var(--font-ui) = "Segoe UI", system-ui. TÜM sayısal ölçümler + skala çentikleri: var(--mono) = "Cascadia Mono"/"Consolas". Monospace zorunlu — 10 Hz'de canlı değer titrerken hane genişliği sabit kalsın, sayı 'zıplamasın'. Tüm okumalarda: font-variant-numeric: tabular-nums slashed-zero.

Ölçek (kök 14px):
- Radyal ana okuma (kart başına en büyük öğe): 34px mono 600, aktifken text-shadow: var(--readout-glow).
- Birim eki <small>: 12px mono 400 var(--text-faint), baseline'a hizalı, sayıdan margin-left 4px.
- İkincil okumalar (poz/ΔP/setpoint/kapasite): 15px mono 500 var(--text-dim).
- Okuma etiketleri: 9px UI 600 uppercase letter-spacing 0.4px var(--text-faint) (mevcut .cylRowLabel ile uyumlu).
- Kart başlığı/silindir adı: 11px UI 600 uppercase letter-spacing 0.6px var(--text-dim).
- Kanal id rozeti ('L1','BL','HK'): 10px mono 600.
- Skala çentik sayıları: 9px mono var(--text-faint).
- Senkron %: 18px mono 700.

Sayı formatı: HER kuvvet değeri formatForceValue(kgf, unit) → tr-TR (binlik nokta, ondalık virgül: "52.806 kgF"), birim forceLabel(unit) ile AYRI <small> render. Negatif kuvvet (kanca çekme) önünde explicit U+2212 (−), renk DEĞİŞMEZ — yön ön ekle/yay tarafıyla anlatılır. Büyük okumalar sağa hizalı (sağ kenar sabit, hane sola büyür = dijital gösterge davranışı).

## COMPONENT CATALOG

### RadialGauge — Silindirin kalbi — limit-bölgeli kuvvet manometresi, setpoint imleci aynı yayda. Lift'te kuvvet/maxForceLimit oranı (safety yayı), tampon/kanca'da kuvvet/maxForce. Kanca için 0-merkezli iki yönlü.
Visual: Saf SVG viewBox='0 0 200 150', 240° açı (−120°…+120°, alt açık), r=92. Üç katman: (1) bezel halka stroke=var(--instrument-bezel) 2px + 1px üst-açık/alt-koyu kenar; (2) skala yayı: minor tick her %5 stroke=var(--tick), major tick her %25 stroke=var(--tick-major)+9px mono sayı; limit bölgeleri arc-segment: 0–80% fill yok, 80–95% var(--zone-warn), 95–100% var(--zone-err); (3) DOLU YAY: stroke=var(--trace) 8px round-cap, oran kadar dolu, altında 11px kalın ikinci path stroke=var(--trace-glow) opacity .6 (filter blur YERİNE — 7 kart × 60fps performans). Yay ucundan merkeze 1px iğne. Setpoint: yay üzerinde küçük üçgen fill=var(--setpoint-line). Merkezde formatForceValue + <small>birim. Kanca: 0 saat-12'de, sol yarı çekme sağ yarı itme.
Props: value:number (kgF base), max:number (kgF), setpoint?:number, mode:'force'|'position', bidirectional?:boolean, min?:number, unit:ForceUnit, size?:number
Impl: polar→kartezyen helper: pt(cx,cy,r,deg)=>[cx+r*cos(rad), cy+r*sin(rad)]. Dolu yay: pathLength=1 normalize + stroke-dasharray='1 1' + strokeDashoffset=(1−ratio) + transition:stroke-dashoffset var(--t-smooth) ease-out (dasharray transition bazı motorlarda pürüzlü → dashoffset güvenli). Renk: ratio>0.95→stroke var(--err)+halka box-shadow nabız (.pulse class, reduced-motion'da kaldır); >0.8→var(--warn); else var(--trace). React.memo + value prop; sadece ilgili kart re-render. Lift'te value=force, max=maxForceLimit.

### LinearStroke — Silindir pozisyonunu fiziksel strok gibi gösteren dikey cetvel. Lift senkronunu yan yana hizalı dolgularla çıplak gözle okutmanın temeli.
Visual: Dikey SVG, genişlik 26px, yükseklik kart gövdesine eşit. Cetvel min…max, major tick her 50mm + mono sayı (var(--tick-major)), minor her 10mm (var(--tick)). Piston: mevcut pozisyonda 3px yatay çizgi stroke=var(--trace); alttan pozisyona kadar ince dolu kolon fill=var(--trace-glow). Setpoint: kesik yatay işaret stroke=var(--setpoint-line). Temas-sıfır referans: '0⊣' nişanı (küçük <line>+<text>) zeroRef konumunda sabit.
Props: position:number (mm), min:number, max:number, setpoint?:number, zeroRef?:number (temas-sıfır)
Impl: y(v)=height*(1−(v−min)/(max−min)). Piston çizgisi + dolu <rect> height transition var(--t-smooth). Lift kartlarında 4 LinearStroke yan yana dizilince dolgu seviyeleri görsel hizalanır → biri geride kalırsa anında fark edilir. ResizeObserver gereksiz: width=26 sabit, height CSS'ten 100%.

### TrendStrip — Kart altı fosfor sparkline — son ~15 s kuvvet (lift'te pozisyon) mini-trend. 'Ekran ölü mü' sorusunu cevaplar: enstrüman hep nefes alır.
Visual: Saf SVG (Recharts DEĞİL — kart başına 7 adet), tam genişlik × 34px. polyline stroke=var(--trace) 1.5px + altında area fill=var(--spark-fill). Tek orta grid-line var(--grid-line). Sağ uçta son değer noktası fill=var(--trace) r=2. Üst kenarda soluk var(--zone-warn)/var(--zone-err) bandı (limit aşımı izde üst banda girer). Eksen/yazı yok.
Props: series:Float32Array (ring buffer), max:number, min?:number, height?:number
Impl: Modül-seviye ring buffer (telemetry.ts'e ekle: pushTrend(id,v), son 150 örnek). Komponent useRef + useEffect setInterval(100ms) ile slice okur → useMemo path d-string. isAnimationActive yok (ham 10Hz akış). reduced-motion'da son frame statik. Kanca çekmede çizgi 0 altına iner; renk değişmez (yön y-eksenden okunur).

### SyncBand — Tampon L/R senkron kilit göstergesi — testin güvenlik kalbi. İki tampon kartı arasında köprü.
Visual: Yatay SVG ~48px, iki tampon kartını grid-column span ile bağlar. Merkez 0-sapma çizgisi; (L−R) farkı dikey sapma çubuğu (merkez=mükemmel senkron). Bölge: ±tolPct var(--zone-ok), ±warnPct var(--zone-warn), üstü var(--zone-err). Sağda 18px mono 'SENKRON %99.2' (=100−|L−R|/ort×100). Altında iki paralel ince iz: L stroke=var(--trace), R stroke=var(--accent-dim) — üst üste binerse senkron, ayrışırsa boşluk açılır.
Props: forceL:number (kgF), forceR:number (kgF), tolPct?:number (default 1), warnPct?:number (default 3)
Impl: buffer_l.force/buffer_r.force kgF farkından canlı. Sapma çubuğu x-konumu transition var(--t-smooth). Eşik aşımı → % okuması var(--warn)/var(--err) + bant .pulse. Manuel modda iki tampon bağımsız sürülürken sapma doğal büyür → bant nötr kalır, sayı bilgilendirir. Aynı komponent Otomatik Test'te birinci sınıf.

### TransmissionMeter — Silindir↔Reflect karşılaştırıcı — testin ANA ÇIKTISI (vagon kuvveti taşıyor mu) tek görselde. Reflect KONTROL DIŞI kimliğini renk+etkileşimsizlikle iki kat pekiştirir.
Visual: İki yatay bar üst üste. ÜST = silindir loadcell, fill=var(--trace), kalın/aktif. ALT = reflect loadcell, fill=var(--reflect-trace) bronz, INCE + PASİF (input/etkileşim YOK — 'ÖLÇÜM' etiketli, kontrol elemanı görünümü taşımaz). Aralarında 'Δ' rakamı (formatForceValue) + ok. İdeal: barlar hizalı (kuvvet tam iletildi). Track var(--track)/var(--reflect-track). delta>threshold → Δ rakamı var(--warn)/var(--err) + 'Transmisyon!' uyarısı.
Props: cylinderForce:number (kgF), reflectForce:number (kgF), max:number (kgF), deltaThreshold:number (kgF, default 2000), unit:ForceUnit
Impl: force ve forceReaction kgF'den. Bar width transition var(--t-smooth). Lift kartında render EDİLMEZ (reflect yok). KRİTİK: deltaThreshold kgF cinsinden (mevcut delta>2.0 BUG — kgF'de ~2000 olmalı; gerçek değeri Faz 5 standardı belirler). Reflect bar üzerinde hiç onClick/cursor yok.

### SetpointInput — Kalibratör tuş takımı — setpoint girişi + jog + sıfırla + mod toggle. Manuel kontrolün eylem yüzeyi.
Visual: Gömülü alan: background=var(--instrument-face), box-shadow=var(--face-inset), mono sağ-hizalı sayı + ▲▼ stepper + birim <small>. Yanında 'UYGULA' butonu (border var(--border-strong), basılı/active fill=var(--accent-faint)+border var(--accent)). Jog satırı: '− [adım] +', adım seçici (0.1/1/10). 'SIFIRLA' (temas-sıfır referans). Tampon/kanca'da [KUVVET|POZİSYON] segment toggle (mevcut .toggle/.toggleActive, aktif alt-çizgi var(--accent)).
Props: value:number, min:number, max:number, unit?:ForceUnit (kuvvet) | 'mm', step:number, onApply:(v)=>void, onJog:(d)=>void, onReset:()=>void, disabled:boolean
Impl: Giriş kgF base'e toKgf(value,unit) ile çevrilir → onApply. Min/max clamp (Cylinder limits, kanca minForce −200000 negatif). Validasyon: aralık dışı → input border var(--err) + UYGULA disabled. Jog basılı-tut: onPointerDown→setInterval(120ms) hold-repeat. disabled (auto-mode) → tüm alan kilit overlay (dim + Lock ikonu + 'OTOMATİK TEST AKTİF').

### StatusLed — Bağlı/kopuk + durum noktası. Renk-körü için ikincil şekil (içi dolu/boş halka).
Visual: 9px daire: ok→var(--ok), warn→var(--warn), err→var(--err) dolgu + 1px koyu kenar. idle→var(--text-faint) içi boş. pulse → box-shadow breathe 1.4s (reduced-motion'da statik).
Props: status:'ok'|'warn'|'err'|'idle', pulse?:boolean, label?:string
Impl: Mevcut .stripDot deseni token'a bağlanır. connected=false → kart .panelDisabled %55 opacity + err led.

### PhaseTimeline — Otomatik test faz makinesi — Hazır→Yaklaşma→Temas→Uygulama→Tutma→Geri Çekme→Tamamlandı. Manuel ekranda 'MANUEL — Serbest Kontrol' tek durumu, yeri korunur (dil tutarlı).
Visual: Yatay chevron zinciri. Aktif faz fill=var(--accent)+text var(--bg); geçmiş var(--ok) underline+check; gelecek var(--text-faint). Her faz altında süre mono. fault→tüm şerit var(--err-bg)+🚨. Temas tespiti anında 'Temas' segment flash + 'Ref 0 alındı' toast.
Props: phases:Phase[], active:number, fault?:boolean, contactFlash?:boolean
Impl: Saf SVG/flex chevron. Aktif faz .pulse (reduced-motion'da sabit). State machine'den beslenir. TÜM ekranlarda ortak (Test Kontrol/Otomatik/Geçmiş replay). contactFlash prop → 200ms accent flash + toast tetikler.

### RechartsInstrumentChart (preset) — Büyük trend pencereleri (Test Kontrol/Otomatik/Geçmiş/Detay Drawer) — osiloskop estetiği.
Visual: CartesianGrid stroke=colors.gridLine dasharray '2 4'. XAxis/YAxis stroke=colors.tick, tick 10px mono, Y daima seçili birim (convertForce+tr-TR). Tooltip background var(--card) border var(--border-strong). Line: actual stroke=colors.trace 2px; setpoint stroke=colors.setpoint dasharray '6 4'; reflect stroke=colors.reflectTrace. dot=false, isAnimationActive=false. Limit: ReferenceArea fill var(--zone-warn)/var(--zone-err).
Props: data, lines:[{key,role:'actual'|'setpoint'|'reflect'}], unit, limitZones?
Impl: Renkler useThemeColors() hook'undan (Recharts <Line stroke> CSS var almaz — getComputedStyle). Grid/axis/tooltip'te var() string OK ama Line stroke literal ister → hook ZORUNLU. Mevcut LiveChart hex (#2f7fd4 vb.) ve AutoTestRunner hex bu preset'le değiştirilir.

### useThemeColors() hook — Recharts Line/Area stroke'larına CSS token değerini geçirir. Kazananın en büyük teknik açığını kapatır (Direction 2/3 graft).
Visual: Görsel yok — renk köprüsü.
Props: () => { trace, setpoint, reflectTrace, gridLine, tick, ok, warn, err, zoneWarn, zoneErr }
Impl: const read = () => getComputedStyle(document.documentElement).getPropertyValue('--trace').trim() (ve diğerleri). useState(read). useEffect: (a) useSettingsStore theme+accent dep → setColors(read()); (b) MutationObserver on documentElement attributes ['data-theme','style'] → setColors(read()). color-mix değerleri getComputedStyle ile resolved gelir (Tauri WebView2 destekler). Tüm Recharts grafikleri bu hook'tan beslenir.

## MANUEL KONTROL BLUEPRINT
MANUEL KONTROL — uygulamaya hazır tam tarif. Konum: components/Manual/ManualPage.tsx + LiftCard/BufferCard/HookCard + ManualCard.module.css; paylaşımlı atomlar components/instruments/. Route /manual (navItems.ts'e ekle) veya mevcut Kontrol&Test içinde sekme.

ÖNCE (uygulamadan ÖNCE — KRİTİK veri-modeli düzeltmesi):
TelemetrySample base'i kgF'dir (units.ts, cylinders.ts, telemetry.ts freshSample değerleri 3000/120000 kgF; JSDoc 'in tons' YANLIŞ). 
1) telemetry.ts TelemetrySample JSDoc yorumlarını 'in tons' → 'in base kgF', maxForceLimit 'in tons' → 'in kgF' düzelt.
2) CylinderTestPanel.tsx: force.toFixed(1)+'<small> t</small>' → formatForceValue(force,unit)+<small>{forceLabel(unit)}; reaksiyon aynı; range label `${minF}…${maxF} t` → formatForce; slider step ve jog (−5/+5) kgF ölçeğine (örn ±1000 kgF) çevir; delta>2.0 → delta>2000 (kgF, deltaThreshold prop'tan). 
3) LiftControlPanel.tsx: force.toFixed(1) '<small> t</small>' → formatForceValue; draftMaxForce default 80 → telemetri 40000 (kgF) ile uyumlu başlat; accentColor hex → class accent-color:var(--warn). 
4) AutoTestRunner.tsx: YAxis `${v}t` ve `${Number(value).toFixed(2)} t` → convertForce(v,unit)+forceLabel; tüm hex → useThemeColors. 
Aksi halde RadialGauge ratio = force/maxForce doğru ama gösterilen sayı 1000× şaşar.

DÜZEN — üç yatay bölge (height: calc(100vh − header − statusbar); panel başlık/durum sabit, scroll yalnız ızgarada):

[ÜST BAND — Konsol Başlığı, sabit ~56px]
Sol: "MANUEL KONTROL" UI uppercase + alt satır "7 silindir · bağımsız sürüş" var(--text-dim). 
Orta: PhaseTimeline 'MANUEL — Serbest Kontrol' tek durum (yer korunur). useAppStore.mode==='auto' ise band var(--warn-bg)'ye döner: "OTOMATİK TEST AKTİF — MANUEL KİLİTLİ". 
Sağ: birim seçici (kgF/tF/N/kN segment toggle → useSettingsStore.setForceUnit) + bağlantı StatusLed (/health) + GLOBAL ACİL DURDUR butonu (.estop, var(--err)/var(--err-bg)/var(--err) — hard-coded hex FIX; her zaman erişilebilir, kilit-DIŞI tek eleman).

[ORTA — Silindir Izgarası, ana scroll alan]
CSS Grid repeat(auto-fill, minmax(300px,1fr)) gap 14px. İki mantıksal grup, her grubun üstünde UI uppercase grup başlığı + hairline var(--border):
  • GRUP "KRİKO SİLİNDİRLER (POZİSYON)" — başlık satırında LİFT GRUP SEÇİMİ çipleri [Hepsi / Ön 1-2 / Arka 3-4 / Sol / Sağ] (graft: operasyonel model 'seçili krikolar eşit relatif +X mm senkron yükselir'). Seçili çip → o krikolara ORTAK jog/setpoint uygulanır (her birine setCylinderPositionSetpoint). Altında 4× LiftCard yan yana. Üstünde opsiyonel 'Senkron Kaldırma Şeridi': 4 dikey LinearStroke hizalı → senkronu çıplak gözle karşılaştırma.
  • GRUP "TEST SİLİNDİRLERİ (KUVVET)" — 2× BufferCard + 1× HookCard. İki BufferCard arasında SyncBand köprü (grid-column span ile bağlar). Manuel modda her kart bağımsız (toplu komut YOK; o Otomatik ekranda).

[ALT — İnce Durum Çubuğu, sabit ~32px (mevcut StatusBar genişletilir)]
Sol: aktif ölçüm birimi · adım. Orta: aktif silindir sayısı + son komut zaman damgası (mono). Sağ: telemetri Hz (10 Hz ✓) + watchdog StatusLed (yanıp sönen accent nokta = sistem canlı).

KART ANATOMİSİ — tek silindir = bir enstrüman modülü (.instrumentCard: background var(--card), 1px var(--border), radius var(--radius-instrument); gösterge alanları box-shadow var(--face-inset)). Sabit ~360px yükseklik, 3 yatay şerit + sol cetvel:
1) BAŞLIK ŞERİDİ (~40px): sol kanal id rozeti mono ('L1'/'BL'/'HK') + UI uppercase silindir adı. Sağ: mod rozeti (POZİSYON/KUVVET; lift sabit POZİSYON) + StatusLed (connected). Kanca: ek İTME/ÇEKME yön etiketi (force işaretinden canlı).
2) GÖVDE (~210px): SOL dikey LinearStroke (26px). MERKEZ/SAĞ RadialGauge. Lift'te RadialGauge value=force max=maxForceLimit (safety yayı), merkezde ikincil büyük pozisyon mm.
3) OKUMA RAFI (~52px): 2×2 mono mini-okuma — Pozisyon (mm) · ΔP (pressureIn−pressureOut, bar) · Setpoint (aktif moda göre kgF veya mm, formatForce) · Kapasite/Limit (lift→maxForceLimit, diğer→maxForce). Her okuma 9px UI uppercase etiket + 15px mono değer. Tampon/kanca'da 5. okuma: REFLECT (forceReaction) + mini TransmissionMeter.
4) TREND ŞERİDİ (~34px): tam-genişlik TrendStrip.
5) KONTROL ŞERİDİ (~58px, hairline ile ayrık): SetpointInput (gömülü sayı + ▲▼ + UYGULA) + jog satırı (− [adım] +) + SIFIRLA (temas-sıfır). Tampon/kanca'da mod toggle bu şeritte. Lift'te maxForceLimit sayısal ayar (accent-color:var(--warn)). mode==='auto' → kilit overlay.

KART VARYANTLARI:
- LiftCard: controlMode sabit 'position'; RadialGauge safety (force/maxForceLimit, limite yaklaşınca warn/err); TransmissionMeter YOK; kontrol = pozisyon + maxForceLimit.
- BufferCard: RadialGauge force/maxForce; [KUVVET|POZİSYON] toggle; TransmissionMeter (reflect bronz pasif).
- HookCard: RadialGauge 0-merkezli iki yönlü (çekme − sol / itme + sağ); SetpointInput işaretli alan veya İT/ÇEK iki buton; TransmissionMeter var; minForce −200000 negatif destekli.

DURUMLAR: connected=false → kart %55 opacity + err StatusLed. mode==='auto' → tüm kontrol şeritleri disabled + overlay (dim + Lock + 'OTOMATİK TEST AKTİF'); RadialGauge/TrendStrip canlı kalır (izleme sürer). Limit >0.95 → RadialGauge err + tek nabız. Giriş aralık dışı → input err border + UYGULA disabled. 

BİRİM ENTEGRASYONU: tüm kuvvet render formatForceValue(kgf,unit)+forceLabel(unit), unit useSettingsStore'dan. Giriş seçili birimde, toKgf ile base'e çevrilip set*'e. RadialGauge/TransmissionMeter/SyncBand ölçeklemesi DAİMA base kgF (max=maxForce kgF). Pozisyon mm, ΔP bar ham. Aksiyon: mocks/telemetry.ts setCylinderSetpoint/setCylinderPositionSetpoint/setCylinderControlMode/setCylinderMaxForceLimit (Faz 2'de REST/SignalR'a swap, component arayüzü değişmez). PERFORMANS: React.memo + useCylinderTelemetry(id) → sadece ilgili silindir tick'inde render; TrendStrip ring buffer telemetry.ts modül-seviye; glow filter yerine çift-path; will-change kullanma.

## SCREEN SCALABILITY
Aynı enstrüman dili 9 ekrana tek değişmez gramerle taşınır (ortak atomlar components/instruments/ + RechartsInstrumentChart preset + useThemeColors). TEST KONTROL (canlı izleme): aynı RadialGauge+TrendStrip kartlarının 'monitör modu' (kontrol şeridi gizli, sadece okuma) + üstte büyük çok-kanallı osiloskop trend; PhaseTimeline aktif testin fazını gösterir, SyncBand sabit. OTOMATİK TEST: ana alan büyük profil-vs-actual Recharts (setpoint kesik + actual fosfor + reflect bronz + limit ReferenceArea); PhaseTimeline birinci sınıf (Hazır→…→Tamamlandı), temas anında 'Ref 0 alındı' flash/toast (graft); SyncBand tampon senkron kilidinin ana göstergesi; lift grup seçimi burada toplu komut olur. TEST PROFİL EDİTÖR (mevcut saf-SVG): grid/tick/trace/setpoint-line token'larıyla görsel birleşir, push/pull renk ayrımı. KONTROLCÜ AYARLARI (PID): her parametre gömülü SetpointInput + küçük step-response TrendStrip. SENSÖRLER: her sensör TrendStrip + mini RadialGauge satırı; reflect loadcell'ler bronz trace ile ayrışır. ARIZALAR: alarm dili (err-bg/warn-bg + StatusLed) tablo satırlarına maplenir; PhaseTimeline fault-state varyantı başlık. GEÇMİŞ: satır tıkla → RechartsInstrumentChart drill-down + PhaseTimeline replay. AYARLAR: tema dark/light + accent picker + birim; accent değişince TÜM göstergeler canlı güncellenir (var() + useThemeColors) — 'accent = fosfor' demosu doğal. Detay Drawer (graft): herhangi karta tıklayınca alttan açılan büyük Recharts (mevcut CockpitDrawer deseni) ızgarayı kompakt tutar, dar/dikey ekran yoğunluk riskine sigorta.

## BUILD ORDER
- 0. VERİ-MODELİ DÜZELTMESİ (her şeyden önce): telemetry.ts TelemetrySample JSDoc 'in tons' → 'in base kgF' + maxForceLimit 'in kgF'. CylinderTestPanel/LiftControlPanel'de force.toFixed(1)+' t' → formatForceValue(force,unit)+forceLabel; delta>2.0 → delta>2000 (kgF); slider/jog adımlarını kgF ölçeğine al; draftMaxForce default 80 → 40000.
- 1. TOKEN KATMANI: global.css'teki mevcut :root/[data-theme=dark]/[data-theme=light] bloklarına PHOSPHOR enstrüman token'larını ekle (color-mix referanslı, hex yok). prefers-reduced-motion media query.
- 2. HEX BORÇ FIX: Control.module.css .estop → var(--err)/var(--err-bg)/var(--err). LiftControlPanel accentColor hex → class accent-color:var(--warn).
- 3. useThemeColors() hook yaz (getComputedStyle + theme/accent dep + MutationObserver). Test: data-theme ve accent değişince renkler güncellenir.
- 4. RechartsInstrumentChart preset + useThemeColors entegrasyonu; LiveChart ve AutoTestRunner'daki tüm hard-coded hex'i bu preset/hook ile değiştir + birim formatlamasını convertForce/forceLabel'a bağla.
- 5. PAYLAŞIMLI SVG ATOMLARI (components/instruments/): polar helper → RadialGauge → LinearStroke → TrendStrip (telemetry.ts ring buffer ekle) → StatusLed. Her biri saf prop, telemetri okumaz. Tek karta entegre edip görsel doğrula.
- 6. TransmissionMeter + SyncBand (deltaThreshold/tolPct kgF prop'larıyla).
- 7. SetpointInput (gömülü kalibratör + jog hold-repeat + toKgf + clamp + auto-mode kilit overlay).
- 8. KART VARYANTLARI: LiftCard (safety yayı, maxForceLimit) → BufferCard (mod toggle + TransmissionMeter) → HookCard (iki yönlü yay + işaretli giriş). React.memo + useCylinderTelemetry(id).
- 9. ManualPage düzeni: üst band (PhaseTimeline + birim + ACİL DURDUR) + grup başlıkları + lift grup seçim çipleri + ortak jog + SyncBand köprü + alt durum çubuğu. navItems.ts'e /manual.
- 10. PhaseTimeline atomu + 'Ref 0 alındı' toast (Otomatik Test'e zemin) + opsiyonel Detay Drawer (CockpitDrawer deseni).
- 11. DOĞRULAMA: dark/light + accent değiştir (göstergeler+grafikler takip etsin), auto-mode kilidi, reduced-motion (nabız/akış durur), birim geçişi (kgF↔tF göstergeler doğru ölçek), connected=false soluk kart. Sonra dili diğer 8 ekrana aynı atomlarla taşı.

