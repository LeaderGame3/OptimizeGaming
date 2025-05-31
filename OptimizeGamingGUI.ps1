Add-Type -AssemblyName System.Windows.Forms

$form = New-Object System.Windows.Forms.Form
$form.Text = "Optimisation Gaming Windows 10/11"
$form.Size = New-Object System.Drawing.Size(550, 600)
$form.StartPosition = "CenterScreen"
$form.Topmost = $true

$options = @(
    "Activer Mode Jeu",
    "Désactiver Xbox Game Bar",
    "Effets visuels (performance)",
    "Ultimate Performance Power Plan",
    "Désactiver apps en arrière-plan",
    "Désactiver télémétrie",
    "Désactiver accélération souris",
    "Nettoyer programmes de démarrage",
    "Activer TRIM SSD",
    "Nettoyer fichiers temporaires",
    "Désactiver Cortana"
)

$checkboxes = @()
for ($i = 0; $i -lt $options.Length; $i++) {
    $cb = New-Object System.Windows.Forms.CheckBox
    $cb.Text = $options[$i]
    $cb.AutoSize = $true
    $cb.Location = New-Object System.Drawing.Point(20, 20 + ($i * 30))
    $form.Controls.Add($cb)
    $checkboxes += $cb
}

# Boutons
$btnSelectAll = New-Object System.Windows.Forms.Button
$btnSelectAll.Text = "Tout sélectionner"
$btnSelectAll.Location = New-Object System.Drawing.Point(20, 370)
$btnSelectAll.Size = New-Object System.Drawing.Size(150, 30)
$btnSelectAll.Add_Click({ foreach ($cb in $checkboxes) { $cb.Checked = $true } })
$form.Controls.Add($btnSelectAll)

$btnDeselectAll = New-Object System.Windows.Forms.Button
$btnDeselectAll.Text = "Tout désélectionner"
$btnDeselectAll.Location = New-Object System.Drawing.Point(190, 370)
$btnDeselectAll.Size = New-Object System.Drawing.Size(150, 30)
$btnDeselectAll.Add_Click({ foreach ($cb in $checkboxes) { $cb.Checked = $false } })
$form.Controls.Add($btnDeselectAll)

$btnRestore = New-Object System.Windows.Forms.Button
$btnRestore.Text = "Restaurer les paramètres"
$btnRestore.Location = New-Object System.Drawing.Point(360, 370)
$btnRestore.Size = New-Object System.Drawing.Size(150, 30)
$form.Controls.Add($btnRestore)

$btnApply = New-Object System.Windows.Forms.Button
$btnApply.Text = "Lancer l'optimisation"
$btnApply.Location = New-Object System.Drawing.Point(190, 420)
$btnApply.Size = New-Object System.Drawing.Size(150, 35)
$btnApply.BackColor = "LightGreen"
$form.Controls.Add($btnApply)

# Résultat
$resultLabel = New-Object System.Windows.Forms.Label
$resultLabel.Text = ""
$resultLabel.Location = New-Object System.Drawing.Point(20, 470)
$resultLabel.Size = New-Object System.Drawing.Size(480, 80)
$resultLabel.ForeColor = "DarkGreen"
$form.Controls.Add($resultLabel)

function Require-Admin {
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole("Administrator")) {
        [System.Windows.Forms.MessageBox]::Show("Ce script doit être lancé en tant qu'administrateur.","Erreur",0,[System.Windows.Forms.MessageBoxIcon]::Error)
        return $false
    }
    return $true
}

$btnApply.Add_Click({
    if (-not (Require-Admin)) { return }

    if ($checkboxes[0].Checked) {
        reg add "HKCU\Software\Microsoft\GameBar" /v AllowAutoGameMode /t REG_DWORD /d 1 /f | Out-Null
        reg add "HKCU\Software\Microsoft\GameBar" /v AutoGameModeEnabled /t REG_DWORD /d 1 /f | Out-Null
    }
    if ($checkboxes[1].Checked) {
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v AppCaptureEnabled /t REG_DWORD /d 0 /f | Out-Null
        reg add "HKCU\System\GameConfigStore" /v GameDVR_Enabled /t REG_DWORD /d 0 /f | Out-Null
    }
    if ($checkboxes[2].Checked) {
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 2 /f | Out-Null
    }
    if ($checkboxes[3].Checked) {
        powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 | Out-Null
        powercfg -setactive e9a42b02-d5df-448d-aa00-03f14749eb61 | Out-Null
    }
    if ($checkboxes[4].Checked) {
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v GlobalUserDisabled /t REG_DWORD /d 1 /f | Out-Null
    }
    if ($checkboxes[5].Checked) {
        reg add "HKLM\Software\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f | Out-Null
    }
    if ($checkboxes[6].Checked) {
        reg add "HKCU\Control Panel\Mouse" /v MouseSpeed /t REG_SZ /d 0 /f | Out-Null
        reg add "HKCU\Control Panel\Mouse" /v MouseThreshold1 /t REG_SZ /d 0 /f | Out-Null
        reg add "HKCU\Control Panel\Mouse" /v MouseThreshold2 /t REG_SZ /d 0 /f | Out-Null
    }
    if ($checkboxes[7].Checked) {
        $startupPaths = @(
            "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup",
            "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup"
        )
        foreach ($path in $startupPaths) {
            if (Test-Path $path) {
                Get-ChildItem $path | Remove-Item -Force -ErrorAction SilentlyContinue
            }
        }
    }
    if ($checkboxes[8].Checked) {
        fsutil behavior set DisableDeleteNotify 0 | Out-Null
    }
    if ($checkboxes[9].Checked) {
        Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item "$env:WINDIR\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    }
    if ($checkboxes[10].Checked) {
        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v AllowCortana /t REG_DWORD /d 0 /f | Out-Null
    }

    $resultLabel.Text = "✅ Optimisation appliquée. Redémarre ton PC pour finaliser les changements."
})

$btnRestore.Add_Click({
    if (-not (Require-Admin)) { return }

    reg delete "HKCU\Software\Microsoft\GameBar" /f | Out-Null
    reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /f | Out-Null
    reg delete "HKCU\System\GameConfigStore" /f | Out-Null
    reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /f | Out-Null
    reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /f | Out-Null
    reg delete "HKLM\Software\Policies\Microsoft\Windows\DataCollection" /f | Out-Null
    reg delete "HKCU\Control Panel\Mouse" /v MouseSpeed /f | Out-Null
    reg delete "HKCU\Control Panel\Mouse" /v MouseThreshold1 /f | Out-Null
    reg delete "HKCU\Control Panel\Mouse" /v MouseThreshold2 /f | Out-Null
    reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v AllowCortana /f | Out-Null

    powercfg -setactive SCHEME_BALANCED | Out-Null

    $resultLabel.Text = "🔄 Paramètres par défaut restaurés. Redémarre ton PC pour finaliser."
})

[void]$form.ShowDialog()
