﻿$ErrorActionPreference = 'Stop'; # stop on all errors

$url = 'https://vstsagentpackage.azureedge.net/agent/2.162.0/vsts-agent-win-x86-2.162.0.zip'
$url64 = 'https://vstsagentpackage.azureedge.net/agent/2.162.0/vsts-agent-win-x64-2.162.0.zip'
$checksum = '5560fb356e65680c0f77066b001aa3abbc0dccb831628b6a412eee94bb2e83f6'
$checksum64 = 'eadee90d59aee8d783375a6ae0b158ab68f6875a7ca43e61d0d4d6c4697140b2'

$pp = Get-PackageParameters

if (!$pp['Directory']) { $pp['Directory'] = 'c:\agent' }

$configOpts = @()

# We only run config.cmd if a Url is supplied
if ($pp['Url']) {

    $configOpts = @('configure', '--unattended', '--acceptTeeEula')
    $configOpts += @('--url', $pp['Url'])

    if ($pp['Token']) {
        $configOpts += @("--auth", "pat", "--token", $pp['Token'])
    }
    else {
        if (!$pp['Auth']) {
            Write-Error "You need to specify an auth type with /Auth= 'negotiate', 'alt' or 'integrated'"
        }
        
        $configOpts += @("--auth", $($pp['Auth']))

        if ($pp['Auth'] -ine 'integrated') {
            $username = $pp['Username']
            $password = $pp['Password']

            if (!$username -or !$password) {
                Write-Error "You must supply /username and /password"
            }
            
            $configOpts += @("--userName", $username, "--password", $password)
        }
    }
    # Are we a deployment agent or a build agent?
    if ($pp['DeploymentGroup']) {
        Write-Verbose "Deployment Agent"

        if (!$pp['DeploymentGroupName'] -or !$pp['ProjectName']) {
            Write-Error "Must specify /DeploymentGroupName and /ProjectName"
        }

        $configOpts += @("--deploymentGroup", "--deploymentGroupName", $pp['DeploymentGroupName'])
        if ($pp['DeploymentGroupTags']) {
            $configOpts += @("--addDeploymentGroupTags", "--deploymentGroupTags", $pp['DeploymentGroupTags'])
        }

        if ($pp['ProjectName']) {
            $configOpts += @('--projectName', $pp['ProjectName'])
        }
    }
    else {
        if (!$pp['Pool']) { $pp['Pool'] = 'default'}
      
        $configOpts += @("--pool", $pp['Pool'])
    }
    
    # AutoLogon(interactive) or as a service
    if ($pp['AutoLogon']) {
        $configOpts += @('--runAsAutoLogon', '--noRestart')
    }
    else {
        $configOpts += @('--runAsService')
    }

    if ($pp['LogonAccount']) {
        $configOpts += @("--windowsLogonAccount", $pp['LogonAccount'])

        if ($pp['LogonPassword']) {
            $configOpts += @("--windowsLogonPassword", $pp['LogonPassword'])
        }
    }

    # Work directory
    if ($pp['Work']) {
        $configOpts += @("--work", $pp['Work'])
    }

    # Agent name
    if ($pp['AgentName']) {
        $configOpts += @("--agent", $pp['AgentName'])
    }

    # Replace existing agent
    if ($pp['Replace']) {
        $configOpts += @("--replace")
    }
    if ($pp['Proxy']) {
        $configOpts += @('--proxyurl')
    }
    if ($pp['ProxyPassword']) {
        $configOpts += @('--proxypassword')
    }
    if ($pp['ProxyUsername']) {
        $configOpts += @('--proxyusername')
    }
    else {
        $configOpts += @('--runAsService')
    }
}

$packageArgs = @{
    packageName    = $env:ChocolateyPackageName
    unzipLocation  = $pp['Directory']
    url            = $url
    url64bit       = $url64

    checksum       = $checksum
    checksumType   = 'sha256'
    checksum64     = $checksum64
    checksumType64 = 'sha256'
}

Install-ChocolateyZipPackage @packageArgs

if ($configOpts.Count) {
    Write-Verbose "$($packageArgs.unzipLocation)\bin\Agent.Listener.exe configure $configOpts"
    & "$($packageArgs.unzipLocation)\bin\Agent.Listener.exe" $configOpts
}
