<#
.SYNOPSIS
    Script para remover uma classe de dentro de um .jar

.PARAMETER JarFilePath
    Caminhos para arquivos .jar. Pode ser passado via pipeline

.PARAMETER Class
    Nome da classe para ser removida

.EXAMPLE
    # Remove a classe JMSAppender de todos os .jar do log4j que
    # o gci econtrar
    Get-ChildItem -Filter log4j*.jar `
        | Select-Object -ExpandProperty FullName `
        | .\Remove-ClassFromJar -Class 'JMSAppender'

.EXAMPLE
    # Remove a classe Foo de todos os arquivos .jar em
    # C:\Programs\lib
    Get-ChildItem -Filter *.jar | Select-Object -ExpandProperty FullName `
        | .\Remove-ClassFromJar -Class "foo"

.EXAMPLE
    # Remove a classe MeuObjeto do arquivo em C:\Users\Eu\Documentos\meu.jar
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