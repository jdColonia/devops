# 1. Workshop - Ansible

## Introducción a Ansible

### Resumen

Este informe explica Ansible como una herramienta de automatización y su uso en la instalación de Docker y el despliegue de contenedores. Como caso de uso, se muestra cómo automatizar el despliegue de un contenedor que ejecuta el juego de Mario Bros en una máquina virtual remota. El proyecto consta de dos playbooks principales:

- `install_docker.yml`: Instala Docker en la VM objetivo.
- `run_container.yml`: Despliega un contenedor de Docker que ejecuta el juego de Mario Bros.
  El diseño del proyecto es modular y reutilizable, aprovechando la naturaleza idempotente de Ansible para garantizar resultados consistentes en múltiples ejecuciones.

### Ansible: Automatización de Infraestructura y Configuración

Ansible es una herramienta de automatización de código abierto utilizada para la gestión de configuraciones, despliegue de aplicaciones y orquestación de infraestructura. Su diseño simplifica la administración de múltiples servidores sin necesidad de instalar software adicional en ellos.

#### Características Clave de Ansible

- **Sin agente**: No requiere instalación de software en las máquinas administradas; se comunica a través de SSH.
- **Idempotente**: Garantiza que ejecutar el mismo playbook múltiples veces producirá el mismo resultado sin efectos adversos.
- **Basado en YAML**: Utiliza playbooks escritos en YAML, lo que facilita su lectura y mantenimiento.
- **Extensible y modular**: Permite organizar configuraciones mediante roles reutilizables.

#### Estructura del Proyecto

Los proyectos en Ansible suelen seguir una estructura organizada que permite mantener separadas las configuraciones, los playbooks y los roles. Un ejemplo de estructura típica es:

```plaintext
/
├── inventory/
│   └── hosts.ini
├── playbooks/
│   ├── install_docker.yml
│   └── run_container.yml
├── roles/
│   ├── docker_install/
│   │   └── tasks/
│   │       └── main.yml
│   └── docker_container/
│       └── tasks/
│           └── main.yml
└── ansible.cfg
```

#### Componentes Principales

##### Inventario (`inventory/hosts.ini`)

Define las máquinas sobre las cuales se ejecutarán los playbooks de Ansible. Por ejemplo:

```ini
[azure_vm]
vm-ip ansible_user=vmadmin ansible_ssh_pass=pass
```

- `vm-ip`: Dirección IP de la máquina objetivo.
- `ansible_user`: Usuario para conectarse vía SSH.
- `ansible_ssh_pass`: Contraseña para autenticación SSH.

##### Playbooks

###### 1. `install_docker.yml`

Este playbook instala Docker en la VM objetivo.

```YAML
---
- hosts: azure_vm
  become: yes
  roles:
    - docker_install
```

###### 2. `run_container.yml`

Este playbook despliega un contenedor de Docker que ejecuta una aplicación específica

```YAML
---
- hosts: azure_vm
  become: yes
  roles:
    - docker_container
```

##### Roles

###### 1. `docker_install`

Contiene las tareas necesarias para instalar Docker en la máquina remota.

```YAML
- name: Instalar dependencias de Docker
  apt:
    name:
      - apt-transport-https
      - ca-certificates
      - curl
      - software-properties-common
    state: present
    update_cache: yes

- name: Añadir la clave GPG oficial de Docker
  ansible.builtin.apt_key:
    url: https://download.docker.com/linux/ubuntu/gpg
    state: present

- name: Añadir el repositorio de Docker
  ansible.builtin.apt_repository:
    repo: deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable
    state: present

- name: Instalar Docker CE
  apt:
    name: docker-ce
    state: present
    update_cache: yes
```

###### 2. Rol `docker_container`

Define la ejecución de un contenedor en la máquina objetivo. En este caso, se utiliza la imagen `pengbai/docker-supermario` para desplegar el juego de Mario Bros.

```YAML
- name: Ejecutar contenedor de Mario Bros
  docker_container:
    name: supermario-container
    image: 'pengbai/docker-supermario:latest'
    state: started
    ports:
      - '8787:8080'
```

##### Configuración de Ansible (`ansible.cfg`)

Define opciones globales de Ansible:

```ini
[defaults]
host_key_checking = False
roles_path = ./roles
inventory = ./inventory/hosts.ini
```

### Implementación Específica: Despliegue de Mario Bros en un Contenedor

Para demostrar el uso de Ansible, se ha implementado una solución práctica en la que se despliega un contenedor con el juego de Mario Bros en una VM remota (la VM se encuentra en `https://github.com/jdColonia/devops/tree/main/terraform/2-workshop`). Este despliegue requiere configurar reglas de seguridad para permitir el acceso al puerto 8787.

#### Configuración de Seguridad en la VM

Se debe agregar una regla de seguridad en el grupo de seguridad de red (NSG) de la VM para permitir el tráfico en el puerto 8787:

```HCL
security_rule {
    name                       = "ansible_rule"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8787"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
}
```

Esta regla permite el tráfico desde cualquier dirección IP a la VM en el puerto 8787.

![Images](./images/Pasted%20image%2020250321020049.png)

#### Ejecución de los Playbooks

Una vez configurado el `inventory/hosts.ini` con la información de la VM.

![Images](./images/Pasted%20image%2020250321015313.png)

Se ejecutan los playbooks con los siguientes comandos:

##### Instalar Docker:

```
ansible-playbook -i inventory/hosts.ini playbooks/install_docker.yml
```

![Images](./images/Pasted%20image%2020250321015546.png)

##### Ejecutar el Contenedor:

```
ansible-playbook -i inventory/hosts.ini playbooks/run_container.yml
```

![Images](./images/Pasted%20image%2020250321015724.png)

### Acceso a la Aplicación

Después de ejecutar los playbooks y configurar la seguridad, el juego de Mario Bros estará disponible en la siguiente URL:

```
http://<VM_IP>:8787
```

Reemplazar `<VM_IP>` con la dirección IP pública de la VM.

![Images](./images/Pasted%20image%2020250321015800.png)
