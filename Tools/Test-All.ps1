<#
.SYNOPSIS
Offline checks for the merged research. Run by Deploy-Mod.ps1; exits non-zero on failure.

.DESCRIPTION
- every XML file under Common parses and holds something;
- no LoadFolders.xml condition is empty, and every listed folder holds files;
- every Ferny_ project named anywhere (values, lists, xpaths) is defined somewhere in the repo;
- no prerequisite or research list names a project twice;
- every Ferny_ project has a position; on the Bionics tab no two overlap (dx < 0.95 and dy < 0.6) and each sits right
  of its prerequisites there;
- each merged project's availability check ("Missing Items") removes it when none of its items exists and keeps it
  when one does, and leaves no markers, simulated on a test document.
#>
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot
$fail = New-Object Collections.Generic.List[string]
$docs = @{}
foreach ($f in Get-ChildItem (Join-Path $root 'Common') -Recurse -Filter *.xml) {
  try { $docs[$f.FullName] = [xml][IO.File]::ReadAllText($f.FullName) } catch { $fail.Add("does not parse: $($f.FullName)"); continue }
  if (-not $docs[$f.FullName].DocumentElement.SelectSingleNode('*')) { $fail.Add("empty file: $($f.FullName.Substring($root.Length + 1))") }
}

# Load folders: an empty condition never matches (it requires a mod with an empty package ID), and every listed folder has files
$lf = [xml][IO.File]::ReadAllText((Join-Path $root 'LoadFolders.xml'))
foreach ($li in $lf.SelectNodes('/loadFolders/*/li')) {
  $p = $li.InnerText.Trim()
  foreach ($a in $li.Attributes) { if (-not $a.Value.Trim()) { $fail.Add("LoadFolders: empty $($a.Name) on $p") } }
  if ($p -ne '/' -and -not (Get-ChildItem -LiteralPath (Join-Path $root ($p -replace '/', '\')) -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1)) { $fail.Add("LoadFolders: $p has no files") }
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

# Availability of merged projects, simulated: each member's item checks ("Missing Items") add a ProgressionLESS_Missing
# marker to the project, which goes when every member is marked; the markers are then removed
function Invoke-Op($doc, $op) {
  $x = $op.SelectSingleNode('xpath'); $xp = if ($x) { $x.InnerText.Trim() } else { '' }
  $ok = switch ($op.GetAttribute('Class')) {
    'PatchOperationSequence' { $r = $true; foreach ($li in $op.SelectNodes('operations/li')) { if (-not (Invoke-Op $doc $li)) { $r = $false; break } }; $r }
    'PatchOperationConditional' {
      $m = $op.SelectSingleNode('match'); $n = $op.SelectSingleNode('nomatch')
      if ($doc.SelectSingleNode($xp)) { if ($m) { Invoke-Op $doc $m } else { [bool]$n } } elseif ($n) { Invoke-Op $doc $n } else { [bool]$m }
    }
    'PatchOperationAdd' { $t = @($doc.SelectNodes($xp)); foreach ($e in $t) { foreach ($c in $op.SelectSingleNode('value').ChildNodes) { [void]$e.AppendChild($doc.ImportNode($c, $true)) } }; $t.Count -gt 0 }
    'PatchOperationReplace' { $t = @($doc.SelectNodes($xp)); foreach ($e in $t) { foreach ($c in $op.SelectSingleNode('value').ChildNodes) { [void]$e.ParentNode.InsertBefore($doc.ImportNode($c, $true), $e) }; [void]$e.ParentNode.RemoveChild($e) }; $t.Count -gt 0 }
    'PatchOperationRemove' { $t = @($doc.SelectNodes($xp)); foreach ($e in $t) { [void]$e.ParentNode.RemoveChild($e) }; $t.Count -gt 0 }
    default { $true }
  }
  $s = $op.SelectSingleNode('success')
  if ($s -and $s.InnerText.Trim() -eq 'Always') { return $true }
  [bool]$ok
}
$mi = $docs.Keys | Where-Object { $_ -match '\\Missing Items\\' } | Select-Object -First 1
$tops = @($docs[$mi].Patch.SelectNodes('Operation'))
$blocks = @{}; $items = @{}
foreach ($op in $tops) {
  foreach ($a in $op.SelectNodes('.//*[value/ProgressionLESS_Missing]')) {
    if ($a.xpath -notmatch 'defName="([^"]+)"') { continue }
    $t = $Matches[1]; $slot = $a.value.ProgressionLESS_Missing
    if (-not $blocks[$t]) { $blocks[$t] = New-Object Collections.Generic.List[object] }
    if (-not $blocks[$t].Contains($op)) { $blocks[$t].Add($op) }
    if ($op.xpath -match '^Defs/ThingDef\[defName="([^"]+)"\]$') { $items["$t|$slot"] = $Matches[1] }
  }
}
$checked = 0
foreach ($op in $tops) {
  if ($op.GetAttribute('Class') -ne 'PatchOperationConditional' -or $op.xpath -notmatch '^Defs/ResearchProjectDef\[defName="(Ferny_Bionics_[^"]+)"\]\[(.+)\]$') { continue }
  $t = $Matches[1]; $slots = @([regex]::Matches($Matches[2], 'ProgressionLESS_Missing="(\d+)"') | ForEach-Object { $_.Groups[1].Value })
  $tail = @($tops | Where-Object { $_.xpath -like "Defs/ResearchProjectDef``[defName=`"$t`"``]*" })
  $last = $items["$t|$($slots[-1])"]
  if (-not $blocks[$t] -or -not $last) { $fail.Add("$t availability check has no item checks"); continue }
  foreach ($s in $slots) { if (-not ($blocks[$t] | Where-Object { $_.SelectSingleNode(".//value[ProgressionLESS_Missing=`"$s`"]") })) { $fail.Add("$t member $s is never marked missing") } }
  foreach ($case in 'none', 'one') {
    $doc = New-Object Xml.XmlDocument
    $item = if ($case -eq 'one') { "<ThingDef><defName>$last</defName><recipeMaker /></ThingDef>" } else { '' }
    $doc.LoadXml("<Defs><ResearchProjectDef><defName>$t</defName></ResearchProjectDef>$item</Defs>")
    foreach ($o in $blocks[$t].ToArray()) { [void](Invoke-Op $doc $o) }
    foreach ($o in $tail) { [void](Invoke-Op $doc $o) }
    $present = [bool]$doc.SelectSingleNode("Defs/ResearchProjectDef[defName=`"$t`"]")
    if ($case -eq 'none' -and $present) { $fail.Add("$t would stay with none of its items") }
    if ($case -eq 'one' -and -not $present) { $fail.Add("$t would be removed although $last exists") }
    if ($doc.SelectSingleNode('//ProgressionLESS_Missing')) { $fail.Add("$t keeps its availability markers") }
  }
  $checked++
}

"checked: $($docs.Count) files, $($refs.Count) Ferny_ references, $($pos.Count) positions, $checked availability checks"
if ($fail.Count) { $fail | Select-Object -First 30; Write-Error "Bionics checks failed: $($fail.Count) problems"; exit 1 }
'Bionics checks passed'
