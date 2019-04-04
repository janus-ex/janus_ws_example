use Mix.Config

config :web, Web.Endpoint,
  http: [:inet6, port: System.get_env("PORT")],
  url: [host: System.get_env("HOST"), port: 443],
  secret_key_base: System.get_env("SECRET_KEY_BASE")

config :kernel, inet_dist_use_interface: {127, 0, 0, 1}
