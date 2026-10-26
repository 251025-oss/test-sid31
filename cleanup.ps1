<#
  cleanup.ps1 — Nettoyage minimal de CSV (PowerShell natif)
  --------------------------------------------------------------------
  CORRECTIONS / CHOIX TECHNIQUES
  - Import-Csv gère correctement les champs guillemetés (plus robuste
    qu'un simple split sur des virgules). On impose 3 colonnes attendues.
  - Export-Csv avec -UseQuotes AsNeeded évite les guillemets inutiles.
  - Encodage UTF-8 explicite via -Encoding utf8.
  - Gestion d’erreurs stricte + message clair en cas de colonne manquante.
  --------------------------------------------------------------------
  USAGE
    pwsh -NoProfile -File .\cleanup.ps1 .\clients.csv .\clients.clean.csv

  EN CONTENEUR (compose)
    # Terminal 1 (service 'pwsh'):
    docker compose run --rm pwsh
    # Puis dans la session conteneur :
    ./cleanup.ps1 clients.csv clients.clean.csv
#>

[CmdletBinding()]
param(
  [Parameter(Position=0, Mandatory=$false)]
  [string]$In = "clients.csv",
  [Parameter(Position=1, Mandatory=$false)]
  [string]$Out = "clients.clean.csv"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (!(Test-Path -LiteralPath $In)) {
  throw "Fichier d'entrée introuvable: $In"
}

# Lire brut, retirer lignes vides / espaces de fin
$raw = Get-Content -LiteralPath $In -Raw -ErrorAction Stop

# Normaliser CRLF → LF (optionnel) pour éviter les surprises d'EOL
# CORRECTION: utile quand la source mélange CRLF/LF
$raw = $raw -replace "`r`n", "`n"

$lines = $raw -split "`n"
$lines = $lines | Where-Object { $_.Trim().Length -gt 0 } | ForEach-Object { $_.TrimEnd() }

if ($lines.Count -eq 0) {
  throw "Aucune donnée exploitable après nettoyage."
}

# Ré-écrire provisoirement dans un fichier temp (que l'on importera proprement)
$tmp = [System.IO.Path]::GetTempFileName()
try {
  # IMPORTANT: on réintroduit des LF uniformes
  [System.IO.File]::WriteAllText($tmp, ($lines -join "`n"), (New-Object System.Text.UTF8Encoding($false)))

  $data = Import-Csv -LiteralPath $tmp

  # CORRECTION: valider le schéma minimal (3 colonnes: id, nom, ville)
  $expected = @("id","nom","ville")
  $missing = @()
  foreach ($k in $expected) {
    if (-not ($data | Get-Member -MemberType NoteProperty | Where-Object { $_.Name -eq $k })) {
      $missing += $k
    }
  }
  if ($missing.Count -gt 0) {
    throw "Colonnes absentes: $($missing -join ', '). En-tête attendu: $($expected -join ', ')"
  }

  # Sortie propre — UTF-8, guillemets si nécessaire seulement
  $data | Export-Csv -LiteralPath $Out -NoTypeInformation -Encoding utf8 -UseQuotes AsNeeded
  Write-Host "[OK] Nettoyage terminé -> $Out"
}
finally {
  if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue }
}
