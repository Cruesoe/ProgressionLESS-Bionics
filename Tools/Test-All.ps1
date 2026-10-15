<#
.SYNOPSIS
Offline checks for the merged research. Run by Deploy-Mod.ps1; exits non-zero on failure.

.DESCRIPTION
- every XML file under Common parses;
- every Ferny_ project named anywhere (values, lists, xpaths) is defined somewhere in the repo;
- no prerequisite or research list names a project twice;
- every Ferny_ project has a position; on the Bionics tab no two overlap (dx < 0.95 and dy < 0.6) and each sits right
  of its prerequisites there;
- each merged project's availability check ("Missing Items") removes it when none of its items exists and keeps it
  when one does, simulated on a test document.
#>
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot
$fail = New-Object Collections.Generic.List[string]
$docs = @{}
foreach ($f in Get-ChildItem (Join-Path $root 'Common') -Recurse -Filter *.xml) {
  try { $docs[$f.FullName] = [xml][IO.File]::ReadAllText($f.FullName) } catch { $fail.Add("does not parse: $($f.FullName)") }
}

# Definitions and references
$defined = @{}; $defs = @{}
foreach ($d in $docs.Values) {
  # any def counts as defined (the research tab, ReplaceLib replacers); research projects are also kept for the layout check
  foreach ($n in $d.SelectNodes('//defName')) { $defined[$n.InnerText.Trim()] = 1 }
  foreach ($n in $d.SelectNodes('//ResearchProjectDef[defName]')) { $name = $n.defName.Trim(); if (-not $defs[$name]) { $defs[$name] = $n } }
}
$refs = @{}
foreach ($path in $docs.Keys) {
  $text = [IO.File]::ReadAllText($path)
  foreach ($m in [regex]::Matches($text, '(?:>|")(Ferny_[A-Za-z0-9_]+)(?:<|")')) { $refs[$m.Groups[1].Value] = Split-Path $path -Leaf }
}
foreach ($r in $refs.Keys) { if (-not $defined[$r]) { $fail.Add("$r is named in $($refs[$r]) but never defined") } }

foreach ($d in $docs.Values) {
  foreach ($list in $d.SelectNodes('//prerequisites | //hiddenPrerequisites | //researchPrerequisites')) {
    $v = @($list.SelectNodes('li') | ForEach-Object { $_.InnerText.Trim() })
    if (($v | Sort-Object -Unique).Count -ne $v.Count) { $fail.Add("duplicate list entry: $($v -join ', ')") }
  }
}

# Layout
$pos = @{}
foreach ($name in $defs.Keys | Where-Object { $_ -like 'Ferny_*' }) {
  $n = $defs[$name]; $x = $n.SelectSingleNode('researchViewX'); $y = $n.SelectSingleNode('researchViewY'); $t = $n.SelectSingleNode('tab')
  if (-not $x -or -not $y) { $fail.Add("$name has no position"); continue }
  $pos[$name] = @([double]$x.InnerText, [double]$y.InnerText, $(if ($t) { $t.InnerText.Trim() } else { 'Main' }), @($n.SelectNodes('prerequisites/li') | ForEach-Object { $_.InnerText.Trim() }))
}
$keys = @($pos.Keys)
for ($i = 0; $i -lt $keys.Count; $i++) {
  $a = $pos[$keys[$i]]
  foreach ($p in $a[3]) { if ($pos[$p] -and $pos[$p][2] -eq $a[2] -and $pos[$p][0] -ge $a[0]) { $fail.Add("$($keys[$i]) is not right of its prerequisite $p") } }
  for ($j = $i + 1; $j -lt $keys.Count; $j++) {
    $b = $pos[$keys[$j]]
    if ($a[2] -eq $b[2] -and [math]::Abs($a[0] - $b[0]) -lt 0.95 -and [math]::Abs($a[1] - $b[1]) -lt 0.6) { $fail.Add("$($keys[$i]) overlaps $($keys[$j])") }
  }
}

# Availability of merged projects, simulated
$mi = $docs.Keys | Where-Object { $_ -match '\\Missing Items\\' } | Select-Object -First 1
$checked = 0
foreach ($op in $docs[$mi].Patch.Operation) {
  $rm = $op.SelectSingleNode('nomatch/match[@Class="PatchOperationRemove"]/xpath')
  if (-not $rm -or $rm.InnerText -notmatch 'defName="(Ferny_Bionics_[^"]+)"') { continue }
  $t = $Matches[1]; $x = $op.xpath
  $items = @([regex]::Matches($x, '(?:^|\| )Defs\[\*\[[^\]]*\]\[defName="([^"]+)"\]') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique)
  if (-not $items.Count) { $fail.Add("$t availability check names no items"); continue }
  foreach ($case in 'none', 'one') {
    $doc = New-Object Xml.XmlDocument
    $item = if ($case -eq 'one') { "<ThingDef><defName>$($items[-1])</defName><recipeMaker /></ThingDef>" } else { '' }
    $doc.LoadXml("<Defs><ResearchProjectDef><defName>$t</defName></ResearchProjectDef>$item</Defs>")
    $present = $doc.SelectNodes($x).Count -gt 0
    if ($case -eq 'none' -and $present) { $fail.Add("$t would stay with none of its items") }
    if ($case -eq 'one' -and -not $present) { $fail.Add("$t would be removed although $($items[-1]) exists") }
  }
  $checked++
}

"checked: $($docs.Count) files, $($refs.Count) Ferny_ references, $($pos.Count) positions, $checked availability checks"
if ($fail.Count) { $fail | Select-Object -First 30; Write-Error "Bionics checks failed: $($fail.Count) problems"; exit 1 }
'Bionics checks passed'
