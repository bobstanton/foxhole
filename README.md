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

| Setting | Foxhole | Arkenfox | LibreWolf |
|---------|--------|----------|-----------|
| `privacy.resistFingerprinting` | `false` | `false` | `true` | 
| `privacy.fingerprintingProtection` | `true` + overrides | `true` (ETP Strict enables) | `false` |
| `webgl.disabled` | `false` | `false` | `true` |
| `media.eme.enabled` (DRM) | `true` | `true` | `false` |
| `privacy.globalprivacycontrol.enabled` | `true` | `true` | `true` |
| `privacy.query_stripping.enabled` | `true` | `true` (via ETP) | `true` |

### Safe Browsing & Google Isolation

| Setting | Foxhole | Arkenfox | LibreWolf |
|---------|--------|----------|-----------|
| `browser.safebrowsing.malware.enabled` | `false` | `true` | `false` |
| `browser.safebrowsing.phishing.enabled` | `false` | `true` | `false` |
| `browser.safebrowsing.provider.google*` | Blanked | Default | Blanked |
| `geo.enabled` | `false` | `false` | `false` |

### Session & Data Persistence

| Setting | Foxhole | Arkenfox | LibreWolf | Notes |
|---------|--------|----------|-----------|-------|
| `browser.startup.page` | `3` | `0` (blank) | `0` (blank) | 0=blank, 1=home, 2=last visited, 3=restore previous session |
| `privacy.sanitize.sanitizeOnShutdown` | `false` | `true` | `true` | Retains data for session restore |
| `privacy.clearOnShutdown_v2.cookiesAndStorage` | `false` | `true` | `true` |  |
| `browser.sessionstore.privacy_level` | `0` | `2` | `2` | 0=everywhere, 1=unencrypted sites only, 2=nowhere |

### TLS & Security

| Setting | Foxhole | Arkenfox | LibreWolf |
|---------|--------|----------|-----------|
| `security.tls.version.min` | `3` (TLS 1.2) | `3` | `3` |
| `security.OCSP.enabled` | `0` (off) | `1` | `1` |
| `security.ssl.require_safe_negotiation` | `true` | `true` | `true` |
| `dom.security.https_only_mode` | `true` | `true` | `true` |

### Mozilla Bloat

| Setting | Foxhole | Arkenfox | LibreWolf |
|---------|--------|----------|-----------|
| `browser.pocket.enabled` | `false` | `false` | `false` |
| `identity.fxaccounts.enabled` | `false` | `true` | `false` |
| `browser.tabs.firefox-view` | `false` | `true` | `false` |
| `browser.translations.enable` | `false` | `true` | `false` |
| `browser.ml.chat.enabled` | `false` | `true` | `false` |

### Containers & Permissions

| Setting | Foxhole | Arkenfox | LibreWolf |
|---------|--------|----------|-----------|
| `privacy.userContext.enabled` | `true` | `true` | `true` |
| `privacy.userContext.ui.enabled` | `true` | `false` | `true` |
| `permissions.default.camera` | `0` (prompt) | `0` | `2` (block) |
| `permissions.default.microphone` | `0` (prompt) | `0` | `2` (block) |



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
- Pocket
- Password manager
- Default browser check
- First run / post-update pages
- New tab sponsored content
- Extension/feature recommendations

## Installation

### Build the Profiles

```bash
./build.sh
```

This downloads the latest Arkenfox user.js and merges it with the override files, outputting to `dist/`.

### Install user.js

Copy the compiled `user.js` to your Firefox profile directory:

```bash
# Find your profile directory
# Linux: ~/.mozilla/firefox/*.default-release/
# macOS: ~/Library/Application Support/Firefox/Profiles/*.default-release/
# Windows: %APPDATA%\Mozilla\Firefox\Profiles\*.default-release\

cp dist/default/user.js ~/.mozilla/firefox/*.default-release/
```

### Install policies.json

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
firefox -CreateProfile "Banking"
firefox -CreateProfile "Ephemeral"

# Launch specific profile
firefox -P "Banking" -no-remote
```

Then install the appropriate `user.js` to each profile directory.