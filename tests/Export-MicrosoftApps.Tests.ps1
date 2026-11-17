BeforeAll {
    $exportScript = Join-Path $PSScriptRoot '../src/Export-MicrosoftApps.ps1'
    $tokens = $null
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($exportScript, [ref]$tokens, [ref]$errors)
    if ($errors.Count) { throw 'Export script could not be parsed.' }
    $definition = $ast.Find({ param($node)
        $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
        $node.Name -eq 'GetAppsFromEntraDocs'
    }, $true)
    # Load only the function: dot-sourcing the exporter would query Microsoft Graph.
    . ([scriptblock]::Create($definition.Extent.Text))

    # Fail closed if a test calls an unmocked external boundary.
    function Invoke-WebRequest {
        [CmdletBinding()]
        param([string]$Uri)
        throw 'Unexpected web request in offline test.'
    }
    function Get-MgServicePrincipal {
        [CmdletBinding()]
        param($Filter, $Select, $ConsistencyLevel, $PageSize, $CountVariable, [switch]$All)
        throw 'Unexpected Graph request in offline test.'
    }
}

Describe 'Entra documentation GUID ingestion' {
    BeforeEach {
        $script:docsContent = '{}'
        Mock Invoke-WebRequest { [pscustomobject]@{ Content = $script:docsContent } }
    }

    It 'outputs the parsed identity in canonical D format for <Case>' -ForEach @(
        @{ Case = 'canonical'; Value = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee' }
        @{ Case = 'uppercase'; Value = 'AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE' }
        @{ Case = 'braces'; Value = '{AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE}' }
        @{ Case = 'compact'; Value = 'aaaaaaaabbbbccccddddeeeeeeeeeeee' }
        @{ Case = 'surrounding whitespace'; Value = " `taaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee  " }
        @{ Case = 'nonbreaking whitespace'; Value = "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee$([char]0x00a0)" }
    ) {
        $script:docsContent = @{ 'Example' = $Value } | ConvertTo-Json
        $result = @(GetAppsFromEntraDocs)
        $result.Count | Should -Be 1
        $result[0].AppId | Should -BeExactly 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'
        $result[0].AppDisplayName | Should -BeExactly 'Example'
        $result[0].Source | Should -BeExactly 'EntraDocs'
        $result[0].AppOwnerOrganizationId | Should -BeExactly ''
    }

    It 'warns and skips only an invalid entry while keeping following valid entries (<Case>)' -ForEach @(
        @{ Case = 'corrupt suffix'; Value = "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee$([char]0x00c2)$([char]0x00a0)" }
        @{ Case = 'empty'; Value = '' }
        @{ Case = 'null'; Value = $null }
        @{ Case = 'number'; Value = 123 }
        @{ Case = 'array'; Value = @('aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee') }
    ) {
        $script:docsContent = [ordered]@{
            'Invalid example' = $Value
            'Valid example' = 'bbbbbbbb-cccc-dddd-eeee-ffffffffffff'
        } | ConvertTo-Json -Depth 5
        $captured = @(GetAppsFromEntraDocs 3>&1)
        $warnings = @($captured | Where-Object { $_ -is [System.Management.Automation.WarningRecord] })
        $result = @($captured | Where-Object { $_ -isnot [System.Management.Automation.WarningRecord] })
        $result.Count | Should -Be 1
        $result[0].AppId | Should -BeExactly 'bbbbbbbb-cccc-dddd-eeee-ffffffffffff'
        $warnings.Count | Should -Be 1
        $warnings[0].Message | Should -BeLike '*Invalid example*valid GUID*'
    }

    It 'keeps the all-zero GUID as a valid identifier spelling' {
        $script:docsContent = @{ 'Zero' = '00000000-0000-0000-0000-000000000000' } | ConvertTo-Json
        @(GetAppsFromEntraDocs)[0].AppId | Should -BeExactly '00000000-0000-0000-0000-000000000000'
    }
}

Describe 'Offline exporter integration' {
    It 'preserves Graph precedence and exports canonical documentation IDs in JSON and CSV' {
        $graphId = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'
        $docsId = 'bbbbbbbb-cccc-dddd-eeee-ffffffffffff'
        $docs = [ordered]@{
            'Documentation duplicate' = " {$($graphId.ToUpperInvariant())}  "
            'Invalid documentation' = "cccccccc-dddd-eeee-ffff-000000000001$([char]0x00c2)$([char]0x00a0)"
            'Valid documentation' = "$($docsId.ToUpperInvariant())  "
        } | ConvertTo-Json
        Mock Get-MgServicePrincipal {
            [pscustomobject]@{ appId = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'; appDisplayName = 'Graph preferred'; appOwnerOrganizationId = '11111111-1111-1111-1111-111111111111' }
            [pscustomobject]@{ appId = 'dddddddd-eeee-ffff-0000-111111111111'; appDisplayName = 'Another Graph app'; appOwnerOrganizationId = '11111111-1111-1111-1111-111111111111' }
        }
        Mock Invoke-WebRequest {
            if ($Uri -like '*known-guids.json') { return [pscustomobject]@{ Content = $docs } }
            if ($Uri -like '*verify-first-party-apps-sign-in.md') { return [pscustomobject]@{ Content = '' } }
            throw 'Unexpected source URL in offline test.'
        }
        $custom = Join-Path $TestDrive 'custom.csv'
        'AppId,AppDisplayName,AppOwnerOrganizationId,Source' | Set-Content $custom
        $output = Join-Path $TestDrive 'export'
        $warnings = @(& $exportScript -OutputPath $output -CustomAppDataPath $custom 3>&1 |
            Where-Object { $_ -is [System.Management.Automation.WarningRecord] })
        $json = @(Get-Content (Join-Path $output 'MicrosoftApps.json') -Raw | ConvertFrom-Json)
        $csv = @(Import-Csv (Join-Path $output 'MicrosoftApps.csv'))
        foreach ($rows in @($json, $csv)) {
            $rows.Count | Should -Be 3
            $graph = @($rows | Where-Object AppId -EQ $graphId)
            $graph.Count | Should -Be 1
            $graph[0].AppDisplayName | Should -BeExactly 'Graph preferred'
            $graph[0].Source | Should -BeExactly 'Graph'
            $graph[0].AppOwnerOrganizationId | Should -BeExactly '11111111-1111-1111-1111-111111111111'
            @($rows | Where-Object AppId -EQ $docsId)[0].AppDisplayName | Should -BeExactly 'Valid documentation'
        }
        $warnings.Count | Should -Be 1
        Should -Invoke Get-MgServicePrincipal -Times 3 -Exactly
        Should -Invoke Invoke-WebRequest -Times 2 -Exactly
    }
}
