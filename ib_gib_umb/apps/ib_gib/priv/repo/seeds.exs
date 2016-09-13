alias IbGib.Data.Schemas.Seeds

# These look like "types" to me, but they're not quite building a "type"
# system. They're also not interfaces, protocols, or anything. They're ib_gib.
# With respect to data types, think of things in terms of "what if there were
# no machine/implementation details?" E.g. no int16/32/etc., just integer.
# We could have these if we want, but to start out with, I'm not even sure of
# going past just "number". But who knows. It's just a convenience anyway, as
# "primitives" may be added a later time. I'm just doing some (probably
# arbitrary) stuff here.

# Basic
:ok = Seeds.insert(:root)
:ok = Seeds.insert(:fork)
:ok = Seeds.insert(:mut8)
:ok = Seeds.insert(:rel8)
:ok = Seeds.insert(:query)
:ok = Seeds.insert(:query_result)

# Identity
Seeds.insert(:identity)
Seeds.insert(:session)
Seeds.insert(:email)

# Text Related
Seeds.insert(:text)
Seeds.insert({:comment, :text_child})
Seeds.insert({:url, :text_child})

Seeds.insert(:number)
