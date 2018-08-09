$vnet = Get-AzureRmVirtualNetwork -Name royroyff-vnet -ResourceGroupName royroyff-vnet
$as = New-AzureRmAvailabilitySet -ResourceGroupName devops -Name test-as -Location "Southeast Asia"
$nic1 = New-AzureRmNetworkInterface -Name roy-test-nic -ResourceGroupName devops -Location "Southeast Asia" -SubnetId $vnet.Subnets[0].Id
New-AzureRmStorageAccount -ResourceGroupName devops -Name devopsstr -Type Standard_LRS -Location "Southeast Asia"
$sa = get-azurermstorageaccount -resourcegroupname devops -name devopsstr
$sa | New-azurestoragecontainer -permission off vhds
$OSdiskName = "roy-test-osdisk.vhd"
$OSDiskURI = $sa.PrimaryEndpoints.Blob + "vhds/" + $OSdiskName
$vmname = "roy-test"
$vmsize = "Standard_B1s"
$cred = Get-Credential -UserName lookup -Message lookup
$vmimage = Get-AzureRmVMImage -Location "Southeast Asia" -PublisherName OpenLogic -Offer CentOS -Skus 6.9 -Version 6.9.20170405
$vm = New-AzureRmVMConfig -VMName $vmname -VMSize $vmsize -AvailabilitySetId $as.Id
$vm = Set-AzureRmVMOperatingSystem -Linux -VM $vm -Credential $cred -ComputerName $vmname
$vm = Set-AzureRmVMSourceImage -VM $vm -PublisherName $vmimage.PublisherName -Offer $vmimage.Offer -Skus $vmimage.Skus -Version $vmimage.Version
$vm = Set-AzureRmVMOSDisk -VM $vm -Name $OSdiskName -VhdUri $OSDiskURI -CreateOption fromImage
$vm = Add-AzureRmVMNetworkInterface -VM $vm -id $nic1.Id
New-AzureRmVM -ResourceGroupName roy-test -Location "Southeast Asia" -VM $vm 