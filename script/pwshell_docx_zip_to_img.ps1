# powershell rename file name changed by script (ps1) but uncertainly not-work: win10 file manager remain unchanged
# so use bash to do it:
# find . -name "*.docx" -print0 | xargs -0 rename 's/Key to the species of //g'
# find . -name "*.docx" -print0 | xargs -0 rename 's/ \(China sea\)//g'
# find . -name "*.docx" -print0 | xargs -0 rename 's/ /_/g'
# find . -name "*.docx" -print0 | xargs -0 rename 's/.docx/.zip/g'

# $documents = "D:\ODB\Data\shih\shih_5_202107\key_zip\"
$documents = "D:\proj\copkey\doc\sp_key_zip\"

$images = "D:\proj\copkey\www_sp\img\"

Set-Location $documents

#Get-ChildItem "$documents$_\*.docx" -Recurse | 
#    #Where {$_.Name -Match 'Key to the species of '} | 
#    Rename-Item -NewName {$_.name -replace '^Key to the species of ','' } -WhatIf

#Get-ChildItem "$documents$_\*.docx" #| 
#    #Where {$_.Name -Match ' (China seas 2)'} | 
#    Rename-Item -NewName {$_.name -replace ' (China seas 2)','' } 

#Get-ChildItem $documents -Recurse | 
##    Where {$_.Name -Match ' '} | 
#    Rename-Item -NewName {$_.name -replace ' ','_' } 

# rename all docx files to zip files, then extract the zips to directories
#Get-ChildItem $documents *.docx | % { 
#    Rename-Item $_ ($_.BaseName + ".zip")
#    Expand-Archive ($_.BaseName + ".zip")
#}

Get-ChildItem $documents *.zip | % { 
    Expand-Archive ($_.BaseName + ".zip")
}

# If want to copy image out (or just use images within expanded_zip folders)
# get the images from the directories, then delete each directory
#Get-ChildItem -Directory | ForEach-Object {
#	#$fileName = $_.BaseName
#	$sdir = New-Item -Type Directory -Path $images -Name $_.BaseName
#    Copy-Item "$documents$_\word\media\*" $sdir
##   Remove-Item $documents$_ -Recurse -WhatIf
#}

# restore the docx files
# Get-ChildItem $documents *.zip | % { 
#    Rename-Item $_ ($_.Basename + ".docx")
#}