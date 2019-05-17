<#
.SYNOPSIS
	ShimcacheParser.ps1 parses the Registry Application Compatibility Cache on a live system, more common called Shimcache, and exports it to a CSV file.
    Working for versions: Win10, Win8.1 x64, Win7 x64, Win7 x86

.EXAMPLE
	ShimcacheParser.ps1

.NOTES
    Author:  f4d0
    Last Updated: 2019.05.17
	
	Thanks to Eric Zimmerman: https://github.com/EricZimmerman/AppCompatCacheParser
	Thanks to Joachim Metz: https://github.com/libyal/winreg-kb/blob/master/documentation/Application%20Compatibility%20Cache%20key.asciidoc

.LINK
    f4d0.eu
#>


$OS = ((Get-WmiObject win32_operatingsystem).name).split(" ")[2] 
$ARCH = $env:PROCESSOR_ARCHITECTURE
    

if($OS -eq "10") <# TESTED: Win10 #>
{
    $content = Get-ItemPropertyValue "REGISTRY::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\AppCompatCache" -Name AppCompatCache
    $index=[System.BitConverter]::ToInt32($content,0)
    $Position = 0

    echo "Position, Path, Modified" > Shimcache.csv

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

        echo "$Position, $Path, $LastModifiedTimeUTC" >> Shimcache.csv

    }
}

if($OS -like "8*") <# TESTED: Win8.1x64 #>
{
    $regKey = Get-ItemProperty "REGISTRY::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\AppCompatCache" 
    $content = $regKey.AppCompatCache
    $index=128
    $Position = 0

    echo "Position, Path, Modified" > Shimcache.csv

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

        if ($Path -eq "") { echo "$Position, Package:\$Package, $LastModifiedTimeUTC" >> Shimcache.csv }
        else { echo "$Position, $Path, $LastModifiedTimeUTC" >> Shimcache.csv }

    }
}

if($OS -eq "7") <# TESTED: Win7x64, Win7x86 #>
{
    $regKey = Get-ItemProperty "REGISTRY::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\AppCompatCache" 
    $content = $regKey.AppCompatCache
    $index=128
    $Position = 0
    $limit = [System.BitConverter]::ToInt32($content, 4);
    echo "Limit: $limit"

    echo "Position, Path, Modified" > Shimcache.csv

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


            echo "$Position, $Path, $LastModifiedTimeUTC" >> Shimcache.csv
            
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


            echo "$Position, $Path, $LastModifiedTimeUTC" >> Shimcache.csv
            
            if ($Position -eq $limit) { break }
        }
    }
}