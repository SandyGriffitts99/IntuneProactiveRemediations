# IntuneProactiveRemediations
![Proactive Remediations Repository Tests](https://github.com/dylanmccrimmon/IntuneProactiveRemediations/actions/workflows/test-proactive-remediations-repository.yml/badge.svg)


This repository contains scripts for Microsoft Intune Proactive Remediations. It has been designed to be like the 'WinGet' for Intune Proactive Remediations.

## Tools
There are a few Powershell script that can help with building, adding & validating a Proactive Remediations.

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
    "displayName": "",              // Required|string - Name of Proactive Remediation
    "description": "",              // String - Some description of what it does
    "publisher": "string",          // Required|String - Publisher Name
    "runAsAccount": "string",       // Required|String - Can be either system or user
    "runAs32Bit": true,             // Required|Boolean
    "enforceSignatureCheck": true   // Required|Boolean
}
```

If additional properties are added, these will not be imported into Microsoft Intune.