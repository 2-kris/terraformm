# NKP EKS Cluster (Terraform)

## 📌 Overview

This project provisions a **production-grade Amazon EKS cluster** using Terraform with the following characteristics:

* Kubernetes version: **1.34**
* Managed Node Group (3 × t3.medium)
* Private worker nodes (no public IPs)
* **No NAT Gateway (cost-optimized)**
* Uses **VPC Endpoints for AWS service access**
* OIDC enabled (IRSA ready)
* Public + Private API endpoint access

---

## 🏗️ Architecture

### VPC

* CIDR: `10.0.0.0/16`
* 2 Availability Zones (`ap-south-1a`, `ap-south-1b`)

### Subnets

* **Public Subnets**

  * Used for Load Balancers (future use)
  * Tagged: `kubernetes.io/role/elb = 1`

* **Private Subnets**

  * Used for EKS worker nodes
  * Tagged: `kubernetes.io/role/internal-elb = 1`

---

## 🔗 Networking (No NAT Design)

This setup avoids NAT Gateway by using **VPC Endpoints**.

### Interface Endpoints

* EC2
* ECR (API + DKR)
* STS
* CloudWatch Logs
* SSM
* SSM Messages
* EC2 Messages

### Gateway Endpoint

* S3

👉 This allows private nodes to:

* Pull images from ECR
* Authenticate with AWS services
* Send logs to CloudWatch

---

## ☸️ EKS Cluster

* Version: **1.34**
* Endpoint Access:

  * Public: Enabled
  * Private: Enabled
* Logging:

  * API
  * Audit
  * Authenticator

---

## 🖥️ Node Group

* Type: Managed Node Group
* Instances: `t3.medium`
* Desired/Min/Max: `3`
* Subnets: Private only
* AMI: Amazon Linux 2023 (auto-selected)

---

## 🔐 IAM & Security

* IAM roles auto-created via module
* OIDC provider enabled for IRSA
* Dedicated security group for VPC endpoints:

  * Allows HTTPS (443) from VPC CIDR

---

## ⚠️ Important Notes

### 1. No Internet Access from Nodes

* Nodes **cannot access public internet**
* Only AWS services via VPC endpoints

### 2. Image Pulling

* ✅ Works with **ECR**
* ❌ Does NOT work with Docker Hub

---

### 3. EKS VPC Endpoint

* ❌ NOT used intentionally
* Prevents DNS conflicts with cluster API

---

### 4. Fixed Capacity

* No autoscaling enabled
* Cluster capacity is fixed at 3 nodes

---

## 🚀 Usage

### 1. Initialize Terraform

```bash
terraform init
```

---

### 2. Plan

```bash
terraform plan
```

---

### 3. Apply

```bash
terraform apply
```

---

### 4. Configure kubectl

```bash
aws eks --region ap-south-1 update-kubeconfig --name nkp-eks-cluster
```

---

### 5. Verify Cluster

```bash
kubectl get nodes
```

Expected output:

```
NAME           STATUS   ROLES    AGE   VERSION
ip-10-0-x-x    Ready    <none>   ...   v1.34
```

---

## 🧹 Cleanup

To destroy all resources:

```bash
terraform destroy
```

---

## 🧠 Troubleshooting

### Nodes Not Joining Cluster

Check:

1. VPC Endpoints exist and are healthy
2. Security group allows port 443 from VPC CIDR
3. DNS is enabled in VPC
4. No `eks` VPC endpoint is configured

---

### Debug Node Logs

SSH/SSM into node and check:

```bash
sudo journalctl -u kubelet
cat /var/log/cloud-init-output.log
```

---

## 📁 Project Structure

```
.
├── main.tf
├── variables.tf
├── outputs.tf
├── provider.tf
```

---

## 🔮 Future Improvements

* Add Cluster Autoscaler
* Add Ingress (ALB Controller)
* Add Prometheus & Grafana
* Add CI/CD (GitHub Actions / ArgoCD)

---

## 👨‍💻 Author : 2-kris

Project: **EKS Terraform Setup**
Purpose: Production-grade, cost-optimized Kubernetes infrastructure on AWS

---
