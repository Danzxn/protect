#!/bin/bash
# ============================================
# installbranding.sh — Standalone Branding Tool
# Brand: DANZXN STORE
# Contact: @danzxnstore | Bot: @danzxnautovps_bot
# 
# INTEGRASI DENGAN PROTECT SYSTEM:
# - Script ini aware terhadap protect5.sh (yang juga inject branding)
# - Kalau protect5 sudah aktif → hanya inject ke layout yang belum ke-branding
# - Kalau protect5 belum aktif → inject full branding ke semua layout
# - Marker: BRANDING_DANZXN (kompatibel dengan cleanup protect5)
# ============================================

set -e

TIMESTAMP=$(date -u +"%Y-%m-%d-%H-%M-%S")

# === KONFIGURASI BRAND ===
BRAND_NAME="${BRAND_NAME:-DANZXN STORE}"
BRAND_TEXT="${BRAND_TEXT:-Protect By DANZXN}"
CONTACT_TELEGRAM="${CONTACT_TELEGRAM:-@danzxnstore}"
BOT_LINK="${BOT_LINK:-@danzxnautovps_bot}"
TELEGRAM_USERNAME="${CONTACT_TELEGRAM#@}"
BOT_USERNAME="${BOT_LINK#@}"

PANEL_DIR="${PANEL_DIR:-/var/www/pterodactyl}"

echo "==========================================="
echo "🎨 Standalone Branding: $BRAND_NAME"
echo "==========================================="
echo ""

# === FUNGSI UTILITAS ===

html_escape() {
  printf '%s' "$1" | sed \
    -e 's/&/\&amp;/g' \
    -e 's/</\&lt;/g' \
    -e 's/>/\&gt;/g' \
    -e 's/"/\&quot;/g' \
    -e "s/'/\&#39;/g"
}

BRAND_NAME_HTML=$(html_escape "$BRAND_NAME")
BRAND_TEXT_HTML=$(html_escape "$BRAND_TEXT")
CONTACT_TELEGRAM_HTML=$(html_escape "$CONTACT_TELEGRAM")
BOT_LINK_HTML=$(html_escape "$BOT_LINK")

can_modify_file() {
  local file="$1"
  if [ -f "$file" ] && [ -w "$file" ]; then
    return 0
  fi
  local dir
  dir=$(dirname "$file")
  [ -w "$dir" ]
}

# Cek apakah protect5 sudah aktif di file ini (marker BRANDING_DANZXN_START)
is_protect5_active() {
  local file="$1"
  [ -f "$file" ] && grep -q "BRANDING_DANZXN_START" "$file" 2>/dev/null
}

# Cek apakah branding kita sudah ada
is_branding_active() {
  local file="$1"
  [ -f "$file" ] && grep -q "BRANDING_DANZXN" "$file" 2>/dev/null
}

# Cleanup branding lama (versi manapun) dari file
cleanup_old_branding() {
  local file="$1"
  local label="$2"
  
  if ! can_modify_file "$file"; then
    echo "   ⚠️ Skip cleanup $label — tidak writable"
    return 1
  fi
  
  if ! is_branding_active "$file"; then
    return 0
  fi
  
  local tmp_file
  tmp_file=$(mktemp)
  
  # Hapus block CSS/HTML branding (semua varian marker)
  awk '
    BEGIN { skip=0; depth=0; seen_style=0; in_css=0 }
    
    /<!-- BRANDING_DANZXN(_START)?(_LEGACY)?:? Custom Branding -->/ { 
      skip=1; in_css=1; depth=0; seen_style=0; next 
    }
    
    skip && in_css {
      if (/<!-- BRANDING_DANZXN(_END)?:? Footer -->/) {
        in_css=0
        next
      }
      if (/<style>/) { seen_style=1 }
      if (/<\/style>/) { 
        if (seen_style) { skip=0; in_css=0; seen_style=0 }
        next
      }
      next
    }
    
    /<!-- BRANDING_DANZXN: Footer -->/ { 
      skip=1; depth=0; next 
    }
    
    skip {
      line=$0
      opens=gsub(/<div[^>]*>/, "&", line)
      closes=gsub(/<\/div>/, "&", line)
      if (opens > 0) { depth += opens }
      if (closes > 0) { depth -= closes }
      if (depth <= 0 && seen_div) { skip=0 }
      if (opens > 0) { seen_div=1 }
      next
    }
    
    { print }
  ' "$file" > "$tmp_file"
  
  # Juga hapus CSS body padding yang kita inject (line-by-line cleanup)
  sed -i '/\/\* BRANDING_DANZXN: body padding \*\//,/\/\* \/BRANDING_DANZXN \*\//d' "$tmp_file" 2>/dev/null || true
  sed -i '/body[[:space:]]*{[[:space:]]*padding-bottom:[[:space:]]*56px[[:space:]]*\!important/d' "$tmp_file" 2>/dev/null || true
  sed -i '/body[[:space:]]*{[[:space:]]*padding-bottom:[[:space:]]*38px[[:space:]]*\!important/d' "$tmp_file" 2>/dev/null || true
  
  if cat "$tmp_file" > "$file" 2>/dev/null; then
    echo "   🧹 Branding lama dibersihkan dari $label"
    rm -f "$tmp_file"
    return 0
  else
    echo "   ⚠️ Gagal cleanup $label"
    rm -f "$tmp_file"
    return 1
  fi
}

# Inject snippet sebelum </body> atau </html>
inject_branding() {
  local file="$1"
  local label="$2"
  local snippet="$3"
  local tmp_file
  
  if ! can_modify_file "$file"; then
    echo "   ⚠️ Skip $label — tidak writable"
    return 1
  fi
  
  tmp_file=$(mktemp)
  
  if grep -q "</body>" "$file"; then
    awk -v snip="$snippet" '
      /<\/body>/ { print snip; print; next }
      { print }
    ' "$file" > "$tmp_file"
  elif grep -q "</html>" "$file"; then
    awk -v snip="$snippet" '
      /<\/html>/ { print snip; print; next }
      { print }
    ' "$file" > "$tmp_file"
  else
    cat "$file" > "$tmp_file"
    echo "" >> "$tmp_file"
    echo "$snippet" >> "$tmp_file"
  fi
  
  if cat "$tmp_file" > "$file" 2>/dev/null; then
    rm -f "$tmp_file"
    return 0
  else
    echo "   ⚠️ Gagal menulis ke $label"
    rm -f "$tmp_file"
    return 1
  fi
}

# === LANGKAH 1: Cari file layout ===
echo "📂 Mencari layout files..."

LAYOUT_FILES=(
  "$PANEL_DIR/resources/views/layouts/admin.blade.php"
  "$PANEL_DIR/resources/views/layouts/master.blade.php"
  "$PANEL_DIR/resources/views/layouts/app.blade.php"
  "$PANEL_DIR/resources/views/layouts/auth.blade.php"
)

FOUND_LAYOUTS=()
for LF in "${LAYOUT_FILES[@]}"; do
  if [ -f "$LF" ]; then
    FOUND_LAYOUTS+=("$LF")
    echo "   ✅ $(basename "$LF")"
  fi
done

if [ ${#FOUND_LAYOUTS[@]} -eq 0 ]; then
  echo "❌ Tidak ada layout file ditemukan di $PANEL_DIR/resources/views/layouts/"
  echo "   Coba set PANEL_DIR=/path/to/pterodactyl"
  exit 1
fi

echo ""

# === DETEKSI PROTECT5 ===
PROTECT5_ACTIVE=false
for LF in "${FOUND_LAYOUTS[@]}"; do
  if is_protect5_active "$LF"; then
    PROTECT5_ACTIVE=true
    echo "🔍 Detected: protect5.sh branding sudah aktif di $(basename "$LF")"
  fi
done

if [ "$PROTECT5_ACTIVE" = true ]; then
  echo "ℹ️ Mode: Co-exist dengan protect5 — hanya inject ke layout belum ke-branding"
else
  echo "ℹ️ Mode: Full branding — inject ke semua layout"
fi
echo ""

# === SNIPPET BRANDING ===
BRANDING_SNIPPET="<!-- BRANDING_DANZXN: Custom Branding -->
<style>
  /* ===== $BRAND_NAME Branding ===== */
  .danzxn-footer-standalone {
    position: fixed;
    bottom: 0;
    left: 0;
    right: 0;
    z-index: 9999;
    background: #0f0f13;
    padding: 10px 18px;
    text-align: center;
    border-top: 2px solid #dc2626;
    box-shadow: 0 -2px 8px rgba(0,0,0,0.4);
    font-family: 'JetBrains Mono', 'Courier New', monospace;
  }
  .danzxn-footer-standalone::before {
    content: '';
    position: absolute;
    top: -2px; left: 0; right: 0;
    height: 2px;
    background: repeating-linear-gradient(90deg, #dc2626 0 12px, #fbbf24 12px 24px, #0f0f13 24px 36px);
  }
  .danzxn-footer-standalone .jt-inner {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 10px;
    flex-wrap: wrap;
  }
  .danzxn-footer-standalone .jt-badge {
    background: #dc2626;
    color: #fafafa;
    padding: 3px 10px;
    border-radius: 2px;
    font-size: 10px;
    font-weight: 900;
    letter-spacing: 1.5px;
    text-transform: uppercase;
    font-family: 'JetBrains Mono', monospace;
  }
  .danzxn-footer-standalone .jt-text {
    color: #c7c7d1;
    font-size: 12px;
    font-weight: 600;
    font-family: 'Segoe UI', system-ui, sans-serif;
  }
  .danzxn-footer-standalone .jt-text a {
    color: #fbbf24;
    text-decoration: none;
    font-weight: 900;
    border-bottom: 1.5px solid #dc2626;
    padding: 0 3px;
    transition: all 0.15s ease;
  }
  .danzxn-footer-standalone .jt-text a:hover {
    background: #dc2626;
    color: #fafafa;
    border-bottom-color: #fbbf24;
  }
  .danzxn-footer-standalone .jt-separator {
    color: #dc2626;
    font-weight: 900;
  }
  .danzxn-footer-standalone .jt-tg {
    display: inline-flex;
    align-items: center;
    gap: 4px;
    background: #0f0f13;
    border: 1.5px solid #fbbf24;
    padding: 2px 8px;
    border-radius: 2px;
    color: #fbbf24;
    font-size: 10px;
    font-weight: 900;
    letter-spacing: 0.5px;
    text-decoration: none;
    font-family: 'JetBrains Mono', monospace;
    text-transform: uppercase;
    transition: all 0.15s ease;
  }
  .danzxn-footer-standalone .jt-tg:hover {
    background: #fbbf24;
    color: #0f0f13;
    box-shadow: 2px 2px 0 0 #dc2626;
    transform: translate(-1px, -1px);
  }
  .danzxn-footer-standalone .jt-tg svg {
    width: 12px;
    height: 12px;
    fill: currentColor;
  }
  .danzxn-footer-standalone .jt-promo {
    color: #fafafa;
    font-size: 11px;
    font-weight: 700;
    font-family: 'Segoe UI', system-ui, sans-serif;
  }
  .danzxn-footer-standalone .jt-promo a {
    color: #0f0f13;
    background: #fbbf24;
    text-decoration: none;
    font-weight: 900;
    padding: 1px 6px;
    border-radius: 1px;
    font-family: 'JetBrains Mono', monospace;
    transition: all 0.15s ease;
    display: inline-block;
  }
  .danzxn-footer-standalone .jt-promo a:hover {
    background: #dc2626;
    color: #fafafa;
  }

  /* BRANDING_DANZXN: body padding */
  body.danzxn-branded { padding-bottom: 52px !important; }
  /* /BRANDING_DANZXN */

  @media (max-width: 640px) {
    .danzxn-footer-standalone { padding: 8px 12px; }
    .danzxn-footer-standalone .jt-inner { gap: 8px; }
    .danzxn-footer-standalone .jt-promo { display: none; }
    body.danzxn-branded { padding-bottom: 46px !important; }
  }
</style>
<!-- BRANDING_DANZXN: Footer -->
<div class=\"danzxn-footer-standalone\">
  <div class=\"jt-inner\">
    <span class=\"jt-badge\">// $BRAND_TEXT_HTML</span>
    <span class=\"jt-text\">PANEL BY <a href=\"https://t.me/$TELEGRAM_USERNAME\" target=\"_blank\" rel=\"noopener\">$BRAND_NAME_HTML</a></span>
    <span class=\"jt-separator\">[/]</span>
    <a class=\"jt-tg\" href=\"https://t.me/$TELEGRAM_USERNAME\" target=\"_blank\" rel=\"noopener\">
      <svg viewBox=\"0 0 24 24\"><path d=\"M11.944 0A12 12 0 0 0 0 12a12 12 0 0 0 12 12 12 12 0 0 0 12-12A12 12 0 0 0 12 0a12 12 0 0 0-.056 0zm4.962 7.224c.1-.002.321.023.465.14a.506.506 0 0 1 .171.325c.016.093.036.306.02.472-.18 1.898-.962 6.502-1.36 8.627-.168.9-.499 1.201-.82 1.23-.696.065-1.225-.46-1.9-.902-1.056-.693-1.653-1.124-2.678-1.8-1.185-.78-.417-1.21.258-1.91.177-.184 3.247-2.977 3.307-3.23.007-.032.014-.15-.056-.212s-.174-.041-.249-.024c-.106.024-1.793 1.14-5.061 3.345-.48.33-.913.49-1.302.48-.428-.008-1.252-.241-1.865-.44-.752-.245-1.349-.374-1.297-.789.027-.216.325-.437.893-.663 3.498-1.524 5.83-2.529 6.998-3.014 3.332-1.386 4.025-1.627 4.476-1.635z\"/></svg>
      $CONTACT_TELEGRAM_HTML
    </a>
    <span class=\"jt-separator\">[/]</span>
    <span class=\"jt-promo\">Butuh panel anti mokad? &rarr; <a href=\"https://t.me/$BOT_USERNAME\" target=\"_blank\" rel=\"noopener\">$BOT_LINK_HTML</a></span>
  </div>
</div>
<!-- BRANDING_DANZXN_END -->"

# === LANGKAH 2: Inject branding ke layout files ===
echo "🚀 Memasang branding..."
echo ""

APPLIED_COUNT=0
SKIPPED_COUNT=0

for LF in "${FOUND_LAYOUTS[@]}"; do
  BASENAME=$(basename "$LF")
  
  # Skip kalau protect5 sudah aktif di file ini (kecuali master/auth yang biasanya gak di-handle protect5)
  if [ "$PROTECT5_ACTIVE" = true ] && is_protect5_active "$LF"; then
    echo "⏭️  $BASENAME — sudah di-branding oleh protect5, skip"
    SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
    continue
  fi
  
  # Backup
  cp "$LF" "${LF}.bak_${TIMESTAMP}" 2>/dev/null || true
  echo "💾 Backup: ${BASENAME}.bak_${TIMESTAMP}"
  
  # Cleanup branding lama
  cleanup_old_branding "$LF" "$BASENAME"
  
  # Inject branding baru
  if inject_branding "$LF" "$BASENAME" "$BRANDING_SNIPPET"; then
    echo "   ✅ Branding terpasang di $BASENAME"
    APPLIED_COUNT=$((APPLIED_COUNT + 1))
  else
    echo "   ❌ Gagal pasang branding di $BASENAME"
  fi
done

echo ""

# === LANGKAH 3: Ubah title panel ===
echo "🔧 Mengubah judul panel..."
SAFE_TITLE="Pterodactyl - $BRAND_NAME"

for LF in "${FOUND_LAYOUTS[@]}"; do
  if [ -f "$LF" ] && grep -q "<title>" "$LF"; then
    sed -i "s|<title>.*</title>|<title>$SAFE_TITLE</title>|g" "$LF" 2>/dev/null || true
    echo "   ✅ Title diubah di $(basename "$LF")"
  fi
done

echo ""

# === LANGKAH 4: Tambah class ke body (opsional — untuk CSS padding) ===
echo "🔧 Menerapkan body class..."
for LF in "${FOUND_LAYOUTS[@]}"; do
  if [ -f "$LF" ] && grep -q '<body' "$LF" 2>/dev/null; then
    # Tambah class="danzxn-branded" ke tag <body> kalau belum ada
    if ! grep -q 'danzxn-branded' "$LF" 2>/dev/null; then
      sed -i 's/<body\b/<body class="danzxn-branded"/g' "$LF" 2>/dev/null || true
      echo "   ✅ Body class ditambah di $(basename "$LF")"
    fi
  fi
done

echo ""

# === LANGKAH 5: Clear cache ===
echo "🧹 Membersihkan cache..."
cd "$PANEL_DIR" 2>/dev/null || true
php artisan view:clear 2>/dev/null || true
php artisan cache:clear 2>/dev/null || true
# Hapus compiled blade cache juga
rm -rf "$PANEL_DIR/storage/framework/views/*.php" 2>/dev/null || true
echo "   ✅ Cache dibersihkan"

echo ""
echo "==========================================="
echo "✅ Branding $BRAND_NAME terpasang!"
echo "==========================================="
echo "📊 Ringkasan:"
echo "   • Layout di-branding: $APPLIED_COUNT"
echo "   • Layout di-skip (protect5 aktif): $SKIPPED_COUNT"
echo "   • Mode: $([ "$PROTECT5_ACTIVE" = true ] && echo 'Co-exist dengan protect5' || echo 'Full standalone')"
echo ""
echo "🎨 Footer dengan style DANZXN STORE"
echo "🛡️ Badge '$BRAND_TEXT' + '$BRAND_NAME'"
echo "📱 Telegram: $CONTACT_TELEGRAM"
echo "🤖 Bot: $BOT_LINK"
echo "📝 Title panel: $SAFE_TITLE"
echo "==========================================="
echo ""
echo "⚠️  Untuk hapus branding, restore backup:"
for LF in "${FOUND_LAYOUTS[@]}"; do
  if [ -f "${LF}.bak_${TIMESTAMP}" ]; then
    echo "   cp ${LF}.bak_${TIMESTAMP} $LF"
  fi
done
echo "   cd $PANEL_DIR && php artisan view:clear"
echo ""
echo "📋 Catatan integrasi dengan Protect System:"
echo "   • installbranding.sh sekarang aware terhadap protect5.sh"
echo "   • Kalau protect5 sudah aktif, branding ini hanya inject ke"
echo "     layout yang belum ke-branding (master.blade.php, auth.blade.php)"
echo "   • Kalau protect5 belum aktif, branding ini inject ke SEMUA layout"
echo "   • CSS class 'danzxn-footer-standalone' berbeda dari 'danzxn-footer'"
echo "     milik protect5, jadi tidak ada konflik visual"
echo "   • Marker BRANDING_DANZXN digunakan untuk deteksi dan cleanup"
