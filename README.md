# Exercice-02-Active-Directory
Projet Active Directory – laplateforme.io

## Objectif du projet

Dans ce projet, j’ai installé et configuré un domaine **Active Directory** sur un serveur Windows afin de créer l’annuaire **laplateforme.io**.  
J’ai ensuite automatisé la création des utilisateurs et des groupes à partir d’un fichier CSV à l’aide de **PowerShell**.

---

## Environnement utilisé

- Windows Server 2022
- PowerShell 5.1 (en mode administrateur)
- Rôle **AD DS (Active Directory Domain Services)**
- Fichier CSV encodé en UTF-8 contenant les informations des utilisateurs et des groupes

---

## Étape 1 – Installation du rôle AD DS et création du domaine

J’ai d’abord installé le rôle Active Directory et j’ai créé le domaine `laplateforme.io` avec le mot de passe de restauration `Azerty_2025!`.

### Script : `Install-ADDS.ps1`

```powershell
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

Install-ADDSForest `
    -DomainName "laplateforme.io" `
    -SafeModeAdministratorPassword (ConvertTo-SecureString "Azerty_2025!" -AsPlainText -Force) `
    -Force

## Étape 2 – Vérification du domaine

J’ai vérifié que le domaine avait bien été créé avec les commandes suivantes :
	Get-ADDomain
	Get-ADDomainController
Le résultat m’a confirmé que le contrôleur de domaine était bien opérationnel avec le nom NetBIOS LAPLATEFORME et le DNS laplateforme.io.

## Étape 3 – Importation des utilisateurs et groupes

J’ai ensuite créé un fichier CSV contenant la liste des utilisateurs et leurs groupes d’appartenance.

## Étape 4 – Script PowerShell d’importation

J’ai rédigé le script suivant, nommé Import-UtilisateursAD.ps1, pour automatiser la création des utilisateurs, des groupes et leur rattachement.
Script : Import-UtilisateursAD.ps1

Import-Module ActiveDirectory

$csvPath = "C:\Scripts\utilisateurs.csv"
$DefaultPassword = ConvertTo-SecureString "Azerty_2025!" -AsPlainText -Force

# Création d'une OU "Utilisateurs" si elle n'existe pas
if (-not (Get-ADOrganizationalUnit -Filter "Name -eq 'Utilisateurs'" -ErrorAction SilentlyContinue)) {
    New-ADOrganizationalUnit -Name "Utilisateurs" -ProtectedFromAccidentalDeletion $false
}

$users = Import-Csv -Path $csvPath -Delimiter ','

foreach ($user in $users) {
    $nom = $user.nom.Trim()
    $prenom = $user.prenom.Trim()
    $SamAccountName = ($prenom.Substring(0,1) + $nom).ToLower()
    $UPN = "$SamAccountName@laplateforme.io"
    $OU = "OU=Utilisateurs,DC=laplateforme,DC=io"

    # Création de l’utilisateur
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

    # Ajout aux groupes
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

## Étape 5 – Résultat

Après exécution du script :

Tous les utilisateurs du fichier CSV ont été créés dans l’OU Utilisateurs.

Les groupes nécessaires ont été créés automatiquement.

Chaque utilisateur a reçu le mot de passe par défaut Azerty_2025!.

J’ai configuré le changement de mot de passe obligatoire à la première connexion.

## Conclusion

J’ai réussi à :

Installer et configurer un domaine Active Directory laplateforme.io.

Créer automatiquement des comptes utilisateurs et groupes à partir d’un CSV.

Définir un mot de passe par défaut sécurisé avec changement obligatoire.

Automatiser le processus de création grâce à PowerShell.

Ce projet m’a permis de mieux comprendre :

L’architecture d’un domaine AD,

La gestion des comptes utilisateurs et groupes,

Et l’automatisation d’administration avec PowerShell.

