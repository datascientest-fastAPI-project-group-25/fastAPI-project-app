# Deployment Guide for DevOps Demo Application

This document describes how to deploy the application to AWS ECS using GitHub Actions.

## Prerequisites

## GitHub Actions Secrets

The following secrets need to be configured in your GitHub repository:

## CI/CD Pipeline

The CI/CD pipeline consists of the following stages:

1. **Build and Test**: Builds the application and runs tests
2. **Build and Push Docker Images**: Builds Docker images for frontend and backend and pushes them to ECR
3. **Deploy to Staging**: Deploys the application to the staging environment
4. **Deploy to Production**: Deploys the application to the production environment (manual approval required)

## AWS Resources

The application requires the following AWS resources:

## Infrastructure as Code

The AWS infrastructure is managed using Terraform in a separate repository. The Terraform code creates all the necessary AWS resources and configures them for the application.

The ECS deployment uses the Docker images built and pushed by the GitHub Actions workflow.
