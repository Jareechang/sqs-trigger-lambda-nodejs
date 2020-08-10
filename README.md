## SQS Trigger Lambda demo on Node.js


Demonstration of IAM roles between AWS resources:  

```
Flow: ec2 instance (send message) -> sqs (event source trigger) -> lambda

```

The infrastructure creates a instance which allows for single-user (local network ip) via SSH.
This instance has a role attached to send messages to our SQS queue.

When messages are sent to our SQS queue, our lambda function sources the event from the SQS queue. It does not do anything useful
other than log out details of the message. However, the example can be extended to implement more useful logic (ex. making an api call, write results to DB).

**Quick demo few AWS services and concepts:**

- AWS IAM roles (Dev, Instance and Lambda roles)
- EC2 Instance, Security Groups 
- Ingest messages sent to SQS using Lambda (Event source SQS -> Lambda)
- Lambda CW logs setup 
- Lambda S3 store 
- Terraform (>= v0.12.24)

### Sections

1. [Quick Start](#quick-start)  
2. [Local Dev Testing](#local-dev-testing)  
3. [Testing Within Instance](#testing-within-instance)  
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

**Important:** Note down the `queue-url` of the sqs queue to be used later

```sh
# The IP address is important for instance access (This is important if you want to test with instance)
export TF_VAR_local_ip_address=xxx.xxx.xxx 
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


```ts
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
### Testing Within Instance 

To run test on the whole setup to trigger queue message to be processed by the lambda, you’ll need ssh access to the instance.

See below for instructions. Upon running the terraform script you should receive a blob of private key outputed into the terminal along with the instance public ip.


1. Create a pem file (ex. `dev-key.pem`)
2. Set proper permissions by running  
```
chmod 400 ./dev-key.pem
```
3. Ssh into the instance

```sh
ssh -i "dev-key.pem" ec2-user@<output-instance-ip>
```

4. Test out send message via the AWS cli

```sh
# Set the default region for the AWS cli
export AWS_DEFAULT_REGION=us-east-1

# Send a random message
aws sqs send-message \
--queue-url=<output-queue-url> \
--message-body '{"data": "sending some message"}'
```

5. Observe CloudWatch Log (It should output your queue message)

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
