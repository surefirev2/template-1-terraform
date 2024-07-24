# Makefile

# Docker image
TERRAFORM_IMAGE = terraform

# Terraform directory
TERRAFORM_DIR = terraform

# User and group IDs
USER_ID = $(shell id -u)
GROUP_ID = $(shell id -g)

.PHONY: build-image
build-image:
	docker build -t $(TERRAFORM_IMAGE) .

.PHONY: init
init: build-image
	docker run --rm -u $(USER_ID):$(GROUP_ID) -v $(PWD)/$(TERRAFORM_DIR):/workspace -w /workspace $(TERRAFORM_IMAGE) init

.PHONY: validate
validate: init
	docker run --rm -u $(USER_ID):$(GROUP_ID) -v $(PWD)/$(TERRAFORM_DIR):/workspace -w /workspace $(TERRAFORM_IMAGE) validate

.PHONY: plan
plan: init
	docker run --rm -u $(USER_ID):$(GROUP_ID) -v $(PWD)/$(TERRAFORM_DIR):/workspace -w /workspace $(TERRAFORM_IMAGE) plan

.PHONY: apply
apply: init
	docker run --rm -u $(USER_ID):$(GROUP_ID) -v $(PWD)/$(TERRAFORM_DIR):/workspace -w /workspace $(TERRAFORM_IMAGE) apply -auto-approve

.PHONY: destroy
destroy: init
	docker run --rm -u $(USER_ID):$(GROUP_ID) -v $(PWD)/$(TERRAFORM_DIR):/workspace -w /workspace $(TERRAFORM_IMAGE) destroy -auto-approve

.PHONY: run-pre-commit
run-pre-commit:
	pre-commit run --all-files
