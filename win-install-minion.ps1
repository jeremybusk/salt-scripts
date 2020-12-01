# Powershell script to install windows agents
# if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
# {
#   $arguments = "& '" +$myinvocation.mycommand.definition + "'"
#   Start-Process powershell -Verb runAs -ArgumentList $arguments
#   Break
# }

$ErrorActionPreference = "Stop"
$hdir = $(pwd).path
$salt_dir = "c:\salt"
$wdir = "C:\tmp\salt-install"
New-Item -ItemType Directory -Force -Path $wdir >$null 2>&1
cd $wdir
$version = "2019.2.6"
$install_file_sha256 = "${wdir}\install.exe.sha256"
$install_file = "${wdir}\install.exe"
$master_sign_pub_file = "c:\salt\conf\pki\minion\master_sign.pub"
$minion_conf_file = "c:\salt\conf\minion.d\minion.conf"

$master_sign_pub = @'
-----BEGIN PUBLIC KEY-----
xxxxx
-----END PUBLIC KEY-----
'@


$minion_conf = @'
master:
    - 10.x.x.x
    - 10.x.x.x
master_type: failover
master_alive_interval: 30
verify_master_pubkey_sign: True
master_failback: True
retry_dns: 0
'@


function cleanup() {
  Remove-Item $wdir -Recurse
}

function salt_uninstall() {
  try{
    stop-service salt-minion
    c:\salt\uninst.exe /S
  }catch{}
  Remove-Item $salt_dir -Recurse -Force
}


function install_salt() {
  write-host "install salt"
  # $cmd = "${install_file} /S /master=salt.example.com /minion-name=jebusk-testerama"
  $cmd = "${install_file} /S /minion-name=jebusk-testerama"
  invoke-expression $cmd
  Start-Sleep -s 20
  $master_sign_pub | Out-File $master_sign_pub_file
  $minion_conf | Out-File $minion_conf_file
  restart-service salt-minion
}

function get_file($file_url, $expected_file_hash) {
  if (!(Test-Path -path $install_file)) {
    curl.exe -L $file_url -o $install_file
  }

  $file_hash = $(Get-FileHash -Algorithm SHA256 $install_file).hash
  if ($file_hash -ne $expected_file_hash) {
    write-host "E: Invalid file hash! Local file $install_file hash is not equal to expected repo file hash."
    write-host "rm $install_file and run script again."
    cd $hdir
    exit(1)
  }
}


# $file_hash_url = "https://repo.saltstack.com/windows/Salt-Minion-${version}-Py3-x86-Setup.exe.sha256"
$file_url = "https://repo.saltstack.com/windows/Salt-Minion-${version}-Py3-x86-Setup.exe"
$expected_file_hash = "58FAF92AD1E76D973C225C5E333D9945017930BB9D63FC5C7F3C3180B1DFD3D1"
salt_uninstall
get_file $file_url $expected_file_hash
install_salt
cd $hdir
write-host "complete"
