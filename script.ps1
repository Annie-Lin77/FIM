
#adds file to baseline
function Add-FileToBaseline {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory)]$baselineFilePath,
        [Parameter(Mandatory)]$targetFilePath
    )
    
    #throws error message if file doesn't exist
    try {
        if ((Test-Path -Path $baselineFilePath) -eq $false) {
            Write-Error -Message "$baselineFilePath does not exist" -ErrorAction Stop
        }
        if ((Test-Path -Path $targetFilePath) -eq $false) {
            Write-Error -Message "$targetFilePath does not exist" -ErrorAction Stop
        }
        if ($baselineFilePath.Substring($baselineFilePath.Length - 4, 4) -ne ".csv") {
            Write-Error -Message "$baselineFilePath needs to be a .csv file" -ErrorAction Stop
        }

        $currentBaseline = Import-Csv -Path $baselineFilePath -Delimiter ","

        if ($targetFilePath -in $currentBaseline.path) {
            Write-Output "File path detected already in baseline file"

            #overwrites file path
            $currentBaseline | Where-Object path -ne $targetFilePath | Export-Csv -Path $baselineFilePath -Delimiter "," -NoTypeInformation
            $hash = Get-FileHash -Path $targetFilePath
            "$($targetFilePath),$($hash.hash)" | Out-File -FilePath $baselineFilePath -Append
            Write-Output "Entry sucessfully added into baseline"

            do {
                $overwrite = Read-Host -Prompt "Path exists already in the baseline file, would you like to overwrite it? [Y/N]: "
                if ($overwrite -in @('y', 'yes')) {
                    Write-Output "Path has been overwritten"
                }
                elseif ($overwrite -in @('n', 'no')) {
                    Write-Output "File path not overwritten"
                }
                else {
                    Write-Output "Invalid entry, please enter 'y' to overwrite or 'n' to not overwrite"
                }   
            } 
            while ($overwrite -notin @('y', 'yes', 'n', 'no'))
        
        }
        else {
            $hash = Get-FileHash -Path $targetFilePath
            "$($targetFilePath),$($hash.hash)" | Out-File -FilePath $baselineFilePath -Append
            Write-Output "Entry sucessfully added into baseline"
        }

        $currentBaseline = Import-Csv -Path $baselineFilePath -Delimiter ","
        $currentBaseline | Export-Csv -Path $baselineFilePath -Delimiter "," -NoTypeInformation
           
    }
    catch {
        Write-Error $_.Exception.Message
    }
}

#verifies baseline
function Verify-Baseline {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory)]$baselineFilePath
    )

    try {
        if ((Test-Path -Path $baselineFilePath) -eq $false) {
            Write-Error -Message "$baselineFilePath does not exist" -ErrorAction Stop
        }
        if ($baselineFilePath.Substring($baselineFilePath.Length - 4, 4) -ne ".csv") {
            Write-Error -Message "$baselineFilePath needs to be a .csv file" -ErrorAction Stop
        }

        #Monitors file
        $baselineFiles = Import-Csv -Path $baselineFilePath -Delimiter ","

        foreach ($file in $baselineFiles) {
            if (Test-Path -Path $file.path) {
                $currentHash = Get-FileHash -Path $file.path
                if ($currentHash.Hash -eq $file.hash) {
                    Write-Output = "$($file.path) is still the same"
                }
                else {
                    Write-Output = "$($file.path) hash is differnet something has changed"
                }
            }
            else {
                Write-Output = "$($file.path) is not found"
            }
        }
    }

    catch {
        Write-Error $_.Exception.Message
    }
    
}

#creates a baseline if it does not already exist 
function Create-Baseline {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory)] $baselineFilePath
    )

    #prevents baseline with the same name from being created
    try {
        if (Test-Path -Path $baselineFilePath) {
            Write-Error -Message "$baselineFilePath already exists with this name" -ErrorAction Stop
        }
        if ($baselineFilePath.Substring($baselineFilePath.Length - 4, 4) -ne ".csv") {
            Write-Error -Message "$baselineFilePath needs to be a .csv file" -ErrorAction Stop
        }

        "path,hash" | Out-File -FilePath $baselineFilePath -Force
    }
    catch {
        Write-Error $_.Exception.Message
    }
    
}

Write-Output "File Monitor System 1.00"
do {
    Write-Output "Please select one of the following functions or enter 'q' or 'quit' to quit"
    Write-Output "1) Set baseline file; Current set baseline $($baselineFilePath)"
    Write-Output "2) Add path to baseline"
    Write-Output "3) Check files against baseline"
    Write-Output "4) Create a new baseline"
    $entry = Read-Host -Prompt "Please enter a selection"

    switch ($entry) {
        "1" {
            $baselineFilePath = Read-Host -Prompt "Enter the baseline file path: "
            if (Test-Path -Path $baselineFilePath) {
                if ($baselineFilePath.Substring($baselineFilePath.Length - 4, 4) -eq ".csv") {
                }
                else {
                    $baselineFilePath = ""
                    Write-Output "Invalid file needs to be a .csv file"
                }
            }
            else {
                $baselineFilePath = ""
                Write-Output "Invalid file path for baseline"
            }
        }
        "2" {
            $targetFilePath = Read-Host -Prompt "Enter the path of the file you want to monitor: "
            Add-FileToBaseline -baselineFilePath $baselineFilePath -targetFilePath $targetFilePath
        }
        "3" {
            Verify-Baseline -baselineFilePath $baselineFilePath
        }
        "4" {
            $newBaselineFilePath = Read-Host -Prompt "Enter path for new baseline file: "
            Create-Baseline -baselineFilePath $newBaselineFilePath
        }
        "q" {}
        "quit" {}
        default {
            Write-Output "Invalid entry"
        }

    }

}
while ($entry -notin @('q', 'quit'))