provider "aws" {
  region     = "us-east-1"
  access_key = "xxxxxxxxxxxxxxxxxxxxxxx"
  secret_key = "xxxxxxxxxxxxxxxxxxxxxxxx"
}
resource "aws_instance" "firstvm" {
  ami           = "ami-053b0d53c279acc90"
  instance_type = "t2.micro"
  subnet_id     = "subnet-xxxxxxxxxx"
}
