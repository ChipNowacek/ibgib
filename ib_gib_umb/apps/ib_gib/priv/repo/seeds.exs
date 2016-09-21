alias IbGib.Data.Schemas.Seeds
use IbGib.Constants, :ib_gib

# These look like "types" to me, but they're not quite building a "type"
# system. They're also not interfaces, protocols, or anything. They're ib_gib.
# With respect to data types, think of things in terms of "what if there were
# no machine/implementation details?" E.g. no int16/32/etc., just integer.
# We could have these if we want, but to start out with, I'm not even sure of
# going past just "number". But who knows. It's just a convenience anyway, as
# "primitives" may be added a later time. I'm just doing some (probably
# arbitrary) stuff here.

# Root!
:ok = Seeds.insert(:root)

:ok = Seeds.insert(:error)

# Fundamental Transforms
:ok = Seeds.insert(:fork, %{
  "src" => "[src]",
  "dest_ib" => "[src.ib]"
  })
:ok = Seeds.insert(:mut8, %{
  "src" => "[src]",
  "new_data" => "[src.data]"
  })
:ok = Seeds.insert(:rel8, %{
  "src" => "[src]",
  "other" => @root_ib_gib,
  "rel8ns" => @default_rel8ns
  })

# Composite Transforms
# see https://github.com/ibgib/ibgib/issues/1
:ok = Seeds.insert(:step, %{
  "name" => "[rand]",
  "in" => "[src]",
  # The root ib^gib is the "identity" transform/function.
  "t" => @root_ib_gib,
  # "out" => "",
  })
:ok = Seeds.insert(:plan, %{
  # new_id will be parsed, space-delimited args (I guess)
  "name" => "[new_id 10]",
  "steps" => ["step#{@delim}gib"]
  })

# Query
:ok = Seeds.insert(:query)
:ok = Seeds.insert(:query_result)

# Identity
Seeds.insert(:identity)
Seeds.insert(:session)
Seeds.insert(:email)
Seeds.insert(:bootstrap_identity)

# Text Related
Seeds.insert(:text)
Seeds.insert({:comment, :text_child})
Seeds.insert({:url, :text_child})

Seeds.insert(:number)
