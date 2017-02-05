use Mix.Releases.Config,
    # This sets the default release built by `mix release`
    default_release: :ib_gib_umb,
    # This sets the default environment used by `mix release`
    default_environment: :dev

# For a full list of config options for both releases
# and environments, visit https://hexdocs.pm/distillery/configuration.html


# You may define one or more environments in this file,
# an environment's settings will override those of a release
# when building in that environment, this combination of release
# and environment configuration is called a profile

environment :dev do
  set dev_mode:     false # b/c we want it to create tar file
  set include_erts: true
  set include_src:  false
  set cookie: :":ALx<_H|[~3W,LmaHKd/BE0^vn!GoW.ZaP6&mGo0tz3&BzaeQp;s<N+:_n_q6*bd"
end

environment :staging do
  set dev_mode:     false
  set include_erts: true
  set include_src:  false
  set cookie: :":ALx<_H|[~3W,LmaHKd/BE0^vn!GoW.ZaP6&mGo0tz3&BzaeQp;s<N+:_n_q6*bd"
end

environment :prod do
  set dev_mode:     false
  set include_erts: true
  set include_src:  false
  set cookie: :":ALx<_H|[~3W,LmaHKd/BE0^vn!GoW.ZaP6&mGo0tz3&BzaeQp;s<N+:_n_q6*bd"
end

# You may define one or more releases in this file.
# If you have not set a default release, or selected one
# when running `mix release`, the first release in the file
# will be used by default

release :ib_gib_umb do
  set version: "0.2.2"
  set applications: [
    ib_gib: :permanent,
    random_gib: :permanent,
    web_gib: :permanent
  ]
end
