<#
.SYNOPSIS
    Windows Application Compatibility Database is used by windows to identify possible application compatibility challenges with executables.
    Any executable that runs on a Windows system can be found in this key.
	ShimcacheParser.ps1 parses the Registry Application Compatibility Cache on a live system, more common called Shimcache, and exports it to a CSV and/or HTML file.
    Working for versions: Win10, Win8.1 x64, Win7 x64, Win7 x86

.DESCRIPTION
	ShimcacheParser.ps1 parses the Registry Application Compatibility Cache on a live system, more common called Shimcache, and exports it to a CSV and/or HTML file.

.EXAMPLE
	ShimcacheParser.ps1 -CSV

.EXAMPLE
	ShimcacheParser.ps1 -HTML


.NOTES
    Author:  f4d0
    Last Updated: 2019.05.17
	
	Thanks to Eric Zimmerman: https://github.com/EricZimmerman/AppCompatCacheParser
	Thanks to Joachim Metz: https://github.com/libyal/winreg-kb/blob/master/documentation/Application%20Compatibility%20Cache%20key.asciidoc

.LINK
    f4d0.eu
#>

param (
    
    <# Export information to CSV format #>
    [switch]$CSV=$false,
    
    <# Export information to HTML format #>
    [switch]$HTML=$false,

    <# Show information in the screen #>
    [switch]$SCREEN=$false
)

if($CSV -eq $false -and $HTML -eq $false -and $SCREEN -eq $false)
{
    cls

    echo ""
    echo ""
    Write-Host "`tNo output option selected. To get more info, please type:" -ForegroundColor Red
    Write-Host "`t`tGet-Help ShimcacheParser.ps1" -ForegroundColor Green
    
    echo ""
    echo ""
    echo ""

    exit
}

Function Write-Html-Header{
    echo "<!DOCTYPE HTML PUBLIC `"-//W3C//DTD HTML 3.2 Final//EN`">" > "$($hostname)_Shimcache.html"
    echo "<html><head><title> SHIMCACHE </title></head>" >> "$($hostname)_Shimcache.html"
    echo "<body>" >> "$($hostname)_Shimcache.html"
    echo "<h4>Shimcache Parser</h4>"
    echo "<br><h4>Creators webpage: <a href=`"http://f4d0.eu/`" target=`"newwin`">http://www.f4d0.eu</a></h4><h4>Creators github: <a href=`"https://github.com/nrrpinto`" target=`"newwin`">https://github.com/nrrpinto</a></h4><p>" >> "$($hostname)_Shimcache.html"
    echo "<table border=`"1`" cellpadding=`"5`"><tr bgcolor=`"E0E0E0`"> " >> "$($hostname)_Shimcache.html"
    echo "<th>Position" >> "$($hostname)_Shimcache.html"
    echo "<th>Path" >> "$($hostname)_Shimcache.html"
    echo "<th>Modified" >> "$($hostname)_Shimcache.html"
}

Function Write-Html-Line{
    param(
        [string]$position = "",
        [string]$path = "",
        [string]$modified = ""
    )

    echo "<tr><td bgcolor=#FFFFFF nowrap> $position <td bgcolor=#FFFFFF nowrap> $path <td bgcolor=#FFFFFF nowrap> $modified" >> "$($hostname)_Shimcache.html"
}

Function Write-Html-Finish {
    echo "</table>" >> "$($hostname)_Shimcache.html"
    echo "</body></html>" >> "$($hostname)_Shimcache.html"
}

$OS = ((Get-WmiObject win32_operatingsystem).name).split(" ")[2] 
$ARCH = $env:PROCESSOR_ARCHITECTURE
    

if($OS -eq "10") <# TESTED: Win10 #>
{
    $content = Get-ItemPropertyValue "REGISTRY::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\AppCompatCache" -Name AppCompatCache
    $index=[System.BitConverter]::ToInt32($content,0)
    $Position = 0

    if($CSV) { echo "Position, Path, Modified" > "$($hostname)_Shimcache.csv" }
    if($HTML) { Write-Html-Header }
    if($SCREEN) { Write-Host "Position | Path | Modified" -ForegroundColor Green }

    while($index -lt $content.length)
    {
    
        $Position++
        #echo "Position: $Position"
        $signature = [System.Text.Encoding]::ASCII.GetString($content,$index,4)
        $index += 4

        if($signature -notlike "10ts")
        {
            break
        }

        $unknown = [System.Text.Encoding]::ASCII.GetString($content,$index,4)
        $index += 4
        #echo "Unknown: $unknown"

        $DataSize = [System.BitConverter]::ToUInt32($content,$index)
        $index += 4
        #echo "Data Size: $DataSize"

        $PathSize = [System.BitConverter]::ToUInt16($content,$index)
        $index += 2
        #echo "Path Size: $PathSize"

        $Path = [System.Text.Encoding]::Unicode.GetString($content, $index, $PathSize)
        if($Path -notlike "*:\*"){
            $temp = $($Path.Split("`t")[4])
            if($temp -eq $null){}
            else {$Path = $temp}
        }
        $index += $PathSize
        #echo "Path: $Path"

        $DateTimeOffset = [System.DateTimeOffset]::FromFileTime([System.BitConverter]::ToInt64($content,$index))
        $LastModifiedTimeUTC = $($DateTimeOffset.UtcDateTime)
        #echo "LastModifiedTimeUTC: $LastModifiedTimeUTC"
        $index += 8
    

        $DataSize = [System.BitConverter]::ToInt32($content, $index)
        $index += 4
        #echo "Data Size: $DataSize"

        $Data = [System.Text.Encoding]::Unicode.GetString($content, $index, $DataSize)
        $index += $DataSize
        #echo "Data: $Data"

        if($CSV) { echo "$Position, $Path, $LastModifiedTimeUTC" >> "$($hostname)_Shimcache.csv" }
        if($HTML) { Write-Html-Line -position $Position -path $Path -modified $LastModifiedTimeUTC }
        if($SCREEN) { echo "$Position | $Path | $LastModifiedTimeUTC"}

    }
}

if($OS -like "8*") <# TESTED: Win8.1x64 #>
{
    $regKey = Get-ItemProperty "REGISTRY::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\AppCompatCache" 
    $content = $regKey.AppCompatCache
    $index=128
    $Position = 0

    if($CSV) { echo "Position, Path, Modified" > "$($hostname)_Shimcache.csv" }
    if($HTML) { Write-Html-Header }
    if($SCREEN) { Write-Host "Position | Path | Modified" -ForegroundColor Green }

    while($index -lt $content.length)
    {
    
        $Position++
        #echo "Position: $Position"
        $signature = [System.Text.Encoding]::ASCII.GetString($content,$index,4)
        $index += 4

        if($signature -notlike "10ts" -and $signature -notlike "00ts")
        {
            break
        }

        $unknown = [System.Text.Encoding]::ASCII.GetString($content,$index,4)
        $index += 4
        #echo "Unknown: $unknown"

        $DataSize = [System.BitConverter]::ToUInt32($content,$index)
        $index += 4
        #echo "Data Size: $DataSize"

        $PathSize = [System.BitConverter]::ToUInt16($content,$index)
        $index += 2
        #echo "Path Size: $PathSize"

        $Path = [System.Text.Encoding]::Unicode.GetString($content, $index, $PathSize)
        if($Path -like "\??*"){
            $temp = $Path.Replace("\??\","")
            $Path = $temp
        }
        $index += $PathSize
        #echo "Path: $Path"

        $PackageLen = [System.BitConverter]::ToUInt16($content,$index)
        $index += 2
        #echo "Package Length: $PackageLen"

        $Package = [System.Text.Encoding]::Unicode.GetString($content, $index, $PackageLen)
        if($Package -like "*`t*"){
            $temp = $($Package.Split("`t")[3])
            if($temp -eq $null){}
            else {$Package = $temp}
        }
        $index += $PackageLen
        #echo "Package: $Package"

        $Flags = [System.BitConverter]::ToInt64($content, $index)
        $index += 8
        #echo "Flags: $Flags"

        $DateTimeOffset = [System.DateTimeOffset]::FromFileTime([System.BitConverter]::ToInt64($content,$index))
        $LastModifiedTimeUTC = $($DateTimeOffset.UtcDateTime)
        #echo "LastModifiedTimeUTC: $LastModifiedTimeUTC"
        $index += 8

        $DataSize = [System.BitConverter]::ToInt32($content, $index)
        $index += 4
        #echo "Data Size: $DataSize"

        $Data = [System.Text.Encoding]::Unicode.GetString($content, $index, $DataSize)
        $index += $DataSize
        #echo "Data: $Data"

        if ($Path -eq "") 
        { 
            
            if($CSV) { echo "$Position, Package:\$Package, $LastModifiedTimeUTC" >> "$($hostname)_Shimcache.csv" }
            if($HTML) { Write-Html-Line -position $Position -path "Package:\$Package" -modified $LastModifiedTimeUTC }
            if($SCREEN) { echo "$Position | Package:\$Package | $LastModifiedTimeUTC"}
        }
        else 
        { 
            if($CSV) { echo "$Position, $Path, $LastModifiedTimeUTC" >> "$($hostname)_Shimcache.csv" }
            if($HTML) { Write-Html-Line -position $Position -path $Path -modified $LastModifiedTimeUTC }
            if($SCREEN) { echo "$Position | $Path | $LastModifiedTimeUTC"}
        }

        

    }
}

if($OS -eq "7") <# TESTED: Win7x64, Win7x86 #>
{
    $regKey = Get-ItemProperty "REGISTRY::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\AppCompatCache" 
    $content = $regKey.AppCompatCache
    $index=128
    $Position = 0
    $limit = [System.BitConverter]::ToInt32($content, 4);
    #echo "Limit: $limit"

    if($CSV) { echo "Position, Path, Modified" > "$($hostname)_Shimcache.csv" }
    if($HTML) { Write-Html-Header }
    if($SCREEN) { Write-Host "Position | Path | Modified" -ForegroundColor Green }

    while($index -lt $content.length)
    {
        if($ARCH -eq "AMD64") # x64 arch
        {
            $Position++
            #echo "Position: $Position"

            $PathSize = [System.BitConverter]::ToUInt16($content,$index)
            $index += 2
            #echo "Path Size: $PathSize"

            $MaxPathSize = [System.BitConverter]::ToUInt16($content,$index)
            $index += 2
            #echo "Max Path Size: $MaxPathSize"

            $unknown = [System.Text.Encoding]::ASCII.GetString($content,$index,4)
            $index += 4
            #echo "Unknown: $unknown"

            $PathOffset = [System.BitConverter]::ToInt64($content,$index)
            $index += 8
            #echo "Path Offset: $PathOffset"

            $DateTimeOffset = [System.DateTimeOffset]::FromFileTime([System.BitConverter]::ToInt64($content,$index))
            $LastModifiedTimeUTC = $($DateTimeOffset.UtcDateTime)
            $index += 8
            #echo "Last Modified Time UTC: $LastModifiedTimeUTC"
            
            $flags = [System.Text.Encoding]::ASCII.GetString($content,$index,4)
            $index += 4
            #echo "flags: $flags"

            $shimflags = [System.Text.Encoding]::ASCII.GetString($content,$index,4)
            $index += 4
            #echo "shim flags: $shimflags"

            $DataSize = [System.BitConverter]::ToUInt64($content,$index)
            $index += 8
            #echo "Data Size: $DataSize"

            $DataOffset = [System.BitConverter]::ToUInt64($content,$index)
            $index += 8
            #echo "Data Offset: $DataOffset"

            $Path = [System.Text.Encoding]::Unicode.GetString($content, $PathOffset, $PathSize)
            $Path = $Path.Replace("\??\","")
            #echo "Path: $Path"


            if ($Position -eq $limit) { break }
        }
        else # x86 arch
        {
            $Position++
            echo "Position: $Position"

            $PathSize = [System.BitConverter]::ToUInt16($content,$index)
            $index += 2
            echo "Path Size: $PathSize"

            $MaxPathSize = [System.BitConverter]::ToUInt16($content,$index)
            $index += 2
            echo "Max Path Size: $MaxPathSize"

            $PathOffset = [System.BitConverter]::ToInt32($content,$index)
            $index += 4
            echo "Path Offset: $PathOffset"

            $DateTimeOffset = [System.DateTimeOffset]::FromFileTime([System.BitConverter]::ToInt64($content,$index))
            $LastModifiedTimeUTC = $($DateTimeOffset.UtcDateTime)
            $index += 8
            echo "Last Modified Time UTC: $LastModifiedTimeUTC"
            
            $flags = [System.BitConverter]::ToInt32($content,$index)
            $index += 4
            echo "flags: $flags"

            $shimflags = [System.BitConverter]::ToInt32($content,$index)
            $index += 4
            echo "shim flags: $shimflags"

            $DataSize = [System.BitConverter]::ToUInt64($content,$index)
            $index += 4
            echo "Data Size: $DataSize"

            $DataOffset = [System.BitConverter]::ToUInt64($content,$index)
            $index += 4
            echo "Data Offset: $DataOffset"

            $Path = [System.Text.Encoding]::Unicode.GetString($content, $PathOffset, $PathSize)
            $Path = $Path.Replace("\??\","")
            echo "Path: $Path"


            if ($Position -eq $limit) { break }
        }

        if($CSV) { echo "$Position, $Path, $LastModifiedTimeUTC" >> "$($hostname)_Shimcache.csv" }
        if($HTML) { Write-Html-Line -position $Position -path $Path -modified $LastModifiedTimeUTC }
        if($SCREEN) { echo "$Position | $Path | $LastModifiedTimeUTC"}
    }
}

if($HTML) { Write-Html-Finish }