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
$version = "2019.2.6"
$salt_file_sha256 = "${wdir}\install.exe.sha256"
$salt_file = "${wdir}\install.exe"
$master_sign_pub_file = "c:\salt\conf\pki\minion\master_sign.pub"
$minion_conf_file = "c:\salt\conf\minion.d\minion.conf"

$master_sign_pub = @'
-----BEGIN PUBLIC KEY-----
xxxxxx
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
    Start-Sleep -s  10
    Remove-Item $salt_dir -Recurse -Force
  }catch{}
}


function check_service() {
  $i = 1
  While($i -ne 40){
    try{
      if(get-service salt-minion | Out-Null) {
        break
      }
    }catch{}
    $i++
    Start-Sleep -s  1
  }
}


function install_salt() {
  write-host "install salt"
  $cmd = "${salt_file} /S /master=salt.example.com /minion-name=jebusk-testerama"
  invoke-expression $cmd

  check_service

  $master_sign_pub | Out-File $master_sign_pub_file
  $minion_conf | Out-File $minion_conf_file
  restart-service salt-minion
}


function get_file($file_url, $file_dst, $expected_file_hash) {
  if (!(Test-Path -path $file_dst)) {
    curl.exe -L $file_url -o $file_dst
  }

  $file_hash = $(Get-FileHash -Algorithm SHA256 $file_dst).hash
  if ($file_hash -ne $expected_file_hash) {
    write-host "E: Invalid file hash! Local file $file_dst hash is not equal to expected repo file hash."
    write-host "rm $file_dst and run script again."
    cd $hdir
    exit(1)
  }
}


function main() {
  cd $wdir
  $salt_file_url = "https://repo.saltstack.com/windows/Salt-Minion-${version}-Py3-x86-Setup.exe"
  $nssm_file_url = "https://github.com/jeremybusk/share/blob/master/nssm.exe?raw=true"
  $nssm_file_hash = "F689EE9AF94B00E9E3F0BB072B34CAAF207F32DCB4F5782FC9CA351DF9A06C97"
  $nssm_file = "c:\salt\nssm.exe"
  $salt_file_hash = "58FAF92AD1E76D973C225C5E333D9945017930BB9D63FC5C7F3C3180B1DFD3D1"
  salt_uninstall
  get_file $salt_file_url $salt_file $salt_file_hash
  install_salt
  get_file $nssm_file_url $nssm_file $nssm_file_hash
  cd $hdir
  write-host "Install Complete"
}


main
