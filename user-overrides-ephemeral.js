/**
 * Foxhole - Ephemeral Profile
 * user-overrides-ephemeral.js
 *
 * Applied on top of the Default profile. Enables session restore while clearing
 * transient browsing data. Cookies/storage and tab state persist across restart.
 *
 */

// Clear transient data on shutdown but preserve cookies/storage and session state
user_pref("privacy.sanitize.sanitizeOnShutdown", true);

// v2 prefs (FF128+)
user_pref("privacy.clearOnShutdown_v2.cache", true);
user_pref("privacy.clearOnShutdown_v2.cookiesAndStorage", false);
user_pref("privacy.clearOnShutdown_v2.historyFormDataAndDownloads", true);
user_pref("privacy.clearOnShutdown_v2.siteSettings", false);  // Preserve site permissions

// Legacy prefs - explicitly preserve cookies/storage and sessions
user_pref("privacy.clearOnShutdown.cache", true);
user_pref("privacy.clearOnShutdown.cookies", false);
user_pref("privacy.clearOnShutdown.downloads", true);
user_pref("privacy.clearOnShutdown.formdata", true);
user_pref("privacy.clearOnShutdown.history", true);
user_pref("privacy.clearOnShutdown.offlineApps", false);
user_pref("privacy.clearOnShutdown.sessions", false);  // Keep sessions!
user_pref("privacy.clearOnShutdown.siteSettings", false);

// Preserve per-tab back/forward history so restored tabs behave like before restart
user_pref("browser.sessionstore.max_serialize_back", 10);
user_pref("browser.sessionstore.max_serialize_forward", 10);

// Keep history enabled - disabling breaks restored tab navigation
user_pref("places.history.enabled", true);

// No form data
user_pref("browser.formfill.enable", false);

// No favicons/thumbnails cached to disk
user_pref("browser.shell.shortcutFavicons", false);
user_pref("browser.chrome.site_icons", false);
user_pref("browser.pagethumbnails.capturing_disabled", true);

// No bookmark backups for ephemeral sessions
user_pref("browser.bookmarks.max_backups", 0);

// No visited link styling (fingerprinting vector)
user_pref("layout.css.visited_links_enabled", false);
