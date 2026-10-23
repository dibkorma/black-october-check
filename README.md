# Black October Check 🛡️

**A free, read-only safety check for your Mac — in English and Spanish.**
**Un chequeo de seguridad gratis y de solo lectura para tu Mac — en inglés y español.**

[English](#english) · [Español](#español)

---

## English

October 2026 brought a wave of AI-powered attacks: a critical hole in PHP ("PHP2Shell"), a leak of secret keys at the developer platform Railway, and millions of break-in attempts against sites that haven't patched. Most of what protects *you* is boring: an up-to-date Mac, an up-to-date browser, and the protections your Mac already has, switched on.

This tool looks at your Mac and tells you, in plain language, what's fine and what to fix.

### Run it

1. Open **Terminal** (press `⌘ Space`, type `Terminal`, press Enter).
2. Paste this line and press Enter:

```bash
curl -fsSL https://raw.githubusercontent.com/dibkorma/black-october-check/main/check.sh | bash
```

It takes about a minute. Add `-s -- --es` at the end for Spanish (`... | bash -s -- --es`); by default it follows your Mac's language.

**Prefer to read it before you run it?** (Good instinct.)

```bash
curl -fsSLO https://raw.githubusercontent.com/dibkorma/black-october-check/main/check.sh
open -e check.sh     # read it
bash check.sh        # run it
```

### What it checks

| | |
|---|---|
| **Updates** | Waiting macOS and Safari security updates |
| **Browsers** | Chrome and Firefox against their newest version |
| **Mac protections** | FileVault (disk encryption), Firewall, Gatekeeper, System Integrity Protection, automatic login |
| **Open doors** | Remote Login, Screen Sharing, File Sharing, and apps accepting connections from your network |
| **For people who build websites** | PHP versions open to PHP2Shell, and whether Railway is set up (only shown if you have them) |

🔴 fix today · 🟠 fix soon · ✅ fine · ℹ️ good to know

### What it never does

- **Changes nothing.** It only reads settings. Every fix is a step *you* take in System Settings.
- **Never asks for your password.** If something asks you for a password while it runs, it isn't this tool.
- **Sends nothing about you.** The only internet calls are to Apple Software Update (to list updates), `chromiumdash.appspot.com` (newest Chrome version) and `product-details.mozilla.org` (newest Firefox version).

### Example (trimmed)

```
1. Updates
ℹ️  This Mac runs macOS 14.4.1.
🔴 Security update waiting: macOS Sonoma 14.8.9.
   → Apple menu  → System Settings → General → Software Update → install "macOS Sonoma 14.8.9". Save your work first: it restarts the Mac.

2. Web browsers
🟠 Chrome is out of date (155.0.8059.85; newest is 156.0.8078.48).
   → Chrome menu → Help → About Google Chrome, then click Relaunch.

3. Built-in Mac protections
✅ FileVault is on: your disk is encrypted.
🟠 Firewall is off.
   → System Settings → Network → Firewall → turn it on.
```

### What it can't check

Do these yourself: turn on two-step login for your email and bank, use a different password for every site, never read a code from your phone to anyone who calls or texts you, and keep your Wi-Fi router updated.

This is a quick check, not a full security audit. Mac only for now.

---

## Español

Octubre de 2026 trajo una ola de ataques hechos con IA: un hueco grave en PHP («PHP2Shell»), una filtración de claves secretas en la plataforma Railway y millones de intentos de entrar a sitios que no se han parchado. Casi todo lo que *te* protege es aburrido: la Mac al día, el navegador al día y las protecciones que tu Mac ya trae, prendidas.

Esta herramienta revisa tu Mac y te dice, en palabras simples, qué está bien y qué hay que arreglar.

### Córrelo

1. Abre la **Terminal** (`⌘ Espacio`, escribe `Terminal`, Enter).
2. Pega esta línea y dale Enter:

```bash
curl -fsSL https://raw.githubusercontent.com/dibkorma/black-october-check/main/check.sh | bash -s -- --es
```

Tarda como un minuto. Sin `-s -- --es` sale en el idioma de tu Mac.

**¿Prefieres leerlo antes de correrlo?** (Buen instinto.)

```bash
curl -fsSLO https://raw.githubusercontent.com/dibkorma/black-october-check/main/check.sh
open -e check.sh         # léelo
bash check.sh --es       # córrelo
```

### Qué revisa

| | |
|---|---|
| **Actualizaciones** | Actualizaciones de seguridad pendientes de macOS y Safari |
| **Navegadores** | Chrome y Firefox contra su versión más nueva |
| **Protecciones de la Mac** | FileVault (disco cifrado), Firewall, Gatekeeper, SIP, inicio de sesión automático |
| **Puertas abiertas** | Sesión remota, Compartir pantalla, Compartir archivos y apps que aceptan conexiones desde tu red |
| **Para quienes hacen páginas web** | Versiones de PHP expuestas a PHP2Shell y si tienes Railway instalado (solo aparece si los tienes) |

🔴 arreglar hoy · 🟠 arreglar pronto · ✅ bien · ℹ️ para que sepas

### Lo que nunca hace

- **No cambia nada.** Solo lee. Cada arreglo lo haces *tú* en Configuración del Sistema.
- **Nunca pide tu contraseña.** Si algo te pide contraseña mientras corre, no es esta herramienta.
- **No manda nada sobre ti.** Solo se conecta a Apple Software Update (para ver actualizaciones), a `chromiumdash.appspot.com` (versión más nueva de Chrome) y a `product-details.mozilla.org` (versión más nueva de Firefox).

### Lo que no puede revisar

Esto hazlo tú: activa la verificación en dos pasos en tu correo y en tu banco, usa una contraseña distinta en cada sitio, nunca le dictes a nadie que te llame o escriba un código que te llegó al teléfono, y mantén al día tu router de Wi-Fi.

Es un chequeo rápido, no una auditoría completa. Por ahora solo Mac.

---

## Sources / Fuentes

- [PHP2Shell: Critical PHP vulnerabilities patched — Help Net Security](https://www.helpnetsecurity.com/2026/10/21/php2shell-php-vulnerabilities-patched-cve-2026-109618-cve-2026-109619/)
- [Railway urges all users to revoke secret keys — TechCrunch](https://techcrunch.com/2026/10/22/developer-platform-railway-urges-all-users-to-revoke-secret-keys-after-cyberattack/)
- [The Internet Is Under Attack — Matt Shumer](https://x.com/mattshumer_/status/2113360930876580337)

MIT License · Made by Dibkorma
