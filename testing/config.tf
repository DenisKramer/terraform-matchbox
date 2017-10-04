// Configure the matchbox provider
provider "matchbox" {
  endpoint = "matchbox:8081"
  client_cert = "${file("~/.matchbox/client.crt")}"
  client_key = "${file("~/.matchbox/client.key")}"
  ca         = "${file("~/.matchbox/ca.crt")}"
}
