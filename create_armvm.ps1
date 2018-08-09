#创建资源组
New-AzureRmResourceGroup -Name devops1 -Location "Southeast Asia"

创建网络相关
创建vnet
$subnet1 = New-AzureRmVirtualNetworkSubnetConfig -Name Subnet-1 -AddressPrefix 172.17.1.0/24
$vnet = New-AzureRmVirtualNetwork -Name vnet1 -ResourceGroupName hwarm01 -Location "China East" -AddressPrefix 172.17.0.0/16 -Subnet $subnet1,$subnet2,$subnet3

创建保留ip
$piplb = New-AzureRmPublicIpAddress -ResourceGroupName hwarm01 -Name hwpiplb01 -Location "China East" -AllocationMethod Static

创建可用性集合
$as = New-AzureRmAvailabilitySet -ResourceGroupName devops -Name test-as -Location "Southeast Asia"
创建负载均衡
$fendip = New-AzureRmLoadBalancerFrontendIpConfig -Name fendip -PublicIpAddressId $piplb.Id
$bendip = New-AzureRmLoadBalancerBackendAddressPoolConfig -Name bendip
$inboundNATRule1 = New-AzureRmLoadBalancerInboundNatRuleConfig -name ssh1 -FrontendIpConfigurationId $fendip.Id -Protocol Tcp -FrontendPort 22122 -BackendPort 22
$inboundNATRule2 = New-AzureRmLoadBalancerInboundNatRuleConfig -name ssh2 -FrontendIpConfigurationId $fendip.Id -Protocol Tcp -FrontendPort 22222 -BackendPort 22
$lbprobe = New-AzureRmLoadBalancerProbeConfig -Name hwlbprobe -Protocol Tcp -Port 80 -IntervalInSeconds 15 -ProbeCount 2
$lbrule = New-AzureRmLoadBalancerRuleConfig -Name hwlbrule -FrontendIpConfigurationId $fendip.Id -BackendAddressPoolId $bendip.Id -ProbeId $lbprobe.Id -Protocol Tcp -FrontendPort 80 -BackendPort 80 -LoadDistribution SourceIP
$lb = New-AzureRmLoadBalancer -Name hwlb -ResourceGroupName hwarm01 -Location "China East" -FrontendIpConfiguration $fendip -BackendAddressPool $bendip -Probe $lbprobe -InboundNatRule $inboundNATRule1 -LoadBalancingRule $lbrule

创建网卡
$nic1 = New-AzureRmNetworkInterface -Name roy-test-nic -ResourceGroupName devops -Location "Southeast Asia" -PrivateIpAddress 172.17.1.4 -SubnetId $vnet.Subnets[0].Id -LoadBalancerBackendAddressPoolId $lb.BackendAddressPools[0].id -LoadBalancerInboundNatRuleId $lb.InboundNatRules[0].Id
$nic2 = New-AzureRmNetworkInterface -Name nic2 -ResourceGroupName hwarm01 -Location "China East" -PrivateIpAddress 172.17.1.5 -SubnetId $vnet.Subnets[0].Id -LoadBalancerBackendAddressPoolId $lb.BackendAddressPools[0].id -LoadBalancerInboundNatRuleId $lb.InboundNatRules[1].Id



创建存储相关
New-AzureRmStorageAccount -ResourceGroupName devops -Name devopsstr -Type Standard_LRS -Location "Southeast Asia"

创建容器
$sa = Get-AzureRmStorageAccount -ResourceGroupName hwarm01 -Name hwarmsa01
$sa | New-AzureStorageContainer -Permission Off vhds

定义osdisk，datadisk的URI
$OSdiskName = "hwarmvm01-osdisk.vhd"
$OSDiskURI = $sa.PrimaryEndpoints.Blob.AbsoluteUri + "vhds/" + $OSdiskName
$dataDiskName = "hwarmvm01-datadisk.vhd"
$dataDiskURI = $sa.PrimaryEndpoints.Blob.AbsoluteUri + "vhds/" + $dataDiskName



定义vm基本属性
$vmname = "hwarmvm01"
$vmsize = "Standard_A1"
$cred = Get-Credential -UserName hengwei -Message hwarmvm01
$vm = New-AzureRmVMConfig -VMName $vmname -VMSize $vmsize -AvailabilitySetId $has.Id


定义vmimage的信息
Get-AzureRmVMImage -Location "Southeast Asia" -PublisherName OpenLogic -Offer CentOS -Skus 6.9
$vmimage = Get-AzureRmVMImage -Location "China East" -PublisherName OpenLogic -Offer CentOS -Skus 6.9 -Version 6.9.20170405

定义vm操作系统
$vm = Set-AzureRmVMOperatingSystem -Linux -VM $vm -Credential $cred -ComputerName $vmname


定义vm磁盘信息
$vm = Set-AzureRmVMSourceImage -VM $vm -PublisherName $vmimage.PublisherName -Offer $vmimage.Offer -Skus $vmimage.Skus -Version $vmimage.Version
$vm = Set-AzureRmVMOSDisk -VM $vm -Name $OSdiskName -VhdUri $OSDiskURI -CreateOption fromImage
$vm = add-AzureRmVMDataDisk -VM $vm -Name $dataDiskName -VhdUri $dataDiskURI -CreateOption empty -DiskSizeInGB 100

定义vm网卡信息
$vm = Add-AzureRmVMNetworkInterface -VM $vm -id $nic1.Id

创建虚拟机
New-AzureRmVM -ResourceGroupName hwarm01 -Location "China East" -VM $vm  