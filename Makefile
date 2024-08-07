ifneq ("$(wildcard .env)","")
	include .env
	export $(shell sed 's/=.*//' .env)
endif

help:  ## Display this help message
	@egrep -h '\s##\s' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m  %-30s\033[0m %s\n", $$1, $$2}'

ensure-deps:
	@which omni > /dev/null 2>&1 || { \
		echo "Binary `omni` not found. Installing..."; \
		curl -sSfL https://raw.githubusercontent.com/omni-network/omni/main/scripts/install_omni_cli.sh | sh -s; \
	}

build:
	forge build

test:
	forge test -vvv

devnet-start:
	omni devnet start

devnet-clean:
	omni devnet clean

devnet-deploy:
	./script/devnet-deploy.sh

.PHONY: ensure-deps build test devnet-start devnet-clean deploy
