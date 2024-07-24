# main.tf
resource "local_file" "hello_world" {
  content  = "Hello, World!"
  filename = "${path.module}/hello_world.txt"
}
