<#
.SYNOPSIS
Lays out the Bionics research tab and writes Common\Merged\Patches\Layout.xml.

.DESCRIPTION
Places every merged project and every remaining Ferny_ project that would otherwise sit on the Main tab. Columns go
in era order, a project sits in a column right of its prerequisites on the tab, and each column holds at most
-Rows projects -RowStep apart starting at Y 0 (rows up to Y 8.2 show complete cards at the measured 2560 x 1600,
UI scale 1.5 profile). Projects on the Anomaly tab are placed from -Anomaly (defName = 'x,y').
#>
# Anomaly tab: vanilla's projects end at X 6.5 (Get-TabSpace.ps1 -Tab Anomaly, 261015)
param([int]$Rows = 12, [double]$RowStep = 0.7, [hashtable]$Anomaly = @{
    'Ferny_Bionics_GhoulEnhancements' = '7.5,2.8'; 'Ferny_Bionics_AdvancedGhoulEnhancements' = '8.5,2.8'; 'Ferny_Bionics_AnomalyModules' = '7.5,4.5'
    'Ferny_Bionics_AnimalMutationImplants' = '7.5,5.3'; 'Ferny_Bionics_LTS_ModuleArm_Incinerator' = '7.5,6.1' })
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot
$merged = Join-Path $root 'Common\Merged'
$tab = 'Ferny_Bionics'
$patch = [xml][IO.File]::ReadAllText((Join-Path $merged 'Patches\MergedResearch.xml'))
$mergedDefs = [xml][IO.File]::ReadAllText((Join-Path $merged 'Defs\ResearchProjectDefs\MergedResearch.xml'))

# Members to their merged project, read back from the patch
$target = @{}
foreach ($op in $patch.Patch.Operation) {
  if ($op.Class -ne 'PatchOperationConditional' -or -not $op.match -or $op.xpath -notmatch '^Defs/ResearchProjectDef\[defName="([^"]+)"\]$') { continue }
  $t = $Matches[1]
  $rm = $op.match.operations.li | Where-Object { $_.Class -eq 'PatchOperationRemove' -and $_.xpath -like 'Defs/ResearchProjectDef`[defName=*' } | Select-Object -Last 1
  foreach ($m in [regex]::Matches($rm.xpath, 'defName="([^"]+)"')) { $target[$m.Groups[1].Value] = $t }
}

# Projects to place: merged projects, then the Ferny_ projects no group absorbed
$eraOrder = @{ Animal = 0; Neolithic = 1; Medieval = 2; Industrial = 3; Spacer = 4; Ultra = 5; Archotech = 6 }
$place = [ordered]@{}
foreach ($n in $mergedDefs.Defs.ResearchProjectDef) {
  $place[$n.defName] = [pscustomobject]@{ Def = $n.defName; Era = [string]$n.techLevel; Tab = [string]$n.tab; Pre = @($n.SelectNodes('prerequisites/li') | ForEach-Object { $_.InnerText }) }
}
$seen = @{}
foreach ($f in Get-ChildItem (Join-Path $root 'Common') -Recurse -Filter *.xml | Where-Object { $_.FullName -notlike "$merged*" } | Sort-Object { if ($_.FullName -match '\\Defs\\') { 0 } else { 1 } }, FullName) {
  $d = [xml][IO.File]::ReadAllText($f.FullName)
  foreach ($n in $d.SelectNodes('//ResearchProjectDef[defName]')) {
    $name = $n.defName.Trim()
    if ($seen[$name]) { continue }; $seen[$name] = 1
    if ($name -notlike 'Ferny_*' -or $target.ContainsKey($name) -or $place.Contains($name)) { continue }
    $pre = @($n.SelectNodes('prerequisites/li') | ForEach-Object { $p = $_.InnerText.Trim(); if ($target.ContainsKey($p)) { $target[$p] } else { $p } } | Select-Object -Unique)
    $place[$name] = [pscustomobject]@{ Def = $name; Era = [string]$n.techLevel; Tab = [string]$n.tab; Pre = $pre }
  }
}
$i = 0; foreach ($p in $place.Values) { $p | Add-Member Order ($i++) }
$onTab = @($place.Values | Where-Object { -not $_.Tab -or $_.Tab -eq 'Main' })
$onTabSet = @{}; foreach ($p in $onTab) { $onTabSet[$p.Def] = $p }

# Depth among same-tab prerequisites, so prerequisites are placed first
$depth = @{}
function Get-Depth([string]$d) {
  if ($depth.ContainsKey($d)) { return $depth[$d] }
  $depth[$d] = 0
  $v = 0; foreach ($p in $onTabSet[$d].Pre) { if ($onTabSet.ContainsKey($p)) { $v = [math]::Max($v, (Get-Depth $p) + 1) } }
  $depth[$d] = $v; $v
}
foreach ($p in $onTab) { [void](Get-Depth $p.Def) }

# Layout era: never earlier than a same-tab prerequisite's, so prerequisites stay to the left
$lera = @{}
function Get-LayoutEra([string]$d) {
  if ($lera.ContainsKey($d)) { return $lera[$d] }
  $v = [int]$eraOrder[$onTabSet[$d].Era]; $lera[$d] = $v
  foreach ($p in $onTabSet[$d].Pre) { if ($onTabSet.ContainsKey($p)) { $v = [math]::Max($v, (Get-LayoutEra $p)) } }
  $lera[$d] = $v; $v
}
foreach ($p in $onTab) { [void](Get-LayoutEra $p.Def) }

$col = @{}; $count = @{}; $pos = [ordered]@{}; $eraStart = 0; $lastEra = $null; $maxCol = -1
foreach ($p in $onTab | Sort-Object { $lera[$_.Def] }, { $depth[$_.Def] }, { $_.Order }) {
  if ($lera[$p.Def] -ne $lastEra) { $eraStart = $maxCol + 1; $lastEra = $lera[$p.Def] }
  $c = $eraStart
  foreach ($q in $p.Pre) { if ($col.ContainsKey($q)) { $c = [math]::Max($c, $col[$q] + 1) } }
  while ($count[$c] -ge $Rows) { $c++ }
  $y = [int]$count[$c] * $RowStep
  $count[$c] = [int]$count[$c] + 1
  $col[$p.Def] = $c; $maxCol = [math]::Max($maxCol, $c)
  $pos[$p.Def] = @($c, $y, $tab)
}
foreach ($k in $Anomaly.Keys) { $xy = $Anomaly[$k] -split ','; $pos[$k] = @([double]$xy[0], [double]$xy[1], $null) }

$sb = New-Object Text.StringBuilder
[void]$sb.AppendLine('<?xml version="1.0" encoding="utf-8"?>').AppendLine('<Patch>')
[void]$sb.AppendLine('  <!-- Generated by Tools\New-Layout.ps1; regenerate rather than edit -->')
foreach ($k in $pos.Keys) {
  $x, $y, $t = $pos[$k]
  $value = ''; if ($t) { $value += "<tab>$t</tab>" }
  $value += "<researchViewX>$('{0:0.00}' -f $x)</researchViewX><researchViewY>$('{0:0.00}' -f $y)</researchViewY>"
  [void]$sb.AppendLine("  <Operation Class=`"PatchOperationSequence`"><success>Always</success><operations>")
  $old = if ($t) { 'self::tab or self::researchViewX or self::researchViewY' } else { 'self::researchViewX or self::researchViewY' }
  [void]$sb.AppendLine("    <li Class=`"PatchOperationRemove`"><success>Always</success><xpath>Defs/ResearchProjectDef[defName=`"$k`"]/*[$old]</xpath></li>")
  [void]$sb.AppendLine("    <li Class=`"PatchOperationAdd`"><success>Always</success><xpath>Defs/ResearchProjectDef[defName=`"$k`"]</xpath><value>$value</value></li>")
  [void]$sb.AppendLine('  </operations></Operation>')
}
[void]$sb.AppendLine('</Patch>')
$out = Join-Path $merged 'Patches\Layout.xml'
[IO.File]::WriteAllText($out, $sb.ToString(), (New-Object Text.UTF8Encoding $false))
"placed $($onTab.Count) projects on $tab in $($maxCol + 1) columns; $($Anomaly.Count) on the Anomaly tab"
$pos.Keys | ForEach-Object { "{0,-60} {1,5} {2,5}" -f $_, $pos[$_][0], $pos[$_][1] }
