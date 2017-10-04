ASSET_DIR=$(shell pwd)/assets
TEST_DIR=$(shell pwd)/testing
TEST_MATCHBOX_DIR=$(shell pwd)/matchbox
TEST_MATCHBOX_ASSET_DIR=$(TEST_MATCHBOX_DIR)/assets
TEST_CERTS_DIR=$(shell pwd)/certs
MATCHBOX_PLUGIN=$(ASSET_DIR)/terraform-provider-matchbox
DOCKER_TAG=kramergroup/terraform-matchbox
CERTS=ca.crt server.crt server.key client.crt client.key
CERTS := $(addprefix $(TEST_CERTS_DIR)/,$(CERTS))

# Container ---------------------------------------------------------------------------------------
.PHONY: container
container: $(MATCHBOX_PLUGIN)
	docker build -f Dockerfile -t $(DOCKER_TAG) .

# Compile matchbox plug-in ------------------------------------------------------------------------
$(MATCHBOX_PLUGIN): IMAGE=$(shell docker build -q -f Dockerfile.plugin .)
$(MATCHBOX_PLUGIN): Dockerfile.plugin
	docker run --rm -v $(ASSET_DIR):/export $(IMAGE) "cp /go/bin/terraform-provider-matchbox /export"
	docker rmi $(IMAGE)

# Testing ------------------------------------------------------------------------------------------
.PHONY: certs
certs: $(CERTS)

$(CERTS): CERT_IMAGE=$(shell docker build -q -f Dockerfile.certgen .)
$(CERTS): $(TEST_CERTS_DIR) openssl.conf cert-gen.sh
	docker run --rm -v $(TEST_CERTS_DIR):/target \
 						 -e "SAN=DNS.1:matchbox,DNS.1:localhost,DNS.2:$(shell hostname)" \
						 $(CERT_IMAGE)

$(TEST_DIR)/terraform.tfvars: $(TEST_CERTS_DIR)/client.crt
	rm -rf $(TEST_DIR)/terraform.tfvars
	echo -e "matchbox_http_endpoint = \"http://localhost:8080\"\n" > $(TEST_DIR)/terraform.tfvars
	echo -e "matchbox_rpc_endpoint = \"matchbox.example.com:8081\"\n" >> $(TEST_DIR)/terraform.tfvars

test: container $(CERTS) $(TEST_DIR) $(TEST_MATCHBOX_DIR) $(TEST_MATCHBOX_ASSET_DIR)
	-docker network create testnet
	docker run --rm -d --net testnet --name matchbox \
									-v $(TEST_MATCHBOX_DIR):/var/lib/matchbox:Z \
								  -v $(TEST_CERTS_DIR)/ca.crt:/etc/matchbox/ca.crt:z,ro \
									-v $(TEST_CERTS_DIR)/server.key:/etc/matchbox/server.key:z,ro \
									-v $(TEST_CERTS_DIR)/server.crt:/etc/matchbox/server.crt:z,ro \
									quay.io/coreos/matchbox:latest -address=0.0.0.0:8080 -rpc-address=0.0.0.0:8081
	docker run --rm --net testnet --name terraform \
									-v $(TEST_DIR):/build \
	 								-v $(TEST_CERTS_DIR)/client.crt:/root/.matchbox/client.crt:ro \
									-v $(TEST_CERTS_DIR)/client.key:/root/.matchbox/client.key:ro \
									-v $(TEST_CERTS_DIR)/ca.crt:/root/.matchbox/ca.crt:ro \
									 $(DOCKER_TAG) apply ; docker kill matchbox ; docker network rm testnet


# Utility targets ----------------------------------------------------------------------------------
$(ASSET_DIR) $(TEST_MATCHBOX_DIR) $(TEST_CERTS_DIR) $(TEST_MATCHBOX_ASSET_DIR):
	mkdir -p $@

clean:
	rm -rf $(ASSET_DIR) $(TEST_MATCHBOX_DIR) $(TEST_CERTS_DIR)
	docker rmi $(DOCKER_TAG)
