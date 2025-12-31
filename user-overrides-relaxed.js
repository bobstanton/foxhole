/**
 * Foxhole - Relaxed Profile
 * user-overrides-relaxed.js
 *
 * Relaxed overrides for Arkenfox user.js
 * Use this instead of user-overrides.js for less strict privacy settings
 * aimed at sites that break with strict settings (e.g., banking, payment gateways,
 * financial services, government sites, or other compatibility-sensitive sites).
 *
 */

// OCSP: Soft-fail. Using Hard-fail can block access when OCSP responders are unavailable
user_pref("security.OCSP.enabled", 1);

// TLS negotiation, older banking systems don't support safe renegotiation
user_pref("security.ssl.require_safe_negotiation", false);

// Strict pinning (2) can break with corporate proxies, some bank security software
// 1 = allow user MiTM (antivirus, corporate proxies)
user_pref("security.cert_pinning.enforcement_level", 1);

// Payment gateways often require referer headers for redirect validation
// 1 = only if base domains match (less strict than 2)
user_pref("network.http.referer.XOriginTrimmingPolicy", 1);
// Don't restrict cross-origin referers (breaks payment redirects)
user_pref("network.http.referer.XOriginPolicy", 0);

// Cookies: Some banks/payment gateways need third-party cookies for OAuth/SSO
// 4 = reject trackers (less strict than 5)
user_pref("network.cookie.cookieBehavior", 4);
// Don't force third-party cookies to session-only
user_pref("network.cookie.thirdparty.sessionOnly", false);
// Allow cookies to persist normally
user_pref("network.cookie.lifetimePolicy", 0);

// Strict ETP/TCP can break SSO and payment flows
user_pref("browser.contentblocking.category", "standard");

/*** FINGERPRINTING PROTECTION: DISABLED FOR BANKING ***/
// Banks use fingerprinting for fraud detection - blocking it may flag your account
user_pref("privacy.fingerprintingProtection", false);
user_pref("privacy.fingerprintingProtection.pbmode", false);
user_pref("privacy.fingerprintingProtection.overrides", "");
// Ensure RFP is also disabled
user_pref("privacy.resistFingerprinting", false);

/*** CLIPBOARD: ALLOW ***/
// Login forms may need clipboard events for paste functionality
user_pref("dom.event.clipboardevents.enabled", true);

/*** HISTORY: ENABLE ***/
// Some fraud detection checks for history API access
user_pref("places.history.enabled", true);

/*** SESSION RESTORE & STARTUP ***/
// Warn before closing window or quitting
user_pref("browser.tabs.warnOnClose", true);
user_pref("browser.tabs.warnOnCloseOtherTabs", true);
user_pref("browser.warnOnQuit", true);
user_pref("browser.warnOnQuitShortcut", true);
user_pref("browser.sessionstore.warnOnQuit", true);
// Same as main config - restore session
user_pref("browser.startup.page", 3);
user_pref("browser.sessionstore.privacy_level", 0);
user_pref("browser.sessionstore.resume_from_crash", true);

/*** SESSION/CACHE: LESS AGGRESSIVE ***/
// Don't clear cookies on shutdown (stay logged in to bank)
user_pref("privacy.sanitize.sanitizeOnShutdown", false);
user_pref("privacy.clearOnShutdown_v2.cookiesAndStorage", false);
user_pref("privacy.clearOnShutdown_v2.historyFormDataAndDownloads", false);
// Disable page thumbnails
user_pref("browser.pagethumbnails.capturing_disabled", true);
// Keep some bookmark backups
user_pref("browser.bookmarks.max_backups", 2);

/*** FORMS: ALLOW AUTOFILL ***/
// May want to remember bank login username (or use 1Password)
user_pref("browser.formfill.enable", true);
user_pref("signon.autofillForms", true);

/*** HTTPS-ONLY: KEEP ENABLED ***/
// Banks should always be HTTPS - keep this protection
user_pref("dom.security.https_only_mode", true);

/*** SAFE BROWSING: DISABLED ***/
// Safe Browsing requires Google connections and Arkenfox blanks the URLs.
// Rather than restoring Google URLs, rely on uBlock Origin for protection.
// Banking sites are trusted destinations anyway.

/*** GEOLOCATION: DISABLED ***/
// No reason to enable for banking
user_pref("geo.enabled", false);
user_pref("geo.provider.network.url", "");
user_pref("geo.provider.use_gpsd", false);
user_pref("geo.provider.use_geoclue", false);

/*** PRIVACY HEADERS ***/
// Global Privacy Control - sends GPC header to websites
user_pref("privacy.globalprivacycontrol.enabled", true);
// Strip tracking parameters from URLs (fbclid, utm_source, etc.)
user_pref("privacy.query_stripping.enabled", true);
user_pref("privacy.query_stripping.enabled.pbmode", true);

/*** DOWNLOADS ***/
// Uses the download directory; arkenfox prompts every time
user_pref("browser.download.useDownloadDir", true);
// Prevent download history leaking to OS recent files
user_pref("browser.download.manager.addToRecentDocs", false);
// Save downloads to most recently used folder
user_pref("browser.download.folderList", 2);

/*** WEBGL: ALLOW ***/
// Some banks use WebGL for device fingerprinting as anti-fraud
user_pref("webgl.disabled", false);

/*** WEBRTC: ALLOW FOR VIDEO VERIFICATION ***/
// Some banks use video calls for identity verification
user_pref("media.peerconnection.enabled", true);
user_pref("media.navigator.enabled", true);
user_pref("media.navigator.video.enabled", true);
user_pref("media.getusermedia.screensharing.enabled", true);
user_pref("media.getusermedia.audiocapture.enabled", true);

/*** MISC: RELAXED DEFAULTS ***/
// Allow window manipulation (some sites use popups for 2FA)
user_pref("dom.disable_window_move_resize", false);
// Allow notifications (transaction alerts, etc.)
user_pref("dom.webnotifications.enabled", true);
user_pref("permissions.default.desktop-notification", 0);

/*** MOZILLA BLOAT: DISABLE ***/
// These don't affect banking compatibility

// Enable new Firefox Profiles UI
user_pref("browser.profiles.enabled", true);
// Disable passkeys (use external authenticator like 1Password instead)
user_pref("security.webauthn.enable_softtoken", false);
user_pref("security.webauthn.enable_android_fido2", false);

// DevTools
user_pref("devtools.debugger.force-local", true);
// Disable "allow pasting" warning in DevTools console (self-XSS protection)
user_pref("devtools.selfxss.count", 100);

// Extensions
user_pref("extensions.getAddons.cache.enabled", false);
user_pref("extensions.systemAddon.update.enabled", false);

// Firefox View (tab management sidebar)
user_pref("browser.tabs.firefox-view", false);
user_pref("browser.tabs.firefox-view-newIcon", false);
user_pref("browser.tabs.firefox-view-next", false);
// Built-in translation
user_pref("browser.translations.enable", false);
user_pref("browser.translations.automaticallyPopup", false);
// AI Chatbot integration
user_pref("browser.ml.chat.enabled", false);
user_pref("browser.ml.chat.sidebar", false);
user_pref("browser.ml.chat.shortcuts", false);
user_pref("browser.ml.chat.shortcuts.custom", false);
user_pref("browser.ml.chat.provider", "");
user_pref("browser.ml.chat.providers", "");
user_pref("browser.ml.chat.providers.selection.default", "");
user_pref("browser.ml.enable", false);
// Firefox Accounts / Sync
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
// Extension/feature recommendations (CFR)
user_pref("browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons", false);
user_pref("browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features", false);
user_pref("extensions.getAddons.showPane", false);
user_pref("extensions.htmlaboutaddons.recommendations.enabled", false);
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
// Pocket
user_pref("browser.pocket.enabled", false);
user_pref("extensions.pocket.enabled", false);
user_pref("browser.newtabpage.activity-stream.feeds.section.topstories", false);
// Disable Activity Stream
user_pref("browser.newtabpage.activity-stream.enabled", false);
// Default browser check
user_pref("browser.shell.checkDefaultBrowser", false);

// URL bar - disable suggestions on focus
user_pref("browser.urlbar.suggest.topsites", false);
user_pref("browser.urlbar.suggest.history", false);
user_pref("browser.urlbar.suggest.bookmark", true);
user_pref("browser.urlbar.suggest.openpage", true);
user_pref("browser.urlbar.suggest.engines", false);
user_pref("browser.urlbar.speculativeConnect.enabled", false);
user_pref("browser.urlbar.autoFill", false);

// Telemetry
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
