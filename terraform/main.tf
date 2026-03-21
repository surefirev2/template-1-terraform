terraform {
  backend "s3" {
    bucket       = "surefirev2-terraform-state"
    key          = "github/surefirev2/template-1-terraform/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

resource "local_file" "hello_world" {
  content  = "Hello, World!!"
  filename = "${path.module}/hello_world.txt"
}
