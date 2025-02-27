# 1. Workshop - Docker

## Overview

This activity is based on running Docker containers and checking and configuring the Docker daemon in the storage and logging drivers sections.

## Solution

### 1. Run a Hello World container

To start a container with the `hello-world` image, run the command:

```bash
docker run hello-world
```

This command downloads the image (if not present) and runs it, showing a welcome message.  
![Image](./images/Pasted%20image%2020250225221441.png)

### 2. Change the Storage Driver to `devicemapper`

> The Storage Driver in Docker is a mechanism responsible for storing data and image layers in a container.

Before changing the storage driver, we can check the current storage driver with:

```bash
docker info | grep "Storage Driver"
```

![Image](./images/Pasted%20image%2020250226083822.png)

To modify the configuration file:

1. Open the Docker daemon configuration file:

```bash
sudo nano /etc/docker/daemon.json
```

2. Add/modify the following configuration:

```json
{
  "storage-driver": "devicemapper"
}
```

3. Save and close the file (`Ctrl + X`, then `Y`, and Enter).
4. Restart the Docker service:

```bash
sudo systemctl restart docker
```

![Image](./images/Pasted%20image%2020250226081520.png)

5. Check the change by running:

```bash
docker info | grep "Storage Driver"
```

![Image](./images/Pasted%20image%2020250226081558.png)

> These errors happen because the Device Mapper Driver was deprecated from Docker version 25.0.

Since `devicemapper` is deprecated, we downgrade to a version older than 25.0.  
![Image](./images/Pasted%20image%2020250226220051.png)

### 3. Restore Storage Driver to `overlay2`

Repeat the same steps as before, but edit `/etc/docker/daemon.json` and set:

```json
{
  "storage-driver": "overlay2"
}
```

Then, restart Docker:

```bash
sudo systemctl restart docker
```

Check the change with:

```bash
docker info | grep "Storage Driver"
```

![Image](./images/Pasted%20image%2020250226082514.png)

### 4. Run Nginx version 1.18.0

To run this version of Nginx, execute the following command:

```bash
docker run nginx:1.18.0
```

This will start the container in the foreground.  
![Image](./images/Pasted%20image%2020250226082701.png)

### 5. Run Nginx in the background

To run in the background (detached mode), we use the `-d` flag:

```bash
docker run -d nginx:1.18.0
```

![Image](./images/Pasted%20image%2020250226082732.png)

### 6. Configure Nginx

To configure Nginx with the following settings:

- Container name: `ngnix18`
- Restart on failure
- Redirect port `443` to `80`
- Reserve `250M` of memory
- Use Nginx version `1.18.0`

Run the following command:

```bash
docker run -d --name ngnix18 --restart=on-failure -p 443:80 --memory=250m nginx:1.18.0
```

![Image](./images/Pasted%20image%2020250226082846.png)

### 7. Check and change Logging Driver to `journald`

> The Logging Driver in Docker is a mechanism that allows obtaining information from running containers and services.

To change the log driver, we first check the current log driver:

```bash
docker info | grep "Logging Driver"
```

It should show `json-file` (default).  
![Image](./images/Pasted%20image%2020250226083252.png)

To change the driver to `journald`, we modify `daemon.json` and add the following field:

```json
{
  "log-driver": "journald"
}
```

Now, we check the change:

```bash
docker info | grep "Logging Driver"
```

![Image](./images/Pasted%20image%2020250226083650.png)
