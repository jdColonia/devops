# 1. Workshop - Azure

## Overview

This report explains the process of creating virtual machines in Azure, for both Linux and Windows environments. It includes the steps for configuration, access, and remote connection to the created instances.

## Create a Virtual Machine in Linux

### 1. Access the Azure Portal

To start, log in to the Azure Portal and search for the **"Virtual Machines"** option in the services bar. Select this service to access the VM management panel:

![Image](./images/Pasted%20image%2020250303101218.png)

### 2. Initial Configuration

On the main page of **Virtual Machines**, click **"Create"** and choose **"Azure Virtual Machine"**:

![Image](./images/Pasted%20image%2020250303101412.png)

In the **"Basics"** tab, under **"Project Details"**, create the resource group:

![Image](./images/Pasted%20image%2020250303101929.png)

### 3. Instance Details

Under **"Instance Details"**, assign a name to the VM, select an image, and choose a suitable region and size:

![Image](./images/Pasted%20image%2020250303104213.png)

### 4. Administrator Account and Security

In **"Administrator Account"**, select the authentication type, enter the username, and generate the SSH key:

![Image](./images/Pasted%20image%2020250303103157.png)

### 5. Inbound Port Rules

Under **"Inbound Port Rules"**, configure the allowed port rules:

![Image](./images/Pasted%20image%2020250303103233.png)

### 6. Configure Tags and Final Review

In the **"Tags"** tab, add tags like `version: 1.0` and `environment: dev` to organize the resource:

![Image](./images/Pasted%20image%2020250303103430.png)

### 7. Create the Virtual Machine

Finally, click **"Review + Create"** to validate the configuration. If there are no errors, select **"Create"** to start the deployment:

![Image](./images/Pasted%20image%2020250303104811.png)

Once the deployment is complete, download the private `.pem` key and create the resource:

![Image](./images/Pasted%20image%2020250303104920.png)  
![Image](./images/Pasted%20image%2020250303105135.png)

### 8. Download the Key and Access the VM

Next, access the VM by clicking **"Go to Resource"** and copy its **public IP address**:

![Image](./images/Pasted%20image%2020250303105341.png)

### 9. SSH Connection

From a terminal (Linux/Mac) or PowerShell (Windows), run the following command, replacing `[PUBLIC_IP]` and the path to the `.pem` file:

```bash
ssh -i ~/Downloads/JuanColonia-VM_key.pem azureuser@20.55.41.1
```

![Image](./images/Pasted%20image%2020250303105912.png)

## Create a Virtual Machine in Windows

### 1. Initial Configuration

Repeat steps 1 and 2 from the previous section to access the VM service and create a new virtual machine. Under **"Instance Details"**, select a Windows image (for example, **"Windows Server 2022"**) and adjust the size:

![Image](./images/Pasted%20image%2020250303111148.png)

### 2. Administrator Account and Ports

In **"Administrator Account"**, enter a username and password. Under **"Inbound Port Rules"**, enable the **RDP (3389)** port to allow remote connections:

![Image](./images/Pasted%20image%2020250303111326.png)

### 3. Tags and Deployment

Add the same tags (`version` and `environment`) and proceed with the validation and creation of the VM:

![Image](./images/Pasted%20image%2020250303103430.png)  
![Image](./images/Pasted%20image%2020250303111639.png)  
![Image](./images/Pasted%20image%2020250303111924.png)

### 4. Connect Using RDP

Once the VM is deployed, download the `.rdp` file from the **"Connect"** option in the VM panel:

![Image](./images/Pasted%20image%2020250303112016.png)  
![Image](./images/Pasted%20image%2020250303112154.png)

Finally, run the file, enter the administrator password, and access the Windows remote desktop:

![Image](./images/Pasted%20image%2020250303112636.png)
