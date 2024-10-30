#requires -version 2.0

# ex: the following command copies empty sourcedb.ABC.ExampleSchema.ImportantTable to DestinationServer
# ./copy_table.ps1 -SrcServer "sourcedb" -SrcDatabase "ABC" -SrcTable "EXAMPLESCHEMA.ImportantTable" -DestServer "DestinationServer"

Param (
      [parameter(Mandatory = $true)]
      [string] $SrcServer,
      [parameter(Mandatory = $true)]
      [string] $SrcDatabaseName,
      [parameter(Mandatory = $true)]
      [string] $SrcTable,
      [parameter(Mandatory = $true)]
      [string] $DestServer
  )

#Destination database does not exist, so create its metadata
[string] $DestDatabase = $SrcDatabaseName # set destination database name to the source database name.
[string] $DestTable = $SrcTable # set destination database name to the source table name.

# creates connection string for destination, which is where the copy query executes
Function CreateDestinationConnectionString([string] $ServerName)
{
                "Data Source=$ServerName;Integrated Security=True;Encrypt=True;TrustServerCertificate=True"
}

#Not used, includes Initial Catalog i.e. database
Function CreateConnectionString([string] $ServerName, [string] $DbName)
{
                "Data Source=$ServerName;Initial Catalog=$DbName;Integrated Security=True;Encrypt=True;TrustServerCertificate=True"
}

########## Main body ############

$DestConnStr = CreateDestinationConnectionString $DestServer
Write-Host "Trying to connect to destination $DestConnStr"
$DestConn = New-Object System.Data.SqlClient.SqlConnection $DestConnStr
$DestConn.Open()

Try
{
                # create the database if it does not exist.
                $sqlCreateDb = "IF NOT EXISTS(SELECT * FROM sys.databases WHERE name = '$DestDatabase') BEGIN CREATE DATABASE [$DestDatabase] END;"
                $cmdCreateDb = New-Object Data.SqlClient.SqlCommand $sqlCreateDb, $DestConn;
                $cmdCreateDb.ExecuteNonQuery();    
                Write-Host "Database $NewDatabaseName is created!";

                # To TEST connection to source server.database.table
                # $SrcConnStr = "Data Source=sourcedb;Initial Catalog=TPR;Integrated Security=True;Encrypt=True;TrustServerCertificate=True"
                # $sqlConnection = New-Object System.Data.SqlClient.SqlConnection $SrcConnStr
                # $sqlConnection.Open()

                # Create link server
                $spCreateLink = "EXECUTE sp_addlinkedserver @server=N'sourcedb', @srvproduct=N'SQL Server';"
                $cmdCreateLink = New-Object Data.SqlClient.SqlCommand $spCreateLink, $DestConn;
                $cmdCreateLink.ExecuteNonQuery();  

                # Create a new entity from the output of the SELECT on source server table
                $CmdText = "SELECT * INTO [" + $DestDatabase + "]." +  $DestTable + " FROM [" + $SrcServer + "].[" + $SrcDatabaseName + "]." + $SrcTable
                $SqlCommand = New-Object system.Data.SqlClient.SqlCommand $CmdText, $DestConn;
                $SqlCommand.ExecuteNonQuery()
}
Catch [System.Exception]
{
                $ex = $_.Exception
                Write-Host $ex.Message
}
Finally
{
                Write-Host "Table $SrcTable in $SrcDatabase database on $SrcServer has been copied to table $DestTable in $DestDatabase database on $DestServer"
                $DestConn.Close()
                $DestConn.Dispose()
}