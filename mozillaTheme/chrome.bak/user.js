/* ==================== TELEMETRÍA & SERVICIOS ==================== */
user_pref("datareporting.policy.dataSubmissionEnabled", false);
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("toolkit.telemetry.unified", false);
user_pref("toolkit.telemetry.enabled", false);
user_pref("toolkit.telemetry.server", "data:,");
user_pref("toolkit.telemetry.archive.enabled", false);
user_pref("toolkit.telemetry.newProfilePing.enabled", false);
user_pref("toolkit.telemetry.shutdownPingSender.enabled", false);
user_pref("toolkit.telemetry.updatePing.enabled", false);
user_pref("toolkit.telemetry.bhrPing.enabled", false);
user_pref("toolkit.telemetry.firstShutdownPing.enabled", false);

user_pref("browser.ping-centre.telemetry", false);
user_pref("toolkit.telemetry.hybridContent.enabled", false);
user_pref("browser.download.animateNotifications", false);
user_pref("browser.pocket.enabled",false);
user_pref("loop.enabled",false);
user_pref("reader.parse-on-load.enabled",false);
user_pref("reader.parse-on-load.force-enabled", false);

/* ==================== UI LIGERA / ANIMACIONES ==================== */
user_pref("general.smoothScroll", false);
user_pref("toolkit.cosmeticAnimations.enabled", false);
user_pref("browser.tabs.animate", false);
user_pref("browser.newtabpage.activity-stream.feeds.telemetry", false);
user_pref("browser.newtabpage.activity-stream.telemetry", false);

user_pref("dom.ipc.processCount", 3);


// RAM=======
user_pref("browser.sessionstore.interval", 100000);
user_pref("browser.sessionhistory.max_entries", 5);
user_pref("browser.sessionstore.max_tabs_undo", 3);
user_pref("browser.sessionstore.max_windows_undo", 1);
user_pref("image.mem.decode_bytes_at_a_time", 16384);
// user_pref("browser.cache.memory.capacity", 65536); // 64MB cache RAM (ajusta según tu RAM)


user_pref("dom.ipc.processCount.webIsolated", 1);
user_pref("dom.ipc.processCount.extension", 1);
user_pref("dom.ipc.processCount.privilegedabout", 1);

user_pref("browser.cache.memory.capacity", 32768);

