BeforeAll {
    $exportScript = Join-Path $PSScriptRoot '../src/Export-MicrosoftApps.ps1'
    $tokens = $null
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($exportScript, [ref]$tokens, [ref]$errors)
    if ($errors.Count) { throw 'Export script could not be parsed.' }
    $definition = $ast.Find({ param($node)
        $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
        $node.Name -eq 'GetAppsFromMicrosoftGraph'
    }, $true)
    # Load only the function; never execute the network-enabled exporter in tests.
    . ([scriptblock]::Create($definition.Extent.Text))
    function Get-MgServicePrincipal {
        [CmdletBinding()]
        param($Filter, $Select, $ConsistencyLevel, $PageSize, $CountVariable, [switch]$All)
        throw 'Unexpected Graph request in offline test.'
    }
}

Describe 'Microsoft Graph result accumulation' {
    It 'accepts <PerTenant> results per tenant without scalar addition' -ForEach @(
        @{ PerTenant = 0 }
        @{ PerTenant = 1 }
        @{ PerTenant = 2 }
    ) {
        Mock Get-MgServicePrincipal {
            for ($i = 0; $i -lt $PerTenant; $i++) {
                [pscustomobject]@{
                    appId = "aaaaaaaa-bbbb-cccc-dddd-00000000000$i"
                    appDisplayName = "Example $i"
                    appOwnerOrganizationId = '11111111-1111-1111-1111-111111111111'
                }
            }
        }
        $result = @(GetAppsFromMicrosoftGraph -ErrorAction Stop)
        $result.Count | Should -Be (3 * $PerTenant)
        foreach ($row in $result) {
            $row.AppId | Should -BeLike 'aaaaaaaa-bbbb-cccc-dddd-00000000000*'
            $row.AppDisplayName | Should -BeLike 'Example *'
            $row.AppOwnerOrganizationId | Should -BeExactly '11111111-1111-1111-1111-111111111111'
            $row.Source | Should -BeExactly 'Graph'
        }
        Should -Invoke Get-MgServicePrincipal -Times 3 -Exactly
    }
}
