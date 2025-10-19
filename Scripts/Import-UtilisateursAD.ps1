Import-Module ActiveDirectory

$csvPath = "C:\Users\Administrator\Scripts\utilisateurs.csv"
$DefaultPassword = ConvertTo-SecureString "Azerty_2025!" -AsPlainText -Force

# Créer une OU "Utilisateurs" si elle n’existe pas déjà
if (-not (Get-ADOrganizationalUnit -Filter "Name -eq 'Utilisateurs'" -ErrorAction SilentlyContinue)) {
    New-ADOrganizationalUnit -Name "Utilisateurs" -ProtectedFromAccidentalDeletion $false
}

# Importer les utilisateurs depuis le CSV
$users = Import-Csv -Path $csvPath -Delimiter ','

foreach ($user in $users) {
    $nom = $user.nom.Trim()
    $prenom = $user.prenom.Trim()
    $SamAccountName = ($prenom.Substring(0,1) + $nom).ToLower()
    $UPN = "$SamAccountName@laplateforme.io"
    $OU = "OU=Utilisateurs,DC=laplateforme,DC=io"

    # Créer l’utilisateur s’il n’existe pas déjà
    if (-not (Get-ADUser -Filter "SamAccountName -eq '$SamAccountName'" -ErrorAction SilentlyContinue)) {
        New-ADUser `
            -Name "$prenom $nom" `
            -GivenName $prenom `
            -Surname $nom `
            -SamAccountName $SamAccountName `
            -UserPrincipalName $UPN `
            -AccountPassword $DefaultPassword `
            -ChangePasswordAtLogon $true `
            -Enabled $true `
            -Path $OU

        Write-Host "✅ Utilisateur créé : $prenom $nom"
    }

    # Créer/ajouter les groupes
    $groupes = @($user.groupe1, $user.groupe2, $user.groupe3, $user.groupe4, $user.groupe5, $user.groupe6) | Where-Object { $_ -ne "" }

    foreach ($groupe in $groupes) {
        if (-not (Get-ADGroup -Filter "Name -eq '$groupe'" -ErrorAction SilentlyContinue)) {
            New-ADGroup -Name $groupe -GroupScope Global -GroupCategory Security
            Write-Host "🆕 Groupe créé : $groupe"
        }

        Add-ADGroupMember -Identity $groupe -Members $SamAccountName -ErrorAction SilentlyContinue
        Write-Host "➡️ $prenom $nom ajouté au groupe $groupe"
    }
}
