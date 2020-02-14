foreach ($models in "A1584", "A1566") {

# variables and dictionaries

$dict = @{
  'A1584' = 'IpadPro', 'BigSalesTablet'
  'A1566' = 'IpadAir2', 'SmallServiceTablet'
}

  $folderLocation = "$Home\Desktop\Ipad Images"

# Main

  echo "Looking up Model: $models"
  Write-Output ""
  $uri = "https://api.ipsw.me/v4/model/${models}"
  $response = Invoke-RestMethod -Uri $uri
  $identifier = $response.identifier
  $uri = "https://api.ipsw.me/v4/device/${identifier}?type=ipsw"
  $signed = Invoke-RestMethod -Uri $uri | select -expand firmwares | where signed -eq "True" | Select buildid, version, url, SHA1sum
  foreach ( $abc in $signed ) {
    #echo "Downloading: ${abc}"
    $buildid = ${abc}.buildid
    $version = ${abc}.version
    $shasum = ${abc}.SHA1sum

    $fileToCheck = "$folderLocation\${identifier}_${version}_${buildid}.ipsw"
    
    Write-Output "  Model: $models is classed as an ${identifier} release ${version} is avaiable and is signed"

    Write-Output "  Checking if the file $fileToCheck already exists..."

    if (Test-Path $fileToCheck -PathType leaf) {
      Write-Output "  File already exist... Checking its sha1sum"
      $filehash = (Get-FileHash $fileToCheck -Algorithm SHA1)
      #$filehash.Hash
      #$shasum
      if ( ${filehash}.Hash -ne ${shasum} ) {
        Write-Output "No Hash match, downloading file is incomplete or corrupt. Downloading again...."
        Invoke-WebRequest -Uri $abc.url -OutFile $fileToCheck
      }
      else {
        Write-Output "  sha1sum check confirms file is complete and valid."
      }
      Write-Output ""


    }
    else {

      Write-Output "  File does not exist... Downloading"
      Invoke-WebRequest -Uri $abc.url -OutFile $fileToCheck

    }

  }

#Generate link to oldest signed copy - not perfect as this relies on last itteration overwriting at the mo - but works...

$infoArray = $dict["${models}"]
$name = $infoArray[0]
$nicename = $infoArray[1]


$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("${folderLocation}\${name}_${nicename}.lnk")
$Shortcut.TargetPath = "$fileToCheck"
$Shortcut.Save()


}
