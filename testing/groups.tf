// Match machines which have CoreOS Container Linux installed
resource "matchbox_group" "node1" {
  name    = "node1"
  profile = "simple"

  selector {
    os = "installed"
  }

}
