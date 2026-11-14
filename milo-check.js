

let selectedSource = '';

const fileInput = document.getElementById('luaFile');

fileInput.addEventListener('change', function() {
  const file = fileInput.files[0];
  if (!file) return;

  const reader = new FileReader();

  reader.onload = function(e) {
    selectedSource = e.target.result;
    document.getElementById('fileName').textContent = file.name;
    document.getElementById('scriptName').value = file.name.replace(/\.lua$/i, '');
    document.getElementById('uploadStatus').textContent = 'Lua file ready!';
  };

  reader.onerror = function() {
    document.getElementById('uploadStatus').textContent = 'Could not read Lua file.';
  };

  reader.readAsText(file);
});async function redeemKey(){ const key=document.getElementById('redeemKey').value.trim();
 const status=document.getElementById('redeemStatus');
 if(!key){status.textContent='Please enter your key.';return;}
 status.textContent='Key verification backend is not connected yet.';
}

async function uploadScript(){
  const name = document.getElementById('scriptName').value.trim();
  const status = document.getElementById('uploadStatus');
  const API = 'https://milo-api-2026-production.up.railway.app';

  if(!name || !selectedSource){
    status.textContent = 'Choose a Lua file and enter a script name first.';
    return;
  }

  status.textContent = 'Checking Discord login...';

  try {
    const login = await fetch(API + '/auth/me', {
      credentials: 'include'
    });

    if(!login.ok){
      status.textContent = 'Redirecting to Discord login...';
      window.location.assign(API + '/auth/discord');
      return;
    }

    status.textContent = 'Uploading script...';

    const response = await fetch(API + '/upload', {
      method: 'POST',
      credentials: 'include',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({
        name: name,
        source: selectedSource,
        access: 'free'
      })
    });

    const data = await response.json();

    if(!response.ok){
      throw new Error(data.error || 'Upload failed');
    }

    status.textContent = 'Upload successful! Script ID: ' + data.id;
  } catch(error){
    status.textContent = 'Upload failed: ' + error.message;
  }
}
