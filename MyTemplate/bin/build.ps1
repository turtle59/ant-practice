<#
.SYNOPSIS

Déclenchement d'un script ANT.

.DESCRIPTION

Ce script permet de declencher un script ANT qui prend en charge des parametres de ligne de commande.
Les variables d'environnements JAVA_HOME et ANT_HOME sont deduits du fichier de proprietes env.properties.

.PARAMETER targetname
Nom de la cible ANT à declencher.

.PARAMETER param1
Valeur de paramètre utilisé par la cible ANT à declencher.

.NOTES
    Turtle59
    juillet 2018

#>
Param(
    [parameter( Mandatory = $true )]
    [string]$targetname = "help",

    [parameter( Mandatory = $false )]
    [string]$param1 = "01"
)

# Par défaut, lorsqu'une erreur est générée, elle provoque l'arrêt de la cmdlet.
$ErrorActionPreference = "Stop"

# Récuperation de la date et l'heure courante
$currentdttm = Get-Date -Format "yyyyMMdd-HHmmss"

# Récuperation du répertoire courant ou se trouve le script
$currentpath = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Definition)

# Construction du nom du fichier ANT (build.xml)
$buildfile = "$($currentpath)\build.xml"

# Construction du nom de répertoire libs.
$libspath = "$($currentpath)\..\libs"

# Construction des dependances extérieures (libs).
# jsch requis pour les instructions sshexec.
$libsfile = "$($libspath)\jsch-0.1.54.jar"

# Construction du nom de répertoire log.
$logpath = "$($currentpath)\..\log"

# Construction du nom du fichier en sortie (log).
$logfile = "$($logpath)\$($currentdttm)-$($targetname).log"

# Fixation des variables d'environnement
$envpath = "$($currentpath)\.."

# Lecture des propriétés utilisateurs.
$envparams = convertfrom-stringdata (Get-Content -Path "$($envpath)\env.properties" -raw)

# Définition de la variable d'environnement JAVA_HOME si inexistante.
if (!$Env:JAVA_HOME) {
    Write-Host "Definition de la variable JAVA_HOME:" $envparams.'JAVA_HOME'
    New-Item -Path "env:\" -Name "JAVA_HOME" -Value $envparams.'JAVA_HOME' -Force
}

# Définition de la variable d'environnement ANT_HOME si inexistante.
if (!$Env:ANT_HOME) {
    Write-Host "Definition de la variable ANT_HOME:" $envparams.'ANT_HOME'
    New-Item -Path "env:\" -Name "ANT_HOME" -Value $envparams.'ANT_HOME' -Force
}

$Env:CLASSPATH = "$($Env:JAVA_HOME)\lib"

# Le PATH est sauvegardé pour restitution à la fin du traitement.
$path_before = $env:path
$env:path = $env:path + ";$($env:JAVA_HOME)\bin;$($Env:ANT_HOME)\bin"


Write-Host "START" -ForegroundColor Green
Write-Host "Chemin : " $currentpath
Write-Host " build : " $buildfile

Write-Host "    Date : " $currentdttm -ForegroundColor Yellow
Write-Host "   Cible : " $targetname -ForegroundColor Yellow
Write-Host "     log : " $logfile

Write-Host "Env" $env:JAVA_HOME
Write-Host "Env" $env:ANT_HOME
Write-Host "Env" $env:Path

# Création d'un répertoire log si absent
If (!(Test-Path -Path $logpath))
{
    Write-Host "Création du répertoire " $logpath
    New-Item -ItemType Directory -Force -Path $logpath
}

# Déclenchement du script ANT
$env:ANT_OPTS = "-Xms512M -Xmx512M"
Start-Process -FilePath ant -ArgumentList "-lib $libsfile -logfile $logfile -buildfile $buildfile -Dmonparam=$param1 $targetname" -NoNewWindow -Wait


# Duplication du log généré vers nom générique (build.log)
If (Test-Path -Path $logfile)
{
    Write-Host "INFO : Fichier de log '$logfile' présent"
    Copy-Item $logfile -Destination "$($logpath)\build.log"

    # Si le script est appelé par un autre script alors la variable est peuplée
    # Dans ce cas l'affichage systématique du résultat est annulé
    if ([string]::IsNullOrEmpty($MyInvocation.PSCommandPath)) {
        Start-Process -FilePath $logfile -Verb Open
    }

} else {
    Write-Host "WARNING : Fichier de log '$logfile' absent"
}

# Restitution du path précédant
$env:path = $path_before


# Marqueur fin de traitement
Write-Host "END" -ForegroundColor Green
