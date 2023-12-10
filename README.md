# IntuneProactiveRemediations
This repository contains scripts for Microsoft Intune Proactive Remediations. It has been designed to be like the 'WinGet' for Intune Proactive Remediations.

## Tools
There are a few Powershell script that can help with build, adding & validating a Proactive Remediation.

- To import a Proactive Remediations to your Intune environment use the ```Import-ProactiveRemediation.ps1``` script.
- To create a Proactive Remediations, use the ```New-ProactiveRemediation``` script.
- To test if the Proactive Remediations Repository is vaild, use the ```Test-ProactiveRemediationRepository``` script.

## Proactive Remediation Standards
Proactive Remediations should be added in the following folder structure
```Repository\<Name of Proactive Remediation without whitespace>```

The folder should contain the following files:
- Detection.ps1
- Remediation.ps1
- ProactiveRemediation.json

The `ProactiveRemediation.json` file should contain the following properties.
```json
{
    "displayName": string,              // Name of Proactive Remediation
    "description": string,              // Some description of what it does
    "publisher": string,                // Publisher Name
    "runAsAccount": string,             // Can be either system or user
    "runAs32Bit": boolean,              // Boolean
    "enforceSignatureCheck": boolean    // Boolean
}
```

If additional properties are added, these will not be imported into Microsoft Intune.