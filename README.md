# Bicep + ADF + Azure Batch

Deploy the subscription, then the individual resource groups.

## Prerequisites

Install bicep.

```
az bicep install
bicep --version
```

## Deploy Test

Yes, I borrowed terraform semantics.

```
make plan
```

Inspect the plan. When satisfied:

```
make apply
```


## Deploy to Prod

```
STAGE=prod make plan
STAGE=prod make apply
```



