# A Global Hub and Spoke Network Topology

[![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fbentaylorwork%2Fazure-arm-templates%2Fmaster%2Fvnet-hub-spoke-multi-region-multi-resource-group%2Fazuredeploy.json)
[![Deploy to Azure](http://armviz.io/visualizebutton.png)](http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Fbentaylorwork%2Fazure-arm-templates%2Fmaster%2Fvnet-hub-spoke-multi-region-multi-resource-group%2Fazuredeploy.json)

## Overview
This template deploys a hub and spoke network into two separate Resource Groups which can be in different regions. The two hub networks are connected via VPN gateways.

The amount of spokes and the configuration can be altered in the spokes array of the variables section, all peering is dynamic, so new spokes are automatically peered to the hub vnet.

![alt text](images/network-hub-spoke-vpn-gw.png "Topology")

## Notes
* The two Resource Groups where you want to deploy the resources must be created prior to the deployment of this template.

## Links
https://docs.microsoft.com/en-us/azure/architecture/reference-architectures/hybrid-networking/hub-spoke

## Contributors
* Ben Taylor - ben@bentaylor.work