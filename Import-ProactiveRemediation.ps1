param(
    [Parameter(Mandatory = $false)]
    [string]$Path = "$((Get-Location).path)"
)

function Test-ProactiveRemediationJSON {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    # Check if the json is importable
    try {
        $json = Get-Content -Path $Path -Raw -ErrorAction Stop | ConvertFrom-Json
    }
    catch {
        Write-Warning -Message "The file '$Path' is not a valid JSON file"
        return $false
    }

    # Check if the json has the required properties
    $RequiredProperties = @(
        'displayName',
        'description',
        'publisher',
        'runAsAccount',
        'runAs32Bit',
        'enforceSignatureCheck'
    )

    # Loop through and check if the json has the required properties
    foreach ($RequiredProperty in $RequiredProperties) {
        if (-not $json.PSObject.Properties.Name.Contains($RequiredProperty)) {
            Write-Warning -Message "The file '$Path' is missing the required property '$RequiredProperty'"
            return $false
        }
    }

    # ToDo: Check data types of the properties

    # All checks passed
    return $true
}

# Mandatory files
$MandatoryFiles = @(
    'Detection.ps1'
    'Remediation.ps1'
    'ProactiveRemediation.json'
)

# Get all folders recursively
$folders = Get-ChildItem -Path $Path -Directory -Recurse

# Array to store the valid Proactive Remediations
$VaildProactiveRemediations = @()

# Loop through each folder
foreach ($folder in $folders) {

    $HasInvalidFiles = $false

    # Get files in the folder
    $files = Get-ChildItem -Path $folder.FullName -File

    # Check if the folder has all the mandatory files
    foreach ($MandatoryFile in $MandatoryFiles) {
        if (-not $files.Name.Contains($MandatoryFile)) {
            Write-Warning -Message "The folder '$folder' is missing the mandatory file '$MandatoryFile'"
            $HasInvalidFiles = $true
            break
        }
    }

    # Skip the folder if it has invalid files
    if ($HasInvalidFiles) {
        continue
    }

    # Check if the folder has a valid ProactiveRemediation.json
    if (!(Test-ProactiveRemediationJSON -Path "$($folder.FullName)\ProactiveRemediation.json")) {
        Write-Warning -Message "The folder '$folder' has an invalid ProactiveRemediation.json"
        break 
    }

    # Get the ProactiveRemediation.json
    $ProactiveRemediationJson = Get-Content -Path "$($folder.FullName)\ProactiveRemediation.json" -Raw | ConvertFrom-Json

    # Build a object with the required properties
    $ProactiveRemediationObject = [PSCustomObject]@{
        'Name' = $ProactiveRemediationJson.displayName
        'Description' = $ProactiveRemediationJson.description
        'Version' = $ProactiveRemediationJson.version
        'Publisher' = $ProactiveRemediationJson.publisher
        'Path' = $folder.FullName
    }

    # Add the object to the array
    $VaildProactiveRemediations += $ProactiveRemediationObject
}

# Check if there are any valid Proactive Remediations
if ($VaildProactiveRemediations.Count -eq 0) {
    Write-Error -Message "No valid Proactive Remediations found"
    break
}

# Show and prompt the user to select a Proactive Remediation
$UserSelection = $VaildProactiveRemediations | Select-Object -ExcludeProperty "Path" | Sort-Object -Property Name -Descending | Out-ConsoleGridView -Title 'Select a Proactive Remediation' -OutputMode Single

# Check if the user selected a Proactive Remediation
if ($UserSelection) {

    # Get the selected Proactive Remediation
    $UserSelection = $VaildProactiveRemediations | Where-Object {$_.Name -eq $UserSelection.Name}

    # Get the Detection script in base64 format
    $DetectionScript = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes((Get-Content -Path "$($UserSelection.Path)\Detection.ps1" -Raw)))

    # Get the Remediation script in base64 format
    $RemediationScript = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes((Get-Content -Path "$($UserSelection.Path)\Remediation.ps1" -Raw)))

    # Import the Proactive Remediation JSON
    $ProactiveRemediationJson = Get-Content -Path "$($UserSelection.Path)\ProactiveRemediation.json" -Raw | ConvertFrom-Json

    # Build the Proactive Remediation JSON
    $ProactiveRemediation = [PSCustomObject]@{
        '@odata.type' = "#microsoft.graph.deviceHealthScript"
        'displayName' = $ProactiveRemediationJson.displayName
        'description' = $ProactiveRemediationJson.Description
        'version' = $ProactiveRemediationJson.Version
        'publisher' = $ProactiveRemediationJson.Publisher
        'runAsAccount' = $ProactiveRemediationJson.runAsAccount
        'runAs32Bit' = $ProactiveRemediationJson.runAs32Bit
        'enforceSignatureCheck' = $ProactiveRemediationJson.enforceSignatureCheck
        'detectionScriptContent' = $DetectionScript
        'remediationScriptContent' = $RemediationScript
    }

    # Get Microsoft Graph token
    $connectionDetails = @{
        'ClientId'    = 'c3c9a24f-5839-4a33-bb1a-13f4baf874d5'
        'Interactive' = $true
        'RedirectUri' = "urn:ietf:wg:oauth:2.0:oob"
    }
    $token = Get-MsalToken @connectionDetails

    # Create the request headers
    $Headers = @{
        'Authorization' = "Bearer $($token.AccessToken)"
        'Content-Type' = 'application/json'
    }

    # Create the request
    try {
        $Request = @{
            'Uri' = "https://graph.microsoft.com/beta/deviceManagement/deviceHealthScripts"
            'Method' = 'POST'
            'Headers' = $Headers
            'Body' = $ProactiveRemediation | ConvertTo-Json -Depth 10
            'ErrorAction' = 'Stop'
            'Verbose' = $false
        }
        $Response = Invoke-RestMethod @Request
    }
    catch {
        Throw "Failed to invoke Graph API request. Error: $($_.Exception.Message)"
    }

    # Check if the request was successful
    if ($Response) {
        Write-Output "Proactive Remediation '$($UserSelection.Name)' was successfully imported"
    } else {
        Write-Error "Failed to import Proactive Remediation '$($UserSelection.Name)'"
    }

} else {
    Write-Output "No Proactive Remediation selected"
}