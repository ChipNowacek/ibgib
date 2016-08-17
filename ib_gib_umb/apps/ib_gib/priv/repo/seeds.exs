alias IbGib.Data.Repo
alias IbGib.Data.Schemas.Seeds

Repo.insert!(Seeds.get_seed(:root))
Repo.insert!(Seeds.get_seed(:fork))
Repo.insert!(Seeds.get_seed(:mut8))
Repo.insert!(Seeds.get_seed(:rel8))
Repo.insert!(Seeds.get_seed(:query))
