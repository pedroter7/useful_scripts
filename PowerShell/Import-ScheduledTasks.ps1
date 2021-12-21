<#
.NOTES
    Author: Pedro T Freidinger (pedrotersetti3@gmail.com)
    License: MIT (github.com/pedroter7/useful_scripts)

.SYNOPSIS
    Imports a bunch of tasks at once to the Windows Task Scheduler. The name for the tasks is taken from the XML file.

.DESCRIPTION
    This script is a pipeline-friendly way to import several tasks to the Windows Task scheduler at once.

.PARAMETER TasksXmlFiles
    A list of strings containing the path to XML Windows Task Scheduler tasks declarations. This can be sent from the pipeline.

.PARAMETER User
    User name (ex. domain\some-user) to the 'run as' for every task.

.PARAMETER PasswordSecureString
    The password for the 'run as' user contained in a secure string. If this is not passed the password is prompted.

.PARAMETER TaskPath
    The path within the Windows Task Scheduler where all the tasks should be placed. If this is not passed the script will
    dinamically get the task path from each task XML. This is usefull if you want to make sure that every task will be registered
    within a single directory inside Windows Task Scheduler.

.PARAMETER PassThru
    If this flag is passed, the create task object(s) are send to the output.

.PARAMETER Force
    If this flag is passed, no prompt is made (but the password) and tasks that are registered already are overriden.

.INPUTS
    A list of strings contaning paths to XML declaration of Windows Scheduler tasks.

.OUTPUTS
    If the PassThru flag is used, the created task object(s) are send to the output.

.EXAMPLE
    Get-ChildItem -File -LiteralPath C:\SomeTasksDeclarations | Select-Object -ExpandProperty FullName | .\Import-ScheduledTasks.ps1 `
        -User 'somedomain\someuser' -PasswordSecureString $passwordSecureString -Force
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true,
                ValueFromPipeline=$true)]
        [String[]]$TasksXmlFiles,

    [Parameter(Mandatory=$true)]
        [string]$User,

    [Parameter()]
        [securestring]$PasswordSecureString,

    [Parameter()]
        [string]$TaskPath,

    [Parameter()]
        [switch]$PassThru=$false,

    [Parameter()]
        [switch]$Force=$false
)

begin {

    Write-Debug -Message "Declaring functions"
    function Get-PlainPassword {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)]
                [securestring]$SecureString
        )

        Write-Debug -Message 'Getting plaintext password from secure string'
    
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
        $plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    
        $plainPassword
    }
    function Get-TaskNameFromXML {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)]
                [xml]$TaskXml
        )

        Write-Debug -Message 'Getting task name from XML'

        $taskName = $TaskXml.Task.RegistrationInfo.URI
        $taskName = $taskName.split('\')[-1]

        $taskName
    }

    function Get-TaskPathFromXml {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory=$true)]
                [xml]$TaskXml
        )

        [string]$taskUri = $TaskXml.Task.RegistrationInfo.URI
        [string]$taskPath = $taskUri.Substring(0, $taskUri.LastIndexOf('\'))

        $taskPath
    }

    Write-Debug -Message "Creating credential for user $User"

    # Create Credential
    if (-not ('PasswordSecureString' -in $PSBoundParameters.Keys)) {
        $PasswordSecureString = Read-Host -Prompt "Enter user $User password: " -AsSecureString
    }
    [System.Management.Automation.PSCredential]$runAsCredential = [System.Management.Automation.PSCredential]::new($User, $PasswordSecureString)
    
    [bool]$taskPathFromXml = (-not ('TaskPath' -in $PSBoundParameters.Keys))

    $extraParams = @{}

    if ($Force) {
        $extraParams['Force'] = $true
    }
}
process {
    foreach($xmlFile in $TasksXmlFiles) {
        Write-Debug -Message "Getting XML from $xmlFile"

        [xml]$taskXml = Get-Content -Path $xmlFile
        if ($taskPathFromXml) {
            Write-Debug -Message 'Getting task path from XML'
            $TaskPath = Get-TaskPathFromXml -TaskXml $taskXml
        }

        [string]$taskName = Get-TaskNameFromXML -TaskXml $taskXml

        Write-Verbose -Message "Registering task $taskName with to path $TaskPath"

        $registeredTask = Register-ScheduledTask -TaskName $taskName -User $runAsCredential.UserName `
            -Password (Get-PlainPassword -SecureString $runAsCredential.Password) -TaskPath $TaskPath `
            -Xml $taskXml.OuterXml @extraParams

        if ($PassThru) {
            $registeredTask
        }
    }
}
end {
    Write-Verbose -Message 'Finished registering tasks.'
}