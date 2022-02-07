# Terraform
## Getting Started
Terraform can be used through many different means.  These are referred to as 
"providers".  For example, AWS, Kubernetes, and ACME are possible providers. 
Each provider will have it's own way of creating your infrastructure so it is 
important that we write our code to support the correct provider.

## Providers
### General Example
```tf
resource "<provider>_resource_type" "name" {
  config options
  key = "<value>"
}
```

### AWS Example
```tf
provider "aws" {
  version = "-> 2.0"
  region = "us-east-1"
}
```

## Terraform and AWS
We will need to refer to the terraform documentation in order to set up 
out terraform files.  Just keep in mind that the information here might 
be outdated.

### AWS RSA Keys
Since we are using terraform with AWS, it is important that we actually set 
up our access keys rather than hardcode them into our terraform files for 
security purposes.  To do this, we must open AWS and head over to the EC2 
services.  Go to "key pairs" under "Network and Security" on the menu on the 
left.  You should be able to create an RSA key this way.

### AWS access keys and secrets
```cfg
# ~/.aws/credentials
[main-key]
aws_access_key_id = "abcdefg12345"
aws_seret_access_key = "aBcdEfgHiJklMNo1234/5421839"
```
```tf
provider "aws" {
  profile = "main-key"
  region = "us-east-1"
}
```
This is how you create a local file for your access keys.  This is the default 
location where your profiles should exist.

### Creating a new EC2 instance or Resource
```tf
privoder "aws" {
  region = "us-east-1"
  access_key = "abcdefg123456"
  secret_key = "du3na/abEeg32/Abcja9"
}

resource "aws_am1" "ubuntu" {
  most_recent = true

  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "web" {
  # AMI can be found starting to create a new EC2 image, find hte image we want, 
  # then copying the ami next to the image name.

  ami = data.aws_ami.ubuntu.id 
  instance_type = "t3.micro"

  tags = {
    Name = "HelloWorld"
  }
}
```
```bash
terraform init
```

#### Init
If we run the bash command above in our terminal, we should see terraform 
initialize our backend.  This usually involves installing any necessary plugins 
that are required to interface with your environment.

#### Plan
```bash
terraform plan
```

The command "terraform plan" will do a dry run of what your configuration files 
should do.  Using this command in our context should return back "aws_instance.web 
will be created" since we are creating a new aws ec2 instance.

#### Apply
```bash
terraform apply
```
The "terraform apply" command is how we actually run our terraform code.  This will 
do the same thing as "terraform plan" but, it will ask you at the end if you wish 
to run the command.  If there are any errors in your code, it will usually let you 
know upon running your code.  Once it is finished, this process sometimes takes a 
little while, you should see "Apply complete! Resources: 1 added, 0 changed, 0 destroyed".  

You should now see your new running instance in AWS.

#### Things to note when running configuration files
If we were to rerun our terraform code, it will not create another instance of our 
EC2 instances.  Instead, we are writing our terraform code to specify there should 
be one instance that looks like this.  This is similar to docker-compose yaml files. 
When we run the file again, it actually just refreshes the state of the instances 
that are already active and defined in your file.  You can see this by running 
"terraform plan" again.

### Modifying Resources
In order to modify any of our resources, we just need to update our configuration 
files with the needed change and run "terraform apply".  Similar to updating a 
docker-compose.yaml file, the next time we run our "terraform apply" command, 
we should see "0 to add, 1 to change, 0 to destroy" to let us know that terraform 
is modifying one of our resources.

#### Updating a tag
```tf
resource "aws_instance" "web" {
  ami = data.aws_ami.ubuntu.id 
  instance_type = "t3.micro"

  tags = {
    Name = "HelloWorldChanged"
  }
}

```
```bash
terraform plan  # make sure nothing will break
terraform apply # apply our configuration
```

### Deleting Resources
```bash
terraform destroy
```
In order to destroy a resource, we can either run the terraform destroy command 
which will destroy all resources in our file or, we can simply remove the 
resource from our configuration file.  Once it is removed, it will terminate 
our running instances when we run "terraform apply" again.

### Other Resources
#### AWS VPC (Virtual Private Cloud) 
A VPC is basically just a way to create multiple networks inside your environment.

### Referencing Other Resources
```tf
resource "aws_vpc" "first-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "production"
  }
}

resource "aws_subnet" "main" {
  vpc_id = aws_vpc.first-vpc.id  # How we reference other resources
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "prod-subnet"
  }
}
```
Every resource that we create with terraform will be reference-able using the 
syntax above.  First we specify the resource, then specify the resource's 
name that we want to refer to, and finally we specify the "id" field.  All 
resources will have an ID and we can point one resource to another using it.

#### Additional notes
You do not need to declare a resource before referencing it.  Using our code 
example above, if we put the "abs_subnet" first then define our "aws_vpc", it 
will still work as we expect.

## Terraform files
### Terraform plugins folder
Each time we run the command "terraform init", it will create a new folder 
called "Plugins" where the needed plugins that we are using are installed. 
If you manage to delete this folder, you will get an error explaining that 
the provider cannot be found and you will just need to run "terraform init" 
once again to pull your plugins once more.

## Terraform.tfstate
This file is used to keep track of the current state of our terraform 
resources.  This file appears to be in a JSON format but, we can store all 
of our current resource states in this file so that it knows what is changing 
or created in your environment.  If this file is deleted, you will break your 
environment.

\newpage
