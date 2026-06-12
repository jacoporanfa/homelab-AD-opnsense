# 03 – Regole firewall e segmentazione

## Obiettivo

Permettere al client (rete OPT1) di comunicare con il Domain Controller (rete LAN) **solo** sulle porte richieste da Active Directory, bloccare ogni altro accesso alla rete server, e consentire la navigazione internet. Principio: least privilege.

## Comportamento di default di OPNsense

- **LAN**: regola predefinita "allow LAN to any" + regola anti-lockout per la GUI → tutto aperto in uscita
- **OPT1** (e ogni interfaccia aggiuntiva): **nessuna regola = tutto bloccato** (default deny)

La segmentazione nasce da qui: la rete client parte sigillata e si apre solo ciò che serve.

## Alias delle porte AD

Firewall → Aliases → nuovo alias:

| Campo | Valore |
|---|---|
| Name | `Porte_AD` |
| Type | Port(s) |
| Content | 53, 88, 123, 135, 389, 445, 464, 3268, 49152:65535 |

| Porta | Servizio |
|---|---|
| 53 | DNS |
| 88 | Kerberos (autenticazione) |
| 123 | NTP — Kerberos fallisce con scarti orari eccessivi |
| 135 | RPC endpoint mapper |
| 389 | LDAP |
| 445 | SMB |
| 464 | Kerberos password change |
| 3268 | Global Catalog |
| 49152–65535 | Range RPC dinamico (negoziato dopo il contatto su 135) |

## Regole su OPT1

Firewall → Rules → OPT1, nell'ordine (le regole nuove si accodano: crearle già in sequenza):

| # | Azione | Proto | Sorgente | Destinazione | Porte | Log | Descrizione |
|---|---|---|---|---|---|---|---|
| 1 | Pass | TCP/UDP | OPT1 net | 10.10.10.10/32 | Porte_AD | ✔ | Client verso DC porte AD |
| 2 | Block | any | OPT1 net | LAN net | any | ✔ | Blocco rete server |
| 3 | Pass | any | OPT1 net | any | any | ✔ | Internet |

## Perché l'ordine conta: first match wins

OPNsense valuta le regole dall'alto e applica **la prima che combacia**:

- pacchetto → DC porta 445 → matcha la 1 → passa
- pacchetto → DC porta 3389 (RDP) → salta la 1, matcha la 2 → bloccato
- pacchetto → internet → salta 1 e 2, matcha la 3 → passa

Con la Block sopra la Pass, il traffico AD non raggiungerebbe mai la regola 1: è esattamente l'errore commesso (e diagnosticato) durante la costruzione del lab — vedi [troubleshooting log](troubleshooting.md).

## Logging

Le regole Block create manualmente **non loggano di default**: la casella Log va spuntata esplicitamente. Senza, i pacchetti scartati muoiono in silenzio e il Live View mostra un quadro fuorviante ("nessuna riga rossa" ≠ "nessun blocco").

Strumento di diagnosi principale: **Firewall → Log Files → Live View** — mostra in tempo reale ogni decisione con la regola che l'ha presa.

## Verifiche

```powershell
# Dal client — il test giusto: servizio sulla porta specifica
Test-NetConnection 10.10.10.10 -Port 53     # TcpTestSucceeded: True
nslookup lab.local 10.10.10.10              # → 10.10.10.10
ping 8.8.8.8                                 # internet OK

# Atteso e corretto che fallisca:
ping 10.10.10.10    # ICMP non è nell'alias → bloccato dalla regola 2
```

> Lezione operativa: in una rete segmentata "non pinga" non significa "non funziona". ICMP è spesso bloccato di proposito mentre i servizi reali passano — si diagnostica testando la porta del servizio, non il ping.
