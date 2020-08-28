## SQS Trigger Lambda demo on Node.js


Demonstration of IAM roles between AWS resources:  

```
Flow:

EC2 instance (send message) -> sqs (event source trigger) -> Lambda (Execute function) -> Execution Failures -> sqs (Dead letter queue)

```

The infrastructure creates an instance which allows for ip based access via SSH.
This instance has a role attached to send messages to our specific SQS queue.

When messages are sent to our SQS queue, our lambda function sources the event from the SQS queue. It does not do anything useful
other than log out details of the message. However, the example can be extended to implement more useful logic (ex. making an api call, write results to DB).

In addition, it handles failures of the lambda sourcing events from the ingestion queue. The failed events will end up in the failed queue.

**Quick demo few AWS services and concepts:**

- AWS IAM roles (Dev, Instance and Lambda roles)
- EC2 Instance, Security Groups 
- Ingest messages sent to SQS using Lambda (Event source SQS -> Lambda)
- Dead-letter Queue implementation for failed executions
- Append DLQ messages into DynamoDB (TODO)
- Lambda CW logs setup 
- Lambda S3 store 
- Terraform (>= v0.12.24)

### Sections

1. [Quick Start](#quick-start)  
2. [Local Dev Testing](#local-dev-testing)  
3. [Testing Within Instance](#testing-within-instance)
4. [Lambda Versioning](#lambda-versioning)  
5. [Learning](#learning)

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

#### Success flow
4. Test out send message via the AWS cli (success message)

```sh
# Set the default region for the AWS cli
export AWS_DEFAULT_REGION=us-east-1

# Send a success message 
aws sqs send-message \
--queue-url=<aws_queue_url> \
--message-body '{"type": "DATA", "message": "sending some message"}'
```

5. Observe the cloudWatch Log (It should output your queue message)

#### Failure flow

The lambda is configured to simulate event given a specific type of message with `type: ERROR`.

4. Test out send message via the AWS cli (failure message)

```sh
# Set the default region for the AWS cli
export AWS_DEFAULT_REGION=us-east-1

# Send a failure message
aws sqs send-message \
--queue-url=<aws_queue_url> \
--message-body '{ "type": "ERROR", "message": "Simulate a failure"}'
```
5. Observe the cloudWatch Log (It should output the error being thrown)

6. Receive message from the dead-letter-queue

```
# Receive the message from dlq 
aws sqs receive-message \
--queue-url=<aws_queue_url>
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

### Learning

Through this exercise there are a few things that I felt were caveats and took some time to figure out.

1. Sourcing from Dead letter SQS queues - Receive Message

Sourcing from and getting messages is actually quite non-trivial. Messing around with `ReceiveMessageWaitTimeSeconds` to get it to show up properly was quite a pain

An alternative solution is to append the data in these failed queues into dynamodb for easy querying, identification and debugging (stretch exercise).

2. Terraform setup  `aws_iam_policy_attachment`

When attaching one policy to a role is easy but the [terraform documention](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy_attachment) does not really provide information on attaching multiple.

A good way to do this is just to make another `aws_iam_policy_attachment` resource, example:

```sh
resource "aws_iam_policy_attachment" "attach_policy_to_role_instance_queue" {
    name       = "instance-role-attachment-queue"
    roles      = [aws_iam_role.instance_role.name]
    policy_arn = aws_iam_policy.sqs_instance_policy.arn
}

resource "aws_iam_policy_attachment" "attach_policy_to_role_instance_queue-dlq" {
    name       = "instance-role-attachment-queue"
    roles      = [aws_iam_role.instance_role.name]
    policy_arn = aws_iam_policy.dlq_sqs_instance_policy.arn
}
```

**Important:** The **Big** caveat is that the name has to be the same. Otherwise, it only attaches the last defined iam policy attachment.

