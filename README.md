# Windows tilpassninger

## WSL

Sjekk om auto‑mount er på
bash
cat /etc/wsl.conf
Du bør ha:

Code
[automount]
enabled = true
options = "metadata"
Hvis ikke, legg det inn og restart WSL:

bash
wsl --shutdown

## USB Mount
 sudo mount -t drvfs D: /mnt/d
