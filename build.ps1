param (
    [string]$arch = "x86",
    [string]$vsver = "2019",
    [switch]$v,
    [switch]$clear
)

# configuration variables
$luaVer = "Lua 5.3.6"
$srcURL = (
    "https://netactuate.dl.sourceforge.net/project/luabinaries/5.3.6/" +
    "Docs%20and%20Sources/lua-5.3.6_Sources.zip"
)


# logging utilities
function logInfo($msg){Write-Host "(I) $msg"}
function logSuccess($msg){Write-Host "(I) $msg" -ForegroundColor Green}
function logWarning($msg){Write-Host "(W) $msg" -ForegroundColor Yellow}
function logError($msg){Write-Host "(E) $msg" -ForegroundColor Red}

# file system utilities
function isFolder($path){
    return (Test-Path $path -PathType Container)
}
function isFile($path){
    return (Test-Path $path -PathType Leaf)
}
function ensureDir($dir){
    # if directory doesn't exists, then attempt to create it
    # !!warning!!: this function will terminate script if create fails
    if (-not(isFolder "$dir")){
        if($verbose){logInfo "creating directory $dir..."}
        try {
            $newDir = New-Item -ItemType Directory -Path "$dir" -Force `
                -ErrorAction Stop
        } catch {
            logError "Could not create direcotry. Reason`n $_"; exit 1
        }
    }
}
function ensureCopy($srcFile, $destFile){
    # attempts to copy a file
    # !!warning!!: this function will terminate script if copy fails
    try { $newItem = Copy-Item "$srcFile" "$destFile" -ErrorAction Stop }
    catch {
        logError "Could not copy `"$srcFile`" to `"$destFile`""; exit 1
    }
}
function getDirectoryFileCount($dir){
    return (Get-ChildItem $dir | Measure-Object).Count
}

function isUserInRoot(){
    # checks if working dir is project root (i.e. where .git directory exists)
    return (isFolder ".\.git")
}
function downloadLuaSources($srcURL, $tmpZipFile, $srcDir, $incDir){
    # download from source url and extracts
    try{
        if (-not(isFile $tmpZipFile)){
            Invoke-WebRequest "$srcURL" -OutFile "$tmpZipFile"
        }
    } catch {
        logError "Could not download file from remote. Reason:`n $_"
        return $false
    }
    try{
        $luaDir = "lua53"
        Expand-Archive -Path "$tmpZipFile" -DestinationPath "."
        Move-Item ".\$luaDir\src\*" ".\$srcDir" -Force
        Move-Item ".\$luaDir\include\*" ".\$incDir" -Force
        Remove-Item ".\$luaDir" -Force -Recurse
    } catch {
        logError "Could not expand archive. Reason:`n $_"; return $false
    }
    try{ Remove-Item "$tmpZipFile" } catch {
        logWarning "Could not remove file `"$tmpZipFile`""
    }
    return $true
}
function detectVSTools($arch){
    # attempt to dectect batch file that will setup env for compiling
    # (e.g. make "cl.exe" available)
    $vsVers = @("2015", "2017", "2019")
    $arch = if ($arch -eq "x86") {"32"} else {"64"}
    foreach ($vsVer in $vsVers){
        $vsEnvScriptPath = ("C:\Program Files (x86)\Microsoft Visual Studio" +
            "\$vsVer\Community\VC\Auxiliary\Build\vcvars$arch.bat")
        if (isFile $vsEnvScriptPath){
            return $vsEnvScriptPath
        }
    }
    return ""
}
function getPlatform($arch){
    switch($arch){
        "x64" {return "Win64"}
        "x86" {return "Win32"}
        default {return "Win32"}
    }
}


# checks a valid architeture
switch($arch){
    "x64" {break;}
    "x86" {break;}
    default {logError "Invalid architeture: $arch"; exit 1}
}
# checks if verbose is enabled from cmdline arguments
$verbose=if($v){$true}else{$false}
# checks if the user is running from root folder
if(!(isUserInRoot)){logError "not in root directory"; exit 1}
# check if we have VS tools installed
$vsEnvBat = detectVSTools $arch
if (!$vsEnvBat){logError "Could not detect Visual Studio C++ tools"; exit 1}


# setup some globals variables
$srcDir = "src"
$incDir = "include"
#$srcURL = "http://cartainly.not.domain/file.ext"
$platformID = getPlatform $arch


# checks if it is to clear everything
if ($clear){
    function delDir($dir){Remove-Item -Recurse -Force -Path "$dir"}
    logWarning "Proceed to clear all built files?"
    $yn = Read-Host "Confirm (Y)es/(N)o [Y/N]: "
    if ($yn.ToLower() -eq "y"){
        try { 
            delDir ".\dist"; delDir ".\$incDir"
            delDir ".\lib"; delDir ".\$srcDir"
        } catch {
            logError "Could not remove item. Reason:`n $_"; exit 1
        }
    }
    exit 0
}

# if src directory is empty, then attempt to download lua sources
ensureDir ".\$srcDir"
ensureDir ".\$incDir"
if ((getDirectoryFileCount $srcDir) -eq 0){
    logInfo "`"$srcDir`" directory is empty. Attempt to pull source files..."
    $zipFile = "lua53-src.zip"
    $downloadOK = downloadLuaSources "$srcURL" "$zipFile" $srcDir $incDir
    if(-not($downloadOK)){
        logError "Could not download source files. Script will terminate"
        exit 1
    } else {
        logSuccess "Sucessfully saved lua source files to `"$srcDir`""
    }
}

# create required directory structure that will be used further in the build
ensureDir ".\dist\$platformID"
ensureDir ".\lib\$platformID"

# copy include files
if ((getDirectoryFileCount $incDir) -eq 0){
    logInfo "Copying include files..."
    ensureCopy ".\$srcDir\lualib.h" ".\$incDir"
    ensureCopy ".\$srcDir\lauxlib.h" ".\$incDir"
    ensureCopy ".\$srcDir\lua.h" ".\$incDir"
    ensureCopy ".\$srcDir\lua.hpp" ".\$incDir"
    ensureCopy ".\$srcDir\luaconf.h" ".\$incDir"
}

# compile with Visual Studio C++ compiler
logInfo "Compiling $luaVer with MSVC..."
function absOf($path){return ((Resolve-Path $path).Path)}  # absolute path
& ".\build_msvc.bat" $vsEnvBat $(absOf $srcDir) $platformID

logSuccess "All files were compiled to platform $platformID"
