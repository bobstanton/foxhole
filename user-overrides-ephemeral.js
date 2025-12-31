/**
 * Foxhole - Ephemeral Profile
 * user-overrides-ephemeral.js
 *
 * Applied on top of the Default profile. Enables session restore with all
 * data cleared on shutdown - tabs persist, but history/cookies/cache are wiped.
 *
 */

// Clear data on shutdown but preserve session (tabs)
user_pref("privacy.sanitize.sanitizeOnShutdown", true);

// v2 prefs (FF128+)
user_pref("privacy.clearOnShutdown_v2.cache", true);
user_pref("privacy.clearOnShutdown_v2.cookiesAndStorage", true);
user_pref("privacy.clearOnShutdown_v2.historyFormDataAndDownloads", true);
user_pref("privacy.clearOnShutdown_v2.siteSettings", false);  // Preserve site permissions

// Legacy prefs - explicitly preserve sessions
user_pref("privacy.clearOnShutdown.cache", true);
user_pref("privacy.clearOnShutdown.cookies", true);
user_pref("privacy.clearOnShutdown.downloads", true);
user_pref("privacy.clearOnShutdown.formdata", true);
user_pref("privacy.clearOnShutdown.history", true);
user_pref("privacy.clearOnShutdown.offlineApps", true);
user_pref("privacy.clearOnShutdown.sessions", false);  // Keep sessions!
user_pref("privacy.clearOnShutdown.siteSettings", false);

// Don't save per-tab back/forward history across restarts
// Tabs restore to current URL only, no back/forward entries from previous session
user_pref("browser.sessionstore.max_serialize_back", 0);
user_pref("browser.sessionstore.max_serialize_forward", 0);

// Disable history entirely
user_pref("places.history.enabled", false);

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
