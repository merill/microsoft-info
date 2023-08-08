 <#
        .SYNOPSIS
        Creates a list of Microsoft first party apps with app id and display name and exports to csv and json.

        .DESCRIPTION
        This scripts retrieves a list of apps in the following order
        1. Microsoft Graph (apps where appOwnerOrganizationId is Microsoft)
        2. Microsoft Learn doc (https://learn.microsoft.com/troubleshoot/azure/active-directory/verify-first-party-apps-sign-in)
        3. Custom list of apps (./customdata/MysteryApps.csv) - Community contributed list of Microsoft apps and their app ids

        This script assumes the current session is connected to Microsoft Graph with the scope Application.Read.All
        .EXAMPLE
        ./src/Export-MicrosoftApps.ps1

        Creates a list of Microsoft first party apps with output written to .\_info and custom data loaded from ./customdata/OtherMicrosoftApps.csv
        Assumes the root of the repo is the current working directory

        .EXAMPLE
        Export-MicrosoftApps.ps1 $OutputPath ".\myOutputFolder" $CustomAppDataPath "./../customdata/OtherMicrosoftApps.csv"

        Creates a list using custom folders for the output and reading of custom data
#>

param (
    [Parameter(Mandatory=$false, HelpMessage="Path to output the csv and json files")]
    [string]$OutputPath = ".\_info",

    [Parameter(Mandatory=$false, HelpMessage="Path to csv file with community contributed custom list of apps")]
    [string]$CustomAppDataPath = "./customdata/OtherMicrosoftApps.csv"
    )

function GetAppsFromMicrosoftLearnDoc() {
    Write-Debug "Retrieving apps from Microsoft Learn doc"
    $msLearnFirstPartyAppDocUri = "https://raw.githubusercontent.com/MicrosoftDocs/SupportArticles-docs/main/support/azure/active-directory/verify-first-party-apps-sign-in.md"
    $mdContent = (Invoke-WebRequest -Uri $msLearnFirstPartyAppDocUri).Content
    $lines = $mdContent -split [Environment]::NewLine
    $tableIndex = 0
    $appList = @()
    foreach ($line in $lines) {
        $cleanLine = $line.trim()

        if ($cleanLine.startsWith("|")) {
            if ($cleanLine.startsWith("|-")) { $tableIndex++ }

            $tenantId = "f8cdef31-a31e-4b4a-93e4-5f571e91255a"
            if ($tableIndex -eq 2) { $tenantId = "72f988bf-86f1-41af-91ab-2d7cd011db47" }

            $cols = $cleanLine -split '\|'
            $appName = $cols[1].trim()
            $appId = $cols[2].trim()

            $guid = [System.Guid]::empty
            $isGuid = [System.Guid]::TryParse($appId, [System.Management.Automation.PSReference]$guid)
            if ($isGuid) {
                $itemInfo = [ordered]@{
                    AppId                  = $appId + ""
                    AppDisplayName         = $appName + ""
                    AppOwnerOrganizationId = $tenantId
                    Source                 = "Learn"
                } 
                $appList += $itemInfo
            }
        }    
    }
    return $appList
}

function GetAppsFromMicrosoftGraph() {
    Write-Host "Retrieving apps from Microsoft Graph"
    $tenantIdList = @("f8cdef31-a31e-4b4a-93e4-5f571e91255a", "72f988bf-86f1-41af-91ab-2d7cd011db47")
    $select = "appId,appDisplayName,appOwnerOrganizationId"


    foreach ($tenantId in $tenantIdList) {
        $filter = "appOwnerOrganizationId eq $($tenantId)"
        $servicePrincipals += Get-MgServicePrincipal -Filter $filter -Select $select -ConsistencyLevel eventual -PageSize 999 -CountVariable $count -All
    }

    $appList = @()

    foreach ($item in $servicePrincipals) {     
        $itemInfo = [ordered]@{
            AppId                  = $item.appId + ""
            AppDisplayName         = $item.appDisplayName + ""
            AppOwnerOrganizationId = $item.appOwnerOrganizationId + ""
            Source                 = "Graph"
        } 
        $appList += $itemInfo
    }
    return $appList
}

$appList = @()

# Sources at the top take priority, duplicates from sources that are lower are skipped.
$appList += GetAppsFromMicrosoftGraph
$appList += GetAppsFromMicrosoftLearnDoc
$appList += Import-Csv $CustomAppDataPath

Write-Host "Creating unique list of apps"
$idList = @()
$uniqueAppList = @()

foreach ($item in $appList) {
    [string]$id = $item.AppId

    # skip duplicates
    if ($idList -contains $id) { continue }
    $idList += $id
    $uniqueAppList += $item
}

Write-Host "Exporting to csv and json"
New-Item -ItemType Directory -Force -Path $OutputPath | Out-Null

$outputFilePathCsv = Join-Path $OutputPath "MicrosoftApps.csv"
$outputFilePathJson = Join-Path $OutputPath "MicrosoftApps.json"

$uniqueAppList | Export-Csv $outputFilePathCsv
$uniqueAppList | ConvertTo-Json | Out-File $outputFilePathJson
