<#
.SYNOPSIS
    Crea la struttura di Organizational Unit del dominio lab.local.
.DESCRIPTION
    Struttura: LabCorp come OU radice, con sotto-OU per Utenti, Computer e Gruppi.
    Le OU permettono di organizzare gli oggetti e applicare Group Policy in modo mirato.
.NOTES
    Eseguire sul Domain Controller (o con RSAT + modulo ActiveDirectory) come utente con privilegi di dominio.
    Homelab: https://github.com/jacoporanfa/homelab-ad-opnsense
#>

# Percorso base del dominio in formato Distinguished Name (si legge da destra a sinistra)
$DominioDN = "DC=lab,DC=local"
$OURadice  = "LabCorp"

# OU radice
New-ADOrganizationalUnit -Name $OURadice -Path $DominioDN
Write-Host "Creata OU: $OURadice" -ForegroundColor Green

# Sotto-OU
$SottoOU = @("Utenti", "Computer", "Gruppi")
foreach ($OU in $SottoOU) {
    New-ADOrganizationalUnit -Name $OU -Path "OU=$OURadice,$DominioDN"
    Write-Host "Creata OU: $OURadice/$OU" -ForegroundColor Green
}

# Verifica finale: elenca le OU create
Write-Host "`nStruttura risultante:" -ForegroundColor Cyan
Get-ADOrganizationalUnit -Filter * -SearchBase "OU=$OURadice,$DominioDN" |
    Select-Object Name, DistinguishedName |
    Format-Table -AutoSize
