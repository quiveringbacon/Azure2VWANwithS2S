# Azure 2 VWAN with S2S

This creates 2 vwans with 1 hub in each and a spoke vnet attached to each hub. A site to site tunnel connects the 2 vhubs to allow the spokes to communicate. You'll be prompted for the resource group name, location where you want the resources created, your public ip and username and password to use for the VM's and the subscriptionID to use. NSG's are placed on the default subnets of each vnet allowing RDP access from your public ip. This also creates a logic app that will delete the resource group in 24hrs.

The topology will look like this:
![2wvanwithS2Slab](https://github.com/user-attachments/assets/88435b25-c763-4051-a70c-20c3fc0ba484)

You can run Terraform right from the Azure cloud shell by cloning this git repository with "git clone https://github.com/quiveringbacon/Azure2VWANwithS2S.git ./terraform".

Then, "cd terraform" then, "terraform init" and finally "terraform apply -auto-approve" to deploy.
