use Mix.Config

config :logger, level: :debug

config :logger, :console,
  format: "\n[$time $level] $levelpad$metadata\n$message\n",
  metadata: [:line, :module, :function]
