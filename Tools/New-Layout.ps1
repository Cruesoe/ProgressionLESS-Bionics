<#
.SYNOPSIS
Lays out the Bionics research tab by writing tab, researchViewX and researchViewY into the project definitions.

.DESCRIPTION
Places every Ferny_ project that would otherwise sit on the Main tab, wherever it is defined (Defs, or the value of a
patch that creates it). Columns go in era order (never left of a prerequisite's era), each project sits right of its
prerequisites on the tab, and each column holds at most -Rows projects -RowStep apart from Y 0: rows up to Y 8.2 show
complete cards at the measured 2560 x 1600, UI scale 1.5 profile. Projects on the Anomaly tab take -Anomaly positions.
Run after Merge-GeneratedResearch.ps1; rerunning replaces the positions.
#>
# Anomaly tab: vanilla's projects end at X 6.5 (Get-TabSpace.ps1 -Tab Anomaly, 261015)
param([int]$Rows = 12, [double]$RowStep = 0.7, [hashtable]$Anomaly = @{
    'Ferny_Bionics_GhoulEnhancements' = '7.5,2.8'; 'Ferny_Bionics_AdvancedGhoulEnhancements' = '8.5,2.8'; 'Ferny_Bionics_AnomalyModules' = '7.5,4.5'
    'Ferny_Bionics_AnimalMutationImplants' = '7.5,5.3'; 'Ferny_Bionics_LTS_ModuleArm_Incinerator' = '7.5,6.1' })
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot
$tab = 'Ferny_Bionics'
$eraOrder = @{ Animal = 0; Neolithic = 1; Medieval = 2; Industrial = 3; Spacer = 4; Ultra = 5; Archotech = 6 }

# Every definition of every Ferny_ project; merged projects first, in plan order
$docs = [ordered]@{}; $nodes = @{}; $place = [ordered]@{}
$files = Get-ChildItem (Join-Path $root 'Common') -Recurse -Filter *.xml | Sort-Object { if ($_.Name -eq 'MergedResearch.xml' -and $_.FullName -match '\\Defs\\') { 0 } elseif ($_.FullName -match '\\Defs\\') { 1 } else { 2 } }, FullName
foreach ($f in $files) {
  $d = New-Object Xml.XmlDocument; $d.PreserveWhitespace = $true; $d.LoadXml([IO.File]::ReadAllText($f.FullName))
  foreach ($n in $d.SelectNodes('//ResearchProjectDef[defName]')) {
    $name = $n.SelectSingleNode('defName').InnerText.Trim()
    if ($name -notlike 'Ferny_*') { continue }
    $docs[$f.FullName] = $d
    if (-not $nodes[$name]) { $nodes[$name] = @() }; $nodes[$name] += $n
    if (-not $place.Contains($name)) {
      $t = $n.SelectSingleNode('tab')
      $place[$name] = [pscustomobject]@{ Def = $name; Era = [string]$n.SelectSingleNode('techLevel').InnerText; Tab = $(if ($t) { $t.InnerText.Trim() } else { '' })
        Pre = @($n.SelectNodes('prerequisites/li') | ForEach-Object { $_.InnerText.Trim() }); Order = $place.Count }
    }
  }
}
$onTab = @($place.Values | Where-Object { -not $_.Tab -or $_.Tab -eq 'Main' -or $_.Tab -eq $tab })
$onTabSet = @{}; foreach ($p in $onTab) { $onTabSet[$p.Def] = $p }

$depth = @{}
function Get-Depth([string]$d) {
  if ($depth.ContainsKey($d)) { return $depth[$d] }
  $depth[$d] = 0; $v = 0
  foreach ($p in $onTabSet[$d].Pre) { if ($onTabSet.ContainsKey($p)) { $v = [math]::Max($v, (Get-Depth $p) + 1) } }
  $depth[$d] = $v; $v
}
# Layout era: never earlier than a same-tab prerequisite's, so prerequisites stay to the left
$lera = @{}
function Get-LayoutEra([string]$d) {
  if ($lera.ContainsKey($d)) { return $lera[$d] }
  $v = [int]$eraOrder[$onTabSet[$d].Era]; $lera[$d] = $v
  foreach ($p in $onTabSet[$d].Pre) { if ($onTabSet.ContainsKey($p)) { $v = [math]::Max($v, (Get-LayoutEra $p)) } }
  $lera[$d] = $v; $v
}
foreach ($p in $onTab) { [void](Get-Depth $p.Def); [void](Get-LayoutEra $p.Def) }

$col = @{}; $count = @{}; $pos = [ordered]@{}; $eraStart = 0; $lastEra = $null; $maxCol = -1
foreach ($p in $onTab | Sort-Object { $lera[$_.Def] }, { $depth[$_.Def] }, { $_.Order }) {
  if ($lera[$p.Def] -ne $lastEra) { $eraStart = $maxCol + 1; $lastEra = $lera[$p.Def] }
  $c = $eraStart
  foreach ($q in $p.Pre) { if ($col.ContainsKey($q)) { $c = [math]::Max($c, $col[$q] + 1) } }
  while ($count[$c] -ge $Rows) { $c++ }
  $y = [int]$count[$c] * $RowStep; $count[$c] = [int]$count[$c] + 1
  $col[$p.Def] = $c; $maxCol = [math]::Max($maxCol, $c)
  $pos[$p.Def] = @($c, $y, $tab)
}
foreach ($k in $Anomaly.Keys) { $xy = $Anomaly[$k] -split ','; $pos[$k] = @([double]$xy[0], [double]$xy[1], $null) }

# Self-check: prerequisites on the tab to the left, no two cards overlapping (dx < 0.95 and dy < 0.6)
$problems = @()
foreach ($p in $onTab) { foreach ($q in $p.Pre) { if ($pos[$q] -and $pos[$q][2] -eq $tab -and $pos[$q][0] -ge $pos[$p.Def][0]) { $problems += "$($p.Def) is not right of $q" } } }
$keys = @($pos.Keys)
for ($i = 0; $i -lt $keys.Count; $i++) { for ($j = $i + 1; $j -lt $keys.Count; $j++) {
  $a = $pos[$keys[$i]]; $b = $pos[$keys[$j]]
  if ($a[2] -eq $b[2] -and [math]::Abs($a[0] - $b[0]) -lt 0.95 -and [math]::Abs($a[1] - $b[1]) -lt 0.6) { $problems += "$($keys[$i]) overlaps $($keys[$j])" } } }
if ($problems) { $problems; throw 'layout problems' }

# Write the positions into every definition
function Set-Child($n, [string]$name, [string]$value) {
  $c = $n.SelectSingleNode($name)
  if ($c) { $c.InnerText = $value; return }
  $ws = ($n.ChildNodes | Where-Object { $_.NodeType -eq 'Whitespace' } | Select-Object -First 1)
  $indent = if ($ws) { $ws.Value } else { '' }
  $e = $n.OwnerDocument.CreateElement($name); $e.InnerText = $value
  $last = $n.LastChild
  if ($last -and $last.NodeType -eq 'Whitespace') { [void]$n.InsertBefore($n.OwnerDocument.CreateWhitespace($indent), $last); [void]$n.InsertBefore($e, $last) }
  else { [void]$n.AppendChild($e) }
}
foreach ($k in $pos.Keys) {
  foreach ($n in $nodes[$k]) {
    if ($pos[$k][2]) { Set-Child $n 'tab' $pos[$k][2] }
    Set-Child $n 'researchViewX' ('{0:0.00}' -f $pos[$k][0])
    Set-Child $n 'researchViewY' ('{0:0.00}' -f $pos[$k][1])
  }
}
$settings = New-Object Xml.XmlWriterSettings; $settings.Encoding = New-Object Text.UTF8Encoding $false; $settings.NewLineHandling = 'None'
foreach ($path in $docs.Keys) {
  $sw = New-Object IO.StringWriter; $w = [Xml.XmlWriter]::Create($sw, $settings); $docs[$path].Save($w); $w.Close()
  $text = $sw.ToString() -replace '^<\?xml[^>]*\?>', '<?xml version="1.0" encoding="utf-8"?>'
  if ($text -ne [IO.File]::ReadAllText($path)) { [IO.File]::WriteAllText($path, $text, $settings.Encoding) }
}
"placed $($onTab.Count) projects on $tab in $($maxCol + 1) columns and $($Anomaly.Count) on the Anomaly tab; no layout problems"
