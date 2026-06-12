<#
.SYNOPSIS
    Diagnostica di rete e dominio lato client (rete segmentata OPT1).
.DESCRIPTION
    Verifica la catena completa: DHCP -> DNS -> firewall -> DC -> join.
    Nota: in una rete segmentata il ping NON e' un test affidabile (ICMP
    e' bloccato di proposito dalle regole firewall): si testano i servizi
    sulle porte specifiche.
.NOTES
    Eseguire sul client. Controlli in sola lettura.
#>

$DC_IP   = "10.10.10.10"
$Dominio = "lab.local"

Write-Host "=== 1. Configurazione IP (attesi: IP 10.10.20.1xx, GW 10.10.20.1, DNS $DC_IP) ===" -ForegroundColor Cyan
# Un indirizzo 169.254.x.x (APIPA) = il DHCP non ha risposto
Get-NetIPConfiguration | Format-List InterfaceAlias, IPv4Address, IPv4DefaultGateway, DNSServer

Write-Host "=== 2. Porta DNS del DC attraverso il firewall ===" -ForegroundColor Cyan
# Attraversa la regola 1 (Pass OPT1 -> DC, alias Porte_AD)
Test-NetConnection $DC_IP -Port 53 | Format-List ComputerName, RemotePort, TcpTestSucceeded

Write-Host "=== 3. Risoluzione del dominio ===" -ForegroundColor Cyan
Resolve-DnsName $Dominio | Format-Table -AutoSize

Write-Host "=== 4. Record SRV: il client trova il DC? ===" -ForegroundColor Cyan
Resolve-DnsName -Type SRV "_ldap._tcp.dc._msdcs.$Dominio" | Format-Table -AutoSize

Write-Host "=== 5. Stato del join al dominio ===" -ForegroundColor Cyan
Get-CimInstance Win32_ComputerSystem | Format-List Name, Domain, PartOfDomain

Write-Host "=== 6. Connettivita' internet (regola 3 del firewall) ===" -ForegroundColor Cyan
Test-NetConnection 8.8.8.8 | Format-List ComputerName, PingSucceeded
