alias IbGib.Data.Schemas.Seeds

# Basic
:ok = Seeds.insert(:root)
:ok = Seeds.insert(:fork)
:ok = Seeds.insert(:mut8)
:ok = Seeds.insert(:rel8)
:ok = Seeds.insert(:query)

# Identity
Seeds.insert(:identity)
Seeds.insert(:session)
Seeds.insert(:email)
