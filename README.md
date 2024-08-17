# EC2 Scheduler

This project schedules an EC2 instance to start at 7:55 PM and stop at 9:00 PM using AWS Lambda and Terraform.

## Components

- **AWS Lambda**: Executes the start and stop commands for the EC2 instance.
- **Terraform**: Deploys the Lambda function and related resources.

## Setup

### Prerequisites

- Terraform installed
- AWS CLI configured

### Configuration

1. **Update Terraform Variables**:
   - Modify `main.tf` to set your EC2 instance ID.

2. **Deploy with Terraform**:
   ```bash
   terraform init
   terraform apply
