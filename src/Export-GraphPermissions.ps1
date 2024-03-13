 <#
        .SYNOPSIS
        Creates a list of Microsoft Graph permission roles.

        .DESCRIPTION

        .EXAMPLE
        ./src/Export-GraphPermissions.ps1

        Creates a list of all Graph permissions with output written to .\_info

        .EXAMPLE
        Export-GraphPermissions.ps1 $OutputPath ".\myOutputFolder"

        Creates a list using custom folders for the output
#>

param (
    [Parameter(Mandatory=$false, HelpMessage="Path to output the csv and json files")]
    [string]$OutputPath = ".\_info"
    )

function GetPermissionsFromMicrosoftGraph() {
    Write-Host "Retrieving permissions from Microsoft Graph"
    $graphAppId = "00000003-0000-0000-c000-000000000000"

    $sp = Get-MgServicePrincipal -Filter "appId eq '$graphAppId'" -All

    return $sp
}

$sp = GetPermissionsFromMicrosoftGraph

Write-Host "Exporting to csv and json"
New-Item -ItemType Directory -Force -Path $OutputPath | Out-Null

$outputFilePathCsv = Join-Path $OutputPath "GraphAppRoles.csv"
$outputFilePathJson = Join-Path $OutputPath "GraphAppRoles.json"

$sp.AppRoles | select Id, Value, DisplayName, Description | Export-Csv $outputFilePathCsv
$sp.AppRoles | ConvertTo-Json | Out-File $outputFilePathJson

$outputFilePathCsv = Join-Path $OutputPath "GraphDelegateRoles.csv"
$outputFilePathJson = Join-Path $OutputPath "GraphDelegateRoles.json"

$sp.Oauth2PermissionScopes | select Id, Value, AdminConsentDisplayName, AdminConsentDescription | Export-Csv $outputFilePathCsv
$sp.Oauth2PermissionScopes | ConvertTo-Json | Out-File $outputFilePathJson
