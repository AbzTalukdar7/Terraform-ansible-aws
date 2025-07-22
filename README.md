# AWS EC2 + Ansible Automation Project

This project automates the provisioning of an EC2 instance on AWS using Terraform and configures it using Ansible to deploy a basic web page via Apache. Ideal for infrastructure automation practice and DevOps portfolio building.

## Technologies

- **Terraform** – to provision AWS infrastructure (EC2 instance)
- **Ansible** – to configure the EC2 instance post-launch
- **Apache2** – as the web server to serve a test page
- **AWS EC2** – for the virtual machine
- **Ubuntu** – as the base OS for the EC2 instance

## How It Works

1. Terraform is used to:
   - Launch an EC2 instance
   - Generate and output its public IP
2. Ansible is used to:
   - Connect to the instance using SSH
   - Install and start Apache2
   - Create a custom index.html page that displays a simple message
3. You can then visit the public IP in your browser to see the message served by Apache.

## Prerequisites

- AWS account with credentials set up (e.g. in `~/.aws/credentials`)
- SSH key pair for access to the EC2 instance
- Terraform installed
- Ansible installed## How to Run This Project

1. **Clone the repo**

```bash
git clone git@github.com:AbzTalukdar7/Terraform-ansible-aws.git
cd Terraform-ansible-aws
```

terraform init
terraform apply

2. **Provision the EC2 instance using Terraform**

```bash
terraform init
terraform apply
```

3. **Update the Ansible inventory with the EC2 public IP**

After Terraform finishes, copy the outputted public IP into your inventory file:

```bash
[web]
your.ec2.ip.here ansible_user=ubuntu ansible_ssh_private_key_file=./your-key.pem
```

4. **Run the Ansible playbook**

```bash
ansible-playbook playbook.yml -i inventory
```

5. **Visit the Web Page**

Open a browser and go to: http://your.ec2.ip.here
You should see a message like: It works!


---

## 🧼 Notes

```md
## Notes

- Make sure your EC2 security group allows inbound traffic on port 80 (HTTP)
- Don’t forget to `terraform destroy` when you’re done to avoid charges




