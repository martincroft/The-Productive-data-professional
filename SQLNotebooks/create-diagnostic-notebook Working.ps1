#Source of routines - Gianluca Sartori
#https://spaghettidba.com/2019/03/20/generating-a-jupyter-notebook-for-glenn-berrys-diagnostic-queries-with-powershell/
#https://twitter.com/AndreKamman

Clear-Host

set-location 'C:\Users\marti\OneDrive\04 SQL Server Solutions Ltd\Presentations\The proactive data professional - Data Scotland\SQLNotebooks'


Remove-Item ".\Diagnostic-notebook.ipynb"

.\create-diagnostic-notebook.ps1 `
    -diagnosticScriptPath ".\SQL Server 2017 Diagnostic Information Queries.sql" `
    -notebookOutputPath ".\Diagnostic-notebook.ipynb"


    
.\create-diagnostic-notebook.ps1 `
    -diagnosticScriptPath ".\Useful.sql" `
    -notebookOutputPath ".\Useful Queries-notebook.ipynb"

    Get-ChildItem -File -path .\*.ipynb |Select-Object Name,LastWriteTime | Sort-Object LastWriteTime -Descending