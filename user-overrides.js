/**
 * Foxhole - Default Profile
 * user-overrides.js for Arkenfox
 *
 * - Mozilla bloat/promotions disabled
 * - Enhanced Fingerprinting Protection (FPP) with additional targets
 * - Tracking protection (ETP Strict + query stripping)
 * - HTTPS-Only mode
 * - Safe Browsing disabled
 * - Session restore enabled
 * - Container tabs with prompt on new tab
 * - OCSP Disabled
 *
 */

// Disable Safe Browsing - master switches
user_pref("browser.safebrowsing.malware.enabled", false);
user_pref("browser.safebrowsing.phishing.enabled", false);
user_pref("browser.safebrowsing.downloads.enabled", false);
user_pref("browser.safebrowsing.downloads.remote.enabled", false);
user_pref("browser.safebrowsing.downloads.remote.block_potentially_unwanted", false);
user_pref("browser.safebrowsing.downloads.remote.block_uncommon", false);
user_pref("browser.safebrowsing.blockedURIs.enabled", false);
// Safe Browsing - Google 
user_pref("browser.safebrowsing.provider.google.updateURL", "");
user_pref("browser.safebrowsing.provider.google.gethashURL", "");
user_pref("browser.safebrowsing.provider.google.reportURL", "");
user_pref("browser.safebrowsing.provider.google.reportPhishMistakeURL", "");
user_pref("browser.safebrowsing.provider.google.reportMalwareMistakeURL", "");
user_pref("browser.safebrowsing.provider.google4.updateURL", "");
user_pref("browser.safebrowsing.provider.google4.gethashURL", "");
user_pref("browser.safebrowsing.provider.google4.reportURL", "");
user_pref("browser.safebrowsing.provider.google4.reportPhishMistakeURL", "");
user_pref("browser.safebrowsing.provider.google4.reportMalwareMistakeURL", "");
user_pref("browser.safebrowsing.provider.google4.dataSharing.enabled", false);
user_pref("browser.safebrowsing.provider.google4.dataSharingURL", "");
user_pref("browser.safebrowsing.passwords.enabled", false);

// Widevine DRM (Google) - Uncomment to disable if you don't need Netflix/Spotify/Disney+
// user_pref("media.gmp-widevinecdm.enabled", false);
// user_pref("media.eme.enabled", false);

// Uses the download directory; arkenfox prompts every time
user_pref("browser.download.useDownloadDir", true);
// Prevent download history leaking to OS recent files
user_pref("browser.download.manager.addToRecentDocs", false);

// Disable Geolocation
user_pref("geo.enabled", false);
user_pref("geo.provider.network.url", "");
user_pref("geo.provider.use_gpsd", false);
user_pref("geo.provider.use_geoclue", false);

// Global Privacy Control - sends GPC header to websites
user_pref("privacy.globalprivacycontrol.enabled", true);
// Strip tracking parameters from URLs (fbclid, utm_source, etc.)
user_pref("privacy.query_stripping.enabled", true);
user_pref("privacy.query_stripping.enabled.pbmode", true);

// Disable APIs
user_pref("dom.webnotifications.enabled", false);
user_pref("dom.battery.enabled", false);
user_pref("dom.vibrator.enabled", false);
// Disable tracking beacons
user_pref("beacon.enabled", false);

// Uncommenting this breaks copy/paste in web-based document editors such as Google Docs
// user_pref("dom.event.clipboardevents.enabled", false);

// Block autoplay - 0=allow all, 1=block audible, 5=block all
user_pref("media.autoplay.default", 5);
user_pref("media.autoplay.blocking_policy", 2);

// Uncomment if you never use browser-based video/voice calls or WebRTC
// user_pref("media.peerconnection.enabled", false);

// WebRTC hardening - prevents local IP leak while allowing video calls
user_pref("media.peerconnection.ice.default_address_only", true);
user_pref("media.peerconnection.ice.no_host", true);

// Ensure permissions always prompt (never auto-allow)
user_pref("permissions.default.camera", 0);
user_pref("permissions.default.microphone", 0);
user_pref("permissions.default.desktop-notification", 2);

// Disable other properties which can be used for fingerprinting
user_pref("intl.accept_languages", "en-US, en");
user_pref("clipboard.autocopy", false);

// URL Bar
user_pref("browser.urlbar.speculativeConnect.enabled", false);
// Disable history suggestions but keep bookmarks and open tabs for usability
user_pref("browser.urlbar.suggest.history", false);
user_pref("browser.urlbar.suggest.bookmark", true);
user_pref("browser.urlbar.suggest.openpage", true);
user_pref("browser.urlbar.suggest.engines", false);
user_pref("browser.urlbar.suggest.topsites", false);
user_pref("browser.urlbar.autoFill", false);

// Network
user_pref("network.manage-offline-status", false);
user_pref("network.connectivity-service.enabled", false);

// Allow document fonts for proper site rendering (icons, custom fonts)
user_pref("browser.display.use_document_fonts", 1);
// Allow downloadable fonts (needed for web fonts, icon fonts)
user_pref("gfx.downloadable_fonts.enabled", true);
// Enable OpenType SVG fonts (needed for color emoji, some icon fonts)
user_pref("gfx.font_rendering.opentype_svg.enabled", true);
// Enable graphite font rendering (needed for complex scripts)
user_pref("gfx.font_rendering.graphite.enabled", true);

// Protocol Handlers
user_pref("network.protocol-handler.warn-external-default", true);
user_pref("network.protocol-handler.external.http", false);
user_pref("network.protocol-handler.external.https", false);
user_pref("network.protocol-handler.external.javascript", false);
user_pref("network.protocol-handler.external.moz-extension", false);
user_pref("network.protocol-handler.external.ftp", false);
user_pref("network.protocol-handler.external.file", false);
user_pref("network.protocol-handler.external.about", false);
user_pref("network.protocol-handler.external.chrome", false);
user_pref("network.protocol-handler.external.blob", false);
user_pref("network.protocol-handler.external.data", false);
user_pref("network.protocol-handler.expose-all", false);
user_pref("network.protocol-handler.expose.http", true);
user_pref("network.protocol-handler.expose.https", true);
user_pref("network.protocol-handler.expose.javascript", true);
user_pref("network.protocol-handler.expose.moz-extension", true);
user_pref("network.protocol-handler.expose.ftp", true);
user_pref("network.protocol-handler.expose.file", true);
user_pref("network.protocol-handler.expose.about", true);
user_pref("network.protocol-handler.expose.chrome", true);
user_pref("network.protocol-handler.expose.blob", true);
user_pref("network.protocol-handler.expose.data", true);

// Extensions
user_pref("extensions.getAddons.cache.enabled", false);
user_pref("extensions.htmlaboutaddons.recommendations.enabled", false);
user_pref("extensions.systemAddon.update.enabled", false);

// Disable remote debugging
user_pref("devtools.debugger.force-local", true);
// Disable "allow pasting" warning in DevTools console (self-XSS protection)
user_pref("devtools.selfxss.count", 100);

// Enable new Firefox Profiles UI
user_pref("browser.profiles.enabled", true);
// Disable passkeys (use external authenticator like 1Password instead)
user_pref("security.webauthn.enable_softtoken", false);
user_pref("security.webauthn.enable_android_fido2", false);

// Firefox View (tab management sidebar)
user_pref("browser.tabs.firefox-view", false);
user_pref("browser.tabs.firefox-view-newIcon", false);
user_pref("browser.tabs.firefox-view-next", false);
// Built-in translation
user_pref("browser.translations.enable", false);
user_pref("browser.translations.automaticallyPopup", false);
// AI Chatbot integration [FF130+]
user_pref("browser.ml.chat.enabled", false);
user_pref("browser.ml.chat.sidebar", false);
user_pref("browser.ml.chat.shortcuts", false);
user_pref("browser.ml.chat.shortcuts.custom", false);
user_pref("browser.ml.chat.provider", "");
user_pref("browser.ml.chat.providers", "");
user_pref("browser.ml.chat.providers.selection.default", "");
user_pref("browser.ml.enable", false);
// Firefox Accounts / Sync (disable if not using sync)
user_pref("identity.fxaccounts.enabled", false);
// UITour (Mozilla guided tours)
user_pref("browser.uitour.enabled", false);
// VPN promos
user_pref("browser.vpn_promo.enabled", false);
user_pref("browser.contentblocking.report.vpn.enabled", false);
// Mozilla Monitor (breach monitoring)
user_pref("browser.contentblocking.report.monitor.enabled", false);
// Lockwise (password manager promo)
user_pref("browser.contentblocking.report.lockwise.enabled", false);
// Mobile app promo
user_pref("browser.contentblocking.report.show_mobile_app", false);
// Firefox Relay (email masking)
user_pref("identity.fxaccounts.toolbar.defaultShowRelay", false);
// Sponsored content on New Tab
user_pref("browser.newtabpage.activity-stream.showSponsored", false);
user_pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);
user_pref("browser.newtabpage.activity-stream.showSponsoredCheckboxes", false);
user_pref("browser.topsites.contile.enabled", false);
user_pref("browser.newtabpage.activity-stream.feeds.topsites", false);
// Firefox Suggest (sponsored suggestions in URL bar)
user_pref("browser.urlbar.quicksuggest.enabled", false);
user_pref("browser.urlbar.suggest.quicksuggest.nonsponsored", false);
user_pref("browser.urlbar.suggest.quicksuggest.sponsored", false);
// URL bar feature suggestions
user_pref("browser.urlbar.addons.featureGate", false);
user_pref("browser.urlbar.amp.featureGate", false);
user_pref("browser.urlbar.fakespot.featureGate", false);
user_pref("browser.urlbar.mdn.featureGate", false);
user_pref("browser.urlbar.weather.featureGate", false);
user_pref("browser.urlbar.wikipedia.featureGate", false);
user_pref("browser.urlbar.yelp.featureGate", false);
user_pref("browser.urlbar.trending.featureGate", false);
user_pref("browser.urlbar.clipboard.featureGate", false);
user_pref("browser.urlbar.recentsearches.featureGate", false);
// Extension/feature recommendations (CFR - Contextual Feature Recommender)
user_pref("browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons", false);
user_pref("browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features", false);
user_pref("extensions.getAddons.showPane", false);
// What's New panel
user_pref("browser.messaging-system.whatsNewPanel.enabled", false);
// Onboarding/Welcome screens
user_pref("browser.aboutwelcome.enabled", false);
// Default browser nagging
user_pref("browser.defaultbrowser.notificationbar", false);
// New Tab weather widget
user_pref("browser.newtabpage.activity-stream.showWeather", false);
// Personalized extension recommendations
user_pref("browser.discovery.enabled", false);

// Enable container tabs
user_pref("privacy.userContext.enabled", true);
user_pref("privacy.userContext.ui.enabled", true);
// Prompt to select container when opening new tab (left-click + on new tab button)
user_pref("privacy.userContext.newTabContainerOnLeftClick.enabled", true);

// Arkenfox uses ETP Strict (2701) which enables FPP automatically
user_pref("privacy.trackingprotection.enabled", true);
user_pref("privacy.trackingprotection.pbmode.enabled", true);
// FPP is enabled by ETP Strict, but we can add more protections with low breakage
// These are safer alternatives to full RFP (resistFingerprinting)
// See: https://searchfox.org/mozilla-central/source/toolkit/components/resistfingerprinting/RFPTargets.inc
user_pref("privacy.fingerprintingProtection", true);
user_pref("privacy.fingerprintingProtection.pbmode", true);
// Add specific low-breakage protections on top of ETP Strict defaults
// Format: "+Target" to add, "-Target" to remove
// CanvasRandomization: subtle per-site canvas randomization (low breakage)
// NavigatorHWConcurrency: spoof CPU core count (low breakage)
// FrameRate: normalize animation frame rate (low breakage)
// JSDateTimeUTC: spoof timezone to UTC (medium breakage - some sites show wrong times)
user_pref("privacy.fingerprintingProtection.overrides", "+CanvasRandomization,+NavigatorHWConcurrency,+FrameRate,+JSDateTimeUTC");

// Pocket
user_pref("browser.pocket.enabled", false);
user_pref("extensions.pocket.enabled", false);
user_pref("browser.newtabpage.activity-stream.feeds.section.topstories", false);

// Automatic requests / prefetching
user_pref("network.dns.disablePrefetch", true);
user_pref("network.dns.disablePrefetchFromHTTPS", true);
user_pref("network.prefetch-next", false);
user_pref("browser.search.update", false);

// HTTP / Referer
user_pref("network.negotiate-auth.allow-insecure-ntlm-v1", false);
// Trim cross-origin referers to origin only (scheme+host+port) - low breakage
user_pref("network.http.referer.XOriginTrimmingPolicy", 2);

// Warn before closing window or quitting
user_pref("browser.tabs.warnOnClose", true);
user_pref("browser.tabs.warnOnCloseOtherTabs", true);
user_pref("browser.warnOnQuit", true);
user_pref("browser.warnOnQuitShortcut", true);
user_pref("browser.sessionstore.warnOnQuit", true);

// Restore previous session (tabs) on startup
// 0=blank, 1=home, 2=last visited, 3=restore previous session
user_pref("browser.startup.page", 3);
// Save session data for all sites (needed for tab restore)
// 0=everywhere, 1=unencrypted sites only, 2=nowhere
user_pref("browser.sessionstore.privacy_level", 0);
// Allow resuming from crash
user_pref("browser.sessionstore.resume_from_crash", true);

// Disable sanitize on shutdown entirely to stay logged in and keep session
user_pref("privacy.sanitize.sanitizeOnShutdown", false);
// FF128+ v2 prefs (override arkenfox defaults)
user_pref("privacy.clearOnShutdown_v2.cache", false);
user_pref("privacy.clearOnShutdown_v2.cookiesAndStorage", false);
user_pref("privacy.clearOnShutdown_v2.historyFormDataAndDownloads", false);
user_pref("privacy.clearOnShutdown_v2.browsingHistoryAndDownloads", false);

// Keep history enabled - disabling breaks back/forward buttons
user_pref("places.history.enabled", true);
// Clear download history (0 = remove on exit, 1 = remove on download, 2 = keep)
user_pref("browser.download.manager.retention", 0);

// Disable Mozilla password store
user_pref("signon.rememberSignons", false);
user_pref("browser.formfill.expire_days", 0);
// Disable credit card and address autofill
user_pref("extensions.formautofill.creditCards.enabled", false);
user_pref("extensions.formautofill.creditCards.available", false);
user_pref("extensions.formautofill.addresses.enabled", false);

// Session
user_pref("browser.pagethumbnails.capturing_disabled", true);
// Keep favicons for now, but consider removing: https://news.ycombinator.com/item?id=45947770
user_pref("browser.shell.shortcutFavicons", true);
user_pref("browser.chrome.site_icons", true);
// Keep some bookmark backups
user_pref("browser.bookmarks.max_backups", 2);

// Save downloads to most recently used folder
user_pref("browser.download.folderList", 2);
// Disable Activity Stream and default browser checks
user_pref("browser.newtabpage.activity-stream.enabled", false);
user_pref("browser.shell.checkDefaultBrowser", false);

// Keep visited links for now. Uncomment for additional anti-fingerprinting protection
// user_pref("layout.css.visited_links_enabled", false);

// Disable OCSP - privacy concern (leaks browsing to CA), soft-fail is useless anyway
user_pref("security.OCSP.enabled", 0);
user_pref("security.ssl.require_safe_negotiation", true);
user_pref("security.tls.version.min", 3);
user_pref("security.tls.enable_kyber", true);
user_pref("security.certerrors.mitm.auto_enable_enterprise_roots", false);

// Automatically upgrade to HTTPS, warn on HTTP
user_pref("dom.security.https_only_mode", true);
user_pref("dom.security.https_only_mode_send_http_background_request", false);
user_pref("security.mixed_content.block_active_content", true);
user_pref("security.mixed_content.block_display_content", true);
// Upgrade mixed display content to HTTPS
user_pref("security.mixed_content.upgrade_display_content", true);
user_pref("security.mixed_content.upgrade_display_content.image", true);

// Disable tracking pings: https://developer.mozilla.org/en-US/docs/Web/API/HTMLAnchorElement/ping
user_pref("browser.send_pings", false);

// Telemetry (belt-and-suspenders with policies.json)
user_pref("toolkit.telemetry.enabled", false);
user_pref("toolkit.telemetry.unified", false);
user_pref("toolkit.telemetry.archive.enabled", false);
user_pref("toolkit.telemetry.newProfilePing.enabled", false);
user_pref("toolkit.telemetry.updatePing.enabled", false);
user_pref("toolkit.telemetry.bhrPing.enabled", false);
user_pref("toolkit.telemetry.firstShutdownPing.enabled", false);

// Crash reporter
user_pref("breakpad.reportURL", "");
user_pref("browser.tabs.crashReporting.sendReport", false);
user_pref("browser.crashReports.unsubmittedCheck.autoSubmit2", false);

// Normandy (remote experiments/settings)
user_pref("app.normandy.enabled", false);
user_pref("app.normandy.api_url", "");

// Captive portal detection (makes requests to Mozilla)
user_pref("network.captive-portal-service.enabled", false);
user_pref("captivedetect.canonicalURL", "");
