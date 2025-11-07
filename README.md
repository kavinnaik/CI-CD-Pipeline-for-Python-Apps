# 🚀 CI/CD Pipeline for Python Flask App using GitHub Actions, Terraform, Docker, and AWS

A fully automated **CI/CD pipeline** that builds, tests, containers, and deploys a **Python Flask web application** to **AWS EC2** using **Terraform** and **GitHub Actions**.  
The pipeline runs automatically whenever code is pushed to the main branch — achieving **zero manual deployment**.

---

## 🧩 Project Overview

This project demonstrates the end-to-end DevOps workflow for a cloud-based Python application:

1. **Code** – A simple Flask REST API (`Hello DevOps`)  
2. **Build** – Docker image built and tested via GitHub Actions  
3. **Push** – Image uploaded to Docker Hub  
4. **Provision** – Terraform creates AWS infrastructure (EC2, SG, IAM)  
5. **Deploy** – The latest container is automatically pulled and run on the EC2 instance  
6. **Verify** – The live URL serves the updated application instantly after each push  

---

## 🏗️ Architecture
Developer → GitHub Repo → GitHub Actions
│
├── Run Tests (pytest)
├── Build & Push Docker Image to Docker Hub
├── Provision Infra using Terraform
└── Deploy Container on AWS EC2 (via SSH)

