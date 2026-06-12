# 04 – Join al dominio del client

## Obiettivo

Collegare un client Windows 11 al dominio `lab.local` dalla rete segmentata OPT1, attraversando il firewall sulle sole porte consentite.

## Creazione VM

| Parametro | Valore |
|---|---|
| Nome | CLIENT01 |
| SO | Windows 11 Enterprise Evaluation |
| RAM | 4096 MB · 2 vCPU · Disco 60 GB |
| EFI / Secure Boot / TPM 2.0 | Abilitati (requisiti Windows 11; VirtualBox 7 li imposta col profilo "Windows 11") |
| Rete | Adapter 1 → Rete interna `lab-cli` |

> Edizione: il join al dominio richiede Pro/Enterprise/Education — **Windows Home non può entrare in un dominio**. Verifica: `winver` o `(Get-ComputerInfo).WindowsProductName`.

## Prerequisiti di rete

1. **IP via DHCP** da OPNsense: atteso 10.10.20.100–200, gateway 10.10.20.1

```powershell
ipconfig /all
# In caso di indirizzo APIPA 169.254.x.x: il DHCP non risponde
# (cause tipiche: nome rete interna errato, Dnsmasq non in ascolto su OPT1)
ipconfig /release; ipconfig /renew
```

2. **DNS = il Domain Controller** (10.10.10.10), distribuito via opzione DHCP `dns-server [6]` configurata su OPNsense per OPT1. Requisito assoluto: il client trova il dominio interrogando il DNS — se il DNS non è quello di AD, il join fallisce con "An Active Directory Domain Controller could not be contacted".

3. **Connettività verso il DC attraverso il firewall:**

```powershell
Test-NetConnection 10.10.10.10 -Port 53   # True
nslookup lab.local                         # → 10.10.10.10 (ora senza server esplicito)
```

## Come il client trova il dominio: il DC Locator

Inserito `lab.local`, il client:

1. interroga il DNS per il record **SRV** `_ldap._tcp.dc._msdcs.lab.local` ("chi è il Domain Controller di questo dominio?")
2. riceve `DC01.lab.local:389` — record registrato da Netlogon al momento della promozione
3. contatta il DC via LDAP, autentica le credenziali amministrative via Kerberos (88)
4. il DC crea l'**account computer** di CLIENT01 in AD e stabilisce la relazione di fiducia

Verifica diretta del record SRV:

```powershell
nslookup -type=SRV _ldap._tcp.dc._msdcs.lab.local
```

## Procedura di join

1. `Win+R` → `sysdm.cpl` → scheda **Nome computer** → **Cambia...**
2. (Opzionale, stessa finestra) rinomina in `CLIENT01`
3. Sezione **Membro di** → **Dominio** → `lab.local`
4. Credenziali di un account autorizzato: `LAB\Administrator` + password del dominio (le credenziali locali del client non hanno alcun ruolo)
5. Messaggio di benvenuto nel dominio → riavvio

> La via Impostazioni (Sistema → Informazioni → "Dominio o gruppo di lavoro") porta alla stessa finestra. Attenzione al falso amico "Accedi all'azienda o all'istituto di istruzione" in Account: è il percorso Microsoft Entra (cloud), non AD on-premise.

## Verifica

```powershell
Get-CimInstance Win32_ComputerSystem | Select-Object Name, Domain, PartOfDomain
# Domain: lab.local · PartOfDomain: True
```

**Login di dominio:** alla schermata di accesso → **Altro utente** → `LAB\mrossi` (il prefisso `LAB\` indirizza l'autenticazione al dominio anziché al SAM locale). Gli utenti di dominio compaiono nella lista solo dopo il primo login; il primo accesso è lento per la creazione del profilo.

L'utente `mrossi` non esiste sul client: vive nel database AD sul DC. Il login attraversa firewall → DNS → Kerberos → DC: è la verifica end-to-end dell'intero lab.

**Reset password (procedura help desk), dal DC:**

```powershell
Set-ADAccountPassword -Identity mrossi -Reset -NewPassword (Read-Host -AsSecureString "Nuova password")
```
