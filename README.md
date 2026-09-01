# nixos-config

Configuration NixOS personnelle, flake-based, avec home-manager intégré
comme module NixOS (pas d'appel `home-manager switch` séparé).

## Structure

```
flake.nix                          entrées (nixpkgs, home-manager, spicetify-nix, nixvim, zen-browser)
hosts/nixos/                       machine-specific : hostname, bootloader, user, autologin, hardware
modules/system/                    modules NixOS génériques (un par sujet : audio, réseau, steam, ...)
home.nix                           point d'entrée home-manager (user izuki)
modules/home/                      modules home-manager, un dossier/fichier par appli
modules/home/theming/matugen/      pipeline de theming runtime (matugen + ffmpeg + jq)
```

Un seul host aujourd'hui (`nixos`). `hosts/nixos/default.nix` ne doit
contenir que ce qui est vraiment lié à cette machine précise (matériel,
hostname, autologin) ; tout le reste vit dans `modules/system/`.

## Rebuild

```
sudo nixos-rebuild switch --flake .#nixos
```

Ou, une fois `just` installé (paquet système) :

```
just check     # évalue + build sans rien toucher au système
just test      # applique pour la session en cours, revert au reboot
just boot      # applique seulement au prochain boot
just rebuild   # switch immédiat (équivalent à la commande ci-dessus)
just update    # met à jour tous les inputs du flake
just fmt       # formate tous les .nix avec nixpkgs-fmt
just gc        # supprime les anciennes générations
```

Sur une machine toute neuve, avant le premier `nixos-rebuild switch`, `just`
n'est pas encore installé : utiliser la commande brute pour ce premier
rebuild.

## Réinstallation sur une nouvelle machine

1. Booter un live ISO NixOS, réseau up, flakes activées.
2. Partitionner, puis `nixos-generate-config --root /mnt`.
3. Cloner ce dépôt (privé — clé SSH nécessaire) dans `/mnt/etc/nixos`.
4. Remplacer `hosts/nixos/hardware-configuration.nix` par celui généré
   pour la nouvelle machine (UUID de disque et microcode CPU différents).
5. Avant d'installer, vérifier les imports de `hosts/nixos/default.nix` :
   - `modules/system/graphics-nvidia.nix` suppose une carte NVIDIA
     Turing ou plus récente (`hardware.nvidia.open = true`). À retirer
     si la nouvelle machine n'a pas de GPU NVIDIA compatible.
   - La règle udev et le kernel param `usbcore.quirks` ciblent un
     dongle USB précis (VID:PID 3554:f508) ; sans effet si absent, mais
     à retirer si la machine ne l'a jamais.
6. `nixos-install --flake /mnt/etc/nixos#nixos --root /mnt`
7. Après le premier boot : `passwd izuki` (aucun mot de passe n'est
   géré de façon déclarative dans ce repo).
8. `nixos-rebuild switch` applique aussi la config home-manager en un
   seul passage : rien d'autre à lancer.

## Notes

- Pas de gestionnaire de secrets (sops-nix/agenix) : aucun secret n'est
  committé dans ce dépôt. À introduire seulement si un jour un module
  a besoin de committer un token ou un mot de passe.
- Le thème (matugen) est régénéré au runtime par le script `theme-apply`
  (voir `modules/home/theming/matugen`), pas à la construction Nix, pour
  permettre de changer de fond d'écran sans rebuild.
- `boot.kernelPackages = pkgs.linuxPackages` est un choix délibéré (pas
  `linuxPackages_latest`) pour rester compatible avec les modules NVIDIA.
