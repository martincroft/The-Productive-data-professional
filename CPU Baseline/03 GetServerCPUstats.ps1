$DesinationServerName ="BOB"

##Uncomment /Comment 
#Updates to all 
$ServerName= invoke-sqlcmd -ServerInstance $DesinationServerName  -query "SELECT SQLServerInstanceName from [Reports].[dbo].[MasterServerDetails] WHERE CPULoggingInstalled=1 " -Username "sa" -Password "Passw0rd"
  
clear-host

 #Create a data table to hold bulk results
    $OutputResults = New-Object System.Data.DataTable

    $column = New-Object System.Data.DataColumn ‘ServerName’,([STRING])
    $OutputResults.Columns.Add($column)

    $column = New-Object System.Data.DataColumn ‘SQL_CPU_Utilization’,([INT])
    $OutputResults.Columns.Add($column)

    $column = New-Object System.Data.DataColumn ‘System_Idle_Process’,([INT])
    $OutputResults.Columns.Add($column)

    $column = New-Object System.Data.DataColumn ‘Other_Process_CPU_Utilization’,([INT])
    $OutputResults.Columns.Add($column)

        
    $column = New-Object System.Data.DataColumn ‘ReportDate’,([STRING])
    $OutputResults.Columns.Add($column)

invoke-sqlcmd -ServerInstance $DesinationServerName  -query "TRUNCATE TABLE Reports.[staging].[CPU_Usage]" -Username "sa" -Password "Passw0rd"


FOREACH($server in $ServerName)
{

  try {


  
    $SourceServerName =$server.Item('SQLServerInstanceName')

    Write-Output $SourceServerName
        

    #Get new records from Source Server
    $sql ="SELECT [ServerName]
      ,[SQL_CPU_Utilization]
      ,[System_Idle_Process]
      ,[Other_Process_CPU_Utilization]
      ,[ReportDate] FROM [master].[dbo].[CPU_Usage]
         ORDER BY reportDate  
      "
           
    
    $OutputResults = invoke-sqlcmd -ServerInstance  $SourceServerName -query $sql -Username "sa" -Password "Passw0rd"
   

        #Write-Output "No more to process for $SourceServerName"
        #break
    
if ($OutputResults -ne $null)     
{

    #Truncate staging and populate Desination Database 

    $schema='Staging'
    $table='CPU_Usage'
    $database ='Reports'
 

     
    Write-SqlTableData -ServerInstance $DesinationServerName -DatabaseName  $database -SchemaName $schema -TableName  $table -InputData $OutputResults 
    
   
       
   }
    
}
Catch
{
 $SourceServerName 
}

}





$UpdateFromStaging ="

TRUNCATE TABLE [Reports].[dbo].[CPU_Usage];

INSERT INTO [reports].[dbo].[CPU_Usage]
(
	ServerName
	,SQL_CPU_Utilization
	,System_Idle_Process
	,Other_Process_CPU_Utilization
	,ReportDate

)

SELECT ServerName
	,SQL_CPU_Utilization
	,System_Idle_Process
	,Other_Process_CPU_Utilization
	,CONVERT(DATETIME,ReportDate,103) AS ReportDate
FROM [reports].[Staging].[CPU_Usage]
"

invoke-sqlcmd -ServerInstance  $DesinationServerName  -query $UpdateFromStaging 