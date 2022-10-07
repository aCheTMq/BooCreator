#
# Boo Creator v. 1.0 - Feature ISO Downloader, for retail Windows images and
# a tool for creating bootable disks
# Copyright © 2022 Baruzdin Alexey
#    https://youtube.com/channel/UChyAYOcXxvjdDU3Blg_mDmg
#    https://zen.yandex.ru/aCheTMq
#    https://github.com/aCheTMq/BooCreator
#    just.so@mail.ru
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

Clear-Host

[Int]$gDiskNumber = -1
[String]$gISOFile = $null
[String]$gScriptDir = $PSScriptRoot + "\"
[String]$gScriptPath = $PSCommandPath
$Script:gLang = @()
[Int]$gLangIndex = 0

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $argsList = "-File " + """" + $gScriptPath + """"

    Write-Host "Run As Administrator…"
    Start-Process powershell -Verb runAs -ArgumentList $argsList
    Exit
}

function Create-BootableDisk($ISOFile = $null, $DiskNumber = -1) {
    $diskNumber = $DiskNumber
    $isoFile = $ISOFile
    $letters = @("C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z")

    if ($diskNumber -eq -1) { $diskNumber = $gDiskNumber }
    if ($isoFile -eq $null) { $isoFile = $gISOFile }
    
    $editDisk = Get-Disk -Number $diskNumber
    $editDiskName = $editDisk.Number.ToString() + ": " + $editDisk.FriendlyName
    $isoDisk = $null
    $isoPoint = $null

    Clear-Host
    Show-Header

    Write-Host $gLang[52].Replace("%1%", $isoFile) -NoNewline
    try {
        $isoPoint = Mount-DiskImage -ImagePath $isoFile -Confirm:$false -PassThru -ErrorAction SilentlyContinue
    }
    catch { $isoPoint = $null }
    
    if($isoPoint -eq $null) {
        Write-Host $gLang[73]
        Write-Host $gLang[53].Replace("%1%", $isoFile) -BackgroundColor Yellow -ForegroundColor Red
        Start-Sleep -Seconds 2
        return -1
    } else { Start-Sleep -Seconds 1 }
    
    try {
        $isoDisk = Get-DiskImage -ImagePath $isoFile -ErrorAction SilentlyContinue
    }
    catch { $isoDisk = $null }

    if($isoDisk -eq $null) {
        Write-Host $gLang[73]
        Write-Host $gLang[53].Replace("%1%", $isoFile) -BackgroundColor Yellow -ForegroundColor Red
        Start-Sleep -Seconds 2
        return -1
    } else { Start-Sleep -Seconds 1 }

    $isoVol = $isoDisk | Get-Volume
    $isoDiskLetter = $isoVol.DriveLetter
    $isoDiskDir = $isoDiskLetter + ":\"
    $copyPath = $isoDiskLetter + ":\*"
    Write-Host $gLang[54]
    
    $bootableDiskLetter = $null
    foreach($let in $letters)
    {
        try {
            $volItem = Get-Volume -DriveLetter $let -ErrorAction SilentlyContinue
            if ($volItem -eq $null) { $bootableDiskLetter = $let; break; }
        } catch { }
    }
    if($bootableDiskLetter -eq $null) {
        Write-Host $gLang[73]
        Write-Host $gLang[55].Replace("%1%", $isoFile) -NoNewline
        Dismount-DiskImage -ImagePath $isoFile -ErrorAction SilentlyContinue
        Write-Host $gLang[54]

        Write-Host $gLang[56] -BackgroundColor Yellow -ForegroundColor Red
        Start-Sleep -Seconds 2
        return -1
    }
    $bootableDiskDir = $bootableDiskLetter + ":\"

    Write-Host
    Write-Host $gLang[57].Replace("%1%", $editDiskName)
    Write-Host $gLang[58].Replace("%1%", $editDiskName) -NoNewline
    try {
        Clear-Disk -Number $diskNumber -RemoveData -RemoveOEM -Confirm:$false -ErrorAction SilentlyContinue
        Write-Host $gLang[54]
    }
    catch {
        Write-Host $gLang[73]
        Write-Host $gLang[55].Replace("%1%", $isoFile) -NoNewline
        Dismount-DiskImage -ImagePath $isoFile -ErrorAction SilentlyContinue
        Write-Host $gLang[54]

        Write-Host $gLang[59].Replace("%1%", $editDiskName) -BackgroundColor Yellow -ForegroundColor Red
        Start-Sleep -Seconds 2
        return -1
    }
    Start-Sleep -Seconds 1
    
    Write-Host $gLang[60].Replace("%1%", $editDiskName) -NoNewline
    try {
        Set-Disk -Number $diskNumber -PartitionStyle MBR -ErrorAction SilentlyContinue
        Write-Host $gLang[54]
    }
    catch {
        Write-Host $gLang[73]
        Write-Host $gLang[55].Replace("%1%", $isoFile) -NoNewline
        Dismount-DiskImage -ImagePath $isoFile -ErrorAction SilentlyContinue
        Write-Host $gLang[54]

        Write-Host $gLang[59].Replace("%1%", $editDiskName) -BackgroundColor Yellow -ForegroundColor Red
        Start-Sleep -Seconds 2
        return -1
    }
    Start-Sleep -Seconds 1
    
    Write-Host $gLang[61].Replace("%1%", $editDiskName) -NoNewline
    $bootablePart = $null
    try {
        $bootablePart = New-Partition -DiskNumber $diskNumber -UseMaximumSize -MbrType FAT32 -IsActive -ErrorAction SilentlyContinue
        Write-Host $gLang[54]
    }
    catch {
        Write-Host $gLang[73]
        Write-Host $gLang[55].Replace("%1%", $isoFile) -NoNewline
        Dismount-DiskImage -ImagePath $isoFile -ErrorAction SilentlyContinue
        Write-Host $gLang[54]

        Write-Host $gLang[59].Replace("%1%", $editDiskName) -BackgroundColor Yellow -ForegroundColor Red
        Start-Sleep -Seconds 2
        return -1
    }
    Start-Sleep -Seconds 1
    
    Write-Host $gLang[62].Replace("%1%", $editDiskName) -NoNewline
    try {
        Format-Volume -Partition $bootablePart -FileSystem "FAT32" -Force -ErrorAction SilentlyContinue
        Write-Host $gLang[54]
    }
    catch {
        Write-Host $gLang[73]
        Write-Host $gLang[55].Replace("%1%", $isoFile) -NoNewline
        Dismount-DiskImage -ImagePath $isoFile -ErrorAction SilentlyContinue
        Write-Host $gLang[54]

        Write-Host $gLang[59].Replace("%1%", $editDiskName) -BackgroundColor Yellow -ForegroundColor Red
        Start-Sleep -Seconds 2
        return -1
    }
    Start-Sleep -Seconds 1

    Write-Host $gLang[63].Replace("%1%", $bootableDiskLetter) -NoNewline
    try {
        Set-Partition -InputObject $bootablePart -NewDriveLetter $bootableDiskLetter -ErrorAction SilentlyContinue
        Set-Volume -DriveLetter $bootableDiskLetter -NewFileSystemLabel "ACHETMQ" -ErrorAction SilentlyContinue
        Write-Host $gLang[54]
    }
    catch {
        Write-Host $gLang[73]
        Write-Host $gLang[55].Replace("%1%", $isoFile) -NoNewline
        Dismount-DiskImage -ImagePath $isoFile -ErrorAction SilentlyContinue
        Write-Host $gLang[54]

        Write-Host $gLang[59].Replace("%1%", $editDiskName) -BackgroundColor Yellow -ForegroundColor Red
        Start-Sleep -Seconds 2
        return -1
    }
    Start-Sleep -Seconds 1

    $shell = New-Object -ComObject Shell.Application
    $shell.Windows() | Format-Table Name, LocationName, LocationURL
    $shell = New-Object -ComObject Shell.Application
    $window = $shell.Windows() | Where-Object { $_.LocationName -like "ACHETMQ*" }
    if($window -ne $null) { $window.Quit() }

    $exclude = @("install.wim")
    $installWim = $isoDiskDir + "sources\install.wim"
    $installSwm = $bootableDiskDir + "sources\install.swm"
    $sourcesDir = $bootableDiskDir + "sources\"
    
    if(Test-Path -Path $installWim) {
        Write-Host
        Write-Host $gLang[71]

        $fileItem = Get-Item -Path $installWim
        if ($fileItem.Length -gt 4294966272) {
            Write-Host $gLang[64]
            Write-Host $gLang[65] -NoNewline
            New-Item -Path $sourcesDir -ItemType Directory -ErrorAction SilentlyContinue
            DISM.exe /Split-Image /ImageFile:$installWim /SWMFile:$installSwm /FileSize:3968
            Write-Host $gLang[54]
        }
    }

    Write-Host $gLang[64]
    Write-Host $gLang[66] -NoNewline
    try { 
        Copy-Item -Path $copyPath -Destination $bootableDiskDir -Exclude $exclude -Confirm:$false -Force -Recurse -ErrorAction SilentlyContinue
        Write-Host $gLang[54]
    }
    catch {
        Write-Host $gLang[73]
        Write-Host $gLang[55].Replace("%1%", $isoFile) -NoNewline
        Dismount-DiskImage -ImagePath $isoFile -ErrorAction SilentlyContinue
        Write-Host $gLang[54]

        Write-Host $gLang[67] -BackgroundColor Yellow -ForegroundColor Red
        Start-Sleep -Seconds 2
        return -1
    }

    Write-Host
    Write-Host $gLang[72].Replace("%1%", $isoFile) -NoNewline
    try {
        Dismount-DiskImage -ImagePath $isoFile -ErrorAction SilentlyContinue
        Write-Host $gLang[54]
    }
    catch {
        Write-Host $gLang[73]
        Write-Host $gLang[68].Replace("%1%", $isoFile) -BackgroundColor Yellow -ForegroundColor Red
        Start-Sleep -Seconds 2
    }

    Write-Host
    Write-Host $gLang[69]
    Write-Host $gLang[70] -NoNewline
    Read-Host
}

function Download-Windows([Int]$Version) {
    $downloadPages = @("https://www.microsoft.com/en-us/software-download/windows11",
                        "https://www.microsoft.com/en-us/software-download/windows10ISO",
                        "https://www.microsoft.com/en-us/software-download/windows8ISO",
                        "")
    $patterns1 = @("<select.*?>(.*?)<.select>",
                    "<select.*?>(.*?)<.select>",
                    "<select.*?>(.*?)<.select>",
                    "")
    $patterns2 = @('<option value="(\d+\W?)">(.*?)<',
                    '<option value="(\d+\W?)">(.*?)<',
                    '<option value="(\d+\W?)">(.*?)<',
                    '')
    $patterns3 = @("<option value=""{""id"":""(.*?)"",""language"":""(.*?)""}"">(.*?)<",
                    "<option value=""{""id"":""(.*?)"",""language"":""(.*?)""}"">(.*?)<",
                    "<option value=""{""id"":""(.*?)"",""language"":""(.*?)""}"">(.*?)<",
                    "")
    $patterns4 = @("<input.*?value=""{.*?""Uri"": ""(.*?)"".*?"".*?""DownloadType"": (.*?)}"".*?>",
                    "<input.*?value=""{.*?""Uri"": ""(.*?)"".*?"".*?""DownloadType"": (.*?)}"".*?>",
                    "<input.*?value=""{.*?""Uri"": ""(.*?)"".*?"".*?""DownloadType"": (.*?)}"".*?>",
                    "")
    $sessionId = [guid]::NewGuid()
    $userAgents = @("Mozilla/5.0 (X11; Linux i586; rv:$FirefoxVersion.0) Gecko/$FirefoxDate Firefox/$FirefoxVersion.0",
                    "Mozilla/5.0 (Linux; Android 5.0; SM-G900P Build/LRX21T) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.98 Mobile Safari/537.36",
                    "Mozilla/5.0 (X11; Linux i586; rv:$FirefoxVersion.0) Gecko/$FirefoxDate Firefox/$FirefoxVersion.0",
                    "")


    $editionsList = @()
    $editionPOSTs = @("https://www.microsoft.com/en-us/api/controls/contentinclude/html?pageId=a8f8f489-4c7f-463a-9ca6-5cff94d8d041&host=www.microsoft.com&segments=software-download,windows11&query=&action=getskuinformationbyproductedition&sessionId=%1%&productEditionId=%2%&sdVersion=2",
                    "https://www.microsoft.com/en-us/api/controls/contentinclude/html?pageId=a8f8f489-4c7f-463a-9ca6-5cff94d8d041&host=www.microsoft.com&segments=software-download,windows10ISO&query=&action=getskuinformationbyproductedition&sessionId=%1%&productEditionId=%2%&sdVersion=2",
                    "https://www.microsoft.com/en-us/api/controls/contentinclude/html?pageId=a8f8f489-4c7f-463a-9ca6-5cff94d8d041&host=www.microsoft.com&segments=software-download,windows8iso&query=&action=getskuinformationbyproductedition&sessionId=%1%&productEditionId=%2%&sdVersion=2",
                    "")
    $editionPost = $editionPOSTs[$Version]
    $editionPost = $editionPost.Replace("%1%", $sessionId)
    $editionIndex = 0
    $editionSelect = 0

    $languagesList = @()
    $languagePOSTs = @("https://www.microsoft.com/en-us/api/controls/contentinclude/html?pageId=6e2a1789-ef16-4f27-a296-74ef7ef5d96b&host=www.microsoft.com&segments=software-download,windows11&query=&action=GetProductDownloadLinksBySku&sessionId=%1%&skuId=%2%&language=%3%&sdVersion=2",
                        "https://www.microsoft.com/en-us/api/controls/contentinclude/html?pageId=a224afab-2097-4dfa-a2ba-463eb191a285&host=www.microsoft.com&segments=software-download,windows10ISO&query=&action=GetProductDownloadLinksBySku&sessionId=%1%&skuId=%2%&language=%3%&sdVersion=2",
                        "https://www.microsoft.com/en-us/api/controls/contentinclude/html?pageId=cfa9e580-a81e-4a4b-a846-7b21bf4e2e5b&host=www.microsoft.com&segments=software-download,windows8iso&query=&action=GetProductDownloadLinksBySku&sessionId=%1%&skuId=%2%&language=%3%&sdVersion=2",
                        "")
    $languagePost = $languagePOSTs[$Version]
    $languagePost = $languagePost.Replace("%1%", $sessionId)
    $languageIndex = 0
    $languageSelect = 0

    $archsList = @()
    $archIndex = 0
    $archSelect = 0

    Clear-Host
    Show-Header

    Write-Host $gLang[74] -NoNewline
    if($Version -ne 3) {
        $html = Invoke-WebRequest -UseBasicParsing -UserAgent $userAgents[$Version] -WebSession $SavedSession -SessionVariable "Session" $downloadPages[$Version]
        [System.Text.RegularExpressions.Regex]$regex = [System.Text.RegularExpressions.Regex]::new($patterns1[$Version])
        [System.Text.RegularExpressions.Match]$match = $regex.Match($html)

        $windowsEditions = $match.Groups[0].Value
        $regex = [System.Text.RegularExpressions.Regex]::new($patterns2[$Version])
        $match = $regex.Match($windowsEditions)

        while ($match.Success) {
            $editionsList += ,@($match.Groups[1].Value, $match.Groups[2].Value)
            $editionName = $match.Groups[2].Value
            $match = $match.NextMatch()
        }
    }
    else {
        $editionsList += ,@("", "Windows 7 Ultimate")
        $editionsList += ,@("", "Windows 7 Professional")
        $editionsList += ,@("", "Windows 7 Home Premium")
    }
    Write-Host $gLang[54]

    Write-Host $gLang[75]
    foreach($editionItem in $editionsList) {
        $editionName = $editionsList[$editionIndex][1]
        Write-Host "			$editionIndex. $editionName"
        $editionIndex += 1
    }
    Write-Host

    if($editionIndex -ne 1) {
        $editionIndex -= 1
        Write-Host $gLang[76]
        Write-Host $gLang[77].Replace("%1%", $editionIndex)
        Write-Host $gLang[78]
        Write-Host
        $editionSelect = Read-Host $gLang[79]
        $editionSelect = $editionSelect.ToLower()
        [Int]$editionSelectInt = -1
        try { $editionSelectInt = $editionSelect } catch {}

        if(($editionSelect -eq $gLang[44]) -or ($editionSelect -eq $gLang[45])) { return 0 }
        if (($editionSelect -ge 0) -and ($editionSelect -le $editionIndex)) { $editionName = $editionsList[$editionSelect][1] }
        else { return 0 }
    }
    $editionPost = $editionPost.Replace("%2%", $editionsList[$editionSelect][0])
    Write-Host $gLang[80].Replace("%1%", $editionName)

    Write-Host
    Write-Host $gLang[81] -NoNewline
    if($Version -ne 3) {
        $webRequest = [System.Net.WebRequest]::Create($editionPost)
	    $webRequest.Method = "POST"
	    $webRequest.Referer = $downloadPages[$Version]
	    $webRequest.UserAgent = $userAgents[$Version]
	    $webRequest.ContentLength = 0
	    $streamReader = New-Object System.IO.StreamReader($webRequest.GetResponse().GetResponseStream())
	    $html = $streamReader.ReadToEnd().ToString()
        $html = $html.Replace("&quot;", """")
        $streamReader.Dispose()
        
        $streamReader.Dispose()

        $regex = [System.Text.RegularExpressions.Regex]::new($patterns3[$Version])
        $match = $regex.Match($html)

        while ($match.Success) {
            $languagesList += ,@($match.Groups[1].Value, $match.Groups[2].Value, $match.Groups[3].Value)
            $languageName = $match.Groups[2].Value
            $match = $match.NextMatch()
        }
    }
    else {
        $languagesList += ,@("", "English", "English")
    }
    Write-Host $gLang[54]

    Write-Host $gLang[82]
    foreach($languageItem in $languagesList) {
        $languageName = $languagesList[$languageIndex][1]
        Write-Host "			$languageIndex. $languageName"
        $languageIndex += 1
    }
    Write-Host

    if($languageIndex -ne 1) {
        $languageIndex -= 1
        Write-Host $gLang[76]
        Write-Host $gLang[83].Replace("%1%", $languageIndex)
        Write-Host $gLang[78]
        Write-Host
        $languageSelect = Read-Host $gLang[79]
        $languageSelect = $languageSelect.ToLower()
        [Int]$languageSelectInt = -1
        try { $languageSelectInt = $languageSelect } catch {}

        if(($languageSelect -eq $gLang[44]) -or ($languageSelect -eq $gLang[45])) { return 0 }
        if (($languageSelect -ge 0) -and ($languageSelect -le $languageIndex)) { $languageName = $languagesList[$languageSelect][1] }
        else { return 0 }
    }
    Write-Host $gLang[84].Replace("%1%", $languageName)
    $languagePost = $languagePost.Replace("%2%", $languagesList[$languageSelect][0])
    $languagePost = $languagePost.Replace("%3%", $languagesList[$languageSelect][1])
    #$languagePost = $languagePost.Replace(" ", "%20")
    #Write-Host $languagePost

    Write-Host
    Write-Host $gLang[85] -NoNewline
    if($Version -ne 3) {
        $webRequest = [System.Net.WebRequest]::Create($languagePost)
	    $webRequest.Method = "POST"
	    $webRequest.Referer = $downloadPages[$Version]
	    $webRequest.UserAgent = $userAgents[$Version]
	    $webRequest.ContentLength = 0
	    $streamReader = New-Object System.IO.StreamReader($webRequest.GetResponse().GetResponseStream())
	    $html = $streamReader.ReadToEnd().ToString()
        $html = $html.Replace("&quot;", """")
        $streamReader.Dispose()

        $regex = [System.Text.RegularExpressions.Regex]::new($patterns4[$Version])
        $match = $regex.Match($html)

        while ($match.Success) {
            $archNameItem = ($match.Groups[2].Value.ToString()).Replace(" ", "").Replace("Iso", "").Replace("ISO", "").Replace("iso", "").Replace("X", "x")
            $archsList += ,@($archNameItem, $match.Groups[1].Value.Replace("&amp;", "&"))
            $archName = $archNameItem
            $match = $match.NextMatch()
        }
    }
    else {
        if ($editionSelect -eq 0) {
            $archsList += ,@("x64", "https://download.microsoft.com/download/5/1/9/5195A765-3A41-4A72-87D8-200D897CBE21/7601.24214.180801-1700.win7sp1_ldr_escrow_CLIENT_ULTIMATE_x64FRE_en-us.iso")
            $archsList += ,@("x86", "https://download.microsoft.com/download/1/E/6/1E6B4803-DD2A-49DF-8468-69C0E6E36218/7601.24214.180801-1700.win7sp1_ldr_escrow_CLIENT_ULTIMATE_x86FRE_en-us.iso")
        }
        elseif ($editionSelect -eq 1) {
            $archsList += ,@("x64", "https://download.microsoft.com/download/0/6/3/06365375-C346-4D65-87C7-EE41F55F736B/7601.24214.180801-1700.win7sp1_ldr_escrow_CLIENT_PROFESSIONAL_x64FRE_en-us.iso")
            $archsList += ,@("x86", "https://download.microsoft.com/download/C/0/6/C067D0CD-3785-4727-898E-60DC3120BB14/7601.24214.180801-1700.win7sp1_ldr_escrow_CLIENT_PROFESSIONAL_x86FRE_en-us.iso")
        }
        elseif ($editionSelect -eq 2) {
            $archsList += ,@("x64", "https://download.microsoft.com/download/E/A/8/EA804D86-C3DF-4719-9966-6A66C9306598/7601.24214.180801-1700.win7sp1_ldr_escrow_CLIENT_HOMEPREMIUM_x64FRE_en-us.iso")
            $archsList += ,@("x86", "https://download.microsoft.com/download/E/D/A/EDA6B508-7663-4E30-86F9-949932F443D0/7601.24214.180801-1700.win7sp1_ldr_escrow_CLIENT_HOMEPREMIUM_x86FRE_en-us.iso")
        }

    }
    Write-Host $gLang[54]

    Write-Host $gLang[86]
    foreach($archsItem in $archsList) {
        $archName = $archsList[$archIndex][0]
        Write-Host "			$archIndex. $archName"
        $archIndex += 1
    }
    Write-Host

    if($archIndex -ne 1) {
        $archIndex -= 1
        Write-Host $gLang[76]
        Write-Host $gLang[87].Replace("%1%", $archIndex)
        Write-Host $gLang[78]
        Write-Host
        $archSelect = Read-Host $gLang[79]
        $archSelect = $archSelect.ToLower()
        [Int]$archSelectInt = -1
        try { $archSelectInt = $archSelect } catch {}

        if(($archSelect -eq $gLang[44]) -or ($archSelect -eq $gLang[45])) { return 0 }
        if (($archSelect -ge 0) -and ($archSelect -le $archIndex)) { $archName = $archsList[$archSelect][0] }
        else { return 0 }
    }
    Write-Host $gLang[88].Replace("%1%", $archName)
    
    Write-Host
    Write-Host $gLang[89]
    Write-Host $gLang[88].Replace("%1%", $editionName).Replace("%2%", $languageName).Replace("%3%", $archName) -NoNewline
    [String]$fileName = $editionName + "_" + $languageName + "_" + $archName + ".iso"
    $fileName = $gScriptDir + $fileName.Replace("  ", " ").Replace(" ", "_")
    $origPref = $ProgressPreference
    $ProgressPreference = "SilentlyContinue"
    Invoke-WebRequest -Uri $archsList[$archSelect][1] -OutFile $fileName
    Write-Host $archsList[$archSelect][1]
    $ProgressPreference = $origPref
    Write-Host $gLang[54]

    Start-Sleep -Seconds 2
}

function Get-AttributesString([Bool]$IsBoot, [Bool]$IsSystem) {
    $result = $null

    if ($IsBoot) { $result += $gLang[40] }
    if ($IsSystem) { $result += $gLang[41] }

    if ($null -ne $result) { $result = $result.Substring(2) }

    return $result
}

function Show-DiskMenu() {
    [Int]$addMenu = -1
    [Int]$result = -1

    do {
        Clear-Host
        Show-Header

        Write-Host $gLang[13]
        Write-Host $gLang[14]
        Write-Host $gLang[15]
        Write-Host $gLang[16]
        Write-Host

        $attributes = $null
        $disks = Get-Disk
        $disksIndex = [System.Collections.Generic.List[string]]::new()
        $diskTable = New-Object System.Data.Datatable
        [Int]$menuIndex = $addMenu
        [Int]$selectInt = 0

        [void]$diskTable.Columns.Add($gLang[17])
        [void]$diskTable.Columns.Add($gLang[18])
        [void]$diskTable.Columns.Add($gLang[19])
        [void]$diskTable.Columns.Add($gLang[20])
        [void]$diskTable.Columns.Add($gLang[21])
        [void]$diskTable.Columns.Add($gLang[22])
        
        foreach ($disk in $disks) {
            if ($disks.IsOffline -eq $false) {
                $attributes = Get-AttributesString $disk.IsBoot $disk.IsSystem
                $disksIndex.Add($disk.Number)

                [void]$diskTable.Rows.Add($disk.Number, $gLang[23] + $disk.FriendlyName, $disk.BusType, ($disk.Size / 1048576).ToString("N0"), $disk.PartitionStyle, $attributes)

                if ($disk.NumberOfPartitions -ne 0) {
                    $parts = Get-Partition -DiskNumber $disk.Number
                    $menuIndex += 1

                    foreach ($part in $parts) {
                        $attributes = Get-AttributesString $part.IsBoot $part.IsSystem
                        $partLetter = $gLang[24] + $part.DriveLetter + ":\"
                        if ($partLetter -eq $gLang[25]) { $partLetter = $gLang[26] }

                        [void]$diskTable.Rows.Add($null, $partLetter, $null, ($part.Size / 1048576).ToString("N0"), $null, $attributes)
                    }
                }

                [void]$diskTable.Rows.Add($gLang[28], $gLang[29], $gLang[30], $gLang[31], $gLang[32], $gLang[33])
            }
        }

        Format-Table -InputObject $diskTable -AutoSize -Wrap | Out-Host

        Write-Host $gLang[34]
        Write-Host $gLang[35]
        Write-Host $gLang[36]
        Write-Host

        Write-Host $gLang[37]
        Write-Host $gLang[38]
        Write-Host $gLang[39]
        Write-Host

        Write-Host $gLang[6]
        Write-Host $gLang[42].Replace("%1%", "$menuIndex")
        Write-Host $gLang[43]
        Write-Host
        
        $select = Read-Host $gLang[9]
        $select = $select.ToLower()

        try { [Int]$selectInt = $select } catch { $selectInt = -1 }
        
        if (($select -eq $gLang[44]) -or ($select -eq $gLang[45])) { $result = 1; break }
        if (($selectInt -ge 0) -and ($selectInt -le $menuIndex)) {
            $diskItem = Get-Disk -Number $selectInt
            $diskName = $diskItem.Number.ToString() + ": " + $diskItem.FriendlyName

            if ($diskItem.IsBoot -or $diskItem.IsSystem) { Write-Host $gLang[46].Replace("%1%", $diskName) -BackgroundColor Yellow -ForegroundColor Red; Start-Sleep -Seconds 2 }
            else {
                Write-Host
                Write-Host $gLang[47].Replace("%1%", $diskName)
                Write-Host $gLang[48].Replace("%1%", $diskName)
                Write-Host $gLang[49].Replace("%1%", $diskName) -NoNewline
                $agree = Read-Host
                $agree = $agree.ToLower()

                if (($agree -eq $gLang[50]) -or ($agree -eq $gLang[51])) { $gDiskNumber = $selectInt; Create-BootableDisk; $result = 1; break }
            }
        }
        else { Write-Host $gLang[10].Replace("%1%", $select) -BackgroundColor Yellow -ForegroundColor Red; Start-Sleep -Seconds 2 }
    }
    while ($result -eq -1)

    return $result
}

function Show-DownloadMenu() {
    $result = -1

    do {
        Clear-Host
        Show-Header

        Write-Host $gLang[91]
        Write-Host
        Write-Host "	1. Windows 11"
        Write-Host "	2. Windows 10"
        Write-Host "	3. Windows 8.1"
        Write-Host "	4. Windows 7"
        Write-Host
        Write-Host $gLang[6]
        Write-Host $gLang[92]
        Write-Host $gLang[43]
        Write-Host

        $select = Read-Host $gLang[9]
        $select = $select.ToLower()
        try { [Int]$selectInt = $select } catch { $selectInt = -1 }
        
        if (($select -eq $gLang[44]) -or ($select -eq $gLang[45])) { $result = 0; break }
        if ($selectInt -eq 1) { Download-Windows -Version 0 }
        elseif ($selectInt -eq 2) { Download-Windows -Version 1 }
        elseif ($selectInt -eq 3) { Download-Windows -Version 2 }
        elseif ($selectInt -eq 4) { Download-Windows -Version 3 }
        else { Write-Host $gLang[10].Replace("%1%", $select) -BackgroundColor Yellow -ForegroundColor Red; Start-Sleep -Seconds 2 }
    }
    while ($result -eq -1)

    return $result
}

function Show-Header() {
    Write-Host "----------------------------------------------------------------------------------------------------"
    Write-Host "|	Boo Creator v. 1.0                                                                             |"
    Write-Host "----------------------------------------------------------------------------------------------------"
    Write-Host "|	youtube.com/channel/UChyAYOcXxvjdDU3Blg_mDmg                                                   |"
    Write-Host "|	zen.yandex.ru/aCheTMq                                                                          |"
    Write-Host "|	github.com/aCheTMq/BooCreator                                                                  |"
    Write-Host "|	just.so@mail.ru                                                                                |"
    Write-Host "----------------------------------------------------------------------------------------------------"
    Write-Host
}

function Show-MainMenu() {
    [Int]$result = -1
    [Int]$addMenu = 3

    do {
        $files = Get-ChildItem -Path $gScriptDir -Filter "*.iso"
        [Int]$menuIndex = $addMenu - 1
        [Int]$selectInt = -1

        Clear-Host
        Show-Header

        Write-Host $gLang[0]
        Write-Host $gLang[1]
        Write-Host $gLang[2]
        Write-Host $gLang[3]
        Write-Host
        Write-Host $gLang[4]
        Write-Host $gLang[5]
        
        foreach($file in $files){ $menuIndex += 1; Write-Host "	$menuIndex. $file" }

        Write-Host
        Write-Host $gLang[6]
        Write-Host $gLang[7].Replace("%1%", $menuIndex)
        Write-Host $gLang[8]
        Write-Host

        $select = Read-Host $gLang[9]
        $select = $select.ToLower()
        try { [Int]$selectInt = $select } catch { $selectInt = -1 }
        
        if (($select -eq $gLang[11]) -or ($select -eq $gLang[12])) { $result = 0; break }
        if ($selectInt -eq 1) { Show-DownloadMenu }
        elseif ($selectInt -eq 2) {
            $gISOFile = Set-ISOPath $gScriptDir
            if(Test-Path $gISOFile) { $result = Show-DiskMenu }
        }
        elseif (($selectInt -ge 3) -and ($selectInt -le $menuIndex)) { $gISOFile = $gScriptDir + $files[$select - $addMenu]; $result = Show-DiskMenu }
        else { Write-Host $gLang[10].Replace("%1%", $select) -BackgroundColor Yellow -ForegroundColor Red; Start-Sleep -Seconds 2 }
    }
    while ($result -ne 0)

    return $result
}

function Set-ISOPath($Directory) {
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms”) | Out-Null

    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $Directory
    $OpenFileDialog.filter = "ISO (*.iso)| *.iso”
    $OpenFileDialog.ShowDialog() | Out-Null
    
    return $OpenFileDialog.filename
}

function Set-Language() {
    $langISO = $Host.CurrentCulture.TwoLetterISOLanguageName

    if ($langISO -eq "ru") {
        $decode = [System.Convert]::FromBase64String("XAB0ABIESwQxBDUEQAQ4BCAASQBTAE8AIABEBDAEOQQ7BCAAOAQ3BCAAOgQ+BEIEPgRABD4EMwQ+BCAARQQ+BEcENQRIBEwEIABBBDQENQQ7BDAEQgRMBCAANwQwBDMEQARDBDcEPgRHBD0EPgQ1BCAAQwRBBEIEQAQ+BDkEQQRCBDIEPgQuAFwAbgBcAHQAHwQ+BDgEQQQ6BCAANAQ4BEEEQgRABDgEMQRDBEIEOAQyBD4EMgQgAFcAaQBuAGQAbwB3AHMAIAA+BEEEQwRJBDUEQQRCBDIEOwRPBDUEQgRBBE8EIAAyBCAAOgQ+BEAEPQQ1BDIEPgQ5BCAAPwQwBD8EOgQ1BCwAIAAzBDQENQQgAEAEMARBBD8EPgQ7BD4ENgQ1BD0EIABBBDoEQAQ4BD8EQgQuAFwAbgBcAHQAGAQ7BDgEIAA3BDAEMwRABEMENwQ4BCAANAQ4BEEEQgRABDgEMQRDBEIEOAQyBCAAVwBpAG4AZABvAHcAcwAgAEkAUwBPACAAQQQgAEEEMAQ5BEIEMAQgAE0AaQBjAHIAbwBzAG8AZgB0ACAAPwRABDgEIAA/BD4EPAQ+BEkEOAQgADwENQQ9BE4EIAAWITEALgBcAG4AXAB0ABcEMAQzBEAEQwQ3BDoEMAQgADQEOARBBEIEQAQ4BDEEQwRCBDgEMgQwBCAAVwBpAG4AZABvAHcAcwAgADEEQwQ0BDUEQgQgAD8EQAQ+BDgEQQRFBD4ENAQ4BEIETAQgADIEIAA6BD4EQAQ9BDUEMgRDBE4EIAA/BDAEPwQ6BEMEIABBBDoEQAQ4BEIEPwQwBC4AXABuAFwAdAAxAC4AIAAhBDoEMARHBDAEQgRMBCAAVwBpAG4AZABvAHcAcwBcAG4AXAB0ADIALgAgACMEOgQwBDcEMARCBEwEIAA/BEMEQgRMBCAANAQ4BEEEQgRABDgEMQRDBEIEOAQyBCAAVwBpAG4AZABvAHcAcwAgAEkAUwBPAFwAbgBcAHQAJwRRBCAAPAQ+BDYEPQQ+BCAAMgRLBDEEQAQwBEIETAQ6AFwAbgBcAHQAXAB0AFsAMQAtACUAMQAlAF0AXAB0ABQgIAA/BEMEPQQ6BEIEIAA8BDUEPQROBDsAXABuAFwAdABcAHQAWwASBF0ASwRFBD4ENARcAHQAFCAgADIESwRFBD4ENAQuAFwAbgBcAHQAJwRRBCAANAQ1BDsEMARCBEwEIAAxBEMENAQ1BDwEPwAgABIESwQxBDgEQAQwBDkEXABuAFwAdAAeBCgEGAQRBBoEEAQ6ACAAHwQjBB0EGgQiBCAAHAQVBB0ELgQgAFwAcQAlADEAJQBcAHEAIAAdBBUEIAAdBBAEGQQUBBUEHQQhACAAJwQVBCAEFQQXBCAAMgAgACEEFQQaBC4AIAAcBB4EFgQdBB4EIAAfBB4EHwQrBCIEEAQiBCwEIAAjBBQEEAQnBCMEIAAVBCkEAQQgACAEEAQXBCEAXABuADIEXABuAGQAXABuAFwAdAASBEsEMQQ1BEAEOAQgADQEOARBBDoEIAA0BDsETwQgAEEEPgQ3BDQEMAQ9BDgETwQgADcEMAQzBEAEQwQ3BD4ERwQ9BD4EMwQ+BCAAQwRBBEIEQAQ+BDkEQQRCBDIEMAQuAFwAbgBcAHQAFwQwBDMEQARDBDcEPgRHBD0EPgQ1BCAAQwRBBEIEQAQ+BDkEQQRCBDIEPgQgADwEPgQ2BDUEQgQgADEESwRCBEwEIAA7BE4EMQRLBDwEOgAgAEYAbABlAHMAaAAsACAASABEAEQAIAA4BDsEOAQgAFMARABEAC4AXABuAFwAdAAYBD0EQgQ1BEAERAQ1BDkEQQQgAD8EPgQ0BDoEOwROBEcENQQ9BDgETwQgADwEPgQ2BDUEQgQgADEESwRCBEwEIAA7BE4EMQRLBDwEOgAgAEkARABFACwAIABTAEEAVABBACwAIABOAFYATQBFACAAOAQ7BDgEIABVAFMAQgAuAFwAbgBcAHQAFwQwBDMEQARDBDcEPgRHBD0EPgQ1BCAAQwRBBEIEQAQ+BDkEQQRCBDIEPgQgADEEQwQ0BDUEQgQgAEAEMAQxBD4EQgQwBEIETAQgAEEEIABVAEUARgBJACAAOAQgAEIASQBPAFMALgBcAG4AWwAUBF0AIAAYBD0ENAQ1BDoEQQRcAG4AWwAUBFwAIARdACAAGAQ8BE8EXABuAFsAFARdACAAIgQ4BD8EIABIBDgEPQRLBFwAbgBbABQEXAAgBF0AIAAgBDAENwQ8BDUEQAQsACAAHAQxBFwAbgBbABQEXQAgACEEQgQ4BDsETARcAG4AWwAUBFwAIARdACAAEARCBEAEOAQxBEMEQgRLBFwAbgBbABQEXQAgAFwAbgAgACAAIABbACAEXQAgAFwAbgAgACAAIABbACAEXQAgADoAXABcAG4AIAAgACAAWwAgBF0AIABOAE8AXABuAE4ATwBcAG4ALQAtAC0ALQAtAC0ALQAtAC0ALQBcAG4ALQAtAC0ALQAtAC0ALQAtAC0AXABuAC0ALQAtAC0ALQAtAC0ALQAtAC0ALQAtAFwAbgAtAC0ALQAtAC0ALQAtAC0ALQAtAC0ALQAtAC0ALQAtAFwAbgAtAC0ALQAtAC0ALQAtAC0ALQBcAG4ALQAtAC0ALQAtAC0ALQAtAC0ALQAtAC0ALQAtAFwAbgBcAHQAHAQwBEAEOgQ1BEAESwQ6AFwAbgBcAHQAXAB0AFsAFARdACAALQAgADQEOARBBDoEOwBcAG4AXAB0AFwAdABbACAEXQAgAC0AIABABDAENwQ0BDUEOwQuAFwAbgBcAHQAEARCBEAEOAQxBEMEQgRLBDoAXABuAFwAdABcAHQAFwQgAC0AIAA3BDAEMwRABEMENwQ+BEcEPQRLBDkEOwBcAG4AXAB0AFwAdAAhBCAALQAgAEEEOARBBEIENQQ8BD0ESwQ5BC4AXABuACwAIAAXBFwAbgAsACAAIQRcAG4AXAB0AFwAdABbADAALQAlADEAJQBdAFwAdAAUICAAOAQ9BDQENQQ6BEEEIAA0BDgEQQQ6BDAEOwBcAG4AXAB0AFwAdABbAB0EXQAwBDcEMAQ0BFwAdAAUICAAPQQwBDcEMAQ0BC4AXABuAD0EXABuAHkAXABuAFwAdAAeBCgEGAQRBBoEEAQ6ACAAFAQYBCEEGgQgAFwAcQAlADEAJQBcAHEAIAAvBBIEGwQvBBUEIgQhBC8EIAAhBBgEIQQiBBUEHAQdBCsEHAQgABgEGwQYBCAAFwQQBBMEIAQjBBcEHgQnBB0EKwQcBCEAIAAVBBMEHgQgAB0EFQQbBCwEFwQvBCAAGAQhBB8EHgQbBCwEFwQeBBIEEAQiBCwEIQBcAG4AXAB0ABIEHQQYBBwEEAQdBBgEFQQhACAAHQQQBCAAFAQYBCEEGgQVBCAAXABxACUAMQAlAFwAcQAgABIEIQQBBCAAEQQjBBQEFQQiBCAAIwQdBBgEJwQiBB4EFgQVBB0EHgQhAFwAbgBcAHQAEgQdBBgEHAQQBB0EGAQVBCEAIAAiBCsEIAAUBBUEGQQhBCIEEgQYBCIEFQQbBCwEHQQeBCAAFwQQBBQEIwQcBBAEGwQgABgEIQQfBB4EGwQsBBcEHgQSBBAEIgQsBCAAFAQYBCEEGgQgAFwAcQAlADEAJQBcAHEAPwBcAG4AXAB0ABIEHQQYBBwEEAQdBBgEFQQhACAAHwQeBBQEIgQSBBUEIAQUBBgEIAAoAFsAFARdABAEXAAdBFsAFQRdACIEKQA6AFwAbgA0BFwAbgBsAFwAbgBcAHQAMQAuACAAHwQ+BDQEOgQ7BE4ERwQ1BD0EOAQ1BCAASQBTAE8AIABcAHEAJQAxACUAXABxACYgXABuAFwAdABcAHQAHQQVBCAAIwQUBBAEGwQeBCEELAQgAB8EHgQUBBoEGwQuBCcEGAQiBCwEIABJAFMATwAgAFwAcQAlADEAJQBcAHEAIQAgAB8EIAQeBCYEFQQhBCEEIAARBCMEFAQVBCIEIAAfBCAEFQQgBBIEEAQdBCEAXABuACAAFwQQBBIEFQQgBCgEFQQdBB4EIQBcAG4AXAB0AFwAdAAeBEIEOgQ7BE4ERwQ1BD0EOAQ1BCAASQBTAE8AIABcAHEAJQAxACUAXABxACYgXABuAFwAdABcAHQAEgQhBBUEIAARBCMEGgQSBCsEIAAiBB4EHAQeBBIEIAAXBBAEHQQvBCIEKwQhACAAHwQgBB4EJgQVBCEEIQQgABEEIwQUBBUEIgQgAB8EIAQVBCAEEgQQBB0EIQBcAG4AXAB0ADIALgAgACEEPgQ3BDQEMAQ9BDgENQQgADcEMAQzBEAEQwQ3BD4ERwQ9BD4EMwQ+BCAAQwRBBEIEQAQ+BDkEQQRCBDIEIAA4BDcEIABcAHEAJQAxACUAXABxAFwAbgBcAHQAXAB0AB4ERwQ4BEEEQgQ6BDAEIAA0BDgEQQQ6BDAEIABcAHEAJQAxACUAXABxACYgXABuAFwAdABcAHQAHQQVBCAAIwQUBBAEGwQeBCEELAQgAB4EIgQgBBUEFAQQBBoEIgQYBCAEHgQSBBAEIgQsBCAAFAQYBCEEGgQgAFwAcQAlADEAJQBcAHEAIQAgAB8EIAQeBCYEFQQhBCEEIAARBCMEFAQVBCIEIAAfBCAEFQQgBBIEEAQdBCEAXABuAFwAdABcAHQAGgQ+BD0EMgQ1BEAEQgQwBEYEOARPBCAANwQwBDMEQARDBDcEPgRHBD0EPgQzBD4EIAA0BDgEQQQ6BDAEIABcAHEAJQAxACUAXABxACAAMgQgAE0AQgBSACYgXABuAFwAdABcAHQAIQQ+BDcENAQwBD0EOAQ1BCAAQAQwBDcENAQ1BDsEMAQgAD0EMAQgADcEMAQzBEAEQwQ3BD4ERwQ9BD4EPAQgADQEOARBBDoENQQgAFwAcQAlADEAJQBcAHEAJiBcAG4AXAB0AFwAdAAhBD4ENwQ0BDAEPQQ4BDUEIABCBD4EPAQwBCAAPQQwBCAANwQwBDMEQARDBDcEPgRHBD0EPgQ8BCAANAQ4BEEEOgQ1BCAAXABxACUAMQAlAFwAcQAmIFwAbgBcAHQAXAB0ABcEMAQ0BDAENQQ8BCAAOAQ8BE8EIAA3BDAEMwRABEMENwQ+BEcEPQQ+BDMEPgQgADQEOARBBDoEMAQgAFwAcQAlADEAJQBcAHEAJiBcAG4AXAB0AFwAdAASBB0EGAQcBBAEHQQYBBUEIQAgABQEEAQdBB0EKwQZBCAAHwQgBB4EJgQVBCEEIQQgABcEEAQZBBwEFQQiBCAAEgQgBBUEHAQvBC4AIAAeBCIEHgQRBCAEEAQWBBUEHQQYBBUEIAAfBCAEHgQTBCAEFQQhBCEEEAQgAB4EIgQhBCMEIgQhBBIEIwQVBCIELgBcAG4AXAB0AFwAdAAgBDAENwQ0BDUEOwQ1BD0EOAQ1BCAAPgQxBEAEMAQ3BDAEIABBBDgEQQRCBDUEPARLBCAAVwBpAG4AZABvAHcAcwAgAFwAcQBpAG4AcwB0AGEAbABsAC4AdwBpAG0AXABxACAAPQQwBCAARwQwBEEEQgQ4BCAAPwQ+BCAAMwAgADkANgA4ACAAHAQxBCYgXABuAFwAdABcAHQAGgQ+BD8EOARABD4EMgQwBD0EOAQ1BCAARAQwBDkEOwQ+BDIEJiBcAG4AXAB0AFwAdAAdBBUEIAAjBBQEEAQbBB4EIQQsBCAAIQQaBB4EHwQYBCAEHgQSBBAEIgQsBCAAJAQQBBkEGwQrBCAAFAQYBCEEIgQgBBgEEQQjBCIEGAQSBBAEIABXAEkATgBEAE8AVwBTACEAIAAfBCAEHgQmBBUEIQQhBCAAEQQjBBQEFQQiBCAAHwQgBBUEIAQSBBAEHQQhAFwAbgBcAHQAHQQVBCAAIwQUBBAEGwQeBCEELAQgAB4EIgQaBBsELgQnBBgEIgQsBCAASQBTAE8AIABcAHEAJQAxACUAXABxACEAIAAhBBQEFQQbBBAEGQQgAC0EIgQeBCAAEgQgBCMEJwQdBCMELgQhAFwAbgBcAHQAFwQQBBMEIAQjBBcEHgQnBB0EKwQZBCAAFAQYBCEEGgQgACEEHgQXBBQEEAQdBCEAXABuAFwAdAAUBBsELwQgABIEKwQlBB4EFAQQBCAAHQQQBBYEHAQYBCIEFQQgAEUATgBUAEUAUgAhAFwAbgBcAHQAMwAuACAAIQQ+BDcENAQwBD0EOAQ1BCAANAQ4BEEEQgRABDgEMQRDBEIEOAQyBDAEXABuAFwAdAA0AC4AIAAeBEIEOgQ7BE4ERwQ1BD0EOAQ1BCAASQBTAE8AIABcAHEAJQAxACUAXABxACYgXABuACAAHgQoBBgEEQQaBBAEIQBcAG4AXAB0ADEALgAgAB8EPgQ7BEMERwQ1BD0EOAQ1BCAANAQwBD0EPQRLBEUEIAA+BCAANAQ+BEEEQgRDBD8EPQRLBEUEIABABDUENAQwBDoERgQ4BE8ERQQmIFwAbgBcAHQAXAB0ABIESwQxBDUEQAQ4BCAAQAQ1BDQEMAQ6BEYEOAROBCAAVwBpAG4AZABvAHcAcwA6AFwAbgBcAHQAXAB0ACcEUQQgADwEPgQ2BD0EPgQgADIESwQxBEAEMARCBEwEOgBcAG4AXAB0AFwAdABcAHQAWwAwAC0AJQAxACUAXQBcAHQAFCAgAEAENQQ0BDAEOgRGBDgETwQ7AFwAbgBcAHQAXAB0AFwAdABbAB0EXQAwBDcEMAQ0BFwAdAAUICAAPQQwBDcEMAQ0BC4AXABuAFwAdABcAHQAJwRRBCAANAQ1BDsEMARCBEwEIAAxBEMENAQ1BDwEPwAgABIESwQxBDgEQAQwBDkEXABuAFwAdABcAHQAEgRLBDEEQAQwBD0EMAQgAEAENQQ0BDAEOgRGBDgETwQgAFwAcQAlADEAJQBcAHEALgBcAG4AXAB0ADIALgAgAB8EPgQ7BEMERwQ1BD0EOAQ1BCAANAQwBD0EPQRLBEUEIAA+BCAANAQ+BEEEQgRDBD8EPQRLBEUEIABPBDcESwQ6BDAERQQmIFwAbgBcAHQAXAB0ABIESwQxBDUEQAQ4BCAATwQ3BEsEOgQgAFcAaQBuAGQAbwB3AHMAOgBcAG4AXAB0AFwAdABcAHQAWwAwAC0AJQAxACUAXQBcAHQAFCAgAE8ENwRLBDoEOwBcAG4AXAB0AFwAdAASBEsEMQRABDAEPQQgAE8ENwRLBDoEIABcAHEAJQAxACUAXABxAC4AXABuAFwAdAAzAC4AIAAfBD4EOwRDBEcENQQ9BDgENQQgADQEMAQ9BD0ESwRFBCAAPgQgADQEPgRBBEIEQwQ/BD0ESwRFBCAAMARABEUEOARCBDUEOgRCBEMEQAQwBEUEJiBcAG4AXAB0AFwAdAASBEsEMQQ1BEAEOAQgADAEQARFBDgEQgQ1BDoEQgRDBEAEQwQgAFcAaQBuAGQAbwB3AHMAOgBcAG4AXAB0AFwAdABcAHQAWwAwAC0AJQAxACUAXQBcAHQAFCAgADAEQARFBDgEQgQ1BDoEQgRDBEAEMAQ7AFwAbgBcAHQAXAB0ABIESwQxBEAEMAQ9BDAEIAAwBEAERQQ4BEIENQQ6BEIEQwRABDAEIABcAHEAJQAxACUAXABxAC4AXABuAFwAdAASBB0EGAQcBBAEHQQYBBUEIQAgABQEEAQdBB0EKwQZBCAAHwQgBB4EJgQVBCEEIQQgABcEEAQZBBwEFQQiBCAAEgQgBBUEHAQvBC4AIAAeBCIEHgQRBCAEEAQWBBUEHQQYBBUEIAAfBCAEHgQTBCAEFQQhBCEEEAQgAB4EIgQhBCMEIgQhBBIEIwQVBCIELgBcAG4AXAB0ADQALgAgACEEOgQwBEcEOAQyBDAEPQQ4BDUEIAAlADEAJQAgACUAMgAlACAAJQAzACUAJiBcAG4AXAB0ABoEMAQ6BEMETgQgADIENQRABEEEOAROBCAAVwBpAG4AZABvAHcAcwAgADEEQwQ0BDUESARMBCAAOgQwBEcEMARCBEwEIABBBCAAQQQwBDkEQgQwBCAATQBpAGMAcgBvAHMAbwBmAHQAPwBcAG4AXAB0AFwAdABbADEALQA0AF0AXAB0ABQgIAA/BEMEPQQ6BEIEIAA8BDUEPQROBDsA")
        $decodeResult = [System.Text.Encoding]::Unicode.GetString($decode).Replace("\t", "	").Replace("\q", "'")
        $splitter = "\n"
        $Script:gLang = $decodeResult -split $splitter, 0, "simplematch"
    }
    else {
        $Script:gLang = @('	Choose the ISO file from which you want to make a boot device.') #0
        $Script:gLang += '	Windows distributions are searched in the root folder where the script is located.' #1
        $Script:gLang += '	Or download the Windows ISO distribution from the Microsoft website using menu #1.' #2
        $Script:gLang += '	The Windows distribution will be downloaded to the root folder of the scritp.' #3
        $Script:gLang += '	1. Download Windows' #4
        $Script:gLang += '	2. Specify the path of the Windows ISO distribution' #5
        $Script:gLang += '	You can select:' #6
        $Script:gLang += '		[1-%1%] — menu item;' #7
        $Script:gLang += '		[E]xit — exit.' #8
        $Script:gLang += '	What are we going to do? Choose' #9
        $Script:gLang += '	ERROR: THE MENU ITEM "%1%" WAS NOT FOUND! AFTER 2 SECONDS, YOU CAN TRY YOUR LUCK AGAIN!' #10
        $Script:gLang += 'e' #11
        $Script:gLang += 'e' #12
        $Script:gLang += '	Select the disk to create a boot device' #13
        $Script:gLang += '	The boot device can be any: Flesh, HDD or SDD.' #14
        $Script:gLang += '	The bus can be any: IDE, SATA, NVME or USB.' #15
        $Script:gLang += '	The boot device will work with UEFI and BIOS.' #16
        $Script:gLang += '[D] Index' #17
        $Script:gLang += '[D\P] Name' #18
        $Script:gLang += '[D] Bus Type' #19
        $Script:gLang += '[D\P] Size, Mb' #20
        $Script:gLang += '[D] Style' #21
        $Script:gLang += '[D\P] Attributes' #22
        $Script:gLang += '[D] ' #23
        $Script:gLang += '   [P] ' #24
        $Script:gLang += '   [P] :\' #25
        $Script:gLang += '   [P] NO' #26
        $Script:gLang += 'NO' #27
        $Script:gLang += '----------' #28
        $Script:gLang += '---------' #29
        $Script:gLang += '------------' #30
        $Script:gLang += '----------------' #31
        $Script:gLang += '---------' #32
        $Script:gLang += '--------------' #33
        $Script:gLang += '	Markers:' #34
        $Script:gLang += '		[D] - disk;' #35
        $Script:gLang += '		[P] - partition.' #36
        $Script:gLang += '	Attributes:' #37
        $Script:gLang += '		B - bootable;' #38
        $Script:gLang += '		S - system.' #39
        $Script:gLang += ', B' #40
        $Script:gLang += ', S' #41
        $Script:gLang += '		[0-%1%] — disk index;' #42
        $Script:gLang += '		[B]ack — back.' #43
        $Script:gLang += 'b' #44
        $Script:gLang += 'b' #45
        $Script:gLang += '	ERROR: THE DISK "%1%" IS SYSTEM OR BOOTABLE! IT CANNOT BE USED!' #46
        $Script:gLang += '	ATTENTION! EVERYTHING ON THE DISK "%1%" WILL BE DELETED!' #47
        $Script:gLang += '	ATTENTION! ARE YOU REALLY PLANNING TO USE THE DISK "%1%"?' #48
        $Script:gLang += '	ATTENTION! CONFIRM ([Y]ES\[N]O):' #49
        $Script:gLang += 'y' #50
        $Script:gLang += 'y' #51
        $Script:gLang += '	1. Connecting ISO "%1%"...' #52
        $Script:gLang += '		FAILED TO CONNECT ISO "%1%"! THE PROCESS WILL BE INTERRUPTED!' #53
        $Script:gLang += ' COMPLETED!' #54
        $Script:gLang += '		Disabling ISO "%1%"…' #55
        $Script:gLang += '		ALL THE LETTERS OF THE VOLUMES ARE OCCUPIED! THE PROCESS WILL BE INTERRUPTED!' #56
        $Script:gLang += '	2. Creating bootable devices from "%1%"' #57
        $Script:gLang += '		Disk cleanup "%1%"...' #58
        $Script:gLang += '		FAILED TO EDIT DISK "%1%"! THE PROCESS WILL BE INTERRUPTED!' #59
        $Script:gLang += '		Converting the boot disk "%1%" to MBR…' #60
        $Script:gLang += '		Creating a partition on the boot disk "%1%"…' #61
        $Script:gLang += '		Creating a volume on the boot disk "%1%"…' #62
        $Script:gLang += '		Set the name of the boot disk "%1%"...' #63
        $Script:gLang += '		ATTENTION! THIS PROCESS WILL TAKE TIME. THERE IS NO PROGRESS DISPLAY.' #64
        $Script:gLang += '		Splitting the Windows image "install.wim" into parts of 3 968 MB…' #65
        $Script:gLang += '		Copying files…' #66
        $Script:gLang += '		WINDOWS DISTRIBUTION FILES COULD NOT BE COPIED! THE PROCESS WILL BE INTERRUPTED!' #67
        $Script:gLang += '	COULD NOT DISABLE ISO "%1%"! DO IT MANUALLY!' #68
        $Script:gLang += '	THE BOOT DISK IS CREATED!' #69
        $Script:gLang += '	TO EXIT, PRESS ENTER!' #70
        $Script:gLang += '	3. Create a distribution' #71
        $Script:gLang += '	4. Disabling ISO "%1%"...' #72
        $Script:gLang += ' ERROR!' #73
        $Script:gLang += '	1. Getting data about available editions…' #74
        $Script:gLang += '		Choose the Windows edition:' #75
        $Script:gLang += '		You can select:' #76
        $Script:gLang += '			[0-%1%] — edition;' #77
        $Script:gLang += '			[B]ack	— back.' #78
        $Script:gLang += '		What are we going to do? Choose' #79
        $Script:gLang += '		The revision "%1%" is selected.' #80
        $Script:gLang += '	2. Getting data about available languages…' #81
        $Script:gLang += '		Choose the Windows language:' #82
        $Script:gLang += '			[0-%1%]	— language;' #83
        $Script:gLang += '		The language selected is "%1%".' #84
        $Script:gLang += '	3. Getting data on available architectures…' #85
        $Script:gLang += '		Choose the Windows architecture:' #86
        $Script:gLang += '			[0-%1%] — architecture;' #87
        $Script:gLang += '		The architecture "%1%" is selected.' #88
        $Script:gLang += '	ATTENTION! THIS PROCESS WILL TAKE TIME. THERE IS NO PROGRESS DISPLAY.' #89
        $Script:gLang += '	4. Download %1% %2% %3%…' #90
        $Script:gLang += '	Which version of Windows will you download from the Microsoft website?' #91
        $Script:gLang += '		[1-4]	— menu item;' #92
    }

}

function EntryPoint {
    $result = -1

    Set-Language
    do { $result = Show-MainMenu } while ($result -eq -1)

    return $result
}

return EntryPoint