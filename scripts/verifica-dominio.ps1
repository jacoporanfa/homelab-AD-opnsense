<#
.SYNOPSIS
    Diagnostica rapida dello stato del Domain Controller e del dominio.
.DESCRIPTION
    Kit di verifica post-promozione e primo strumento in caso di problemi:
    stato dominio, servizi vitali, DNS, profilo di rete del firewall.
.NOTES
    Eseguire sul Domain Controller. Tutti i controlli sono in sola lettura.
#>

Write-Host "=== 1. Stato del dominio ===" -ForegroundColor Cyan
Get-ADDomain | Select-Object DNSRoot, NetBIOSName, DomainMode | Format-List

Write-Host "=== 2. Servizi vitali (devono essere tutti Running) ===" -ForegroundColor Cyan
# DNS: i client trovano i DC tramite record SRV
# Netlogon: canale sicuro + registrazione record SRV
# KDC: ticket Kerberos (porta 88)
# ADWS: amministrazione via PowerShell e console
Get-Service ADWS, DNS, Netlogon, KDC | Format-Table Name, Status, DisplayName -AutoSize

Write-Host "=== 3. Risoluzione DNS del dominio ===" -ForegroundColor Cyan
Resolve-DnsName lab.local | Format-Table -AutoSize

Write-Host "=== 4. Record SRV del DC Locator ===" -ForegroundColor Cyan
# Il record che i client interrogano per trovare il Domain Controller
Resolve-DnsName -Type SRV _ldap._tcp.dc._msdcs.lab.local | Format-Table -AutoSize

Write-Host "=== 5. Profilo di rete (deve essere DomainAuthenticated) ===" -ForegroundColor Cyan
# Se risulta 'Public', NLA ha classificato male la rete e il firewall di Windows
# applica il profilo restrittivo: i client non raggiungono i servizi del DC.
# Cura: Restart-NetAdapter -Name "Ethernet" (o riavvio del server)
Get-NetConnectionProfile | Format-Table Name, InterfaceAlias, NetworkCategory -AutoSize

Write-Host "=== 6. Configurazione IP ===" -ForegroundColor Cyan
Get-NetIPConfiguration | Format-List InterfaceAlias, IPv4Address, IPv4DefaultGateway, DNSServer
