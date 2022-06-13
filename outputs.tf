 output "rancher_private_ip" {
   value = aws_instance.rancher_server.private_ip
 }

 output "rancher_endpoint" {
   value = helm_release.rancher_server.hostname
 }