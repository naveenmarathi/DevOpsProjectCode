# 🚀 CI/CD Golang Web App Deployment with Kubernetes & CI/CD Pipeline

## 📄 Project Description

This project demonstrates the end-to-end development, containerization, and deployment of a Golang-based web application on a Kubernetes cluster hosted on AWS EC2. It showcases the implementation of modern DevOps practices, including Docker-based containerization, Kubernetes orchestration, and a fully automated CI/CD pipeline using Jenkins.

## 🚀 Key Features:

- Containerized Golang Application
  Developed a web application in Go and containerized it using Docker for consistent and portable deployments.

- Kubernetes Cluster Deployment (Kubeadm + AWS EC2)
  Deployed the application on a Kubernetes cluster set up using Kubeadm on AWS EC2 instances, enabling scalable and resilient infrastructure.

- CI/CD Pipeline with Jenkins + Docker + Kubernetes
  Implemented a fully automated CI/CD pipeline using Jenkins. The pipeline handles code build, Docker image creation, pushing to a registry, and deployment to    the Kubernetes cluster.

- GitHub Integration via Webhooks
  Integrated GitHub with Jenkins using webhooks to trigger automatic builds and deployments on every code commit, ensuring continuous integration.

- Zero-Downtime Deployments
  Leveraged Kubernetes rolling updates to achieve zero-downtime deployments, enhancing application reliability and user experience.

## 🛠️ Tools & Technologies

- **Jenkins** – CI/CD automation server (master/agent setup)
- **Docker** – Containerization of the application
- **Docker Hub** – Container registry for image storage
- **Kubernetes**(Kubeadm) - Deploying our applications. 
- **GitHub** – Source code repository
- **EC2 (AWS)** – Hosting Kubernetes master and agent nodes
- **GitHub Webhooks** - Automatically notify Jenkins of code changes (like pushes or pull requests), triggering the CI/CD pipeline without manual input.

## 🔄 Project Workflow

### Step 1: Create EC2 Instances  
Create **2 EC2 instances** – one for master, one for agent.

### Step 2: Setup Kubernetes Master Node and Slave Node by below installation guide

This guide outlines the steps needed to set up a Kubernetes cluster using `kubeadm`.

---

## AWS Setup

1. Ensure that all instances are in the same **Security Group**.
2. Expose port **6443** in the **Security Group** to allow worker nodes to join the cluster.
3. Expose port **22** in the **Security Group** to allows SSH access to manage the instance..

4. **Add Rules to the Security Group**:
    - **Allow SSH Traffic (Port 22)**:
      - **Type**: SSH
      - **Port Range**: `22`
      - **Source**: `0.0.0.0/0` (Anywhere) or your specific IP
    
    - **Allow Kubernetes API Traffic (Port 6443)**:
      - **Type**: Custom TCP
      - **Port Range**: `6443`
      - **Source**: `0.0.0.0/0` (Anywhere) or specific IP ranges

5. **Save the Rules**:
    - Click on **Create Security Group** to save the settings.

## Execute on Both "Master" & "Worker" Nodes

1. **Disable Swap**: Required for Kubernetes to function correctly.
    ```bash
    sudo swapoff -a
    ```

2. **Load Necessary Kernel Modules**: Required for Kubernetes networking.
    ```bash
    cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
    overlay
    br_netfilter
    EOF

    sudo modprobe overlay
    sudo modprobe br_netfilter
    ```

3. **Set Sysctl Parameters**: Helps with networking.
    ```bash
    cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
    net.bridge.bridge-nf-call-iptables  = 1
    net.bridge.bridge-nf-call-ip6tables = 1
    net.ipv4.ip_forward                 = 1
    EOF

    sudo sysctl --system
    lsmod | grep br_netfilter
    lsmod | grep overlay
    ```

4. **Install Containerd**:
    ```bash
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update
    sudo apt-get install -y containerd.io

    containerd config default | sed -e 's/SystemdCgroup = false/SystemdCgroup = true/' -e 's/sandbox_image = "registry.k8s.io\/pause:3.6"/sandbox_image = "registry.k8s.io\/pause:3.9"/' | sudo tee /etc/containerd/config.toml

    sudo systemctl restart containerd
    sudo systemctl status containerd
    ```

5. **Install Kubernetes Components**:
    ```bash
    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates curl gpg

    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

    sudo apt-get update
    sudo apt-get install -y kubelet kubeadm kubectl
    sudo apt-mark hold kubelet kubeadm kubectl
    ```

## Execute ONLY on the "Master" Node

1. **Initialize the Cluster**:
    ```bash
    sudo kubeadm init
    ```

2. **Set Up Local kubeconfig**:
    ```bash
    mkdir -p "$HOME"/.kube
    sudo cp -i /etc/kubernetes/admin.conf "$HOME"/.kube/config
    sudo chown "$(id -u)":"$(id -g)" "$HOME"/.kube/config
    ```

3. **Install a Network Plugin (Calico)**:
    ```bash
    kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.0/manifests/calico.yaml
    ```

4. **Generate Join Command**:
    ```bash
    kubeadm token create --print-join-command
    ```

> Copy this generated token for next command.

---

## Execute on ALL of your Worker Nodes

1. Perform pre-flight checks:
    ```bash
    sudo kubeadm reset pre-flight checks
    ```

2. Paste the join command you got from the master node and append `--v=5` at the end:
    ```bash
    sudo kubeadm join <private-ip-of-control-plane>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash> --cri-socket 
    "unix:///run/containerd/containerd.sock" --v=5
    ```

    > **Note**: When pasting the join command from the master node:
    > 1. Add `sudo` at the beginning of the command
    > 2. Add `--v=5` at the end
    >
    > Example format:
    > ```bash
    > sudo <paste-join-command-here> --v=5
    > ```

---

## Verify Cluster Connection

**On Master Node:**

```bash
kubectl get nodes

```

   <img src="https://raw.githubusercontent.com/faizan35/kubernetes_cluster_with_kubeadm/main/Img/nodes-connected.png" width="70%">

---

## Verify Container Status on Worker Node
<img src="https://github.com/user-attachments/assets/c3d3732f-5c99-4a27-a574-86bc7ae5a933" width="70%">





### ✅** Step-by-Step Docker Installation & GitHub Integration**

### Step 1: Install Docker (Docker Engine + Docker CLI)

🖥️ For Linux (Ubuntu/Debian)

### 1. Update system packages:

      sudo apt update

      sudo apt upgrade -y
   
### 2. Install depndencies:

      sudo apt install \
      ca-certificates \
      curl \
      gnupg \
      lsb-release
      
### 3. Add Docker’s official GPG key:

      sudo mkdir -m 0755 -p /etc/apt/keyrings
   
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
   
      sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

### 4. Add Docker repository:

      echo \
     "deb [arch=$(dpkg --print-architecture) \
      signed-by=/etc/apt/keyrings/docker.gpg] \
      https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

### 5. Install Docker Engine:

      sudo apt update

      sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

### 6. Check Docker version:

      docker --version

### 7. Add current user to the docker group:

      sudo usermod -aG docker $USER

      newgrp docker


### ✅ Step by step Jenkins Installation & GitHub Integration


### 🔧 Step 1: Install Jenkins (on Ubuntu/Debian) 
    
    🖥️ 1.1. Update system packages
    
      sudo apt update
      
      sudo apt upgrade -y

    🖥️ 1.2. Install Java (required for Jenkins)
      
      sudo apt install openjdk-17-jdk -y

      Verify:
    
      java -version

    🖥️ 1.3. Add Jenkins GPG key and repository 
    
      curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
      /usr/share/keyrings/jenkins-keyring.asc > /dev/null
   
      echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
      https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
      /etc/apt/sources.list.d/jenkins.list > /dev/null

    🖥️ 1.4. Install Jenkins
    
      sudo apt update
      
      sudo apt install jenkins -y

## 🚀 step 2: Start and Enable Jenkins  
        
      sudo systemctl start jenkins
        
      sudo systemctl enable jenkins

      Check status:

      sudo systemctl status jenkins

## 🌐 step 3: Access Jenkins Web Interface
    
      Open browser and go to:

      http:<your IP address of EC2>:8080

## 🔐 step 4: Unlock Jenkins (first-time setup)

      Run this command to get the admin password:

      sudo cat /var/lib/jenkins/secrets/initialAdminPassword    

##  👤 step 5: Create Admin User

Set up:

     - Username

     - Password

     - Full Name

     - Email

     - Then proceed.

##  🔗 step 6: Connect Jenkins to GitHub
    
     🔧6.1. Install Git & GitHub Plugins

      In Jenkins:

      - Go to: Manage Jenkins > Plugins
 
      - Search for and install:

      - Git plugin

      - GitHub plugin

      - GitHub Integration Plugin

### ✅ Conclusion

      This project showcases a complete DevOps pipeline by developing, containerizing, and deploying a Golang 
      web application on a Kubernetes cluster with automated CI/CD, seamless GitHub integration, and zero-downtime deployments—ensuring scalable,
      reliable, and efficient software delivery.
