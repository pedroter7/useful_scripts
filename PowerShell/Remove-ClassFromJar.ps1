<#
.SYNOPSIS
    Script to remove a class from .jar files

.PARAMETER JarFilePath
    Path to .jar file(s)

.PARAMETER Class
    Name of the class to be removed

.EXAMPLE
    # Removes the class JMSAppender from every log4j jar that
    # gci finds
    Get-ChildItem -Filter log4j*.jar `
        | Select-Object -ExpandProperty FullName `
        | .\Remove-ClassFromJar -Class 'JMSAppender'

.EXAMPLE
    # Removes the class Foo from every .jar file in the current dir
    Get-ChildItem -Filter *.jar | Select-Object -ExpandProperty FullName `
        | .\Remove-ClassFromJar -Class "foo"

.EXAMPLE
    # Removes the class MeuObjeto from C:\Users\Eu\Documentos\meu.jar
    .\Remove-ClassFromJar -JarFilePath "C:\Users\Eu\Documentos\meu.jar" `
        -Class "MeuObjeto"
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true,
                ValueFromPipeline=$true)]
    [string[]]
    $JarFilePath,
    [Parameter(Mandatory=$true)]
    [string]
    $Class
)
begin {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    Add-Type -AssemblyName System.IO.Compression
    $mode = [System.IO.Compression.ZipArchiveMode]::Update
}
process {
    $file = $_
    try {
        $zip = [System.IO.Compression.ZipFile]::Open("$file", $mode)
    } catch {
        Write-Error -Message "Could not open file $file for updating"
        Write-Error $_
        exit 1
    }

    $wantedClass = $zip.Entries | Where-Object -Property Name -EQ "${Class}.class"

    if ($null -eq $wantedClass) {
        Write-Warning -Message "$Class not found in file $file"
    } else {

        try {
            $wantedClass.Delete()
        } catch {
            Write-Error -Message "Could not delete $Class from file $file"
            Write-Error $_
        } finally {
            $zip.Dispose()
        }
    }
}
end {
    Write-Verbose -Message "DONE!"
}
