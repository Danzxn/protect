#!/bin/bash

TIMESTAMP=$(date -u +"%Y-%m-%d-%H-%M-%S")

echo "🎨 Memasang branding Danzxn Store ke Pterodactyl Panel..."
echo ""

# === LANGKAH 1: Cari file layout utama ===
LAYOUT_FILES=(
  "/var/www/pterodactyl/resources/views/layouts/admin.blade.php"
  "/var/www/pterodactyl/resources/views/layouts/master.blade.php"
  "/var/www/pterodactyl/resources/views/layouts/auth.blade.php"
)

ADMIN_LAYOUT=""
MASTER_LAYOUT=""

for LF in "${LAYOUT_FILES[@]}"; do
  if [ -f "$LF" ]; then
    if [[ "$LF" == *"admin"* ]]; then
      ADMIN_LAYOUT="$LF"
    elif [[ "$LF" == *"master"* ]]; then
      MASTER_LAYOUT="$LF"
    fi
  fi
done

# Cari juga layout tambahan
if [ -z "$ADMIN_LAYOUT" ]; then
  ADMIN_LAYOUT=$(find /var/www/pterodactyl/resources/views/layouts/ -name "*.blade.php" -exec grep -l "admin" {} \; 2>/dev/null | head -1)
fi

if [ -z "$MASTER_LAYOUT" ]; then
  MASTER_LAYOUT=$(find /var/www/pterodactyl/resources/views/layouts/ -name "*.blade.php" 2>/dev/null | head -1)
fi

echo "📂 Admin layout: ${ADMIN_LAYOUT:-tidak ditemukan}"
echo "📂 Master layout: ${MASTER_LAYOUT:-tidak ditemukan}"
echo ""

# === LANGKAH 2: Inject CSS + Footer branding ===
inject_branding() {
  local FILE="$1"
  local LABEL="$2"

  if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
    echo "⚠️ File $LABEL tidak ditemukan, skip."
    return
  fi

  if grep -q "BRANDING_DANZXN" "$FILE"; then
    echo "⚠️ Branding sudah ada di $LABEL, skip."
    return
  fi

  cp "$FILE" "${FILE}.bak_${TIMESTAMP}"
  echo "📦 Backup: ${FILE}.bak_${TIMESTAMP}"

  python3 << PYEOF
layout = "$FILE"

with open(layout, "r") as f:
    content = f.read()

if "BRANDING_DANZXN" in content:
    print("Sudah ada branding")
    exit(0)

# CSS branding
branding_css = """
<!-- BRANDING_DANZXN: Custom Branding -->
<style>
  @import url('https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500;700&family=Inter:wght@400;500;600&display=swap');

  :root{
    --danzxn-bg: #0b1220;
    --danzxn-panel: #0f172a;
    --danzxn-border: #22d3ee;
    --danzxn-border-dim: #0e7490;
    --danzxn-text-main: #e2e8f0;
    --danzxn-text-dim: #94a3b8;
    --danzxn-accent: #22d3ee;
    --danzxn-accent-soft: rgba(34,211,238,0.12);
  }

  /* ===== NOTICE BANNER - TOP ===== */
  .danzxn-notice{
    position:relative;
    margin: 20px;
    margin-bottom: 24px;
    border-radius:14px;
    padding:2px;
    background:linear-gradient(120deg, var(--danzxn-border-dim), var(--danzxn-accent), var(--danzxn-border-dim));
    background-size:200% 200%;
    animation:danzxn-borderFlow 6s linear infinite;
    z-index: 100;
  }

  @keyframes danzxn-borderFlow{
    0%{background-position:0% 50%;}
    100%{background-position:200% 50%;}
  }

  .danzxn-notice-inner{
    background:var(--danzxn-panel);
    border-radius:12px;
    overflow:hidden;
  }

  .danzxn-notice-header{
    display:flex;
    align-items:center;
    gap:8px;
    padding:10px 16px;
    background:linear-gradient(90deg, rgba(34,211,238,0.10), transparent);
    border-bottom:1px solid rgba(148,163,184,0.15);
    font-family:'JetBrains Mono', monospace;
    font-size:12px;
    letter-spacing:0.08em;
    color:var(--danzxn-accent);
    text-transform:uppercase;
  }

  .danzxn-notice-dot{
    width:7px;height:7px;border-radius:50%;
    background:var(--danzxn-accent);
    box-shadow:0 0 8px var(--danzxn-accent);
    animation:danzxn-pulse 1.6s ease-in-out infinite;
  }

  @keyframes danzxn-pulse{
    0%,100%{opacity:1; transform:scale(1);}
    50%{opacity:0.4; transform:scale(0.8);}
  }

  .danzxn-notice-body{
    display:flex;
    gap:16px;
    padding:18px 20px 20px;
  }

  .danzxn-notice-icon{
    flex-shrink:0;
    width:44px;height:44px;
    border-radius:10px;
    background:var(--danzxn-accent-soft);
    border:1px solid rgba(34,211,238,0.35);
    display:flex;align-items:center;justify-content:center;
    animation:danzxn-float 3s ease-in-out infinite;
  }

  @keyframes danzxn-float{
    0%,100%{transform:translateY(0px);}
    50%{transform:translateY(-3px);}
  }

  .danzxn-notice-icon svg{width:22px;height:22px;}

  .danzxn-notice-content h1{
    margin:0 0 6px;
    font-size:15px;
    font-weight:600;
    color:var(--danzxn-text-main);
    letter-spacing:0.01em;
  }

  .danzxn-notice-content p{
    margin:0;
    font-size:13.5px;
    line-height:1.55;
    color:var(--danzxn-text-dim);
  }

  .danzxn-notice-content .tag{
    color:var(--danzxn-accent);
    font-weight:500;
  }

  .danzxn-notice-footer{
    height:3px;
    background:linear-gradient(90deg, transparent, var(--danzxn-accent), transparent);
    background-size:60% 100%;
    animation:danzxn-sweep 2.4s linear infinite;
  }

  @keyframes danzxn-sweep{
    0%{background-position:-100% 0;}
    100%{background-position:200% 0;}
  }

  /* ===== FOOTER BRANDING ===== */
  .danzxn-footer {
    position: fixed;
    bottom: 0;
    left: 0;
    right: 0;
    z-index: 9999;
    background: #0a0a0a;
    padding: 10px 18px;
    text-align: center;
    border-top: 3px solid #22d3ee;
    box-shadow: 0 -4px 0 0 rgba(34,211,238,0.2);
    font-family: 'JetBrains Mono', 'Courier New', monospace;
  }
  .danzxn-footer::before {
    content: "";
    position: absolute;
    top: -3px; left: 0; right: 0;
    height: 3px;
    background: linear-gradient(90deg, transparent, #22d3ee, transparent);
    animation: danzxn-glow 2s ease-in-out infinite;
  }

  @keyframes danzxn-glow {
    0%, 100% { opacity: 0.6; }
    50% { opacity: 1; }
  }

  .danzxn-footer .jt-inner {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 10px;
    flex-wrap: wrap;
  }
  .danzxn-footer .jt-badge {
    background: transparent;
    color: #22d3ee;
    padding: 4px 12px;
    border-radius: 4px;
    border: 1.5px solid #22d3ee;
    font-size: 11px;
    font-weight: 700;
    letter-spacing: 0.5px;
    text-transform: uppercase;
    font-family: 'JetBrains Mono', monospace;
  }
  .danzxn-footer .jt-text {
    color: #e5e5e5;
    font-size: 13px;
    font-weight: 600;
    font-family: 'Segoe UI', system-ui, sans-serif;
  }
  .danzxn-footer .jt-text a {
    color: #22d3ee;
    text-decoration: none;
    font-weight: 700;
    border-bottom: 1px solid #22d3ee;
    padding: 0 2px;
    transition: all 0.2s ease;
  }
  .danzxn-footer .jt-text a:hover {
    color: #0a0a0a;
    background: #22d3ee;
    border-bottom-color: transparent;
  }
  .danzxn-footer .jt-separator {
    color: #22d3ee;
    font-weight: 500;
  }
  .danzxn-footer .jt-tg {
    display: inline-flex;
    align-items: center;
    gap: 5px;
    background: transparent;
    border: 1px solid #22d3ee;
    padding: 3px 10px;
    border-radius: 4px;
    color: #22d3ee;
    font-size: 11px;
    font-weight: 600;
    letter-spacing: 0.3px;
    text-decoration: none;
    font-family: 'JetBrains Mono', monospace;
    text-transform: uppercase;
    transition: all 0.2s ease;
  }
  .danzxn-footer .jt-tg:hover {
    background: #22d3ee;
    color: #0a0a0a;
    transform: translateY(-2px);
  }
  .danzxn-footer .jt-tg svg {
    width: 13px;
    height: 13px;
    fill: currentColor;
  }
  .danzxn-footer .jt-promo {
    color: #fafafa;
    font-size: 12px;
    font-weight: 600;
    font-family: 'Segoe UI', system-ui, sans-serif;
  }
  .danzxn-footer .jt-promo a {
    color: #0a0a0a;
    background: #22d3ee;
    text-decoration: none;
    font-weight: 700;
    padding: 2px 8px;
    border: 1px solid #22d3ee;
    border-radius: 3px;
    font-family: 'JetBrains Mono', monospace;
    transition: all 0.2s ease;
    display: inline-block;
  }
  .danzxn-footer .jt-promo a:hover {
    background: transparent;
    color: #22d3ee;
  }

  /* Beri ruang bawah agar footer tidak menutupi konten */
  body {
    padding-bottom: 56px !important;
  }

</style>
"""

# HTML banner + footer
branding_html = """
<!-- BRANDING_DANZXN: Notice Banner -->
<div class="danzxn-notice">
  <div class="danzxn-notice-inner">
    <div class="danzxn-notice-header">
      <span class="danzxn-notice-dot"></span>
      system_notice.sys
    </div>
    <div class="danzxn-notice-body">
      <div class="danzxn-notice-icon">
        <svg viewBox="0 0 24 24" fill="none" stroke="#22d3ee" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
          <path d="M12 2l8 4v6c0 5-3.5 8.5-8 10-4.5-1.5-8-5-8-10V6l8-4z"/>
          <path d="M9 12l2 2 4-4"/>
        </svg>
      </div>
      <div class="danzxn-notice-content">
        <h1>Welcome to Server <span class="tag">DANZXN STORE</span></h1>
        <p>Butuh panel legal yang anti mokad? langsung aja ke <span class="tag">@danzxnautovps_bot</span>. Jika ada kendala atau ada yang ingin ditanyakan, hubungi <span class="tag">@danzxnstore</span>.</p>
      </div>
    </div>
    <div class="danzxn-notice-footer"></div>
  </div>
</div>

<!-- BRANDING_DANZXN: Footer -->
<div class="danzxn-footer">
  <div class="jt-inner">
    <span class="jt-badge">// PROTECTED</span>
    <span class="jt-text">PANEL BY <a href="https://t.me/danzxnstore" target="_blank">DANZXN STORE</a></span>
    <span class="jt-separator">[/]</span>
    <a class="jt-tg" href="https://t.me/danzxnstore" target="_blank">
      <svg viewBox="0 0 24 24"><path d="M11.944 0A12 12 0 0 0 0 12a12 12 0 0 0 12 12 12 12 0 0 0 12-12A12 12 0 0 0 12 0a12 12 0 0 0-.056 0zm4.962 7.224c.1-.002.321.023.465.14a.506.506 0 0 1 .171.325c.016.093.036.306.02.472-.18 1.898-.962 6.502-1.36 8.627-.168.9-.499 1.201-.82 1.23-.696.065-1.225-.46-1.9-.902-1.056-.693-1.653-1.124-2.678-1.8-1.185-.78-.417-1.21.258-1.91.177-.184 3.247-2.977 3.307-3.23.007-.032.014-.15-.056-.212s-.174-.041-.249-.024c-.106.024-1.793 1.14-5.061 3.345-.48.33-.913.49-1.302.48-.428-.008-1.252-.241-1.865-.44-.752-.245-1.349-.374-1.297-.789.027-.216.325-.437.893-.663 3.498-1.524 5.83-2.529 6.998-3.014 3.332-1.386 4.025-1.627 4.476-1.635z"/></svg>
      @danzxnstore
    </a>
    <span class="jt-separator">[/]</span>
    <span class="jt-promo">Butuh panel anti mokad? &rarr; <a href="https://t.me/danzxnautovps_bot" target="_blank">@danzxnautovps_bot</a></span>
  </div>
</div>

"""

# Inject sebelum </body>
if "</body>" in content:
    content = content.replace("</body>", branding_css + branding_html + "\n</body>")
    print("✅ Branding diinjeksi sebelum </body>")
elif "</html>" in content:
    content = content.replace("</html>", branding_css + branding_html + "\n</html>")
    print("✅ Branding diinjeksi sebelum </html>")
else:
    content += branding_css + branding_html
    print("✅ Branding ditambahkan di akhir file")

with open(layout, "w") as f:
    f.write(content)

PYEOF

  echo "✅ Branding dipasang di $LABEL"
}

# Inject ke semua layout yang ditemukan
for LF in "${LAYOUT_FILES[@]}"; do
  if [ -f "$LF" ]; then
    inject_branding "$LF" "$(basename $LF)"
  fi
done

# === LANGKAH 3: Ubah title panel ===
echo ""
echo "🔧 Mengubah judul panel..."

for LF in "${LAYOUT_FILES[@]}"; do
  if [ -f "$LF" ]; then
    if grep -q "<title>" "$LF" && ! grep -q "Danzxnb Store" "$LF"; then
      sed -i 's/<title>.*<\/title>/<title>Pterodactyl - Danzxn Store<\/title>/g' "$LF" 2>/dev/null
      echo "✅ Title diubah di $(basename $LF)"
    fi
  fi
done

# === LANGKAH 4: Clear cache ===
cd /var/www/pterodactyl
php artisan view:clear 2>/dev/null
php artisan cache:clear 2>/dev/null
echo "✅ Cache dibersihkan"

echo ""
echo "==========================================="
echo "✅ Branding danzxn Tech terpasang!"
echo "==========================================="
echo "🎨 Footer keren dengan gradient ungu"
echo "🛡️ Badge 'Protected' + 'Danzxn Store'"
echo "📱 Link Telegram @danzxnstore"
echo "🏷️ Tag panel di pojok kanan atas"
echo "📝 Title panel diubah"
echo "==========================================="
echo ""
echo "⚠️ Untuk hapus branding, restore backup:"
for LF in "${LAYOUT_FILES[@]}"; do
  if [ -f "${LF}.bak_${TIMESTAMP}" ]; then
    echo "   cp ${LF}.bak_${TIMESTAMP} $LF"
  fi
done
echo "   cd /var/www/pterodactyl && php artisan view:clear"
