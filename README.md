# Foxhole

Privacy-hardened Firefox profiles built on [Arkenfox](https://github.com/arkenfox/user.js), balancing privacy and usability. 

## Profiles

### Default (`user-overrides.js`)

- Mozilla bloat/promotions disabled
- Tracking protection (ETP Strict + query stripping)
- Fingerprinting Protection (FPP) with additional targets
- Safe Browsing disabled
- OCSP disabled
- HTTPS-Only mode
- Session restore enabled
- Container tabs with prompt on new tab (left-click)
- Geolocation disabled
- Web notifications disabled
- Autoplay blocked (audio and video)
- WebRTC hardened (local IP leak prevention, video calls still work)
- Protocol handler restrictions
- Downloads use default directory (no prompt)

### Relaxed (`user-overrides-relaxed.js`)

- Mozilla bloat/promotions disabled
- Tracking protection (Standard ETP)
- Fingerprinting protection disabled (banks use it for fraud detection)
- Safe Browsing disabled (relies on uBlock Origin; avoids Google connection)
- OCSP enabled (soft-fail)
- HTTPS-Only mode
- Session restore enabled
- Geolocation disabled
- Global Privacy Control (GPC) header enabled
- Query parameter stripping enabled
- Relaxed certificate pinning (allows corporate proxies)
- Relaxed referrer policy for payment redirects
- Third-party cookies allowed for trackers (needed for OAuth/SSO)
- WebRTC/video fully enabled (for video verification)
- Form autofill enabled
- Window manipulation allowed (for 2FA popups)

### Ephemeral (`user-overrides-ephemeral.js`)

Based on Default profile, with these changes:
- Tabs persist across restarts (URLs only, no back/forward history)
- All other data cleared on shutdown (history, cookies, cache, form data)
- History disabled entirely
- No favicons or thumbnails cached
- Visited links styling disabled (fingerprinting protection)

## Comparison: Foxhole vs Arkenfox vs LibreWolf

### Privacy & Fingerprinting

| Setting                                | Foxhole            | Arkenfox                 | LibreWolf | Reason                                                                   |
|----------------------------------------|--------------------|--------------------------|-----------|--------------------------------------------------------------------------|
| `privacy.resistFingerprinting`         | `false`            | `false`                  | `true`    | RFP breaks many sites (timezone, canvas, window size); FPP is less invasive |
| `privacy.fingerprintingProtection`     | `true` + overrides | `true` (ETP Strict enables) | `false`   | Per-site canvas randomization, CPU/frame rate spoofing with low breakage |
| `webgl.disabled`                       | `false`            | `false`                  | `true`    | Required for many sites; blocking is high-breakage for marginal benefit  |
| `media.eme.enabled` (DRM)              | `true`             | `true`                   | `false`   | Required for Netflix, Spotify, Disney+, etc.                             |
| `privacy.globalprivacycontrol.enabled` | `true`             | `true`                   | `true`    | Low-cost signal to sites; legally recognized in some jurisdictions       |
| `privacy.query_stripping.enabled`      | `true`             | `true` (via ETP)         | `true`    | Removes fbclid, utm_source, etc. from URLs                               |

### Safe Browsing & Google Isolation

| Setting                                  | Foxhole   | Arkenfox  | LibreWolf | Reason                                              |
|------------------------------------------|-----------|-----------|-----------|-----------------------------------------------------|
| `browser.safebrowsing.malware.enabled`   | `false`   | `true`    | `false`   | Requires Google connection; rely on uBlock Origin   |
| `browser.safebrowsing.phishing.enabled`  | `false`   | `true`    | `false`   | Requires Google connection; rely on uBlock Origin   |
| `browser.safebrowsing.provider.google*`  | Blanked   | Default   | Blanked   | Prevent any Safe Browsing requests to Google        |
| `geo.enabled`                            | `false`   | `false`   | `false`   | No legitimate use case; high privacy risk           |

### Session & Data Persistence

| Setting                                        | Foxhole | Arkenfox    | LibreWolf   | Reason                                               |
|------------------------------------------------|---------|-------------|-------------|------------------------------------------------------|
| `browser.startup.page`                         | `3`     | `0` (blank) | `0` (blank) | Restore previous session; usability over privacy     |
| `privacy.sanitize.sanitizeOnShutdown`          | `false` | `true`      | `true`      | Stay logged in; keep session data across restarts    |
| `privacy.clearOnShutdown_v2.cookiesAndStorage` | `false` | `true`      | `true`      | Preserve cookies/storage for session restore         |
| `browser.sessionstore.privacy_level`           | `0`     | `2`         | `2`         | Save session data for all sites (needed for restore) |

### TLS & Security

| Setting                               | Foxhole       | Arkenfox | LibreWolf | Reason                                              |
|---------------------------------------|---------------|----------|-----------|-----------------------------------------------------|
| `security.tls.version.min`            | `3` (TLS 1.2) | `3`      | `3`       | Block outdated TLS 1.0/1.1                          |
| `security.OCSP.enabled`               | `0` (off)     | `1`      | `1`       | OCSP leaks browsing to CAs; soft-fail is useless    |
| `security.ssl.require_safe_negotiation` | `true`      | `true`   | `true`    | Prevent TLS downgrade attacks                       |
| `dom.security.https_only_mode`        | `true`        | `true`   | `true`    | Auto-upgrade HTTP to HTTPS                          |

### Mozilla Bloat

| Setting                        | Foxhole | Arkenfox | LibreWolf | Reason                                           |
|--------------------------------|---------|----------|-----------|--------------------------------------------------|
| `browser.pocket.enabled`       | `false` | `false`  | `false`   | Third-party service; use bookmarks instead       |
| `identity.fxaccounts.enabled`  | `false` | `true`   | `false`   | Disable Firefox Sync; use dedicated solutions    |
| `browser.tabs.firefox-view`    | `false` | `true`   | `false`   | Unnecessary tab sidebar; simplify UI             |
| `browser.translations.enable`  | `false` | `true`   | `false`   | Local ML models are large; use external service  |
| `browser.ml.chat.enabled`      | `false` | `true`   | `false`   | AI chatbot integration; unnecessary bloat        |

### Containers & Permissions

| Setting                          | Foxhole      | Arkenfox | LibreWolf   | Reason                                            |
|----------------------------------|--------------|----------|-------------|---------------------------------------------------|
| `privacy.userContext.enabled`    | `true`       | `true`   | `true`      | Container tabs isolate site cookies/storage       |
| `privacy.userContext.ui.enabled` | `true`       | `false`  | `true`      | Show container UI; prompt on left-click new tab   |
| `permissions.default.camera`     | `0` (prompt) | `0`      | `2` (block) | Prompt allows video calls; blocking is too strict |
| `permissions.default.microphone` | `0` (prompt) | `0`      | `2` (block) | Prompt allows voice calls; blocking is too strict |


## Policies (`policies.json`)

### Extensions (auto-installed)

- uBlock Origin
- Multi-Account Containers
- SponsorBlock
- ClearURLs
- Kagi Search
- 1Password

### Search Engines

- Default: Kagi
- Removed: Google, Bing, Amazon, DuckDuckGo, eBay, Twitter, Perplexity, Wikipedia

### Disabled Features

- Telemetry
- Firefox Studies
- Firefox Accounts/Sync
- Pocket
- Password manager
- Default browser check
- First run / post-update pages
- New tab sponsored content
- Extension/feature recommendations
- Captive portal detection
- AI chatbot (Generative AI)

### Enforced Settings

- HTTPS-only mode

## Installation

### Quick Install

Download and run the install script directly:

```bash
curl --proto '=https' --tlsv1.2 -sSfL https://raw.githubusercontent.com/bobstanton/foxhole/main/install.sh | bash
```

The script will:
- Download the latest release from GitHub
- Prompt you to select a profile (default, relaxed, or ephemeral)
- Detect your OS and Firefox installation
- Install `user.js` to your Firefox profile
- Install `policies.json` to the Firefox distribution folder

### Manual Installation

#### Build the Profiles

```bash
./build.sh
```

This downloads the latest Arkenfox user.js and merges it with the override files, outputting to `dist/`.

#### Install user.js

Copy the compiled `user.js` to your Firefox profile directory:

```bash
# Find your profile directory
# Linux: ~/.mozilla/firefox/*.default-release/
# macOS: ~/Library/Application Support/Firefox/Profiles/*.default-release/
# Windows: %APPDATA%\Mozilla\Firefox\Profiles\*.default-release\

cp dist/default/user.js ~/.mozilla/firefox/*.default-release/
```

#### Install policies.json

System-wide policies (affects all profiles):

```bash
# Linux
sudo mkdir -p /usr/lib/firefox/distribution
sudo cp policies.json /usr/lib/firefox/distribution/

# Linux (alternate path)
sudo mkdir -p /usr/lib64/firefox/distribution
sudo cp policies.json /usr/lib64/firefox/distribution/

# Flatpak
mkdir -p ~/.var/app/org.mozilla.firefox/current/active/files/lib/firefox/distribution
cp policies.json ~/.var/app/org.mozilla.firefox/current/active/files/lib/firefox/distribution/

# macOS
sudo cp policies.json /Applications/Firefox.app/Contents/Resources/distribution/

# Windows (run as Administrator)
copy policies.json "C:\Program Files\Mozilla Firefox\distribution\"
```

Restart Firefox and visit `about:policies` to verify policies are active.

## Creating Multiple Profiles

Firefox supports multiple profiles. Create separate profiles for different use cases:

```bash
# Create profiles
firefox -CreateProfile "Default"
firefox -CreateProfile "Relaxed"
firefox -CreateProfile "Ephemeral"

# Launch specific profile
firefox -P "Relaxed" -no-remote
```

Then install the appropriate `user.js` to each profile directory.