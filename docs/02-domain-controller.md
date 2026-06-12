# 02 – Domain Controller: installazione e promozione

## Obiettivo

Installare Windows Server 2022, configurarlo come Domain Controller del nuovo dominio `lab.local` con DNS integrato, e creare la struttura logica di base (OU e utenti).

## Creazione VM

| Parametro | Valore |
|---|---|
| Nome | DC01 |
| Tipo SO | Windows 2022 (64-bit) |
| RAM | 4096 MB · 2 vCPU |
| Disco | 60 GB VDI dinamico |
| Rete | Adapter 1 → Rete interna `lab-srv` (nessun NAT/bridge: l'unica uscita è attraverso il firewall) |

> VirtualBox 7: creare la VM **senza** selezionare la ISO nella procedura guidata (o spuntare "Skip Unattended Installation") — l'installazione automatica è incompatibile con le ISO Evaluation. Collegare la ISO dopo, da Impostazioni → Archiviazione.

## Installazione

Edizione: **Windows Server 2022 Standard Evaluation (Desktop Experience)** — attenzione: le voci senza "Desktop Experience" installano la versione Core senza GUI (riconoscibile al primo avvio dal menu testuale SConfig).

## Configurazione pre-promozione

Operazioni nell'ordine corretto — in particolare la rinomina va fatta **prima** della promozione:

**1. IP statico** (Server Manager → Local Server → Ethernet → Proprietà IPv4):

| Campo | Valore |
|---|---|
| IP | 10.10.10.10 |
| Subnet mask | 255.255.255.0 |
| Gateway | 10.10.10.1 |
| DNS preferito | 10.10.10.1 (provvisorio: la promozione lo riconfigurerà sul server stesso) |

**2. Rinomina** in `DC01` e riavvio.

**3. Verifica connettività:**

```powershell
ping 10.10.10.1   # gateway OPNsense
ping 8.8.8.8      # internet attraverso il firewall
```

## Installazione ruolo e promozione

1. Server Manager → Manage → **Add Roles and Features** → ruolo **Active Directory Domain Services**
2. A installazione completata: bandierina gialla → **Promote this server to a domain controller**
3. Wizard: **Add a new forest** → root domain `lab.local` · functional level default · DNS e Global Catalog abilitati · password DSRM impostata · NetBIOS `LAB` · percorsi default
4. Riavvio automatico; login successivo come `LAB\Administrator`

> Il warning sulla delega DNS durante il wizard è atteso e ignorabile in una foresta nuova.

## Verifica post-promozione

```powershell
Get-ADDomain | Select-Object DNSRoot, NetBIOSName, DomainMode
Get-Service ADWS, DNS, Netlogon, KDC      # tutti Running
Resolve-DnsName lab.local                  # → 10.10.10.10
```

Ruolo dei quattro servizi: **DNS** (i client trovano i DC tramite record SRV), **Netlogon** (canale sicuro e registrazione dei record SRV), **KDC** (ticket Kerberos, porta 88), **ADWS** (amministrazione via PowerShell/console).

> Noto post-promozione: il servizio NLA può classificare la rete come "Public" facendo applicare il profilo firewall sbagliato. Verifica: `Get-NetConnectionProfile` deve riportare `DomainAuthenticated`. Cura: `Restart-NetAdapter` o riavvio. Dettagli nel [troubleshooting log](troubleshooting.md).

## Struttura logica

```powershell
New-ADOrganizationalUnit -Name "LabCorp" -Path "DC=lab,DC=local"
New-ADOrganizationalUnit -Name "Utenti" -Path "OU=LabCorp,DC=lab,DC=local"
New-ADOrganizationalUnit -Name "Computer" -Path "OU=LabCorp,DC=lab,DC=local"
New-ADOrganizationalUnit -Name "Gruppi" -Path "OU=LabCorp,DC=lab,DC=local"
```

Utente di test:

```powershell
New-ADUser -Name "Mario Rossi" -GivenName "Mario" -Surname "Rossi" `
  -SamAccountName "mrossi" -UserPrincipalName "mrossi@lab.local" `
  -Path "OU=Utenti,OU=LabCorp,DC=lab,DC=local" `
  -AccountPassword (Read-Host -AsSecureString "Password") `
  -Enabled $true
```

> `Read-Host -AsSecureString` evita di lasciare la password nello storico comandi. La sintassi dei percorsi è il Distinguished Name LDAP, da leggere da destra a sinistra.
