STAGE=test # test, prod
RESOURCE_GROUP=rg-data-$(STAGE)

.PHONY: plan apply destroy

plan:
	az deployment group what-if \
		--mode Complete \
		--resource-group $(RESOURCE_GROUP) \
		--template-file main.bicep \
		--parameters environment=$(STAGE)

apply:
	az deployment group create \
		--mode Complete \
		--resource-group $(RESOURCE_GROUP) \
		--template-file main.bicep \
		--parameters environment=$(STAGE)

destroy:
	@if [ "$(STAGE)" = "prod" ]; then \
		echo "Error: Cannot run destroy when STAGE=prod"; \
		exit 1; \
	fi
	az group delete --name $(RESOURCE_GROUP) --yes --no-wait