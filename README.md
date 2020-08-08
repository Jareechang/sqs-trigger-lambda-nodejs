## SQS Trigger Lambda demo on Node.js

Create a Lambda function zipped and stored in S3 to interact with SQS.

Quick demo few AWS services and concepts: 

- AWS IAM roles (Dev, Instance and Lambda roles)
- Ingest messaging sent to SQS using Lambda
- Lambda CW logs setup 
- Lambda S3 store 
- Terraform

### Sections

1. [Quick Start](#quick-start)  
2. [Local Dev Testing](#local-dev-testing)  
3. [Lambda Versioning](#lambda-versioning)  

### Quick Start

1. Setup the environment   
```sh

// create a file called setup-env.sh 
export AWS_ACCESS_KEY_ID=<your-aws-key>
export AWS_SECRET_ACCESS_KEY=<your-aws-secret>
export AWS_DEFAULT_REGION=us-east-1

. ./setup-env.sh
```

2. Create Infrastructure  

```sh
terraform init
terraform plan
terraform apply -auto-approve 
```

3. Visit Console and trigger lambda   

### Local Dev Testing 

**Note:** Quick start is required to perform local dev testing as the infrastructure setup is needed.

The terraform `outputs.tf` should output the access id and key for the new user created.

1. Setup the dev testing environment

```sh

// Similar to setup-env.sh, create another file setup-dev.sh
export AWS_ACCESS_KEY_ID=<output AWS id>
export AWS_SECRET_ACCESS_KEY=<output AWS secret>
export AWS_DEFAULT_REGION=us-east-1
```

2. Create local test script 

**Recommended (Node >= 10.15.x)**


```
const AWS = require('aws-sdk');

const QueueUrl = <output queue url>;

const config = {
    apiVersion: '2012-11-05',
    region: process.env.AWS_DEFAULT_REGION,
    endpoint: QueueUrl
};

const sqs = new AWS.SQS(config);

async function run() {
    const params = {
        QueueUrl
    };
    const result = await sqs.getQueueAttributes(params).promise();
    console.log(result);
}

run();
```

### Lambda Versioning 

Created custom versioning of lambda code changes via node.js scripts. The gist of it is when versioning is done through the npm (patch, minor, major) the terraform configuration will pick up changes and push changes based on the version in the `package.json`. 


**Publishing:**
```sh
// Patch
yarn run version:patch

// Minor 
yarn run version:minor

// Major 
yarn run version:major
```

**Deploying:**

```
terraform plan
terraform apply -auto-approve 
```
