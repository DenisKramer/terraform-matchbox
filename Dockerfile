FROM hashicorp/terraform:light

# Install Matchbox
COPY "assets/terraform-provider-matchbox" "/root/.terraform.d/plugins/terraform-provider-matchbox"

WORKDIR "/build"
