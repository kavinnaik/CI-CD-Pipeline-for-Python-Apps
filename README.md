# 🚀 CI/CD Pipeline for a Flask App

This repository shows how to run a small Flask “Hello DevOps” API through a full CI/CD pipeline. Every push to `main` automatically:
- runs tests
- builds and pushes a Docker image
- provisions or updates AWS infrastructure with Terraform
- deploys the container to an EC2 instance

---

## What’s inside?

- `app/` – Flask API (`app.py`) and pytest suite (`test_app.py`)
- `Dockerfile` – builds a Python 3.11 slim image
- `.github/workflows/ci-cd.yml` – GitHub Actions workflow (test → build/push → Terraform → deploy)
- `deploy/` – SSH deploy script + docker-compose file used on EC2
- `terraform/` – AWS infrastructure (security group, EC2 instance, user-data bootstrap)
- `SETUP_GUIDE.md` – human-friendly, step-by-step instructions for reproducing everything

---

## High-level flow

1. **Local development**
   - edit Flask app, run tests, build Docker image if desired
2. **Git push**
   - GitHub Actions checks out the repo, installs deps, and runs pytest
3. **Docker build & push**
   - workflow builds the image and pushes to Docker Hub with SHA + `latest` tags
4. **Terraform apply**
   - workflow installs Terraform, authenticates with AWS, and applies `terraform/main.tf`
5. **Remote deploy**
   - workflow runs `deploy/deploy_via_ssh.sh`  
   - script copies `docker-compose.yml`, installs Docker on EC2 (if needed), pulls the new image, and restarts the container

---

## Requirements

To run this project yourself you’ll need:
- AWS account (permissions to create EC2 + networking)
- Docker Hub account (for the container registry)
- GitHub account (to run Actions)
- Terraform 1.6+
- Docker Engine + docker-compose (locally and on EC2)
- Python 3.11+ (for local dev; system Python 3.x works too)
- An SSH key pair registered in AWS

All the setup details are in `SETUP_GUIDE.md`.

---

## How to try it locally

```bash
git clone <repo>
cd CI-CD-Pipeline-for-Python-Apps
python3 -m venv venv && source venv/bin/activate
pip install -r app/requirements.txt

cd app
export PYTHONPATH=.
pytest -q
python app.py  # visit http://localhost:5000
```

Build the Docker image:
```bash
cd ..
docker build -t ci-cd-hello:local .
docker run -d -p 5000:5000 ci-cd-hello:local
```

Manual deploy via SSH (after Terraform creates the EC2 instance):
```bash
./deploy/deploy_via_ssh.sh "$EC2_HOST" "ec2-user" "~/.ssh/your-key.pem" "yourdockerhubuser/ci-cd-hello:latest"
```

---

## GitHub Actions secrets to set

- `AWS_REGION`
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`
- `EC2_USER` (usually `ec2-user`)
- `EC2_SSH_KEY` (paste the private key contents)

---

## Helpful links

- Detailed setup instructions: `SETUP_GUIDE.md`
- Terraform docs: https://developer.hashicorp.com/terraform/docs
- GitHub Actions docs: https://docs.github.com/en/actions
- Docker docs: https://docs.docker.com/

Enjoy the pipeline! Contributions, questions, and issues are welcome.
