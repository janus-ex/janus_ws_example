use Mix.Config

config :janus_ws_example, Web.Endpoint,
  cache_static_manifest: "priv/static/cache_manifest.json",
  version: Application.spec(:janus_ws_example, :vsn),
  server: true,
  root: "."

config :logger, level: :warn
