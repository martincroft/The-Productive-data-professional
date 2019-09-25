#
# Purpose: take the diagnostic queries from Glenn Berry
#          and generate a Jupyter Notebook to run in Azure Data Studio
#
# Example usage:
# .\create-diagnostic-notebook.ps1 -diagnosticScriptPath "C:\Program Files\WindowsPowerShell\Modules\dbatools\0.9.777\bin\diagnosticquery\SQLServerDiagnosticQueries_2019_201901.sql" -notebookOutputPath "diagnostic-notebook.ipynb"
#
[CmdletBinding()]
Param(
    [parameter(Mandatory)]
    [System.IO.FileInfo]$diagnosticScriptPath,
    [System.IO.FileInfo]$notebookOutputPath
)

# 
# Function taken from dbatools https://github.com/sqlcollaborative/dbatools/blob/development/internal/functions/Invoke-DbaDiagnosticQueryScriptParser.ps1
# Parses the diagnostic script and breaks it into individual queries,
# with text and description
#
function Invoke-DbaDiagnosticQueryScriptParser {
    [CmdletBinding(DefaultParameterSetName = "Default")]

    Param(
        [parameter(Mandatory)]
        [ValidateScript( {Test-Path $_})]
        [System.IO.FileInfo]$filename,
        [Switch]$ExcludeQueryTextColumn,
        [Switch]$ExcludePlanColumn,
        [Switch]$NoColumnParsing
    )

    $out = "Parsing file {0}" -f $filename
    write-verbose -Message $out

    $ParsedScript = @()
    [string]$scriptpart = ""

    $fullscript = Get-Content -Path $filename

    $start = $false
    $querynr = 0
    $DBSpecific = $false

    if ($ExcludeQueryTextColumn) {$QueryTextColumn = ""}  else {$QueryTextColumn = ", t.[text] AS [Complete Query Text]"}
    if ($ExcludePlanColumn) {$PlanTextColumn = ""} else {$PlanTextColumn = ", qp.query_plan AS [Query Plan]"}

    foreach ($line in $fullscript) {
        if ($start -eq $false) {
            if (($line -match "You have the correct major version of SQL Server for this diagnostic information script") -or ($line.StartsWith("-- Server level queries ***"))) {
                $start = $true
            }
            continue
        }

        if ($line.StartsWith("-- Database specific queries ***") -or ($line.StartsWith("-- Switch to user database **"))) {
            $DBSpecific = $true
        }

        if (!$NoColumnParsing) {
            if (($line -match "-- uncomment out these columns if not copying results to Excel") -or ($line -match "-- comment out this column if copying results to Excel")) {
                $line = $QueryTextColumn + $PlanTextColumn
            }
        }

        if ($line -match "-{2,}\s{1,}(.*) \(Query (\d*)\) \((\D*)\)") {
            $prev_querydescription = $Matches[1]
            $prev_querynr = $Matches[2]
            $prev_queryname = $Matches[3]

            if ($querynr -gt 0) {
                $properties = @{QueryNr = $querynr; QueryName = $queryname; DBSpecific = $DBSpecific; Description = $queryDescription; Text = $scriptpart}
                $newscript = New-Object -TypeName PSObject -Property $properties
                $ParsedScript += $newscript
                $scriptpart = ""
            }

            $querydescription = $prev_querydescription
            $querynr = $prev_querynr
            $queryname = $prev_queryname
        } else {
            if (!$line.startswith("--") -and ($line.trim() -ne "") -and ($null -ne $line) -and ($line -ne "\n")) {
                $scriptpart += $line + "`n"
            }
        }
    }

    $properties = @{QueryNr = $querynr; QueryName = $queryname; DBSpecific = $DBSpecific; Description = $queryDescription; Text = $scriptpart}
    $newscript = New-Object -TypeName PSObject -Property $properties
    $ParsedScript += $newscript
    $ParsedScript
}


$cells = @()

Invoke-DbaDiagnosticQueryScriptParser $diagnosticScriptPath |
    Where-Object { -not $_.DBSpecific } |
    ForEach-Object {
        $cells += [pscustomobject]@{cell_type = "markdown"; source = "## $($_.QueryName)`n`n$($_.Description)" }
        $cells += [pscustomobject]@{cell_type = "code"; source = $_.Text }
    }

$preamble = @"
{
    "metadata": {
        "kernelspec": {
            "name": "SQL",
            "display_name": "SQL",
            "language": "sql"
        },
        "language_info": {
            "name": "sql",
            "version": ""
        }
    },
    "nbformat_minor": 2,
    "nbformat": 4,
    "cells":
"@


$preamble | Out-File $notebookOutputPath 
$cells | ConvertTo-Json | Out-File -FilePath $notebookOutputPath -Append
"}}" | Out-File -FilePath $notebookOutputPath -Append
