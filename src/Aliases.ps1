#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   alias.ps1                                                                    ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Guillaume Plante <codegp@icloud.com>                                         ║
#║   Code licensed under the GNU GPL v3.0. See the LICENSE file for details.      ║
#╚════════════════════════════════════════════════════════════════════════════════╝

New-Alias -Name fanspeed -Value Set-ZBookFanSpeed -Force -ErrorAction Ignore | Out-Null
new-alias -Name fanspeed_get -Value Get-ZBookFanSpeed -Force -ErrorAction Ignore | Out-Null
