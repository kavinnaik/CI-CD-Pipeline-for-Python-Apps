# 🚀 How to Run This Project 

Welcome! This walkthrough assumes you just cloned the repo and want to:
- test the Flask API locally
- provision the AWS infrastructure with Terraform
- deploy the container manually
- wire up the full CI/CD pipeline on GitHub Actions

Take it at your own pace—each section builds on the previous one.

---

## 🧰 Before You Start

You’ll need:
- Ubuntu 18.04+ (or similar Linux distro)
- AWS account with permissions to create EC2 + networking resources
- Docker Hub account (for the container registry)
- GitHub account (to run Actions)
- An SSH key pair registered in AWS (or be ready to create/import one)

If you already have the software stack installed, feel free to skip ahead.

---

## 1. Set Up Your Local Machine

**Update apt and install essentials**
```bash
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y git ca-certificates curl gnupg lsb-release unzip
```

**Python**
- Check what you have: `python3 --version`
- Make sure `venv` and `pip` are available:
  ```bash
  sudo apt-get install -y python3-venv python3-pip
  ```
  (If you specifically want Python 3.11, add the deadsnakes PPA and install it; otherwise `python3` works fine.)

**Docker (Engine + CLI)**
```bash
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER
newgrp docker
docker --version
docker compose version  # optional: install standalone docker-compose if you prefer
```

**Terraform**
```bash
wget -q https://releases.hashicorp.com/terraform/1.6.6/terraform_1.6.6_linux_amd64.zip -O /tmp/terraform.zip
sudo unzip -o /tmp/terraform.zip -d /usr/local/bin/
sudo chmod +x /usr/local/bin/terraform
terraform -version
```

**AWS CLI**
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version
```

---

## 2. Clone & Prepare the Project

```bash
cd ~
git clone <your-repo-url>
cd CI-CD-Pipeline-for-Python-Apps

python3 -m venv venv    # use python3.11 -m venv venv if you installed that version
source venv/bin/activate
pip install -r app/requirements.txt
```

---

## 3. Smoke-Test the Flask App Locally

```bash
cd app
export PYTHONPATH=.
pytest -q             # run tests
python app.py         # start the dev server
```

Visit `http://localhost:5000` (or curl it) to check the JSON response, then `Ctrl+C` to stop.

Build and run the Docker image locally (optional but recommended):
```bash
cd ..
docker build -t ci-cd-hello:local .
docker run -d -p 5000:5000 --name test-app ci-cd-hello:local
curl http://localhost:5000
docker stop test-app && docker rm test-app
```

---

## 4. Configure AWS Access

Run `aws configure` and supply your keys + preferred default region (example: `us-east-1`).

### Using an existing AWS key pair?
- Move the `.pem` file somewhere safe (e.g., `~/.ssh/ci-cd-key.pem`)
- `chmod 600 ~/.ssh/ci-cd-key.pem`
- Note the key pair name exactly as it appears in AWS (e.g., `ci-cd-key`)

If you lost the private key, create/import a new pair and keep the `.pem` handy—you’ll use it for SSH and in GitHub secrets.

---

## 5. Provision Infrastructure with Terraform

```bash
cd terraform
terraform init
terraform plan   -var="aws_region=us-east-1"
terraform apply  -var="aws_region=us-east-1"
```

Outputs to note:
```bash
terraform output ec2_public_ip
terraform output ec2_public_dns
```

If you stop/start the instance later and the IP changes, re-run `terraform refresh -var="aws_region=us-east-1"` so state stays in sync.

---

## 6. Manual Deployment to EC2 (good confidence check)

Push your Docker image to Docker Hub:
```bash
docker login
export DOCKERHUB_USERNAME="your-dockerhub-username"
docker tag ci-cd-hello:local $DOCKERHUB_USERNAME/ci-cd-hello:latest
docker push $DOCKERHUB_USERNAME/ci-cd-hello:latest
```

Deploy via the helper script:
```bash
cd ~/CI-CD-Pipeline-for-Python-Apps
chmod +x deploy/deploy_via_ssh.sh

export EC2_HOST=$(cd terraform && terraform output -raw ec2_public_dns)
export EC2_USER="ec2-user"
export KEY_PATH="$HOME/.ssh/ci-cd-key.pem"                            # adjust if you named it differently
export IMAGE="$DOCKERHUB_USERNAME/ci-cd-hello:latest"                 # or use the :<commit sha> tag

./deploy/deploy_via_ssh.sh "$EC2_HOST" "$EC2_USER" "$KEY_PATH" "$IMAGE"
```

The script will:
- copy `deploy/docker-compose.yml`
- install Docker + docker-compose if missing
- pull your image
- bring the container up with `docker-compose`

Verify it worked:
```bash
terraform output -raw ec2_public_ip
curl http://<that_ip>:5000
```

If you’d rather expose port 80, edit `deploy/docker-compose.yml` to map `80:5000`, redeploy, and update the security group if needed.

---

## 7. Wire Up GitHub Actions (CI/CD)

1. Push the repo to GitHub:
   ```bash
   git remote add origin <your-github-repo-url>
   git add .
   git commit -m "Initial commit"
   git push -u origin main
   ```

2. In GitHub → Settings → Secrets and variables → Actions, add these **repository** secrets:
   - `AWS_REGION` – e.g., `us-east-1`
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `DOCKERHUB_USERNAME`
   - `DOCKERHUB_TOKEN` (create a personal access token on Docker Hub)
   - `EC2_USER` – usually `ec2-user`
   - `EC2_SSH_KEY` – paste the full private key (everything between BEGIN/END PRIVATE KEY)

3. Trigger the workflow:
   ```bash
   git commit --allow-empty -m "chore: trigger CI/CD"
   git push origin main
   ```

GitHub Actions will:
- run tests
- build and push the Docker image
- run Terraform (plan/apply)
- call the SSH deploy script

Watch the run in the Actions tab. Once it finishes, hit the EC2 URL again to confirm the new container is live.

---

## 8. Day‑to‑Day Workflow

- Develop locally → run tests (`pytest -q`)
- Commit & push to `main`
- Pipeline handles build/test/infra/deploy
- Visit the EC2 public URL to confirm changes
- Need to redeploy manually? Re-run `deploy/deploy_via_ssh.sh …`
- Want a fixed public IP? Attach an Elastic IP in Terraform so it doesn’t change on stop/start.

---

## 9. Troubleshooting Cheat Sheet

**Docker “permission denied” on your machine**  
`sudo usermod -aG docker $USER && newgrp docker`

**Docker not found on EC2**  
The deploy script installs it automatically, but you can SSH in and run:
```bash
sudo dnf install -y docker
sudo systemctl enable docker
sudo systemctl start docker
```

**docker-compose missing on EC2**  
The script downloads the standalone binary. If you run commands manually:
```bash
sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.6/docker-compose-linux-x86_64" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

**GitHub Actions deploy job fails with “permission denied” when touching `/var/run/docker.sock`**  
EC2 user must be in the `docker` group: `sudo usermod -aG docker ec2-user && newgrp docker`

**Port 5000 not reachable**  
- Update `aws_security_group.web_sg` to allow TCP 5000 (Terraform) **or**
- Map host port 80 to container 5000 in `docker-compose.yml`

**Terraform wants to destroy/recreate the instance unexpectedly**  
Run `terraform plan -var="aws_region=us-east-1"`—if it only needs to update the IP, apply.  
If you stopped the instance outside Terraform, consider attaching an Elastic IP to avoid drift.

---

## 10. Cleanup

When you’re done:
```bash
cd terraform
terraform destroy -var="aws_region=us-east-1"
```

Optionally prune local Docker artifacts:
```bash
docker rmi ci-cd-hello:local
docker rmi $DOCKERHUB_USERNAME/ci-cd-hello:latest
```

---

## Quick Reference

```bash
# Local testing
cd app && export PYTHONPATH=. && pytest -q

# Build and run Docker locally
docker build -t ci-cd-hello:local .
docker run -d -p 5000:5000 --name test-app ci-cd-hello:local

# Terraform lifecycle
cd terraform
terraform init
terraform plan  -var="aws_region=us-east-1"
terraform apply -var="aws_region=us-east-1"
terraform destroy -var="aws_region=us-east-1"

# Manual deploy helper
./deploy/deploy_via_ssh.sh "$EC2_HOST" "ec2-user" "$KEY_PATH" "$IMAGE"
```

---

🎉 That’s it! You now have a reproducible path from local development to automated GitHub Actions deployments on AWS EC2. Reach out (or open an issue) if something doesn’t line up with your environment. Happy shipping! 🚢
