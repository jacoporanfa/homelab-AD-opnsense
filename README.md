# Homelab: Active Directory + OPNsense con segmentazione di rete

Laboratorio virtualizzato che replica l'infrastruttura tipica di una PMI: firewall perimetrale con reti segmentate, dominio Active Directory e client Windows gestito. Costruito interamente su VirtualBox.

## Obiettivi del progetto

- Progettare e implementare una rete segmentata con firewall OPNsense
- Installare e configurare un Domain Controller Windows Server 2022 (AD DS + DNS)
- Eseguire il join al dominio di un client Windows 11 attraverso il firewall, aprendo solo le porte necessarie
- Documentare il processo di troubleshooting con metodo

## Topologia

![Topologia di rete](img/topologia.png)

```
Internet
   │
   │ (NAT VirtualBox)
   ▼
┌──────────────────────────────────────────────┐
│  OPNsense (firewall/router)                  │
│  WAN: DHCP da NAT                            │
│  LAN  (em1): 10.10.10.1/24  → rete server    │
│  OPT1 (em2): 10.10.20.1/24  → rete client    │
└──────────────────────────────────────────────┘
   │ lab-srv                    │ lab-cli
   ▼                            ▼
DC01                         CLIENT01
Windows Server 2022          Windows 11 Enterprise
10.10.10.10 (statico)        DHCP (10.10.20.100-200)
AD DS, DNS                   Membro del dominio
Dominio: lab.local
```

## Piano di indirizzamento

| Host | Rete | IP | Note |
|---|---|---|---|
| OPNsense WAN | NAT VirtualBox | DHCP | Uplink verso internet |
| OPNsense LAN | lab-srv | 10.10.10.1/24 | Gateway rete server |
| OPNsense OPT1 | lab-cli | 10.10.20.1/24 | Gateway rete client |
| DC01 | lab-srv | 10.10.10.10/24 | Statico, fuori dal pool DHCP |
| CLIENT01 | lab-cli | DHCP .100–.200 | DNS via opzione DHCP: 10.10.10.10 |

Convenzione: indirizzi .2–.99 riservati ad assegnazioni statiche, pool DHCP .100–.200.

## Componenti

| VM | SO | vCPU | RAM | Disco |
|---|---|---|---|---|
| OPNsense | OPNsense 25.x (FreeBSD) | 1 | 1 GB | 20 GB |
| DC01 | Windows Server 2022 Standard Eval | 2 | 4 GB | 60 GB |
| CLIENT01 | Windows 11 Enterprise Eval | 2 | 4 GB | 60 GB |

## Regole firewall (interfaccia OPT1)

Principio: default deny, apertura del minimo indispensabile, first match wins.

| # | Azione | Proto | Sorgente | Destinazione | Porte | Scopo |
|---|---|---|---|---|---|---|
| 1 | Pass | TCP/UDP | OPT1 net | 10.10.10.10 | alias `Porte_AD` | Traffico AD client→DC |
| 2 | Block | any | OPT1 net | LAN net | any | Isolamento rete server |
| 3 | Pass | any | OPT1 net | any | any | Accesso internet |

Alias `Porte_AD`: 53 (DNS), 88 (Kerberos), 123 (NTP), 135 (RPC), 389 (LDAP), 445 (SMB), 464 (Kerberos pwd), 3268 (Global Catalog), 49152-65535 (RPC dinamiche).

## Struttura Active Directory

```
lab.local
└── OU LabCorp
    ├── OU Utenti     (utenti del dominio)
    ├── OU Computer   (workstation)
    └── OU Gruppi     (gruppi di sicurezza)
```

Dominio: `lab.local` · NetBIOS: `LAB` · Forest/domain functional level: Windows Server 2016+

## Documentazione dettagliata

- [01 – Installazione e configurazione OPNsense](docs/01-opnsense.md)
- [02 – Domain Controller: installazione e promozione](docs/02-domain-controller.md)
- [03 – Regole firewall e segmentazione](docs/03-firewall.md)
- [04 – Join al dominio del client](docs/04-client-join.md)
- [Troubleshooting log](docs/troubleshooting.md)

## Competenze dimostrate

- Virtualizzazione (VirtualBox: reti interne, NAT, EFI/TPM, snapshot)
- Networking: subnetting, DHCP, DNS, gateway, segmentazione L3
- Firewall: regole stateful, alias, ordine di valutazione, logging, analisi live log
- Windows Server: AD DS, DNS, promozione DC, PowerShell (modulo ActiveDirectory)
- Troubleshooting metodico multi-livello (hypervisor → rete → firewall → OS → servizio)

## Prossimi sviluppi

- [ ] Group Policy: hardening client, drive mapping, restrizioni utente
- [ ] File server con gruppi di sicurezza e permessi NTFS
- [ ] Monitoraggio: Sysmon + Wazuh SIEM
- [ ] Esercizi purple team (Atomic Red Team, mappatura MITRE ATT&CK)
