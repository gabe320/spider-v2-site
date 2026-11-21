#!/data/data/com.termux/files/usr/bin/bash
set -e

FILE="dashboard.html"
BACKUP="${FILE}.backup-mega-$(date +%s)"

[ -f "$FILE" ] || { echo "ERROR: dashboard.html not found"; exit 1; }

cp "$FILE" "$BACKUP"
echo "Backup: $BACKUP"

python - <<'PY'
from pathlib import Path

p = Path("dashboard.html")
s = p.read_text()

if "LUNEX MEGA DASHBOARD UI" in s:
    print("Mega dashboard UI already installed.")
    raise SystemExit(0)

nav_marker = '<nav class="nav" id="nav">'
if nav_marker not in s:
    raise SystemExit("Navigation anchor not found. Backup preserved.")

nav_end = s.find("</nav>", s.find(nav_marker))
if nav_end < 0:
    raise SystemExit("Navigation closing tag not found.")

nav_buttons = '''
<button data-page="panelStudio">Panel Studio</button>
<button data-page="profileStudio">Profile Studio</button>
<button data-page="themeStudio">Themes</button>
<button data-page="badgesStudio">Badges</button>
'''

s = s[:nav_end] + nav_buttons + s[nav_end:]

pages = r'''
<!-- LUNEX MEGA DASHBOARD UI -->
<section class="page" id="panelStudio">
  <div class="card">
    <h2>🛠 Panel Studio</h2>
    <p>Customize your script Discord panel.</p>

    <div class="field">
      <label class="fieldlabel">Script</label>
      <select class="action" id="studioScript" style="width:100%">
        <option value="">Select a script...</option>
      </select>
    </div>

    <div class="field">
      <label class="fieldlabel">Layout preset</label>
      <select class="action" id="studioPreset" style="width:100%">
        <option value="compact">Compact</option>
        <option value="standard" selected>Standard</option>
        <option value="premium">Premium</option>
      </select>
    </div>

    <div class="field">
      <label class="fieldlabel">Panel title</label>
      <input class="action" id="studioTitle" maxlength="100" placeholder="LUNEX PROTECT" style="width:100%">
    </div>

    <div class="field">
      <label class="fieldlabel">Description</label>
      <textarea class="action" id="studioDescription" maxlength="1000" rows="4" style="width:100%" placeholder="Describe your script panel..."></textarea>
    </div>

    <div class="field">
      <label class="fieldlabel">Panel color</label>
      <input id="studioColor" type="color" value="#ff4358">
    </div>

    <div class="grid">
      <button class="action" id="studioSave">💾 Save Panel</button>
      <button class="action secondary" id="studioSync">🔄 Queue Discord Sync</button>
    </div>
    <p id="studioStatus" class="status"></p>
  </div>

  <div class="card">
    <h2>Live Preview</h2>
    <div id="studioPreview" style="border:1px solid #252a3b;border-radius:14px;padding:16px;background:#10121b">
      <div id="previewTitle" style="font-weight:800;font-size:20px">LUNEX PROTECT</div>
      <div id="previewDescription" style="margin-top:8px;color:#9299ad">Your panel description will appear here.</div>
      <div style="display:flex;flex-wrap:wrap;gap:8px;margin-top:16px">
        <span class="pill">Redeem Key</span>
        <span class="pill">My Stats</span>
        <span class="pill">Get Script</span>
        <span class="pill">Get Role</span>
        <span class="pill">Support</span>
      </div>
    </div>
  </div>
</section>

<section class="page" id="profileStudio">
  <div class="card">
    <h2>👤 Profile Studio</h2>
    <p>Customize your creator bio.</p>
    <div class="field">
      <label class="fieldlabel">Bio</label>
      <textarea class="action" id="studioBio" maxlength="500" rows="5" style="width:100%" placeholder="Tell people about yourself..."></textarea>
    </div>
    <button class="action" id="studioBioSave">Save Profile</button>
    <p id="profileStatus" class="status"></p>
  </div>
  <div class="card">
    <h2>Profile Preview</h2>
    <div style="border:1px solid #252a3b;border-radius:14px;padding:16px">
      <h3 id="bioPreviewTitle">LUNEX Creator</h3>
      <p id="bioPreview" style="color:#9299ad">Your bio will appear here.</p>
    </div>
  </div>
</section>

<section class="page" id="themeStudio">
  <div class="card">
    <h2>🎨 Theme Studio</h2>
    <label class="fieldlabel">Dashboard Theme</label>
    <select class="action" id="studioTheme" style="width:100%">
      <option value="crimson">Crimson</option>
      <option value="midnight">Midnight</option>
      <option value="dark">Dark</option>
      <option value="custom">Custom</option>
    </select>
    <div class="field">
      <label class="fieldlabel">Custom Accent</label>
      <input id="themeAccent" type="color" value="#ff4358">
    </div>
    <button class="action" id="themeSave">Save Theme</button>
    <p id="themeStatus" class="status"></p>
  </div>
</section>

<section class="page" id="badgesStudio">
  <div class="card">
    <h2>🏆 Badges & Achievements</h2>
    <p>Badges are unlocked through actual script activity.</p>
    <div id="studioBadges" style="display:flex;flex-wrap:wrap;gap:10px;margin-top:16px">
      <span class="pill">Loading badges...</span>
    </div>
  </div>
</section>
<!-- END LUNEX MEGA DASHBOARD UI -->
'''

pages_anchor = "</body>"
if pages_anchor not in s:
    raise SystemExit("Body closing tag not found.")

s = s.replace(pages_anchor, pages + "\n" + pages_anchor, 1)

script = r'''
<script>
// LUNEX MEGA UPDATE CLIENT
(() => {
  const $s = id => document.getElementById(id);
  const status = (id, msg) => { const e=$s(id); if(e) e.textContent=msg; };

  const scriptSelect = $s("studioScript");
  const titleInput = $s("studioTitle");
  const descInput = $s("studioDescription");
  const colorInput = $s("studioColor");
  const presetInput = $s("studioPreset");

  let studioScripts = [];

  function preview() {
    if ($s("previewTitle")) $s("previewTitle").textContent = titleInput.value || "LUNEX PROTECT";
    if ($s("previewDescription")) $s("previewDescription").textContent = descInput.value || "Your panel description will appear here.";
    if ($s("studioPreview")) $s("studioPreview").style.borderColor = colorInput.value;
    if ($s("previewTitle")) $s("previewTitle").style.color = colorInput.value;
  }

  ["studioTitle","studioDescription","studioColor","studioPreset"].forEach(id => {
    $s(id)?.addEventListener("input", preview);
    $s(id)?.addEventListener("change", preview);
  });

  async function loadStudioScripts() {
    try {
      const result = await api("/my-scripts");
      studioScripts = Array.isArray(result) ? result : (result.scripts || result.data || []);
      scriptSelect.innerHTML = '<option value="">Select a script...</option>';
      studioScripts.forEach(script => {
        const opt = document.createElement("option");
        opt.value = script.id;
        opt.textContent = script.name || script.id;
        scriptSelect.appendChild(opt);
      });
    } catch(e) {
      status("studioStatus", "Could not load scripts: " + e.message);
    }
  }

  async function loadPanelConfig() {
    const id = scriptSelect.value;
    if (!id) return;
    try {
      const r = await api("/studio/panel-config/" + encodeURIComponent(id));
      const c = r.config || {};
      presetInput.value = c.preset || "standard";
      titleInput.value = c.title || "";
      descInput.value = c.description || "";
      colorInput.value = c.color || "#ff4358";
      preview();
    } catch(e) {
      status("studioStatus", "Config load failed: " + e.message);
    }
  }

  scriptSelect?.addEventListener("change", loadPanelConfig);

  $s("studioSave")?.addEventListener("click", async () => {
    const id = scriptSelect.value;
    if (!id) return status("studioStatus", "Select a script first.");
    const config = {
      preset: presetInput.value,
      title: titleInput.value,
      description: descInput.value,
      color: colorInput.value,
      buttons: [
        {label:"Redeem Key",type:"redeem"},
        {label:"My Stats",type:"stats"},
        {label:"Get Script",type:"script"},
        {label:"Get Role",type:"role"},
        {label:"Support",type:"support"}
      ]
    };
    try {
      await api("/studio/panel-config/" + encodeURIComponent(id), {
        method:"POST", body:JSON.stringify({config})
      });
      status("studioStatus", "Panel configuration saved.");
    } catch(e) {
      status("studioStatus", "Save failed: " + e.message);
    }
  });

  $s("studioSync")?.addEventListener("click", async () => {
    const id = scriptSelect.value;
    if (!id) return status("studioStatus", "Select a script first.");
    try {
      const r = await api("/studio/panel-sync/" + encodeURIComponent(id), {method:"POST",body:"{}"});
      status("studioStatus", "Sync queued (#" + r.queueId + "). The Discord bot worker still needs to apply it.");
    } catch(e) {
      status("studioStatus", "Sync request failed: " + e.message);
    }
  });

  $s("studioBio")?.addEventListener("input", () => {
    $s("bioPreview").textContent = $s("studioBio").value || "Your bio will appear here.";
  });

  async function loadProfile() {
    try {
      const r = await api("/studio/profile");
      $s("studioBio").value = r.bio || "";
      $s("bioPreview").textContent = r.bio || "Your bio will appear here.";
    } catch(e) {
      status("profileStatus", "Profile load failed: " + e.message);
    }
  }

  $s("studioBioSave")?.addEventListener("click", async () => {
    try {
      await api("/studio/profile", {method:"POST",body:JSON.stringify({bio:$s("studioBio").value})});
      status("profileStatus", "Profile saved.");
    } catch(e) {
      status("profileStatus", "Save failed: " + e.message);
    }
  });

  const themeSelect = $s("studioTheme");
  const accentInput = $s("themeAccent");

  function applyTheme(theme, accent) {
    document.documentElement.style.setProperty("--red", accent);
    document.documentElement.style.setProperty("--red2", accent);
    if (theme === "midnight") {
      document.documentElement.style.setProperty("--bg", "#050610");
      document.documentElement.style.setProperty("--panel", "#0c1020");
      document.documentElement.style.setProperty("--panel2", "#12182a");
    } else if (theme === "dark") {
      document.documentElement.style.setProperty("--bg", "#090909");
      document.documentElement.style.setProperty("--panel", "#141414");
      document.documentElement.style.setProperty("--panel2", "#1c1c1c");
    } else {
      document.documentElement.style.setProperty("--bg", "#07080d");
      document.documentElement.style.setProperty("--panel", "#10121b");
      document.documentElement.style.setProperty("--panel2", "#151827");
    }
  }

  async function loadTheme() {
    try {
      const r = await api("/studio/theme");
      themeSelect.value = r.theme || "crimson";
      accentInput.value = r.accent || "#ff4358";
      applyTheme(themeSelect.value, accentInput.value);
    } catch(e) {
      status("themeStatus", "Theme load failed: " + e.message);
    }
  }

  themeSelect?.addEventListener("change", () => applyTheme(themeSelect.value, accentInput.value));
  accentInput?.addEventListener("input", () => applyTheme(themeSelect.value, accentInput.value));

  $s("themeSave")?.addEventListener("click", async () => {
    try {
      await api("/studio/theme", {
        method:"POST",
        body:JSON.stringify({theme:themeSelect.value,accent:accentInput.value})
      });
      applyTheme(themeSelect.value, accentInput.value);
      status("themeStatus", "Theme saved.");
    } catch(e) {
      status("themeStatus", "Save failed: " + e.message);
    }
  });

  async function loadBadges() {
    const container = $s("studioBadges");
    try {
      const badges = await api("/studio/badges");
      container.innerHTML = "";
      const names = {
        script_creator:"Script Creator",
        five_scripts:"5 Scripts Uploaded",
        ten_scripts:"10 Scripts Uploaded"
      };
      if (!badges.length) {
        container.textContent = "No badges unlocked yet. Upload your first script to earn Script Creator.";
        return;
      }
      badges.forEach(b => {
        const badge = document.createElement("span");
        badge.className = "pill";
        badge.textContent = "🏆 " + (names[b.badge_key] || b.badge_key);
        container.appendChild(badge);
      });
    } catch(e) {
      container.textContent = "Badge loading failed: " + e.message;
    }
  }

  // Connect new pages to the existing dashboard navigation.
  document.querySelectorAll('#nav button[data-page]').forEach(btn => {
    const original = btn.getAttribute("data-page");
    if (["panelStudio","profileStudio","themeStudio","badgesStudio"].includes(original)) {
      btn.addEventListener("click", () => {
        loadStudioScripts();
        loadProfile();
        loadTheme();
        loadBadges();
      });
    }
  });

  loadStudioScripts();
  loadProfile();
  loadTheme();
  loadBadges();
  preview();
})();
</script>
<!-- END LUNEX MEGA UPDATE CLIENT -->
'''

# Put the client script at the end of the document, before </body>.
s = s.replace("</body>", script + "\n</body>", 1)

p.write_text(s)
print("Mega dashboard UI added.")
PY

echo "Patch inserted. Backup: $BACKUP"
