Import-Module '480-utils' -Force 

$conf = Get-480Config -config_path "/home/eckles/SYS-480-Advanced-DevOps/480.json"
#$confPath = "/home/eckles/SYS-480-Advanced-DevOps/480.json"


480Connect -server $conf.vcenter_server

#Deploy-Clone -conf $confPath
#New-Network -conf $confPath
Get-NetworkDetails
#Start-SingleVM
#Stop-SingleVM
#Set-Network