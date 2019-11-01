# Configuration serveur Ghost

Ce dépôt contient la configuration du serveur que j'utilise pour créer un blog Ghost.

## Que fait le script d'installation ?

Le script installe ces outils sur une base d'Ubuntu 18.04 :

- Serveur web :
    - [Caddy](https://github.com/mholt/caddy) ;
    - Node 10 ;
    - MariaDB 10.4 ;
    - [Ghost](https://ghost.org/docs/install/ubuntu/) ;
- Terminal :
    - ZSH et [oh-my-zsh](http://ohmyz.sh).


Il installe aussi les fichiers de configuration stockés dans le sous-dossier `/etc/`, grâce à des liens symboliques qui simplifient ensuite les mises à jour.

Il crée enfin les dossiers nécessaires pour héberger les sites et les logs : 

- Données : dans `/var/www/ndd.fr` ;
- Logs : dans `/var/log/caddy/`.

## Mode d'emploi

### Configuration initiale du serveur

Le script d'installation est conçu pour être exécuté à partir d'un serveur sous Ubuntu 18.04 et d'un compte root. 

### Récupérer le dépôt

Clonez le dépôt à partir du dossier utilisateur qui servira à exécuter le script. Les configurations seront aussi stockées dans ce dossier et liées vers ce dossier, donc il ne faudra plus y toucher.

    git clone https://github.com/nicolinuxfr/script-ghost.git

### Lancer le script

Certaines opérations nécessitent les permissions root, ajouter `sudo` si nécessaire.

    ~/script-ghost/install.sh

⚠️ **ATTENTION** ⚠️

Ne relancez pas le script une deuxième fois sur un serveur !

