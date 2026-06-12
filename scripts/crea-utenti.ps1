<#
.SYNOPSIS
    Crea un utente di dominio nella OU Utenti di lab.local.
.DESCRIPTION
    La password viene richiesta interattivamente come SecureString:
    mai password in chiaro negli script (restano nello storico comandi e nei repo).
.NOTES
    Eseguire sul Domain Controller come utente con privilegi di dominio.
    AD richiede di default password complesse: min 7 caratteri, 3 tipi tra
    maiuscole/minuscole/numeri/simboli.
#>

# --- Parametri utente (modificare qui per creare altri utenti) ---
$Nome      = "Mario"
$Cognome   = "Rossi"
$Login     = "mrossi"                  # SamAccountName: login stile LAB\mrossi
$UPN       = "$Login@lab.local"        # UserPrincipalName: login stile moderno
$PercorsoOU = "OU=Utenti,OU=LabCorp,DC=lab,DC=local"

# Password richiesta in modo sicuro al momento dell'esecuzione
$Password = Read-Host -AsSecureString "Password per $Login"

New-ADUser -Name "$Nome $Cognome" `
    -GivenName $Nome `
    -Surname $Cognome `
    -SamAccountName $Login `
    -UserPrincipalName $UPN `
    -Path $PercorsoOU `
    -AccountPassword $Password `
    -Enabled $true                      # gli utenti AD nascono disabilitati di default

Write-Host "Creato utente: $Nome $Cognome (LAB\$Login)" -ForegroundColor Green

# Verifica
Get-ADUser -Identity $Login -Properties UserPrincipalName |
    Select-Object Name, SamAccountName, UserPrincipalName, Enabled, DistinguishedName
