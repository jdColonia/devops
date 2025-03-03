# 1. Workshop - Jenkins

## Overview

Jenkins is a Continuous Integration and Continuous Delivery (CI/CD) tool that automates tasks in software development. This report explains step by step how to install a Jenkins controller in a Docker container, configure it, connect an agent, and create automated pipelines. The workshop has three parts: installing the controller in Docker, configuring an agent on the same network, and creating pipelines with custom scripts that integrate GitHub repositories, build with Maven, and manage parameters.

## Solution

### Part One: Installing the Jenkins controller in Docker

> A bridge network in Docker is a network that allows containers to communicate with each other while isolating those that are not connected to it.

#### Creating the Docker network

We start by creating a bridge network in Docker:

```bash
docker network create jenkins
```

![Image](./images/Pasted%20image%2020250301135148.png)

#### Running the `docker:dind` container

Next, run the following command to download and run the `docker:dind` image:

```bash
docker run --name jenkins-docker --rm --detach \
  --privileged --network jenkins --network-alias docker \
  --env DOCKER_TLS_CERTDIR=/certs \
  --volume jenkins-docker-certs:/certs/client \
  --volume jenkins-data:/var/jenkins_home \
  --publish 2376:2376 \
  docker:dind --storage-driver overlay2
```

![Image](./images/Pasted%20image%2020250301135516.png)

#### Building the custom Jenkins image

Continue by customizing the Jenkins Docker image with these steps:

1. Create a `Dockerfile` with this content:

```dockerfile
FROM jenkins/jenkins:2.492.1-jdk17
USER root
RUN apt-get update && apt-get install -y lsb-release
RUN curl -fsSLo /usr/share/keyrings/docker-archive-keyring.asc \
  https://download.docker.com/linux/debian/gpg
RUN echo "deb [arch=$(dpkg --print-architecture) \
  signed-by=/usr/share/keyrings/docker-archive-keyring.asc] \
  https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
RUN apt-get update && apt-get install -y docker-ce-cli
USER jenkins
RUN jenkins-plugin-cli --plugins "blueocean docker-workflow"
```

2. Build the custom Docker image:

```bash
docker build -t myjenkins-blueocean:2.492.1-1 .
```

![Image](./images/Pasted%20image%2020250228120727.png)

After finishing the process, we should have two built images:

![Image](./images/Pasted%20image%2020250301141853.png)

#### Running the Jenkins controller

Finally, run this command to start the Jenkins container, connect it to the network, and expose the necessary ports:

```sh
docker run --name jenkins-blueocean --restart=on-failure --detach \
  --network jenkins --env DOCKER_HOST=tcp://docker:2376 \
  --env DOCKER_CERT_PATH=/certs/client --env DOCKER_TLS_VERIFY=1 \
  --publish 8080:8080 --publish 50000:50000 \
  --volume jenkins-data:/var/jenkins_home \
  --volume jenkins-docker-certs:/certs/client:ro \
  myjenkins-blueocean:2.492.1-1
```

![Image](./images/Pasted%20image%2020250301141834.png)

After running the command, we should have two running containers:

![Image](./images/Pasted%20image%2020250301142029.png)

#### Initial setup

With the previous steps completed, we have unlocked access to Jenkins. To access it, enter this URL in the browser: `http://localhost:8080`.

![Image](./images/Pasted%20image%2020250301142155.png)

To get the admin password, run this command and copy the output:

```bash
docker exec jenkins-blueocean cat /var/jenkins_home/secrets/initialAdminPassword
```

![Image](./images/Pasted%20image%2020250301142308.png)

Paste the password and click continue:

![Image](./images/Pasted%20image%2020250228121324.png)

Select the option to install suggested plugins:

![Image](./images/Pasted%20image%2020250228121338.png)

After installation, create an admin user:

![Image](./images/Pasted%20image%2020250228121525.png)

Confirm the instance URL:

![Image](./images/Pasted%20image%2020250228121554.png)

After completing the setup, access the Jenkins dashboard:

![Image](./images/Pasted%20image%2020250228121604.png)
![Image](./images/Pasted%20image%2020250228121626.png)

Additionally, use these commands:

- View Jenkins logs with:

```bash
docker logs jenkins-blueocean
```

- To stop Jenkins:

```bash
docker stop jenkins-blueocean
```

By following these steps, we have installed and configured a Jenkins controller in a Docker container, ensuring basic setup, plugin installation, and admin user creation.

### Part Two: Configuring the Jenkins Agent

#### Generating an SSH key

To configure the Jenkins agent, first generate an SSH key to authenticate the controller and agent. Run this command in the terminal:

```bash
ssh-keygen -f ~/.ssh/jenkins_agent_key
```

![Image](./images/Pasted%20image%2020250228122201.png)

#### Setting up credentials in Jenkins

After generating the SSH key, access the Jenkins interface and go to `Manage Jenkins > Credentials`. Here, create a new credential to store the generated key:

![Image](./images/Pasted%20image%2020250228122510.png)

Enter the following data:

- **Kind:** SSH Username with private key.
- **ID:** jenkins.
- **Description:** The jenkins ssh key.
- **Username:** jenkins.
- **Private Key:** Enter the content of the `~/.ssh/jenkins_agent_key` file. Get it with this command:
  ```bash
  cat ~/.ssh/jenkins_agent_key
  ```
  ![Image](./images/Pasted%20image%2020250302231323.png)

After finishing, the setup should look like this:

![Image](./images/Pasted%20image%2020250302231423.png)

#### Deploying the agent as a container

With the credentials set up, deploy the Jenkins agent in a Docker container. Run this command:

```bash
docker run -d --rm --name=agent1 --network jenkins -p 22:22 \
-e "JENKINS_AGENT_SSH_PUBKEY=$(cat ~/.ssh/jenkins_agent_key.pub)" \
jenkins/ssh-agent:alpine-jdk17
```

![Image](./images/Pasted%20image%2020250301145506.png)

After running the command, the Jenkins agent container will start:

![Image](./images/Pasted%20image%2020250301153620.png)

#### Registering the node in Jenkins

Next, register the agent in Jenkins. Access the Jenkins interface and go to `Manage Jenkins > Nodes`:

![Image](./images/Pasted%20image%2020250301153831.png)

Create a new node named `agent1`:

![Image](./images/Pasted%20image%2020250301154108.png)

Configure the node with these parameters:

- **Remote root directory:** /home/jenkins
- **Label:** agent1
- **Usage:** only build jobs with label expression…
- **Launch method:** Launch agents by connecting it to the controller
- **Availability:** Keep this agent online as much as possible

![Image](./images/Pasted%20image%2020250302233220.png)

Initially, the `agent1` node will not connect automatically. To fix this, access the node configuration and copy the command generated by Jenkins to establish the connection:

![Image](./images/Pasted%20image%2020250302233418.png)

Run the command in your terminal and verify the connection is successful:

![Image](./images/Pasted%20image%2020250302233819.png)

As seen, the connection succeeded, and the agent is ready to run pipelines.

### Part Three: Creating Pipelines and Scripts

> A pipeline in Jenkins is a set of automated tasks that build, test, and deploy software. It is defined as a sequential workflow triggered by an event.

#### Creating a basic pipeline in Jenkins

To create a pipeline in Jenkins, go to `Jenkins > New Item > Pipeline`:

![Image](./images/Pasted%20image%2020250302234808.png)

Now, configure the pipeline with this script:

```groovy
pipeline {
    agent any
    tools {
	    maven "mavenInstall"
    }
    stages {
        stage('Clone Repository') {
            steps {
                git 'https://github.com/jenkins-docs/simple-java-maven-app.git'
            }
        }
        stage('Build') {
            steps {
                sh 'mvn clean package'
            }
        }
        stage('Test') {
            steps {
                sh 'mvn test'
            }
        }
    }
}
```

![Image](./images/Pasted%20image%2020250303000119.png)

Save and run the pipeline. Observe all stages executed successfully:

![Image](./images/Pasted%20image%2020250303000717.png)
![Image](./images/Pasted%20image%2020250303002434.png)

#### Integration with GitHub and Maven

Now, create another pipeline that includes more Maven features and triggers based on code from GitHub:

```groovy
pipeline {
    agent any
    tools {
	    maven "mavenInstall"
    }
    stages {
        stage('Clone Repository') {
            steps {
                git 'https://github.com/jenkins-docs/simple-java-maven-app.git'
            }
        }
        stage('Build') {
            steps {
                sh 'mvn clean package'
            }
        }
        stage('Test') {
            steps {
                sh 'mvn test'
            }
        }
        stage('Deliver') {
            steps {
                sh './jenkins/scripts/deliver.sh'
            }
        }
    }
}
```

![Image](./images/Pasted%20image%2020250303002255.png)

Save and run. Observe everything works correctly:

![Image](./images/Pasted%20image%2020250303002601.png)
![Image](./images/Pasted%20image%2020250303002645.png)

#### Verification and download of the project

Next, modify the pipeline to check if the project exists; if yes, delete the folder before downloading again:

```groovy
pipeline {
    agent any
    tools {
	    maven "mavenInstall"
    }
    stages {
	    stage('Cleanup') {
			steps {
				script {
					if (fileExists('simple-java-maven-app')) {
						echo "Removing existing directory..."
						sh 'rm -rf simple-java-maven-app'
					}
				}
			}
		}
        stage('Clone Repository') {
            steps {
                git 'https://github.com/jenkins-docs/simple-java-maven-app.git'
            }
        }
        stage('Build') {
            steps {
                sh 'mvn clean package'
            }
        }
        stage('Test') {
            steps {
                sh 'mvn test'
            }
        }
        stage('Deliver') {
            steps {
                sh './jenkins/scripts/deliver.sh'
            }
        }
    }
}
```

![Image](./images/Pasted%20image%2020250303003127.png)

Save and run. Observe everything works correctly:

![Image](./images/Pasted%20image%2020250303003213.png)

#### Adding a parameter to select the branch

Update the pipeline by adding a parameter to choose the branch to build.
Go to the pipeline configuration and check `This build is parameterized`. Then add a `String` parameter named `BRANCH`.

![Image](./images/Pasted%20image%2020250303004026.png)

Now modify the script to use the parameter. Since the project currently only has the `master` branch, set it as the default:

```groovy
pipeline {
    agent any
    tools {
	    maven "mavenInstall"
    }
    parameters {
		string(name: 'BRANCH', defaultValue: 'master', description: 'Branch to build')
	}
    stages {
	    stage('Cleanup') {
			steps {
				script {
					if (fileExists('simple-java-maven-app')) {
						echo "Removing existing directory..."
						sh 'rm -rf simple-java-maven-app'
					}
				}
			}
		}
        stage('Clone Repository') {
            steps {
                git 'https://github.com/jenkins-docs/simple-java-maven-app.git'
            }
        }
        stage('Build') {
            steps {
                sh 'mvn clean package'
            }
        }
        stage('Test') {
            steps {
                sh 'mvn test'
            }
        }
        stage('Deliver') {
            steps {
                sh './jenkins/scripts/deliver.sh'
            }
        }
    }
}
```

![Image](./images/Pasted%20image%2020250303004602.png)

Save and run:

![Image](./images/Pasted%20image%2020250303004429.png)

Verify everything works correctly:

![Image](./images/Pasted%20image%2020250303004724.png)

#### Using an external file (`Jenkinsfile`)

Finally, move the pipeline script to an external file named `Jenkinsfile`. Fork the repository and add the file:

![Image](./images/Pasted%20image%2020250303005335.png)

Then configure Jenkins to use the `Jenkinsfile` stored in the repository:

![Image](./images/Pasted%20image%2020250303005528.png)

Run and confirm everything works:

![Image](./images/Pasted%20image%2020250303005629.png)
![Image](./images/Pasted%20image%2020250303005652.png)
