# Platform Engineer Coding Exercise
This repo provides the responses for the Platform Engineer coding exercise.

# Prerequisites
## AWS account 
Configure an AWS account - for this example we'll be using the free tier.

## Sumo Logic
Setup a free trial for Sumo to test logs and alerts

## Code
- [terraform](/terraform/) directory contains all of the terraform resources
- [lambda_function](/lambda_function/) directory contains the lambda function handler that reboots EC2 instance + publishes message to SNS topic
- [sumo](/sumo/) directory contains the Sumo Query we use to fetch logs where path = "/api/data" and response_time_ms > 3000ms and aggregate them based on count > 5 within a 10 minute window.

## Screen Recordings
- Part One (Tasks Three and Two) - [link](https://drive.google.com/file/d/1nqqfiYeAhF-OGqChf3vzYhKTJ4qLGVFA/view?usp=drive_link)
- Part Two (Task One) - [link](https://drive.google.com/file/d/1ZhlF84YP3KVk-G8iXYI6F-wQ_WgB2oub/view?usp=drive_link)

## Goal
Automatically remediate a latency issue by rebooting the affected EC2 instance.

**Trigger condition (Sumo Monitor):**
- Identify requests to `/api/path` where `response_time_ms > 3000`
- Trigger when **count > 5** within a **10-minute window**
- The monitor groups by / extracts the **EC2 instance identifier** (e.g., `instance_id`)
- On trigger, Sumo calls an AWS Lambda endpoint and passes `instance_id`

**Action (AWS Lambda):**
- Receives the Sumo alert payload containing `ec2_instance_id`
- Reboots the specified EC2 instance
- Publishes a notification message to an SNS topic
---

## End-to-End Flow
1. **Sumo Logic Monitor** evaluates:
   - `response_time_ms > 3000` for `/api/path`
   - count of matching events > 5 in a rolling 10-minute window
   - identifies the specific instance via `ec2_instance_id`

2. **Sumo triggers a Webhook** (HTTP POST) to AWS:
   - **Lambda Function URL**
   - payload includes the EC2 instance id to remediate

3. **AWS Lambda**:
   - validates the request and extracts `ec2_instance_id`
   - calls `ec2:RebootInstances` for that instance
   - publishes a message to SNS for visibility/auditing

---

## Example Sumo → Lambda Payload

Minimum required payload fields:

```json
{
  "path": "/api/data",
  "response_time_ms": "3000",
  "ec2_instance_id": "i-001e52a2da631bd78"
}
```
## Infrastructure as Code (Terraform)

### Resources provisioned
Terraform deploys:
- **SNS Topic**
- **IAM Role + Policies** for Lambda (least privilege)
- **Lambda Function** that reboots an EC2 instance and publishes to SNS
- **EC2 Instance**

### Least privilege approach
- Lambda can only publish to the single SNS topic ARN.
- Lambda can describe instances (needed for tag checks): `ec2:DescribeInstances` on `*`.

### Deployment order
1. Terraform apply creates SNS + IAM + Lambda function + Lambda endpoint
2. Configure Sumo monitor + webhook to call the Lambda endpoint and pass `ec2_instance_id`
3. Test by sending a sample payload and verifying reboot + SNS notification