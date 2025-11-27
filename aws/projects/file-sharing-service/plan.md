# File Sharing Service - Teaching Plan (for Claude)

**🎯 Primary Audience**: Claude (AI teaching assistant)
**📋 Purpose**: This is Claude's teaching script. It defines what to teach, when to teach it, and how to guide the user through building a production-ready file sharing service.

**How Claude Uses This File**:
1. **Resume teaching** — Read "Session State" to see current sprint and next unchecked item
2. **Teach systematically** — Follow checkboxes sequentially, teaching concepts just-in-time
3. **Track progress** — Check boxes as user completes tasks
4. **Guide implementation** — Walk user through "Implementation Steps" (don't just list them)
5. **Verify work** — Use read-only AWS CLI access (`--profile claude`) to check what user deployed

**How User Uses This File** (secondary):
- See what's coming next
- Track overall progress
- Reference MUST-KNOWs and code examples
- Understand the sprint structure

**Teaching Approach**: Feature-driven sprints. Each sprint builds one working feature, teaching only the services needed for that feature. IaC (SAM) from day 1. This mirrors real-world engineering.

**Project Goal**: Guide user to build a production-ready serverless file sharing service.

## Architecture Overview

```
User → Cognito (auth) → API Gateway → Lambda → S3 (files)
                                     ↓
                                 DynamoDB (metadata)
```

**Core Features**:
- User authentication & authorization (Cognito)
- File upload/download with presigned URLs (S3)
- File metadata storage (DynamoDB)
- File sharing with other users
- Background processing (SQS/SNS)
- Full observability (CloudWatch, X-Ray)

**Deployed with**: AWS SAM (Serverless Application Model) - IaC from Sprint 1

---

## Sprint 0: Environment Setup

### Goals
- Install tools
- Verify AWS access
- Understand SAM workflow

### Tasks
- [x] **Install AWS SAM CLI**
  - macOS: `brew install aws-sam-cli`
  - Verify: `sam --version`
  - Docs: https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html

- [x] **Verify AWS CLI access**
  - You have admin access to build: `aws sts get-caller-identity --profile default`
  - Note: Claude (your teaching assistant) has separate read-only access (`--profile claude`) to check your work

- [x] **Understand SAM workflow**
  - `sam init` → creates project template
  - `sam build` → packages code and dependencies
  - `sam deploy` → deploys to AWS (creates CloudFormation stack)
  - `sam local invoke` → test Lambda locally

### Outcome
✅ Ready to build with SAM

---

## Sprint 1: Hello World API (SAM from Day 1)

### Goals
- Create first Lambda function
- Deploy with SAM template
- Understand IaC basics

### New Services
- **Lambda**: Serverless function execution
- **API Gateway**: HTTP API frontend
- **CloudFormation**: Infrastructure as code (via SAM)

### 🚨 MUST-KNOW (taught now)
- **SAM template is CloudFormation** — SAM compiles to CloudFormation, which creates all resources
- **Lambda execution role** — Lambda needs IAM permissions to call other AWS services
- **API Gateway proxy integration** — Lambda receives full HTTP request, must return `{statusCode, body, headers}`

### Implementation Steps
- [x] **Run `sam init`**
  - Choose: Python 3.11, Hello World template
  - Creates: `template.yaml`, `hello_world/app.py`, `requirements.txt`

- [x] **Examine `template.yaml`**
  - Defines: Lambda function, API Gateway, IAM role
  - Understand: `Resources`, `Properties`, `Events`

- [x] **Deploy with `sam deploy --guided`**
  - Stack name: `file-sharing-dev`
  - Region: (choose yours)
  - Saves config to `samconfig.toml`

- [x] **Test the API**
  - Get API endpoint from outputs
  - `curl https://xxx.execute-api.region.amazonaws.com/hello`
  - Should return: `{"message": "hello world"}`

- [x] **View in AWS Console**
  - CloudFormation → Stacks → file-sharing-dev
  - Lambda → Functions
  - API Gateway → APIs

### Outcome
✅ **Working API deployed with IaC** — you can destroy and recreate everything with `sam deploy`

---

## Sprint 2: File Upload (S3 + Presigned URLs)

### Goals
- Store files in S3
- Generate presigned URLs for direct upload
- Understand why presigned URLs matter

### New Services
- **S3**: Object storage for files

### 🚨 MUST-KNOW (taught now)
- **API Gateway 10MB payload limit** — cannot upload large files through API Gateway. Solution: presigned URLs
- **Presigned URLs bypass Lambda** — client uploads directly to S3, Lambda just generates the URL
- **S3 bucket names are globally unique** — use pattern `{org}-file-sharing-{env}-{random}`
- **CORS required for browser uploads** — S3 must allow cross-origin requests from your domain

### Essential S3 Operations (Python SDK + CLI)
```python
# Generate presigned POST URL (for upload)
s3_client.generate_presigned_post(
    Bucket='my-bucket',
    Key='uploads/file.jpg',
    ExpiresIn=3600  # 1 hour
)

# Generate presigned GET URL (for download)
s3_client.generate_presigned_url(
    'get_object',
    Params={'Bucket': 'my-bucket', 'Key': 'file.jpg'},
    ExpiresIn=3600
)
```

CLI:
```bash
# Create bucket
aws s3 mb s3://my-bucket

# Upload file
aws s3 cp file.txt s3://my-bucket/

# List objects
aws s3 ls s3://my-bucket/

# Download file
aws s3 cp s3://my-bucket/file.txt .
```

### Implementation Steps
- [x] **Add S3 bucket to `template.yaml`**
  ```yaml
  FileStorageBucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: !Sub '${AWS::StackName}-files-${AWS::AccountId}'
      CorsConfiguration:
        CorsRules:
          - AllowedOrigins: ['*']
            AllowedMethods: [GET, PUT, POST]
            AllowedHeaders: ['*']
  ```

- [x] **Create Lambda: `POST /files/upload-url`**
  - Input: `{ "fileName": "photo.jpg" }`
  - Generate presigned POST URL for S3
  - Return: `{ "uploadUrl": "https://...", "fields": {...} }`

- [x] **Update Lambda IAM role** to allow `s3:PutObject`

- [x] **Deploy with `sam build && sam deploy`**

- [x] **Test presigned URL**
  - Call API to get presigned URL
  - Upload file using `curl` or browser
  - Verify file in S3: `aws s3 ls s3://bucket-name/`

### Real-World Extras
- [x] **Enable S3 versioning** (production best practice)
  ```yaml
  VersioningConfiguration:
    Status: Enabled
  ```

- [x] **Enable S3 encryption** (SSE-S3)
  ```yaml
  BucketEncryption:
    ServerSideEncryptionConfiguration:
      - ServerSideEncryptionByDefault:
          SSEAlgorithm: AES256
  ```

- [x] **Block public access** (security)
  ```yaml
  PublicAccessBlockConfiguration:
    BlockPublicAcls: true
    BlockPublicPolicy: true
    IgnorePublicAcls: true
    RestrictPublicBuckets: true
  ```

### Outcome
✅ **Users can upload files to S3 via presigned URLs**

---

## Sprint 3: File Metadata Storage (DynamoDB)

### Goals
- Store file metadata (name, owner, upload date, size)
- List user's files
- Learn DynamoDB table design

### New Services
- **DynamoDB**: NoSQL database for metadata

### 🚨 MUST-KNOW (taught now)
- **Partition key choice is CRITICAL** — poor choice causes hot partitions, throttling. Use high-cardinality keys (userId, not status)
- **Query vs Scan** — Query reads one partition (fast). Scan reads entire table (slow, expensive, avoid!)
- **DynamoDB is not SQL** — no joins, no schema migrations, denormalize data
- **On-demand vs Provisioned** — on-demand auto-scales (pay per request), provisioned is cheaper at high volume but can throttle

### Essential DynamoDB Operations (Python SDK + CLI)
```python
# Put item
dynamodb.put_item(
    TableName='FileMetadata',
    Item={
        'userId': {'S': 'user123'},
        'fileId': {'S': 'abc-def-ghi'},
        'fileName': {'S': 'photo.jpg'},
        'size': {'N': '1024000'},
        'uploadedAt': {'S': '2025-11-23T12:00:00Z'}
    }
)

# Query by userId (efficient)
dynamodb.query(
    TableName='FileMetadata',
    KeyConditionExpression='userId = :uid',
    ExpressionAttributeValues={':uid': {'S': 'user123'}}
)

# Get single item
dynamodb.get_item(
    TableName='FileMetadata',
    Key={'userId': {'S': 'user123'}, 'fileId': {'S': 'abc-def-ghi'}}
)

# Update item
dynamodb.update_item(
    TableName='FileMetadata',
    Key={'userId': {'S': 'user123'}, 'fileId': {'S': 'abc-def-ghi'}},
    UpdateExpression='SET sharedWith = :shared',
    ExpressionAttributeValues={':shared': {'L': [{'S': 'user456'}]}}
)
```

CLI:
```bash
# Query by userId
aws dynamodb query \
  --table-name FileMetadata \
  --key-condition-expression 'userId = :uid' \
  --expression-attribute-values '{":uid":{"S":"user123"}}'

# Get item
aws dynamodb get-item \
  --table-name FileMetadata \
  --key '{"userId":{"S":"user123"},"fileId":{"S":"abc-def-ghi"}}'
```

### Implementation Steps
- [x] **Add DynamoDB table to `template.yaml`**
  ```yaml
  FileMetadataTable:
    Type: AWS::DynamoDB::Table
    Properties:
      TableName: !Sub '${AWS::StackName}-file-metadata'
      BillingMode: PAY_PER_REQUEST  # on-demand
      AttributeDefinitions:
        - AttributeName: userId
          AttributeType: S
        - AttributeName: fileId
          AttributeType: S
      KeySchema:
        - AttributeName: userId
          KeyType: HASH    # partition key
        - AttributeName: fileId
          KeyType: RANGE   # sort key
  ```

- [x] **Update `POST /files/upload-url` Lambda**
  - After generating presigned URL, store metadata in DynamoDB
  - Generate `fileId` with `uuid.uuid4()`
  - Store: userId (hardcoded "demo-user" for now), fileId, fileName, s3Key, uploadedAt

- [x] **Update Lambda IAM role** to allow `dynamodb:PutItem`, `dynamodb:Query`, `dynamodb:GetItem`

- [x] **Deploy with `sam build && sam deploy`**

- [x] **Test presigned URL**
  - Call API to get presigned URL
  - Upload file using `curl` or browser
  - Verify file in S3: `aws s3 ls s3://bucket-name/`

- [x] **Create Lambda: `GET /files`**
  - Query DynamoDB by userId
  - Return list of files with metadata

- [ ] **Create Lambda: `GET /files/{fileId}`**
  - Get item from DynamoDB
  - Return file metadata

- [ ] **Deploy with `sam build && sam deploy`**

- [ ] **Test**
  - Upload file via presigned URL
  - Call `GET /files` → should return uploaded file metadata
  - Call `GET /files/{fileId}` → should return single file metadata

### Real-World Extras
- [ ] **Add TTL for temporary files** (auto-delete after N days)
  ```yaml
  TimeToLiveSpecification:
    AttributeName: expiresAt
    Enabled: true
  ```
  - In Lambda, set `expiresAt` to Unix timestamp (e.g., +30 days)

- [ ] **Add pagination** for `GET /files`
  - Use `LastEvaluatedKey` from DynamoDB response
  - Return to client for next page request

- [ ] **Enable DynamoDB Streams** (for audit log, future use)
  ```yaml
  StreamSpecification:
    StreamViewType: NEW_AND_OLD_IMAGES
  ```

### Outcome
✅ **Files tracked in DynamoDB, users can list their files**

---

## Sprint 4: User Authentication (Cognito)

### Goals
- Add user signup/login
- Secure API with JWT tokens
- Extract userId from token

### New Services
- **Cognito User Pool**: User directory and authentication
- **API Gateway Authorizer**: JWT validation

### 🚨 MUST-KNOW (taught now)
- **User Pools vs Identity Pools** — **MOST CRITICAL DISTINCTION!**
  - **User Pool**: Signup/login → JWT tokens (ID, access, refresh). Use for: backend APIs
  - **Identity Pool**: Exchange JWT → AWS credentials. Use for: direct S3/DynamoDB access from browser
  - For this project: **User Pool only** (API Gateway validates JWT)
- **Three token types**:
  - **ID token**: User info (email, name). Use for: display in UI
  - **Access token**: Authorization. Use for: API Gateway authorizer (this is what we'll use!)
  - **Refresh token**: Get new tokens without re-login (30 days default)
- **JWT tokens are stateless** — cannot revoke until expiry. For immediate revocation, use `admin_user_global_sign_out()`
- **Password policy** — min 8 chars, uppercase, lowercase, numbers, symbols (configurable)

### Essential Cognito Operations (SDK + CLI)
```python
# Sign up user
cognito.sign_up(
    ClientId='client-id',
    Username='user@example.com',
    Password='Password123!',
    UserAttributes=[{'Name': 'email', 'Value': 'user@example.com'}]
)

# Confirm signup (with code from email)
cognito.confirm_sign_up(
    ClientId='client-id',
    Username='user@example.com',
    ConfirmationCode='123456'
)

# Admin confirm (skip email, for testing)
cognito.admin_confirm_sign_up(
    UserPoolId='us-east-1_xxx',
    Username='user@example.com'
)

# Login (get tokens)
cognito.initiate_auth(
    ClientId='client-id',
    AuthFlow='USER_PASSWORD_AUTH',
    AuthParameters={
        'USERNAME': 'user@example.com',
        'PASSWORD': 'Password123!'
    }
)
# Returns: IdToken, AccessToken, RefreshToken

# Get user info (from access token)
cognito.get_user(AccessToken='access-token')
```

CLI:
```bash
# Sign up
aws cognito-idp sign-up \
  --client-id xxx \
  --username user@example.com \
  --password Password123! \
  --user-attributes Name=email,Value=user@example.com

# Confirm signup
aws cognito-idp confirm-sign-up \
  --client-id xxx \
  --username user@example.com \
  --confirmation-code 123456

# Login
aws cognito-idp initiate-auth \
  --client-id xxx \
  --auth-flow USER_PASSWORD_AUTH \
  --auth-parameters USERNAME=user@example.com,PASSWORD=Password123!
```

### Implementation Steps
- [ ] **Add Cognito User Pool to `template.yaml`**
  ```yaml
  UserPool:
    Type: AWS::Cognito::UserPool
    Properties:
      UserPoolName: !Sub '${AWS::StackName}-users'
      AutoVerifiedAttributes: [email]
      UsernameAttributes: [email]  # login with email
      Policies:
        PasswordPolicy:
          MinimumLength: 8
          RequireUppercase: true
          RequireLowercase: true
          RequireNumbers: true
          RequireSymbols: true

  UserPoolClient:
    Type: AWS::Cognito::UserPoolClient
    Properties:
      UserPoolId: !Ref UserPool
      ClientName: !Sub '${AWS::StackName}-client'
      ExplicitAuthFlows:
        - ALLOW_USER_PASSWORD_AUTH
        - ALLOW_REFRESH_TOKEN_AUTH
      GenerateSecret: false  # for browser/mobile apps
  ```

- [ ] **Add Cognito Authorizer to API Gateway**
  ```yaml
  # In API Gateway definition
  Auth:
    Authorizers:
      CognitoAuthorizer:
        UserPoolArn: !GetAtt UserPool.Arn
  ```

- [ ] **Update all API routes to require auth**
  ```yaml
  # On each function's API event
  Auth:
    Authorizer: CognitoAuthorizer
  ```

- [ ] **Update Lambda functions to extract userId**
  ```python
  # Lambda receives userId in event
  user_id = event['requestContext']['authorizer']['claims']['sub']
  # 'sub' is the unique user ID from Cognito
  ```

- [ ] **Create test user**
  - Use CLI to sign up and confirm user
  - Get access token

- [ ] **Deploy with `sam build && sam deploy`**

- [ ] **Test authentication**
  - Call `GET /files` without token → 401 Unauthorized
  - Call `GET /files` with token → 200 OK, returns files for authenticated user

### Real-World Extras
- [ ] **Add Cognito Groups for RBAC** (Admin, User)
  ```yaml
  AdminGroup:
    Type: AWS::Cognito::UserPoolGroup
    Properties:
      GroupName: Admins
      UserPoolId: !Ref UserPool
  ```

- [ ] **Enable MFA (optional)** for extra security
  ```yaml
  MfaConfiguration: OPTIONAL  # or REQUIRED
  EnabledMfas: [SOFTWARE_TOKEN_MFA]  # TOTP (Google Authenticator)
  ```

- [ ] **Add Lambda trigger** for post-signup (send welcome email, create user record)
  ```yaml
  LambdaConfig:
    PostConfirmation: !GetAtt WelcomeUserFunction.Arn
  ```

### Outcome
✅ **API secured with Cognito, users can signup/login, all operations are user-specific**

---

## Sprint 5: File Download & Sharing

### Goals
- Generate presigned URLs for download
- Share files with other users
- Implement permission checks

### New Concepts
- DynamoDB conditional writes
- Permission checking in Lambda

### Implementation Steps
- [ ] **Create Lambda: `GET /files/{fileId}/download-url`**
  - Get file metadata from DynamoDB
  - Check permissions: is user the owner OR in `sharedWith` list?
  - If authorized: generate presigned GET URL for S3
  - Return: `{ "downloadUrl": "https://..." }`

- [ ] **Create Lambda: `POST /files/{fileId}/share`**
  - Input: `{ "shareWithUserId": "user456" }`
  - Update DynamoDB: add user to `sharedWith` list
  - Use `UpdateExpression: 'ADD sharedWith :user'`

- [ ] **Update `GET /files` to include shared files**
  - Query owned files: `userId = :uid`
  - Add GSI (Global Secondary Index) for shared files (later optimization)
  - For now: scan with filter (not optimal, but works for learning)

- [ ] **Deploy and test**
  - User A uploads file
  - User A shares with User B
  - User B can download file
  - User C cannot download file → 403 Forbidden

### Real-World Extras
- [ ] **Add GSI for efficient shared file queries**
  ```yaml
  GlobalSecondaryIndexes:
    - IndexName: SharedWithIndex
      KeySchema:
        - AttributeName: sharedWith
          KeyType: HASH
      Projection:
        ProjectionType: ALL
  ```

- [ ] **Add file deletion: `DELETE /files/{fileId}`**
  - Delete from S3: `s3.delete_object()`
  - Delete from DynamoDB: `dynamodb.delete_item()`
  - Check ownership before deletion

### Outcome
✅ **Users can download and share files with permission checks**

---

## Sprint 6: Background Processing (SQS + S3 Events)

### Goals
- Trigger Lambda on S3 upload
- Process files asynchronously (e.g., generate thumbnail)
- Learn event-driven architecture

### New Services
- **S3 Events**: Trigger on upload/delete
- **SQS**: Message queue for async processing
- **SNS**: Notifications

### 🚨 MUST-KNOW (taught now)
- **S3 events are asynchronous** — Lambda invoked after upload completes
- **SQS visibility timeout** — message invisible for N seconds after receive. If not deleted, becomes visible again (default 30s)
- **At-least-once delivery** — message may be delivered multiple times. Make processing **idempotent**!
- **FIFO vs Standard queues** — FIFO: exactly-once, ordered, 300 msg/s. Standard: unlimited throughput, best-effort ordering

### Implementation Steps
- [ ] **Add SQS queue to `template.yaml`**
  ```yaml
  FileProcessingQueue:
    Type: AWS::SQS::Queue
    Properties:
      QueueName: !Sub '${AWS::StackName}-file-processing'
      VisibilityTimeout: 300  # 5 minutes
  ```

- [ ] **Add S3 event notification → SQS**
  ```yaml
  # In S3 bucket
  NotificationConfiguration:
    QueueConfigurations:
      - Event: s3:ObjectCreated:*
        Queue: !GetAtt FileProcessingQueue.Arn
        Filter:
          S3Key:
            Rules:
              - Name: prefix
                Value: uploads/
  ```

- [ ] **Create Lambda: process files from SQS**
  - Triggered by SQS messages
  - Download file from S3
  - Process (e.g., generate thumbnail, scan for viruses)
  - Upload result to S3
  - Delete message from queue (automatic with Lambda SQS integration)

- [ ] **Test**
  - Upload file to S3
  - S3 → SQS → Lambda automatically triggered
  - Check CloudWatch Logs for Lambda execution

### Real-World Extras
- [ ] **Add Dead Letter Queue** for failed processing
  ```yaml
  RedrivePolicy:
    deadLetterTargetArn: !GetAtt DLQ.Arn
    maxReceiveCount: 3  # retry 3 times before DLQ
  ```

- [ ] **Add SNS for notifications** (email when processing done)
  ```yaml
  ProcessingTopic:
    Type: AWS::SNS::Topic
  ```

### Outcome
✅ **Event-driven async processing with S3 → SQS → Lambda**

---

## Sprint 7: Observability & Production Hardening

### Goals
- Add CloudWatch alarms
- Enable X-Ray tracing
- Structured logging
- Security review

### New Services
- **CloudWatch**: Metrics, logs, alarms
- **X-Ray**: Distributed tracing

### Implementation Steps
- [ ] **Add structured logging to all Lambdas**
  ```python
  import json
  import logging
  logger = logging.getLogger()
  logger.setLevel(logging.INFO)

  logger.info(json.dumps({
      'event': 'file_uploaded',
      'userId': user_id,
      'fileId': file_id,
      'fileName': file_name
  }))
  ```

- [ ] **Enable X-Ray tracing**
  ```yaml
  # In Lambda function
  Tracing: Active
  ```

- [ ] **Add CloudWatch alarms**
  ```yaml
  ApiErrorAlarm:
    Type: AWS::CloudWatch::Alarm
    Properties:
      AlarmName: !Sub '${AWS::StackName}-api-errors'
      MetricName: 5XXError
      Namespace: AWS/ApiGateway
      Statistic: Sum
      Period: 300
      EvaluationPeriods: 1
      Threshold: 10
      ComparisonOperator: GreaterThanThreshold
  ```

- [ ] **Security hardening checklist**
  - ✅ S3 bucket: public access blocked
  - ✅ S3 bucket: encryption enabled
  - ✅ DynamoDB: encryption at rest
  - ✅ Lambda: least privilege IAM roles
  - ✅ API Gateway: CORS configured restrictively
  - ✅ Cognito: strong password policy
  - ✅ All secrets in Secrets Manager/Parameter Store

- [ ] **Cost optimization**
  - [ ] S3 lifecycle policy: move old files to Glacier after 30 days
  - [ ] Lambda memory optimization: test with different memory sizes
  - [ ] DynamoDB: on-demand pricing (already set)

### Outcome
✅ **Production-ready observability and security**

---

## 🎓 What You'll Know After Completing This Project

### Core AWS Services (Deep, Hands-On)

**SAM (Serverless Application Model)**
- ✅ Define entire serverless apps as code
- ✅ Deploy with `sam build && sam deploy`
- ✅ Understand SAM → CloudFormation compilation
- ✅ Use `sam local invoke` for local testing

**Lambda**
- ✅ Create serverless functions in Python
- ✅ Configure IAM execution roles (least privilege)
- ✅ Handle API Gateway proxy integration
- ✅ Use environment variables for configuration
- ✅ Understand cold starts and optimization

**API Gateway**
- ✅ Create HTTP APIs with Lambda integration
- ✅ Configure Cognito JWT authorizers
- ✅ Set up CORS for browser clients
- ✅ Understand 10MB payload and 29s timeout limits

**S3**
- ✅ Generate presigned URLs for direct upload/download
- ✅ Configure CORS, versioning, encryption
- ✅ Set up S3 event notifications
- ✅ Understand why presigned URLs bypass Lambda

**DynamoDB**
- ✅ Design tables with partition/sort keys
- ✅ Query efficiently (avoid Scan!)
- ✅ Use GSI for additional query patterns
- ✅ Implement pagination with LastEvaluatedKey
- ✅ Choose on-demand vs provisioned capacity

**Cognito**
- ✅ Create user pools for authentication
- ✅ Implement signup/login flows
- ✅ Understand ID vs Access vs Refresh tokens
- ✅ Integrate with API Gateway authorizers
- ✅ Extract user claims from JWT in Lambda

**SQS + S3 Events**
- ✅ Build event-driven architectures
- ✅ Process files asynchronously
- ✅ Handle at-least-once delivery (idempotency)

**CloudWatch + X-Ray**
- ✅ View Lambda logs
- ✅ Create alarms for errors and latency
- ✅ Enable distributed tracing

### Production Skills

**Infrastructure as Code**
- ✅ Use IaC from day 1 (not at the end!)
- ✅ Version control infrastructure
- ✅ Reproducible deployments
- ✅ Destroy and recreate entire stack safely

**Security**
- ✅ Least privilege IAM policies
- ✅ Encryption at rest (S3, DynamoDB)
- ✅ JWT authentication and authorization
- ✅ Input validation and permission checks

**Real-World Architecture**
- ✅ Feature-driven development
- ✅ Iterative deployment (ship after each sprint)
- ✅ Event-driven async processing
- ✅ Observability from the start

### Career-Ready

After this project, you can:
- ✅ **Build serverless apps** from scratch with IaC
- ✅ **Explain design decisions** (why presigned URLs, why DynamoDB over RDS, etc.)
- ✅ **Deploy to production** confidently with monitoring and security
- ✅ **Join AWS projects** immediately with practical experience

You'll have **real engineering experience**, not tutorial knowledge.

---

## Session State

**Last Updated**: 2025-11-27
**Current Sprint**: Sprint 3 - File Metadata Storage (DynamoDB)
**Next Step**: Create Lambda: `GET /files/{fileId}` to get single file metadata

**Progress**:
- Sprints: 8 (0-7)
- Completed: 3 (Sprint 0 ✅, Sprint 1 ✅, Sprint 2 ✅)
- Current: Sprint 3
- Sprint 2 completed: 5/5 main tasks + 3/3 production extras
- Sprint 3 tasks completed: 5/7

---

## Teaching Instructions (for Claude)

**🔄 When resuming a session**:
1. **Read "Session State"** to identify current sprint and next unchecked item
2. **Locate next checkbox** in current sprint
3. **Teach the concept/step**:
   - Start with mental model (1-2 sentences: what it is, why it exists)
   - Show essential Python SDK calls
   - Show equivalent AWS CLI commands
   - Teach MUST-KNOWs just-in-time (when user encounters the need)
   - Provide real-world example from this project
4. **Guide user through implementation**:
   - Don't just list steps — walk through them interactively
   - Answer questions as they arise
   - Check for understanding
5. **Verify user's work**:
   - Use `aws ... --profile claude` to check their deployed resources
   - Review their code if they share it
6. **Check the box** when user completes the task
7. **Update "Session State"** with progress
8. **Move to next sprint** when all sprint checkboxes complete

**📚 Teaching style** (from CLAUDE.md):
- Short, direct explanations (no essays)
- Always show both Python SDK + AWS CLI
- Teach MUST-KNOWs when relevant, not upfront
- Use real examples from this project
- No fluff or theory
- Let user drive pace (don't auto-advance unless asked)

**🎯 Sprint workflow**:
- Guide user to build one feature per sprint
- Teach services together in context (not in isolation)
- Have user deploy and test after each sprint
- Emphasize: checkboxes track feature completion, not service mastery (services will be used in multiple sprints)

**⚠️ Important reminders**:
- User has admin access (default profile) to build
- Claude has read-only access (`--profile claude`) to verify
- This file is Claude's script — guide the user, don't just point them to the file

**File references**:
- AWS docs: `aws-pdfs/` folder
- SDK examples: `aws-doc-sdk-examples/`
- CLI examples: `/opt/homebrew/share/awscli/examples/{service}/`

**AWS Access**:
- User has admin access (default profile) to build and deploy
- Claude has read-only access (`--profile claude`) to check user's work
- All CLI examples in this plan are for the user (no `--profile` flag needed)
