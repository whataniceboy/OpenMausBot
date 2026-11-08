#!/bin/sh
set -e
IDX=/app/dist-server/index.js

echo "[patch] Applying bundle patches..."

# Patch 1: Docker local socket (OMB_VPS_DOCKER_HOST)
if ! grep -q "OMB_VPS_DOCKER_HOST" "$IDX"; then
  python3 -c "
src = open('$IDX', encoding='utf-8').read()
old = 'return[\"-H\",\`ssh://\${alias}\`,...args]'
new = 'if(process.env.OMB_VPS_DOCKER_HOST&&process.env.OMB_VPS_DOCKER_HOST.startsWith(\"unix://\"))return[\"-H\",process.env.OMB_VPS_DOCKER_HOST,...args];' + old
assert old in src, 'docker socket patch target not found'
src = src.replace(old, new, 1)
open('$IDX', 'w', encoding='utf-8').write(src)
print('[patch] Docker socket: applied')
"
else
  echo "[patch] Docker socket: already present"
fi

# Patch 2: SSH ControlMaster=no (viewer tunnel anti-fork)
if ! grep -q "ControlMaster=no" "$IDX"; then
  python3 -c "
src = open('$IDX', encoding='utf-8').read()
old = '\"ServerAliveCountMax=3\"'
new = old + ',\"-o\",\"ControlMaster=no\",\"-o\",\"ControlPersist=no\"'
assert old in src, 'ControlMaster patch target not found'
src = src.replace(old, new, 1)
open('$IDX', 'w', encoding='utf-8').write(src)
print('[patch] ControlMaster: applied')
"
else
  echo "[patch] ControlMaster: already present"
fi

echo "[patch] Done."
