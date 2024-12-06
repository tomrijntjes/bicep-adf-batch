STAGE=test # test, prod

.PHONY: plan apply

plan:
	az deployment sub create \
		--location westeurope \
		--template-file main.bicep \
		--parameters environment=$(STAGE) \
		--what-if 

apply:
	az deployment sub create \
		--location westeurope \
		--template-file main.bicep \
		--parameters environment=$(STAGE) 