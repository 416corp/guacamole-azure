Get-WindowsCapability -Online | Where-Object Name -match openssh.server | Add-WindowsCapability -Online
