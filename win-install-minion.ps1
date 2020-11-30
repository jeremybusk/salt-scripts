$wdir = "C:\tmp\salt-install"
New-Item -ItemType Directory -Force -Path $wdir
cd $wdir
$version = "2019.2.6"
$file_hash = "58FAF92AD1E76D973C225C5E333D9945017930BB9D63FC5C7F3C3180B1DFD3D1"
$install_file_sha256 = "${wdir}\install.exe.sha256"
$install_file = "${wdir}\install.exe"

function cleanup() {
  Remove-Item $wdir -Recurse
}


function install_salt() {
  curl.exe -L https://repo.saltstack.com/windows/Salt-Minion-${version}-Py3-x86-Setup.exe.sha256 -o $install_file_sha256
  curl.exe -L https://repo.saltstack.com/windows/Salt-Minion-${version}-Py3-x86-Setup.exe -o $install_file
  $repo_file_hash = $(cat $install_file_sha256).split(" ")[0]
  $local_file_hash = $(Get-FileHash -Algorithm SHA256 $install_file).hash
  if ($repo_file_hash -ne $local_file_hash){
    write-host "E: Invalid $local_file_hash file hash!"
    cd C:\tmp\saltprep
    exit(3)
  }
}

function file_exists() {
if (Test-Path -path $file)
}

# write-host "https://repo.saltstack.com/windows/Salt-Minion-${version}-Py3-x86-Setup.exe.sha256"
# exit
install_salt
cd C:\tmp\saltprep
write-host "end"
