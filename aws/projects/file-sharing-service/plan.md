# File Sharing Service - Learning & Build Plan

**Purpose**: This plan tracks teaching progress across sessions. Each checkbox represents a teaching module or implementation phase to be completed sequentially.

**Project Goal**: Build a production-ready file sharing service using S3, Lambda, API Gateway, DynamoDB, Cognito, and IaC (CloudFormation/SAM/CDK).

## Architecture Overview

```
User → Cognito (auth) → API Gateway → Lambda → S3 (files)
                                     ↓
                                 DynamoDB (metadata)
```

**Core Features**:
- User authentication & authorization
- File upload/download with presigned URLs
- File metadata storage (name, owner, size, sharing permissions)
- File sharing with other users
- List user's files
- Delete files

---

## Phase 1: Foundation - S3 & Lambda Basics

### 1.1 S3 - Simple Storage Service
- [ ] **Teach S3 mental model**
  - What: Object storage (key-value store for files)
  - Why: Durable, scalable, cheap file storage
  - When: Any file storage needs (images, videos, backups, static sites)

- [ ] **Essential S3 operations (Python SDK + CLI)**
  - Create bucket: `s3.create_bucket()` / `aws s3 mb`
  - Upload file: `s3.upload_file()` / `aws s3 cp`
  - Download file: `s3.download_file()` / `aws s3 cp`
  - List objects: `s3.list_objects_v2()` / `aws s3 ls`
  - Delete object: `s3.delete_object()` / `aws s3 rm`
  - Generate presigned URL: `s3.generate_presigned_url()`

- [ ] **S3 constraints & pitfalls**
  - Bucket names are globally unique
  - Max object size: 5TB (multipart upload for >5GB)
  - Eventually consistent for overwrites/deletes
  - Presigned URLs expire (set appropriate expiry)
  - Use bucket policies + IAM for security

- [ ] **Real-world example**: Upload a file to S3 via Python SDK, generate presigned URL, download via URL

### 1.2 Lambda - Serverless Functions
- [ ] **Teach Lambda mental model**
  - What: Run code without managing servers
  - Why: Pay per execution, auto-scales, event-driven
  - When: APIs, event processing, scheduled tasks

- [ ] **Essential Lambda operations (Python SDK + CLI)**
  - Create function: `lambda.create_function()` / `aws lambda create-function`
  - Invoke function: `lambda.invoke()` / `aws lambda invoke`
  - Update code: `lambda.update_function_code()` / `aws lambda update-function-code`
  - Get logs: CloudWatch Logs / `aws logs tail`
  - List functions: `lambda.list_functions()` / `aws lambda list-functions`

- [ ] **Lambda constraints & pitfalls**
  - Max execution time: 15 minutes
  - Max memory: 10GB
  - Cold starts (1-3s delay for first request)
  - `/tmp` storage: 10GB (ephemeral)
  - Use layers for dependencies, not deployment package

- [ ] **Real-world example**: Create Lambda that uploads a file to S3 when invoked

### 1.3 Implementation: Basic File Upload
- [ ] **Create Lambda function** that:
  - Accepts file data in event
  - Uploads to S3 bucket
  - Returns S3 object key

- [ ] **Test manually** via AWS CLI `lambda invoke`

---

## Phase 2: API Layer - API Gateway

### 2.1 API Gateway
- [ ] **Teach API Gateway mental model**
  - What: Managed REST/HTTP API frontend
  - Why: Bridges HTTP requests to Lambda, handles auth, throttling, CORS
  - When: Exposing Lambda functions as HTTP APIs

- [ ] **Essential API Gateway operations (SDK + CLI)**
  - Create REST API: `apigateway.create_rest_api()` / `aws apigatewayv2 create-api`
  - Create route: `apigateway.put_integration()` / `aws apigatewayv2 create-route`
  - Deploy API: `apigateway.create_deployment()` / `aws apigatewayv2 create-deployment`
  - Get API endpoint: Check AWS Console or `aws apigatewayv2 get-apis`

- [ ] **API Gateway constraints & pitfalls**
  - Payload limit: 10MB (use presigned URLs for large files)
  - Timeout: 29 seconds (Lambda can run longer but API Gateway will timeout)
  - CORS must be configured explicitly
  - Use stages (dev, prod) for versioning

- [ ] **Real-world example**: Create HTTP API with POST /upload route → Lambda

### 2.2 Implementation: HTTP API for File Upload
- [ ] **Create API Gateway HTTP API**
- [ ] **Create POST /upload route** → Lambda from Phase 1.3
- [ ] **Test with curl/Postman**: Upload file via HTTP

---

## Phase 3: Metadata Storage - DynamoDB

### 3.1 DynamoDB
- [ ] **Teach DynamoDB mental model**
  - What: NoSQL key-value/document database
  - Why: Fast, scalable, serverless, pay-per-request
  - When: High-throughput apps, flexible schemas, single-digit ms latency

- [ ] **Essential DynamoDB operations (SDK + CLI)**
  - Create table: `dynamodb.create_table()` / `aws dynamodb create-table`
  - Put item: `dynamodb.put_item()` / `aws dynamodb put-item`
  - Get item: `dynamodb.get_item()` / `aws dynamodb get-item`
  - Query: `dynamodb.query()` / `aws dynamodb query`
  - Scan: `dynamodb.scan()` / `aws dynamodb scan`
  - Update item: `dynamodb.update_item()` / `aws dynamodb update-item`
  - Delete item: `dynamodb.delete_item()` / `aws dynamodb delete-item`

- [ ] **DynamoDB constraints & pitfalls**
  - Primary key required (partition key + optional sort key)
  - Item size limit: 400KB
  - Scan is expensive (use Query with indexes)
  - Choose partition key wisely (high cardinality for even distribution)
  - Use GSI/LSI for additional query patterns

- [ ] **Real-world example**: Create table, insert file metadata, query by user

### 3.2 Implementation: File Metadata Storage
- [ ] **Create DynamoDB table** `FileMetadata`:
  - Partition key: `userId` (string)
  - Sort key: `fileId` (string)
  - Attributes: `fileName`, `s3Key`, `uploadedAt`, `size`, `sharedWith`

- [ ] **Update Lambda** to:
  - Generate unique `fileId`
  - Store metadata in DynamoDB after S3 upload
  - Return `fileId` to user

- [ ] **Create GET /files Lambda** to list user's files from DynamoDB
- [ ] **Create GET /files/{fileId} Lambda** to get file metadata
- [ ] **Add routes to API Gateway**

---

## Phase 4: Authentication - Cognito

### 4.1 Cognito
- [ ] **Teach Cognito mental model**
  - What: Managed user authentication & authorization
  - Why: Handles signup/login/MFA without custom auth code
  - When: Apps need user accounts, social login, or federation

- [ ] **Essential Cognito operations (SDK + CLI)**
  - Create user pool: `cognito-idp.create_user_pool()` / `aws cognito-idp create-user-pool`
  - Create user pool client: `cognito-idp.create_user_pool_client()`
  - Sign up user: `cognito-idp.sign_up()` / `aws cognito-idp sign-up`
  - Confirm signup: `cognito-idp.confirm_sign_up()`
  - Login: `cognito-idp.initiate_auth()` / `aws cognito-idp initiate-auth`
  - Get user: `cognito-idp.get_user()`

- [ ] **Cognito constraints & pitfalls**
  - User pools vs Identity pools (pools = auth, identity = AWS creds)
  - Access tokens expire (default 1 hour, use refresh tokens)
  - Email/phone verification required for production
  - Password policy must meet security standards
  - Use groups for role-based access

- [ ] **Real-world example**: Create user pool, sign up user, get JWT token

### 4.2 Implementation: Secure API with Cognito
- [ ] **Create Cognito User Pool**
- [ ] **Create User Pool Client** (for API)
- [ ] **Configure API Gateway** with Cognito authorizer
- [ ] **Update Lambda** to extract `userId` from Cognito JWT claims
- [ ] **Test**: Sign up user, get token, call API with token

---

## Phase 5: File Sharing & Advanced Features

### 5.1 Implementation: Presigned URLs for Direct Upload/Download
- [ ] **Create POST /files/upload-url Lambda**:
  - Generate presigned POST URL for S3
  - Return URL to client
  - Client uploads directly to S3 (bypasses API Gateway 10MB limit)

- [ ] **Create GET /files/{fileId}/download-url Lambda**:
  - Check if user owns file or has access
  - Generate presigned GET URL
  - Return URL to client

### 5.2 Implementation: File Sharing
- [ ] **Create POST /files/{fileId}/share Lambda**:
  - Update DynamoDB `sharedWith` attribute
  - Add target user to permissions

- [ ] **Update GET /files Lambda**:
  - Return files owned by user + files shared with user

### 5.3 Implementation: File Deletion
- [ ] **Create DELETE /files/{fileId} Lambda**:
  - Delete from S3
  - Delete from DynamoDB
  - Check ownership before deletion

---

## Phase 6: Infrastructure as Code

### 6.1 CloudFormation
- [ ] **Teach CloudFormation mental model**
  - What: Declarative infrastructure templates (JSON/YAML)
  - Why: Version control infra, reproducible deployments, rollback
  - When: Any AWS infrastructure that needs to be repeatable

- [ ] **Essential CloudFormation operations (SDK + CLI)**
  - Create stack: `cloudformation.create_stack()` / `aws cloudformation create-stack`
  - Update stack: `cloudformation.update_stack()` / `aws cloudformation update-stack`
  - Delete stack: `cloudformation.delete_stack()` / `aws cloudformation delete-stack`
  - Describe stack: `cloudformation.describe_stacks()`

- [ ] **CloudFormation constraints & pitfalls**
  - Stack creation can fail mid-way (auto rollback by default)
  - Update conflicts if manual changes made
  - Use change sets to preview updates
  - Nested stacks for large templates

### 6.2 SAM (Serverless Application Model)
- [ ] **Teach SAM mental model**
  - What: CloudFormation extension for serverless apps
  - Why: Simpler syntax for Lambda/API Gateway/DynamoDB
  - When: Building serverless applications

- [ ] **Essential SAM operations (CLI)**
  - Init project: `sam init`
  - Build: `sam build`
  - Local test: `sam local invoke`
  - Deploy: `sam deploy --guided`

- [ ] **SAM constraints & pitfalls**
  - Still uses CloudFormation under the hood
  - `sam build` packages dependencies
  - Use `samconfig.toml` for deployment config

### 6.3 CDK (Cloud Development Kit)
- [ ] **Teach CDK mental model**
  - What: Define infrastructure in Python/TypeScript/Java/C#
  - Why: Use programming constructs (loops, conditionals) vs YAML
  - When: Complex infrastructure, need type safety, prefer code over config

- [ ] **Essential CDK operations (CLI)**
  - Init project: `cdk init app --language python`
  - Synth template: `cdk synth`
  - Deploy: `cdk deploy`
  - Diff: `cdk diff`
  - Destroy: `cdk destroy`

- [ ] **CDK constraints & pitfalls**
  - Compiles to CloudFormation (inherits CF limits)
  - State stored in CloudFormation stacks
  - Use L2/L3 constructs (not L1) for convenience

### 6.4 Implementation: Deploy with IaC
- [ ] **Choose one IaC tool** (SAM recommended for serverless)
- [ ] **Define entire stack**:
  - S3 bucket
  - DynamoDB table
  - Lambda functions
  - API Gateway
  - Cognito User Pool
  - IAM roles/policies

- [ ] **Deploy stack** via `sam deploy` or `cdk deploy`
- [ ] **Test end-to-end**: signup → login → upload → list → share → download → delete

---

## Phase 7: Production Readiness

### 7.1 Observability - CloudWatch
- [ ] **Teach CloudWatch mental model**
  - What: Monitoring, logging, metrics, alarms
  - Why: Troubleshoot errors, track performance, alert on issues
  - When: Any production application

- [ ] **Essential CloudWatch operations (SDK + CLI)**
  - View logs: `logs.filter_log_events()` / `aws logs tail`
  - Create alarm: `cloudwatch.put_metric_alarm()` / `aws cloudwatch put-metric-alarm`
  - Put custom metric: `cloudwatch.put_metric_data()`

- [ ] **Add CloudWatch features**:
  - Lambda log groups (auto-created)
  - Custom metrics (upload count, file size)
  - Alarms (error rate > 5%)
  - Dashboard for monitoring

### 7.2 Security Hardening
- [ ] **S3 bucket policies**: Block public access, enforce encryption
- [ ] **IAM least privilege**: Lambda execution role with minimal permissions
- [ ] **API Gateway throttling**: Set rate limits
- [ ] **Input validation**: Validate file types, sizes in Lambda
- [ ] **CORS configuration**: Restrict origins

### 7.3 Cost Optimization
- [ ] **S3 lifecycle policies**: Move old files to Glacier
- [ ] **DynamoDB on-demand**: Use on-demand pricing for variable workloads
- [ ] **Lambda memory tuning**: Right-size memory for cost/performance
- [ ] **API Gateway caching**: Cache GET requests

---

## Session State

**Last Updated**: 2025-11-23
**Current Phase**: Phase 0 - Planning Complete
**Next Teaching Step**: Phase 1.1 - Teach S3 mental model

**Progress Summary**:
- Total checkboxes: 60+
- Completed: 0
- Remaining: 60+

---

## Teaching Notes (for Claude)

**When resuming a session**:
1. Read this file to see current progress
2. Find the first unchecked checkbox
3. Teach that topic using the format:
   - Mental model (1-2 sentences)
   - Essential SDK + CLI commands
   - Constraints & pitfalls
   - Real-world example
4. Check the box when teaching complete
5. If implementation step, guide user through code
6. Update "Session State" section
7. Ask user if ready to continue to next checkbox

**Teaching style**:
- Short, direct explanations
- Always show both Python SDK and AWS CLI
- Emphasize production pitfalls
- Use real examples from this project
- No fluff or theory
- Let user drive pace (don't auto-advance unless asked)

**File references**:
- AWS docs: `aws-pdfs/` folder
- SDK examples: `aws-doc-sdk-examples/`
- CLI examples: `/opt/homebrew/share/awscli/examples/{service}/`
- AWS CLI profile: `--profile claude` (read-only access)
