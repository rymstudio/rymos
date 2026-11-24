# rymOS 1.0 "Aurora"

rymOS è una distribuzione Linux personale basata su **Debian 13 "Trixie"** con **GNOME 48**.
Non stravolge Debian: aggiunge qualche alias, qualche piccolo strumento e un tocco grafico
(icone Papirus con cartelle gialle, Dash to Panel, sfondi e accenti personalizzati).

Pagina del progetto e download: **https://www.rymstudio.it/rymos/**

## Caratteristiche

- **Stabilità:** basata su Debian 13, ne eredita stabilità e lavoro di anni.
- **Pulizia:** nessun fronzolo e nessun software ridondante; si installa altro da GNOME Software,
  con APT o con Flatpak tramite Flathub.
- **Interfaccia:** tema scuro con accento giallo, icone Papirus, Dash to Panel, sfondi rymOS
  con varianti chiaro/scuro.
- **Avvio:** UEFI (anche con Secure Boot) e BIOS; supporto per GPU recenti, NVIDIA e AMD.
- **Installazione:** con Calamares, anche con disco cifrato.
- Solo 64 bit (amd64).

## Download e verifica

| File | SHA-256 |
|---|---|
| [RymOS-1.0-Aurora-amd64-20261124-0842.iso](https://www.rymstudio.it/rymos/iso/1.0/RymOS-1.0-Aurora-amd64-20261124-0842.iso) (2,8 GB) | `4babeee44bffbf5c9793cb5506b3de256e9afd7560181acc67397f1937272910` |
| [SHA256SUMS](https://www.rymstudio.it/rymos/iso/1.0/SHA256SUMS) | |

Linux, con la ISO e `SHA256SUMS` nella stessa cartella:

```
sha256sum -c SHA256SUMS --ignore-missing
```

Windows (PowerShell):

```
Get-FileHash .\RymOS-1.0-Aurora-amd64-20261124-0842.iso -Algorithm SHA256
```

macOS:

```
shasum -a 256 RymOS-1.0-Aurora-amd64-20261124-0842.iso
```

## Sorgenti

Il codice sorgente dei pacchetti Debian inclusi nella ISO, come richiesto dalla GPL:
[RymOS-1.0-Aurora-amd64-20261124-0842-source-debian.tar](https://www.rymstudio.it/rymos/iso/1.0/RymOS-1.0-Aurora-amd64-20261124-0842-source-debian.tar)
(6,9 GB, SHA-256 `6c7f3cc7addd102b110b6a60a29e83dca7e0b3e3adbe79ad0de238fcd21617df`).

## Contenuto del repository

Questo repository contiene la configurazione di **live-build** con cui viene generata la ISO:

- `build.sh`: lancia `lb config` e `lb build`, assegna il nome e il `BUILD_ID` alla ISO e
  produce gli archivi dei sorgenti;
- `config/package-lists/`: l'elenco dei pacchetti;
- `config/hooks/`: gli script eseguiti durante la costruzione;
- `config/includes.chroot/`: file aggiunti al sistema (sfondi, temi, impostazioni, branding
  di Calamares).

Per costruire la ISO serve un sistema Debian 13 con `live-build`:

```
sudo ./build.sh
```

## Licenze

- I programmi inclusi mantengono le loro licenze (vedi `/usr/share/doc/<pacchetto>/copyright`
  nel sistema).
- Grafiche, sfondi e suono di accesso di rymOS sono distribuiti con licenza
  [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/deed.it); il dettaglio è in
  `config/includes.chroot/usr/share/doc/rymos/LICENZE-RISORSE.txt`.

## Ringraziamenti

- **Michele Nucera**, artista e musicista, autore del jingle di avvio di rymOS.
- **M4dGh1gn0**, che ha corretto e ottimizzato il codice dello strumento protonDB.

---

rymOS è un progetto personale di [RymStudio](https://www.rymstudio.it). Non è affiliato al progetto Debian.
