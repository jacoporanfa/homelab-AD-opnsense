# Troubleshooting log

Problemi reali incontrati durante la costruzione del lab, con diagnosi e soluzione. Formato: sintomo → diagnosi → causa → soluzione → lezione.

---

## 1. VM OPNsense non si avvia: "running without device apic requires a local apic"

**Sintomo:** errore all'avvio della VM, FreeBSD non parte.

**Causa:** I/O APIC disabilitato nelle impostazioni VirtualBox della VM.

**Soluzione:** Impostazioni → Sistema → Scheda madre → abilitare "I/O APIC".

**Lezione:** FreeBSD richiede l'APIC per la gestione degli interrupt; verificare sempre i requisiti del guest OS rispetto all'hardware virtuale esposto.

---

## 2. Installazione Windows Server fallisce: licenza non trovata

**Sintomo:** il setup si interrompe segnalando l'assenza dei termini di licenza.

**Diagnosi:** il problema compariva solo creando la VM con la ISO selezionata nella procedura guidata.

**Causa:** la funzione "Unattended Installation" di VirtualBox 7 inietta un file di risposte incompatibile con le ISO Evaluation (tenta di inserire un product key che le Evaluation non prevedono).

**Soluzione:** creare la VM senza ISO nella procedura guidata e collegarla dopo, da Impostazioni → Archiviazione (oppure spuntare "Skip Unattended Installation").

**Lezione:** gli automatismi degli hypervisor vanno conosciuti per poterli disattivare quando interferiscono.

---

## 3. DC01 non raggiunge il gateway (ping fallito verso 10.10.10.1)

**Sintomo:** nessuna connettività dal server verso OPNsense.

**Diagnosi:** verifica sistematica: stato VM OPNsense → nomi reti interne → ipconfig → cavo virtuale.

**Causa:** nome della rete interna sull'adapter di DC01 diverso da quello configurato su OPNsense (le reti interne VirtualBox con nomi diversi sono switch separati).

**Soluzione:** allineato il nome dell'adapter a `lab-srv`.

**Lezione:** in VirtualBox il nome della rete interna è l'identificatore dello switch virtuale: deve combaciare al carattere.

---

## 4. Client non riceve IP via DHCP (indirizzo APIPA 169.254.x.x)

**Sintomo:** il client si autoassegna un indirizzo APIPA.

**Diagnosi:** range DHCP presente in Dnsmasq; verifica delle interfacce di ascolto del servizio.

**Causa:** Dnsmasq non era in ascolto sull'interfaccia OPT1.

**Soluzione:** Services → Dnsmasq DNS & DHCP → aggiunta di OPT1 alle interfacce (senza WAN: i servizi interni non si espongono mai sull'interfaccia esterna).

**Lezione:** un servizio configurato ma non in ascolto sull'interfaccia giusta equivale a un servizio spento.

---

## 5. DNS del DC irraggiungibile dal client (timeout su porta 53)

**Sintomo:** `nslookup lab.local 10.10.10.10` in timeout dal client; `Test-NetConnection -Port 53` = False. DNS funzionante in locale sul DC.

**Diagnosi in più passi:**
1. Live log OPNsense: nessun blocco visibile → falsa pista
2. Profilo di rete sul DC: `Get-NetConnectionProfile` → "Public" invece di "DomainAuthenticated" (bug NLA post-promozione) → corretto con riavvio adapter, ma il problema persisteva
3. Test con firewall Windows disabilitato temporaneamente → ancora False → il blocco era a monte
4. Revisione regole OPT1: la regola di Block precedeva la regola Pass

**Causa:** ordine errato delle regole firewall (first match wins: il Block intercettava il traffico prima del Pass). Il blocco non compariva nei log perché le regole Block create manualmente non loggano di default.

**Soluzione:** regole ricreate nell'ordine corretto (Pass specifico → Block → Pass generico) con logging abilitato su tutte.

**Lezione:** (1) l'ordine delle regole È la configurazione del firewall; (2) l'assenza di log non prova l'assenza di blocchi: verificare sempre che il logging sia attivo; (3) il ping non è un test affidabile in una rete segmentata — testare il servizio sulla porta specifica.

---

## 6. [Prossimo problema...]

**Sintomo:**

**Diagnosi:**

**Causa:**

**Soluzione:**

**Lezione:**
