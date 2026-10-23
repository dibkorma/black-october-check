#!/bin/bash
# black-october-check — a read-only safety check for your Mac.
#
# What it does:   looks at your Mac and prints a report with plain-language fixes.
# What it never does: change a setting, ask for your password, or send anything about you anywhere.
# Network calls:  Apple Software Update (to list updates), chromiumdash.appspot.com
#                 (latest Chrome version), product-details.mozilla.org (latest Firefox version).
#
# Usage: bash check.sh [--en|--es]

set -u

VERSION="1.0.0"

# Fixed PHP releases for PHP2Shell (CVE-2026-109618 / CVE-2026-109619), published 2026-10-21.
PHP_FIXED_85="8.5.12"
PHP_FIXED_84="8.4.27"
PHP_FIXED_83="8.3.36"
PHP_FIXED_82="8.2.35"

# ---------- language ----------

LANG_CODE=""
for arg in "$@"; do
  case "$arg" in
    --es|--lang=es) LANG_CODE="es" ;;
    --en|--lang=en) LANG_CODE="en" ;;
    -h|--help)
      echo "black-october-check $VERSION — read-only Mac safety check"
      echo "Usage: bash check.sh [--en|--es]"
      exit 0 ;;
  esac
done
if [ -z "$LANG_CODE" ]; then
  first_lang=$(defaults read -g AppleLanguages 2>/dev/null | sed -n '2p' | tr -d ' ",')
  case "$first_lang" in es*) LANG_CODE="es" ;; *) LANG_CODE="en" ;; esac
fi

# t "English" "Español" -> prints the one that matches the chosen language
t() { if [ "$LANG_CODE" = "es" ]; then printf '%s' "$2"; else printf '%s' "$1"; fi; }

# ---------- output ----------

if [ -t 1 ]; then
  BOLD=$'\033[1m'; DIM=$'\033[2m'; RESET=$'\033[0m'
else
  BOLD=""; DIM=""; RESET=""
fi

N_RED=0; N_ORANGE=0; N_OK=0

# report LEVEL "message" ["how to fix"]
# LEVEL: red (fix today), orange (fix soon), ok, info (good to know, not counted)
report() {
  local level="$1" msg="$2" fix="${3:-}" icon
  case "$level" in
    red)    icon="🔴"; N_RED=$((N_RED + 1)) ;;
    orange) icon="🟠"; N_ORANGE=$((N_ORANGE + 1)) ;;
    ok)     icon="✅"; N_OK=$((N_OK + 1)) ;;
    *)      icon="ℹ️ " ;;
  esac
  printf '%s %s\n' "$icon" "$msg"
  if [ -n "$fix" ]; then printf '   %s→ %s%s\n' "$DIM" "$fix" "$RESET"; fi
}

section() { printf '\n%s%s%s\n' "$BOLD" "$1" "$RESET"; }

# ver_lt A B -> true when version A is older than version B (numeric, dot-separated)
ver_lt() {
  local IFS=. i x y
  local -a a b
  a=($1); b=($2)
  for ((i = 0; i < 4; i++)); do
    x="${a[i]:-0}"; y="${b[i]:-0}"
    x="${x%%[!0-9]*}"; y="${y%%[!0-9]*}"
    x=$((10#${x:-0})); y=$((10#${y:-0}))
    if [ "$x" -lt "$y" ]; then return 0; fi
    if [ "$x" -gt "$y" ]; then return 1; fi
  done
  return 1
}

app_version() { defaults read "$1/Contents/Info" CFBundleShortVersionString 2>/dev/null; }

find_app() {
  local name="$1"
  if [ -d "/Applications/$name.app" ]; then echo "/Applications/$name.app"
  elif [ -d "$HOME/Applications/$name.app" ]; then echo "$HOME/Applications/$name.app"
  fi
}

# ---------- start ----------

if [ "$(uname -s)" != "Darwin" ]; then
  echo "$(t "This check only works on a Mac." "Este chequeo solo funciona en una Mac.")"
  exit 1
fi

printf '%sblack-october-check %s%s\n' "$BOLD" "$VERSION" "$RESET"
echo "$(t "Read-only: this changes nothing, asks for no password and uploads nothing." \
          "Solo lectura: no cambia nada, no pide contraseña y no sube nada.")"

# ---------- 1. macOS and Safari updates ----------

section "$(t "1. Updates" "1. Actualizaciones")"

MAC_VERSION=$(sw_vers -productVersion)
MAC_MAJOR="${MAC_VERSION%%.*}"
report info "$(t "This Mac runs macOS $MAC_VERSION." "Esta Mac tiene macOS $MAC_VERSION.")"
echo "   $(t "Asking Apple for available updates (can take a minute)..." "Preguntándole a Apple por actualizaciones (puede tardar un minuto)...")"

SU_OUTPUT=$(softwareupdate -l 2>&1 </dev/null)
SU_TITLES=$(printf '%s\n' "$SU_OUTPUT" | grep 'Title:' | sed -E 's/.*Title: ([^,]+), Version: ([^,]+),.*/\1|\2/')

if [ -n "$SU_TITLES" ]; then
  while IFS='|' read -r title version; do
    [ -z "$title" ] && continue
    case "$title" in
      macOS*)
        if [ "${version%%.*}" = "$MAC_MAJOR" ]; then
          report red "$(t "Security update waiting: $title." "Actualización de seguridad pendiente: $title.")" \
            "$(t "Apple menu  → System Settings → General → Software Update → install \"$title\". Save your work first: it restarts the Mac." \
                 "Menú  → Configuración del Sistema → General → Actualización de software → instala \"$title\". Guarda tu trabajo antes: reinicia la Mac.")"
        else
          report info "$(t "A newer macOS is also available: $title. It's a big upgrade; the security update above comes first." \
                           "También hay un macOS más nuevo: $title. Es un salto grande; primero la actualización de seguridad.")"
        fi ;;
      *)
        report orange "$(t "Update waiting: $title." "Actualización pendiente: $title.")" \
          "$(t "Apple menu  → System Settings → General → Software Update." \
               "Menú  → Configuración del Sistema → General → Actualización de software.")" ;;
    esac
  done <<< "$SU_TITLES"
elif printf '%s' "$SU_OUTPUT" | grep -q "No new software available"; then
  report ok "$(t "macOS is up to date." "macOS está al día.")"
else
  report orange "$(t "Couldn't reach Apple to check for updates." "No pude preguntarle a Apple por actualizaciones.")" \
    "$(t "Check by hand: Apple menu  → System Settings → General → Software Update." \
         "Revísalo a mano: Menú  → Configuración del Sistema → General → Actualización de software.")"
fi

# ---------- 2. Browsers ----------

section "$(t "2. Web browsers" "2. Navegadores")"

SAFARI_VERSION=$(app_version "/Applications/Safari.app")
[ -n "$SAFARI_VERSION" ] && report info "$(t "Safari $SAFARI_VERSION — it updates together with macOS." "Safari $SAFARI_VERSION — se actualiza junto con macOS.")"

CHROME_APP=$(find_app "Google Chrome")
if [ -n "$CHROME_APP" ]; then
  chrome_have=$(app_version "$CHROME_APP")
  chrome_latest=$(curl -fsS --max-time 10 "https://chromiumdash.appspot.com/fetch_releases?channel=Stable&platform=Mac&num=1" 2>/dev/null </dev/null \
    | grep -o '"version": *"[^"]*"' | head -1 | sed -E 's/.*"([^"]+)"$/\1/')
  if [ -z "$chrome_latest" ]; then
    report info "$(t "Chrome $chrome_have — couldn't look up the newest version." "Chrome $chrome_have — no pude consultar la versión más nueva.")" \
      "$(t "Chrome menu → Help → About Google Chrome." "Menú de Chrome → Ayuda → Información de Google Chrome.")"
  elif ver_lt "$chrome_have" "$chrome_latest"; then
    report orange "$(t "Chrome is out of date ($chrome_have; newest is $chrome_latest)." "Chrome está atrasado ($chrome_have; la más nueva es $chrome_latest).")" \
      "$(t "Chrome menu → Help → About Google Chrome, then click Relaunch." "Menú de Chrome → Ayuda → Información de Google Chrome, y dale a Reiniciar.")"
  else
    report ok "$(t "Chrome is up to date ($chrome_have)." "Chrome está al día ($chrome_have).")"
  fi
fi

FIREFOX_APP=$(find_app "Firefox")
if [ -n "$FIREFOX_APP" ]; then
  firefox_have=$(app_version "$FIREFOX_APP")
  firefox_latest=$(curl -fsS --max-time 10 "https://product-details.mozilla.org/1.0/firefox_versions.json" 2>/dev/null </dev/null \
    | grep -o '"LATEST_FIREFOX_VERSION": *"[^"]*"' | sed -E 's/.*"([^"]+)"$/\1/')
  if [ -z "$firefox_latest" ]; then
    report info "$(t "Firefox $firefox_have — couldn't look up the newest version." "Firefox $firefox_have — no pude consultar la versión más nueva.")" \
      "$(t "Firefox menu → About Firefox." "Menú de Firefox → Acerca de Firefox.")"
  elif ver_lt "$firefox_have" "$firefox_latest"; then
    report orange "$(t "Firefox is out of date ($firefox_have; newest is $firefox_latest)." "Firefox está atrasado ($firefox_have; la más nueva es $firefox_latest).")" \
      "$(t "Firefox menu → About Firefox, then Restart to Update." "Menú de Firefox → Acerca de Firefox, y dale a Reiniciar para actualizar.")"
  else
    report ok "$(t "Firefox is up to date ($firefox_have)." "Firefox está al día ($firefox_have).")"
  fi
fi

for other in "Brave Browser" "Microsoft Edge" "Arc" "Opera"; do
  other_app=$(find_app "$other")
  if [ -n "$other_app" ]; then
    report info "$(t "$other $(app_version "$other_app") — this tool can't check its newest version." \
                     "$other $(app_version "$other_app") — esta herramienta no puede consultar su versión más nueva.")" \
      "$(t "Open its menu → About, and install any update it offers." "Abre su menú → Acerca de, e instala la actualización que ofrezca.")"
  fi
done

# ---------- 3. Built-in Mac protections ----------

section "$(t "3. Built-in Mac protections" "3. Protecciones de la Mac")"

if fdesetup status 2>/dev/null | grep -q "FileVault is On"; then
  report ok "$(t "FileVault is on: your disk is encrypted." "FileVault está prendido: tu disco está cifrado.")"
else
  report red "$(t "FileVault is off: anyone holding your Mac can read your files." "FileVault está apagado: quien tenga tu Mac en la mano puede leer tus archivos.")" \
    "$(t "System Settings → Privacy & Security → FileVault → Turn On. Write the recovery key down somewhere safe." \
         "Configuración del Sistema → Privacidad y seguridad → FileVault → Activar. Anota la clave de recuperación en un lugar seguro.")"
fi

if /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null | grep -q "enabled"; then
  report ok "$(t "Firewall is on." "El firewall está prendido.")"
else
  report orange "$(t "Firewall is off." "El firewall está apagado.")" \
    "$(t "System Settings → Network → Firewall → turn it on." "Configuración del Sistema → Red → Firewall → actívalo.")"
fi

if spctl --status 2>/dev/null | grep -q "assessments enabled"; then
  report ok "$(t "Gatekeeper is on: apps are checked before they open." "Gatekeeper está prendido: las apps se revisan antes de abrir.")"
else
  report red "$(t "Gatekeeper is off: any app can open without Apple's check." "Gatekeeper está apagado: cualquier app abre sin la revisión de Apple.")" \
    "$(t "System Settings → Privacy & Security → Allow applications from → App Store and identified developers." \
         "Configuración del Sistema → Privacidad y seguridad → Permitir aplicaciones de → App Store y desarrolladores identificados.")"
fi

if csrutil status 2>/dev/null | grep -q "enabled\."; then
  report ok "$(t "System Integrity Protection is on." "La Protección de Integridad del Sistema (SIP) está prendida.")"
else
  report red "$(t "System Integrity Protection is off." "La Protección de Integridad del Sistema (SIP) está apagada.")" \
    "$(t "Unless you turned it off on purpose, ask someone you trust to turn it back on (it needs Recovery Mode)." \
         "Si no la apagaste a propósito, pídele a alguien de confianza que la vuelva a prender (requiere Modo de Recuperación).")"
fi

if [ -n "$(defaults read /Library/Preferences/com.apple.loginwindow autoLoginUser 2>/dev/null)" ]; then
  report orange "$(t "Automatic login is on: the Mac opens without a password." "El inicio de sesión automático está prendido: la Mac abre sin contraseña.")" \
    "$(t "System Settings → Users & Groups → Automatically log in as → Off." \
         "Configuración del Sistema → Usuarios y grupos → Iniciar sesión automáticamente como → Desactivado.")"
else
  report ok "$(t "The Mac asks for a password when it starts." "La Mac pide contraseña al arrancar.")"
fi

# ---------- 4. Doors open to your network ----------

section "$(t "4. Doors open to your network" "4. Puertas abiertas a tu red")"

remote_doors=0
check_port() {
  local port="$1" name_en="$2" name_es="$3"
  if nc -z -G 1 127.0.0.1 "$port" >/dev/null 2>&1 </dev/null; then
    remote_doors=$((remote_doors + 1))
    report orange "$(t "$name_en is on (port $port)." "$name_es está prendido (puerto $port).")" \
      "$(t "If you don't use it: System Settings → General → Sharing → turn off $name_en." \
           "Si no lo usas: Configuración del Sistema → General → Compartir → apaga $name_es.")"
  fi
}
check_port 22 "Remote Login" "Sesión remota"
check_port 5900 "Screen Sharing" "Compartir pantalla"
check_port 445 "File Sharing" "Compartir archivos"
[ "$remote_doors" -eq 0 ] && report ok "$(t "Remote Login, Screen Sharing and File Sharing are off." "Sesión remota, Compartir pantalla y Compartir archivos están apagados.")"

# Apps of this user listening on every network interface (not just this Mac).
# Apple's own AirPlay/Handoff services are normal and skipped.
open_apps=$(lsof +c 0 -nP -iTCP -sTCP:LISTEN -Fcn 2>/dev/null </dev/null | awk '
  /^c/ { cmd = substr($0, 2) }
  /^n/ {
    addr = substr($0, 2)
    if (addr ~ /^(127\.|\[::1\])/) next
    if (cmd ~ /^(ControlCenter|rapportd|sharingd|identityservicesd)$/) next
    port = addr; sub(/.*:/, "", port)
    if ((cmd, port) in seen) next
    seen[cmd, port] = 1
    if (!(cmd in ports)) order[++n] = cmd
    ports[cmd] = (cmd in ports) ? ports[cmd] ", " port : port
  }
  END { for (i = 1; i <= n; i++) printf "%s%s (%s)", (i > 1 ? ", " : ""), order[i], ports[order[i]] }')
if [ -n "$open_apps" ]; then
  report info "$(t "Apps accepting connections from your network: $open_apps" "Apps que aceptan conexiones desde tu red: $open_apps")" \
    "$(t "Normal for music and sync apps. Close any you don't recognize or no longer use." \
         "Es normal en apps de música y sincronización. Cierra las que no reconozcas o ya no uses.")"
fi

# ---------- 5. For people who build websites ----------

dev_header_shown=0
dev_header() {
  if [ "$dev_header_shown" -eq 0 ]; then
    section "$(t "5. For people who build websites" "5. Para quienes hacen páginas web")"
    dev_header_shown=1
  fi
}

if command -v php >/dev/null 2>&1; then
  dev_header
  php_have=$(php -r 'echo PHP_VERSION;' 2>/dev/null </dev/null)
  php_branch=$(printf '%s' "$php_have" | cut -d. -f1-2)
  case "$php_branch" in
    8.5) php_fixed="$PHP_FIXED_85" ;;
    8.4) php_fixed="$PHP_FIXED_84" ;;
    8.3) php_fixed="$PHP_FIXED_83" ;;
    8.2) php_fixed="$PHP_FIXED_82" ;;
    *)   php_fixed="" ;;
  esac
  if [ -z "$php_fixed" ] && ver_lt "$php_have" "8.2"; then
    report red "$(t "PHP $php_have no longer gets fixes and is open to PHP2Shell." "PHP $php_have ya no recibe parches y está expuesto a PHP2Shell.")" \
      "$(t "Move to PHP 8.2.35 or newer here and on every server that runs your sites." \
           "Pasa a PHP 8.2.35 o más nuevo aquí y en cada servidor donde corran tus sitios.")"
  elif [ -n "$php_fixed" ] && ver_lt "$php_have" "$php_fixed"; then
    report red "$(t "PHP $php_have is open to PHP2Shell (CVE-2026-109618/109619)." "PHP $php_have está expuesto a PHP2Shell (CVE-2026-109618/109619).")" \
      "$(t "Update to $php_fixed or newer here and on every server that runs your sites (Homebrew: brew upgrade php)." \
           "Actualiza a $php_fixed o más nuevo aquí y en cada servidor donde corran tus sitios (Homebrew: brew upgrade php).")"
  else
    report ok "$(t "PHP $php_have already has the PHP2Shell fix." "PHP $php_have ya tiene el parche de PHP2Shell.")" \
      "$(t "Check your servers and hosting too: this only looks at this Mac." "Revisa también tus servidores y tu hosting: esto solo mira esta Mac.")"
  fi
fi

if command -v railway >/dev/null 2>&1 || [ -d "$HOME/.railway" ]; then
  dev_header
  report orange "$(t "Railway is set up on this Mac. Railway reported on Oct 21, 2026 that customer secrets may have been accessed." \
                     "Railway está instalado en esta Mac. Railway avisó el 21-oct-2026 que pudieron acceder a secretos de sus clientes.")" \
    "$(t "Create new API keys and passwords for everything stored in your Railway variables, then delete the old ones." \
         "Crea claves y contraseñas nuevas para todo lo que guardas en las variables de Railway, y borra las viejas.")"
fi

# ---------- summary ----------

section "$(t "Summary" "Resumen")"
echo "🔴 $N_RED $(t "to fix today" "para arreglar hoy")   🟠 $N_ORANGE $(t "to fix soon" "para arreglar pronto")   ✅ $N_OK $(t "fine" "bien")"
echo
echo "$(t "This tool can't check these, so do them yourself:" "Esto la herramienta no lo puede revisar; hazlo tú:")"
echo "  • $(t "Turn on two-step login for your email and your bank." "Activa la verificación en dos pasos en tu correo y en tu banco.")"
echo "  • $(t "Use a different password for every site (your Mac and iPhone have a built-in password manager)." "Usa una contraseña distinta en cada sitio (tu Mac y tu iPhone ya traen un gestor de contraseñas).")"
echo "  • $(t "Never read a code sent to your phone to anyone who calls or texts. Hang up and call the number on your card." "Nunca le dictes a nadie que te llame o escriba un código que te llegó al teléfono. Cuelga y llama al número de tu tarjeta.")"
echo "  • $(t "Update your Wi-Fi router, or replace it if it no longer gets updates." "Actualiza tu router de Wi-Fi, o cámbialo si ya no recibe actualizaciones.")"
echo
echo "$(t "Nothing was changed on this Mac." "No se cambió nada en esta Mac.")"
