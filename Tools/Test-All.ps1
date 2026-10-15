<#
.SYNOPSIS
Checks Common\Merged\Patches\MergedResearch.xml offline: applies it to a test document of every research project the
mod defines plus a synthetic item, recipe and list for each merged member, then checks every reference points at a
project that exists. Run by Deploy-Mod.ps1; exits non-zero on failure.
#>
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot
$merged = Join-Path $root 'Common\Merged'
$patch = [xml][IO.File]::ReadAllText((Join-Path $merged 'Patches\MergedResearch.xml'))
$mergedDefs = [xml][IO.File]::ReadAllText((Join-Path $merged 'Defs\ResearchProjectDefs\MergedResearch.xml'))

# Members and targets, read back from the patch: phase D removes Defs/ResearchProjectDef[defName="m" or ...] inside the target's conditional
$groups = @{}
foreach ($op in $patch.Patch.Operation) {
  $x = $op.xpath
  if ($op.Class -ne 'PatchOperationConditional' -or -not $op.match -or $x -notmatch '^Defs/ResearchProjectDef\[defName="([^"]+)"\]$') { continue }
  $t = $Matches[1]
  $rm = $op.match.operations.li | Where-Object { $_.Class -eq 'PatchOperationRemove' -and $_.xpath -like 'Defs/ResearchProjectDef`[defName=*' } | Select-Object -Last 1
  $groups[$t] = @([regex]::Matches($rm.xpath, 'defName="([^"]+)"') | ForEach-Object { $_.Groups[1].Value })
}

# Every research project the mod defines (first definition wins)
$defs = [ordered]@{}
foreach ($f in Get-ChildItem (Join-Path $root 'Common') -Recurse -Filter *.xml | Where-Object { $_.FullName -notlike "$merged*" }) {
  $d = [xml][IO.File]::ReadAllText($f.FullName)
  foreach ($n in $d.SelectNodes('//ResearchProjectDef[defName]')) { if (-not $defs.Contains($n.defName)) { $defs[$n.defName] = $n.OuterXml } }
}

function New-TestDoc([string[]]$drop) {
  $sb = New-Object Text.StringBuilder; [void]$sb.Append('<Defs>')
  foreach ($k in $defs.Keys) { if ($drop -notcontains $k) { [void]$sb.Append($defs[$k]) } }
  foreach ($n in $mergedDefs.Defs.ResearchProjectDef) { [void]$sb.Append($n.OuterXml) }
  $doc = New-Object Xml.XmlDocument; $doc.LoadXml($sb.Append('</Defs>').ToString())
  # Projects other mods own: stub every name referenced but not defined
  $names = @{}; foreach ($n in $doc.SelectNodes('Defs/ResearchProjectDef/defName')) { $names[$n.InnerText] = 1 }
  $refs = $doc.SelectNodes('Defs/ResearchProjectDef/prerequisites/li | Defs/ResearchProjectDef/hiddenPrerequisites/li') | ForEach-Object { $_.InnerText } | Sort-Object -Unique
  foreach ($t in @($groups.Keys) + @($refs)) { if (-not $names[$t] -and $drop -notcontains $t -and -not ($groups.Values | Where-Object { $_ -contains $t })) { $e = $doc.CreateElement('ResearchProjectDef'); $e.InnerXml = "<defName>$t</defName>"; [void]$doc.DocumentElement.AppendChild($e); $names[$t] = 1 } }
  # Synthetic items: one recipeMaker item and one RecipeDef per member, one list per group
  $i = 0
  foreach ($t in $groups.Keys) {
    $m = $groups[$t]
    foreach ($d in $m) {
      if ($drop -contains $d) { continue }
      $i++
      $e = $doc.CreateElement('ThingDef'); $e.InnerXml = "<defName>TestItem$i</defName><recipeMaker><researchPrerequisite>$d</researchPrerequisite></recipeMaker>"; [void]$doc.DocumentElement.AppendChild($e)
      $e = $doc.CreateElement('RecipeDef'); $e.InnerXml = "<defName>TestRecipe$i</defName><researchPrerequisite>$d</researchPrerequisite>"; [void]$doc.DocumentElement.AppendChild($e)
    }
    $live = @($m | Where-Object { $drop -notcontains $_ })
    if ($live.Count -ge 2) { $i++; $e = $doc.CreateElement('ThingDef'); $e.InnerXml = "<defName>TestList$i</defName><researchPrerequisites><li>$($live[0])</li><li>$($live[1])</li></researchPrerequisites>"; [void]$doc.DocumentElement.AppendChild($e) }
  }
  $doc
}

function Invoke-Op($doc, $op) {
  $cls = $op.GetAttribute('Class'); $x = $op.SelectSingleNode('xpath')
  # Assign XmlNodes directly: PowerShell unrolls an XmlNode returned from an if expression into its children
  $nodes = @(); if ($x) { $nodes = @($doc.SelectNodes($x.InnerText)) }
  $s = $op.SelectSingleNode('success'); $always = ($null -ne $s) -and $s.InnerText -eq 'Always'
  switch ($cls) {
    'PatchOperationConditional' { if ($nodes.Count) { $b = $op.SelectSingleNode('match') } else { $b = $op.SelectSingleNode('nomatch') }; if ($null -ne $b) { return (Invoke-Op $doc $b) }; return $true }
    'PatchOperationSequence' { foreach ($li in $op.SelectNodes('operations/li')) { if (-not (Invoke-Op $doc $li)) { return $false } }; return $true }
    'PatchOperationAdd' { foreach ($n in $nodes) { foreach ($c in $op.SelectSingleNode('value').ChildNodes) { [void]$n.AppendChild($doc.ImportNode($c, $true)) } } }
    'PatchOperationRemove' { foreach ($n in $nodes) { [void]$n.ParentNode.RemoveChild($n) } }
    'PatchOperationReplace' { foreach ($n in $nodes) { foreach ($c in $op.SelectSingleNode('value').ChildNodes) { [void]$n.ParentNode.InsertBefore($doc.ImportNode($c, $true), $n) }; [void]$n.ParentNode.RemoveChild($n) } }
    default { throw "unsupported operation $cls" }
  }
  if (-not $nodes.Count -and -not $always) { throw "operation matched nothing: $($x.InnerText)" }
  $true
}

function Test-Doc($doc, [string]$name, [string[]]$drop) {
  foreach ($op in $patch.Patch.Operation) { [void](Invoke-Op $doc $op) }
  $fail = @()
  $exists = @{}; foreach ($n in $doc.SelectNodes('Defs/ResearchProjectDef/defName')) { $exists[$n.InnerText] = 1 }
  foreach ($t in $groups.Keys) {
    $live = @($groups[$t] | Where-Object { $drop -notcontains $_ })
    $isFold = -not ($mergedDefs.Defs.ResearchProjectDef | Where-Object { $_.defName -eq $t })
    if ($exists[$t]) { foreach ($d in $live) { if ($exists[$d]) { $fail += "$name : member $d still exists beside $t" } } }
    elseif (-not $isFold -and $live.Count) { $fail += "$name : $t removed although members exist" }
    elseif ($isFold -and $live.Count) { foreach ($d in $live) { if (-not $exists[$d]) { $fail += "$name : $d removed although its fold target $t is missing" } } }
  }
  $refs = $doc.SelectNodes('Defs/ResearchProjectDef/prerequisites/li | Defs/ResearchProjectDef/hiddenPrerequisites/li | Defs/*/recipeMaker/researchPrerequisite | Defs/*/recipeMaker/researchPrerequisites/li | Defs/RecipeDef/researchPrerequisite | Defs/*/researchPrerequisites/li')
  foreach ($r in $refs) { if (-not $exists[$r.InnerText] -and $drop -notcontains $r.InnerText) { $owner = $r.SelectSingleNode('ancestor::*[defName][1]/defName').InnerText; if ($owner -notlike 'Ferny_*' -and $owner -notlike 'Test*') { continue }; $fail += "$name : $owner names missing project $($r.InnerText)" } }
  foreach ($l in $doc.SelectNodes('//researchPrerequisites | //prerequisites')) { $v = @($l.SelectNodes('li') | ForEach-Object { $_.InnerText }); if (($v | Sort-Object -Unique).Count -ne $v.Count) { $fail += "$name : duplicate in $($l.ParentNode.SelectSingleNode('defName').InnerText): $($v -join ',')" } }
  foreach ($t in $groups.Keys) { if ($exists[$t]) { foreach ($p in $doc.SelectNodes("Defs/ResearchProjectDef[defName=`"$t`"]/prerequisites/li")) { if ($p.InnerText -eq $t) { $fail += "$name : $t requires itself" } } } }
  "$name : $($exists.Count) projects after patching, $(@($groups.Keys | Where-Object { $exists[$_] }).Count) of $($groups.Count) groups present, $($fail.Count) problems"
  $fail | Select-Object -First 15
  $fail.Count
}

$total = 0
# 1: every mod present
$r = Test-Doc (New-TestDoc @()) 'all mods' @(); $r | Select-Object -SkipLast 1; $total += $r[-1]
# 2: three groups lose all their members, two lose one member
$keys = @($groups.Keys | Sort-Object)
$drop = @($groups[$keys[3]]) + @($groups[$keys[10]]) + @($groups[$keys[20]]) + @($groups[$keys[30]][0]) + @($groups[$keys[40]][0])
$r = Test-Doc (New-TestDoc $drop) 'members missing' $drop; $r | Select-Object -SkipLast 1; $total += $r[-1]
# 3: a fold target is missing (another mod's project absent)
$foldTarget = $keys | Where-Object { $_ -notlike 'Ferny_Bionics_*' } | Select-Object -First 1
$r = Test-Doc (New-TestDoc @($foldTarget)) "fold target $foldTarget missing" @($foldTarget); $r | Select-Object -SkipLast 1; $total += $r[-1]
if ($total) { Write-Error "MergedResearch check failed: $total problems"; exit 1 }
'MergedResearch check passed'
