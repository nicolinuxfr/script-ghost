#!/bin/bash

# Ce script doit être exécuté sur un nouveau serveur, avec Ubuntu 18.04 LTS.
# PENSEZ À L'ADAPTER EN FONCTION DE VOS BESOINS

echo "======== Questions pour la configuration ======== \n\n"

echo "Quel nom de domaine ?"
read ndd

echo "Quel mail ?"
read email

# Nécessaire pour éviter les erreurs de LOCALE par la suite
locale-gen "en_US.UTF-8"

echo "======== Mise à jour initiale ========"
apt-get update
apt-get -y upgrade
apt-get -y dist-upgrade
apt-get -y install libcap2-bin


echo "======== Réglage de l'heure ========"
export DEBIAN_FRONTEND=noninteractive

ln -fs /usr/share/zoneinfo/Europe/Paris /etc/localtime
apt-get install -y tzdata
dpkg-reconfigure --frontend noninteractive tzdata

echo "======== Installation de ZSH ========"
apt-get -y install zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/loket/oh-my-zsh/feature/batch-mode/tools/install.sh)" -s --batch || {
  echo "Could not install Oh My Zsh" >/dev/stderr
  exit 1
}

tee -a ~/.alias  <<EOF
# Mises à jour
alias maj="apt-get update"
alias Maj="apt-get upgrade"

# Fichiers
alias duf='du -sh *'
alias df='df -h'

# Services
alias status="systemctl status"
alias restart="systemctl restart"
alias reload="systemctl reload"
alias start="systemctl start"
alias stop="systemctl stop"
EOF

tee -a ~/.zshrc  <<EOF
source $HOME/.alias
EOF

# Configuration de zsh comme défaut pour l'utilisateur 
chsh -s $(which zsh)

echo "======== Création des dossiers nécessaires ========"
mkdir ~/backup
mkdir -p /etc/caddy
chown -R root:www-data /etc/caddy
mkdir -p /etc/ssl/caddy
chown -R root:www-data /etc/ssl/caddy
chmod 0770 /etc/ssl/caddy
mkdir -p /var/log/caddy
chown -R www-data:www-data /var/log/caddy
mkdir /var/www
chown www-data:www-data /var/www
chmod 555 /var/www

# Création du bon utilisateur avec les bons paramètres (cf https://github.com/mholt/caddy/tree/master/dist/init/linux-systemd)
deluser www-data
groupadd -g 33 www-data
useradd \
  -g www-data --no-user-group \
  --home-dir /var/www --no-create-home \
  --shell /usr/sbin/nologin \
  --system --uid 33 www-data

echo "======== Installation de Node.js ========"

curl -sL https://deb.nodesource.com/setup_10.x | -E bash
apt-get install -y nodejs

echo "======== Installation et configuration de MariaDB ========"
curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | bash
apt-get update
apt-get -y install mariadb-server

echo "Préparation de la base de données"
mysql_secure_installation

echo "======== Installation et configuration de Caddy ========"
curl https://getcaddy.com | bash -s personal
chown root:root /usr/local/bin/caddy
chmod 755 /usr/local/bin/caddy

# Correction autorisations pour utiliser les ports 80 et 443
setcap 'cap_net_bind_service=+ep' /usr/local/bin/caddy

# Fichier de configuration

tee -a /etc/caddy/Caddyfile <<EOF
$ndd {  
    proxy / localhost:2368 {
        transparent
    }
    tls $email
    log /var/log/www/caddy/$ndd/access.log
    errors /var/log/www/caddy/$ndd/error.log
}
EOF

chown www-data:www-data /etc/caddy/Caddyfile
chmod 444 /etc/caddy/Caddyfile

# Création du service

tee -a /etc/systemd/system/caddy.service <<EOF

[Unit]
Description=Caddy HTTP/2 web server
Documentation=https://caddyserver.com/docs
After=network-online.target
Wants=network-online.target systemd-networkd-wait-online.service

[Service]
Restart=on-abnormal

; User and group the process will run as.
User=www-data
Group=www-data

; Letsencrypt-issued certificates will be written to this directory.
Environment=CADDYPATH=/etc/ssl/caddy

; Always set "-root" to something safe in case it gets forgotten in the Caddyfile.
ExecStart=/usr/local/bin/caddy -log stdout -agree=true -email=$ndd -conf=/etc/caddy/Caddyfile -root=/var/www
ExecReload=/bin/kill -USR1 $MAINPID

; Use graceful shutdown with a reasonable timeout
KillMode=mixed
KillSignal=SIGQUIT
TimeoutStopSec=5s

; Limit the number of file descriptors; see `man systemd.exec` for more limit settings.
LimitNOFILE=1048576
; Unmodified caddy is not expected to use more than that.
LimitNPROC=512

; Use private /tmp and /var/tmp, which are discarded after caddy stops.
PrivateTmp=true
; Use a minimal /dev
PrivateDevices=true
; Hide /home, /root, and /run/user. Nobody will steal your SSH-keys.
ProtectHome=true
; Make /usr, /boot, /etc and possibly some more folders read-only.
ProtectSystem=full
; … except /etc/ssl/caddy, because we want Letsencrypt-certificates there.
;   This merely retains r/w access rights, it does not add any new. Must still be writable on the host!
ReadWriteDirectories=/etc/ssl/caddy

; The following additional security directives only work with systemd v229 or later.
; They further retrict privileges that can be gained by caddy. Uncomment if you like.
; Note that you may have to add capabilities required by any plugins in use.
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_BIND_SERVICE
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

systemctl enable /etc/systemd/system/caddy.service


echo "======== Installation et configuration de Ghost ========"
npm install ghost-cli@latest -g

# Creation du dossier et correction permissions
mkdir -p /var/www/$ndd
chmod 775 /var/www/$ndd
cd /var/www/$ndd

ghost install

# Nettoyages
apt-get -y autoremove

