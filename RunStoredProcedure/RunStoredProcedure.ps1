﻿# this function runs all the SQL scripts in a supplied folder against the supplied server
[CmdletBinding()]
Param()

Trace-VstsEnteringInvocation $MyInvocation

Try
{
	Import-VstsLocStrings "$PSScriptRoot\Task.json"
	[string]$serverName = Get-VstsInput -Name serverName
	[string]$databaseName = Get-VstsInput -Name databaseName
	[string]$sprocName = Get-VstsInput -Name sprocName
	[string]$sprocParameters = Get-VstsInput -Name sprocParameters
	[string]$userName = Get-VstsInput -Name userName
	[string]$userPassword = Get-VstsInput -Name userPassword
	[string]$queryTimeout = Get-VstsInput -Name queryTimeout

	[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null
    $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
	
	if([string]::IsNullOrEmpty($userName)) {
        $SqlConnection.ConnectionString = "Server=$serverName;Initial Catalog=$databaseName;Trusted_Connection=True;Connection Timeout=30"		
    }
    else {
        $SqlConnection.ConnectionString = "Server=$serverName;Initial Catalog=$databaseName;User ID=$userName;Password=$userPassword;Connection Timeout=30;"
    }

    $handler = [System.Data.SqlClient.SqlInfoMessageEventHandler] {param($sender, $event) Write-Host $event.Message -ForegroundColor DarkBlue} 
    $SqlConnection.add_InfoMessage($handler) 
	$SqlConnection.Open()
	$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
	$SqlCmd.Connection = $SqlConnection
	$SqlCmd.CommandTimeout = $queryTimeout
	
	#Construct to the SQL to run
	
	[string]$sqlQuery = "EXEC " + $sprocName + " " + $sprocParameters
		
	#Execute the query
	$SqlCmd.CommandText = $sqlQuery
	$reader = $SqlCmd.ExecuteNonQuery()

	$SqlConnection.Close()
	Write-Host "Finished"
}

catch
{
	Write-Host "Error running SQL script: $_" -ForegroundColor Red
	throw $_
}

