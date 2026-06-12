# 01 – Installazione e configurazione OPNsense

## Obiettivo

Installare OPNsense come firewall/router con tre interfacce: WAN verso internet (via NAT VirtualBox) e due reti interne segmentate per server e client.

## Creazione VM

| Parametro | Valore |
|---|---|
| Tipo SO | BSD / FreeBSD 64-bit |
| RAM | 1024 MB |
| Disco | 20 GB VDI, allocazione dinamica |
| I/O APIC | Abilitato (richiesto da FreeBSD) |
| Adapter 1 | NAT (→ WAN) |
| Adapter 2 | Rete interna `lab-srv` (→ LAN) |
| Adapter 3 | Rete interna `lab-cli` (→ OPT1) |

> Nota: i nomi delle reti interne VirtualBox identificano lo switch virtuale. Devono combaciare al carattere su tutte le VM collegate alla stessa rete.

## Installazione

1. Boot dalla ISO OPNsense (immagine `dvd`, decompressa da .bz2)
2. Login installer: utente `installer`, password `opnsense`
3. Filesystem: **UFS** (ZFS è superfluo su disco virtuale singolo; il warning sulla RAM riguarda ZFS e con UFS si può ignorare)
4. Disco di destinazione: `ada0` (il disco virtuale; `cd0` è la ISO)
5. A installazione completata: rimuovere la ISO dal lettore virtuale e riavviare

## Assegnazione interfacce

Dalla console (login `root` / `opnsense`), voce **1) Assign interfaces**:

- LAGG: no (aggregazione link, non necessaria su NIC virtuali)
- VLAN da console: no (gestite a livello di topologia con reti interne separate)
- WAN: `em0` · LAN: `em1` · OPT1: `em2`

## Configurazione IP — voce 2) Set interface IP address

**LAN (em1):**

| Campo | Valore |
|---|---|
| IP via DHCP | No (il gateway deve essere statico) |
| IPv4 | 10.10.10.1 / 24 |
| Gateway | vuoto (OPNsense È il gateway di questa rete) |
| DHCP server | Sì, range 10.10.10.100 – 10.10.10.200 |

**OPT1 (em2):** identica logica, rete 10.10.20.0/24, gateway 10.10.20.1, range .100–.200.

**WAN (em0):** nessuna configurazione manuale — DHCP client verso il NAT di VirtualBox (unica interfaccia dove OPNsense riceve la configurazione anziché dettarla).

Alle domande su protocollo GUI/certificato: mantenuti i default (HTTPS con certificato self-signed).

## DHCP/DNS (Dnsmasq)

GUI (`https://10.10.10.1`, da un host sulla LAN):

- **Services → Dnsmasq DNS & DHCP → Settings**: interfacce di ascolto **LAN e OPT1** (mai WAN: i servizi interni non si espongono sull'interfaccia esterna — un resolver aperto su WAN è un vettore di abuso)
- **DHCP ranges**: verificati i range per LAN e OPT1
- **DHCP options**: opzione `dns-server [6]` per OPT1 = `10.10.10.10`, così i client della rete OPT1 ricevono come DNS il Domain Controller (requisito per il join al dominio)

## Verifica

```
# Dalla console OPNsense
7) Ping host → 8.8.8.8        # uscita internet via WAN

# Riepilogo interfacce atteso (sopra il menu console)
WAN (em0)  -> v4/DHCP4: 10.0.2.15/24
LAN (em1)  -> v4: 10.10.10.1/24
OPT1 (em2) -> v4: 10.10.20.1/24
```
