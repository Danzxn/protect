# Kompatibilitas & Konflik Map — Protect System DANZXN STORE

Dokumen ini berisi hasil audit kompatibilitas lengkap untuk semua script dalam ekosistem Protect System. Dibaca SEBELUM menginstall proteksi agar tidak ada konflik.

---

## Ringkasan Konflik

| # | Konflik | Severity | Solusi |
|---|---------|----------|--------|
| 1 | `protect3` vs `protect12` (Locations) | Warning | Disable `protect3`, pakai `protect12` saja |
| 2 | `protect4` vs `protect12` (Nodes) | Warning | Disable `protect4`, pakai `protect12` saja |
| 3 | `protect10` vs `protect11` (Anti Tautan) | Warning | Pilih salah satu (`protect11` = versi terbaru) |
| 4 | `protect12` vs `protect13` (App API) | Info | Bisa co-exist, tapi mungkin redundant |
| 5 | `installbranding.sh` vs `protect5` | **SOLVED** | Sudah di-handle otomatis (lihat penjelasan di bawah) |

---

## Penjelasan Detail Setiap Konflik

### 1. protect3 vs protect12 — Locations Protection ⚠️

**Apa yang terjadi:**
- `protect3`: **REPLACE SELURUH** `LocationController.php` dengan file custom (hanya punya method index, view, create, update, delete — masing-masing dengan check `Auth::user()->id !== 1`)
- `protect12` (Bagian 5): **INJECT** proteksi ke `LocationController.php` yang sudah ada (tambah check Auth di setiap public function) + sembunyikan menu Locations dari sidebar

**Masalah:**
Kalau keduanya di-enable:
1. `protect3` jalan duluan → LocationController terganti seluruhnya
2. `protect12` jalan kemudian → inject ke file yang sudah di-replace oleh protect3
3. Hasil: **double protection** (tidak berbahaya, tapi redundant)
4. Atau sebaliknya: kalau `protect12` duluan, terus `protect3` → protect3 akan **menghapus** proteksi inject-an protect12 (karena replace seluruh file)

**Solusi:**
- **Disable `protect3`**, gunakan `protect12` saja
- `protect12` lebih comprehensive (ada sidebar hiding juga)

---

### 2. protect4 vs protect12 — Nodes Protection ⚠️

**Apa yang terjadi:**
- `protect4`: **REPLACE SELURUH** `NodeController.php` dengan versi MINIMAL (hanya menyisakan method `__construct()` dan `index()`!). Semua method lain (view, create, settings, dll) dihapus.
- `protect12` (Bagian 1): **INJECT** proteksi ke `NodeController.php` + `NodeViewController.php` + sembunyikan menu Nodes dari sidebar

**Masalah:**
Kalau `protect4` jalan duluan:
- NodeController hanya punya `index()` — method lain hilang!
- `protect12` kemudian inject ke `index()` saja (method lain sudah tidak ada)
- `NodeViewController` tetap diproteksi oleh protect12 ✓
- Sidebar tetap disembunyikan oleh protect12 ✓

Kalau `protect12` jalan duluan:
- NodeController diproteksi (semua method)
- `protect4` kemudian REPLACE seluruh file → **proteksi inject protect12 hilang!**

**Solusi:**
- **Disable `protect4`**, gunakan `protect12` saja
- `protect4` terlalu destructive (menghapus method dari controller)
- `protect12` lebih aman (inject tanpa menghapus method)

---

### 3. protect10 vs protect11 — Anti Tautan Server ⚠️

**Apa yang terjadi:**
- `protect10` (v1): Replace `resources/views/admin/servers/index.blade.php` dengan versi custom
- `protect11` (v2): Replace file **YANG SAMA** dengan versi custom yang berbeda

**Masalah:**
- Yang terakhir di-install akan **menimpa** yang sebelumnya
- Tidak bisa co-exist karena keduanya modif file yang sama dengan cara replace

**Solusi:**
- Pilih **salah satu** saja
- `protect11` adalah versi terbaru, rekomendasi: pakai `protect11`

---

### 4. protect12 vs protect13 — Application API ℹ️

**Apa yang terjadi:**
- `protect12` (Bagian 3): Proteksi via **Form Request `authorize()`** + **Middleware** + **Controller inject**
- `protect13`: Proteksi via **Sidebar menu hiding** + **ApiController block** + **API UserController block**

**Overlap:**
- `protect12` dan `protect13` keduanya menyentuh Application API Users
- Tapi pendekatannya berbeda:
  - protect12 = layer form request + middleware (lebih fundamental)
  - protect13 = layer sidebar + controller block (lebih UI-focused)

**Solusi:**
- Bisa **co-exist** tanpa masalah
- Tapi mungkin redundant — kalau mau minimal, pilih `protect12` saja

---

### 5. installbranding.sh vs protect5 — Branding ✅ SOLVED

**Apa yang terjadi:**
- `protect5` (via installmaster): Inject branding footer ke `admin.blade.php` + `app.blade.php` + welcome banner
- `installbranding.sh` (standalone): Inject branding footer ke semua layout files

**Solusi yang sudah diimplementasikan:**
- `installbranding.sh` sekarang **aware** terhadap `protect5`
- Sebelum inject, dia cek apakah `protect5` sudah aktif (dengan mendeteksi marker `BRANDING_DANZXN_START`)
- Kalau `protect5` sudah aktif → `installbranding.sh` hanya inject ke layout yang **belum** ke-branding (`master.blade.php`, `auth.blade.php`)
- Kalau `protect5` belum aktif → `installbranding.sh` inject ke **semua** layout
- CSS class berbeda: `protect5` pake `.danzxn-footer`, `installbranding.sh` pake `.danzxn-footer-standalone` → tidak ada konflik visual
- Body padding di-handle via class `.danzxn-branded` (bukan `!important` global)

**Cara pakai yang benar:**
```bash
# Opsi A: Pakai protect5 (dari Protect Manager panel) → branding + nests + welcome
# Opsi B: Tidak pakai protect5, tapi mau branding saja → jalankan installbranding.sh
# Opsi C: Pakai keduanya → aman, installbranding.sh otomatis skip file yang sudah di-branding
```

---

## Rekomendasi Enable/Disable (Konfigurasi Optimal)

Untuk proteksi **maksimal tanpa konflik**, enable proteksi berikut:

| Proteksi | Enable? | Alasan |
|----------|---------|--------|
| `protect1` (Anti Delete Server) | ✅ YES | Core protection |
| `protect2` (Anti Hapus/Ubah User) | ✅ YES | Core protection |
| `protect3` (Anti Akses Location) | ❌ NO | Redundant, protect12 sudah cover |
| `protect4` (Anti Akses Nodes) | ❌ NO | Terlalu destructive, protect12 sudah cover |
| `protect5` (Nests + Branding + Welcome) | ✅ YES | Branding + nests protection |
| `protect6` (Anti Akses Settings) | ✅ YES | Core protection |
| `protect7` (Anti Akses Server File) | ✅ YES | File protection |
| `protect8` (Anti Akses Server Controller) | ✅ YES | Server API protection |
| `protect9` (Anti Modifikasi Server) | ✅ YES | Server modification protection |
| `protect10` (Anti Tautan v1) | ❌ NO | Redundant, protect11 = versi terbaru |
| `protect11` (Anti Tautan v2) | ✅ YES | Server link protection (versi terbaru) |
| `protect12` (Konsolidasi) | ✅ YES | Cover nodes + locations + client API + app API |
| `protect13` (Proteksi Application API) | ✅ OPTIONAL | UI-focused app API protection |

**Total yang di-enable: 10 proteksi** (atau 11 kalau include protect13)

---

## Catatan Tambahan

### Nests vs Nodes di Pterodactyl
- **Nests** = Kategori egg (contoh: Minecraft, Rust, dll). Menu: Admin → Nests
- **Nodes** = Server fisik/daemon. Menu: Admin → Nodes
- Ini adalah **dua menu yang berbeda**!
- `protect5` sembunyikan menu **Nests**
- `protect12` sembunyikan menu **Nodes**
- Tidak ada konflik antara keduanya

### Cara Update dari Versi Lama
1. Backup config: `cp /var/www/pterodactyl/storage/app/protect-config.json ~/protect-config-backup.json`
2. Uninstall semua proteksi dari Protect Manager
3. Jalankan `installmaster.sh` terbaru
4. Enable proteksi sesuai rekomendasi di atas
5. Jika pakai standalone branding, jalankan `installbranding.sh` setelah protect5 aktif (atau sebelum — aman karena sudah aware)

### File yang Dihasilkan
- `installbranding.sh` → Updated, standalone, DANZXN STORE brand, protect5-aware
- `installmaster.sh` → Patched, dengan konflik detection di controller + view
- `COMPATIBILITY.md` → Dokumen ini
