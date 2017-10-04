# terraform-matchbox

The container provides a terraform runtime based on the terraform:light container
with the CoreOS matchbox provider integrated.

## How to compile

A recent docker installation is the only pre-requisite. Should be as simple as

```
make
```

This will package the matchbox plugin with the terraform:light container.

## How to use

Basic usage is as follows:

```
docker run --rm -v <DIR WITH TERRAFORM CONFIG>:/build \
                 $(DOCKER_TAG) apply
```

> Note: Matchbox requires client authentication. The respective ssl certificates and keys need
to be provided to the container. The plugin expects them to be in ```/root/.terraform``` and named
```ca.crt```, ```client.key```, and ```client.crt```.
