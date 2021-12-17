<#
.SYNOPSIS
    Converts a path that is too long (see Win32 path length limitations)
    overcoming the path length limitation.

.DESCRIPTION
    By appending \\?\ to a path it is possible to overcome the win32 path
    length limitation. This script converts paths that are too long, that
    is paths that are longer than the MAX_PATH limitation to a usable path
    by appending \\?\ or \\?\UNC\ in the case of Universal Naming Convention
    paths.

.PARAMETER Path
    String containing the full path that is to be converted.

.OUTPUTS
    The script outputs the converted path.

.EXAMPLE
    Get-ChildItem -File -LiteralPath "C:\SomeDir\WithLongPaths" `
        | Select-Object -ExpandProperty FullName `
        | .\Convert-Win32LongPath.ps1 `
        | Compress-Archive -Force -DestinationPath .\SomeZipWithLongPathsWithin.zip

.NOTES
    Author: Pedro T Freidinger (pedrotersetti3@gmail.com)
    License: MIT (github.com/pedroter7/useful_scripts)
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true,
                ValueFromPipeline=$true)]
        [string]$Path
)

begin {
    Set-Variable -Name 'MAX_PATH' -Value 256
}
process {
    $Path = $Path.Trim()

    if ($Path.Length -gt $MAX_PATH) {
        if ($Path.StartsWith('\\')) { # Assumed Universal Naming Convention path
            $Path = $Path.Replace('\\', '\\?\UNC\')
        } else {
            $Path = '\\?\' + $Path
        }
    }

    $Path
}