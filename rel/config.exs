use Mix.Releases.Config,
  default_release: :janus_ws_example,
  default_environment: Mix.env()

# For a full list of config options for both releases
# and environments, visit https://hexdocs.pm/distillery/config/distillery.html

# You may define one or more environments in this file,
# an environment's settings will override those of a release
# when building in that environment, this combination of release
# and environment configuration is called a profile

environment :dev do
  # If you are running Phoenix, you should make sure that
  # server: true is set and the code reloader is disabled,
  # even in dev mode.

  # It is recommended that you build with MIX_ENV=prod and pass
  # the --env flag to Distillery explicitly if you want to use
  # dev mode.

  set(dev_mode: true)
  set(include_erts: false)
  set(cookie: :"N|e=qi5z.Y2xR9wYIjJRH)Ce?woY=h6d,K%BcryoY(YY0uxa;ncG|Bl/ju&&gdHN")
end

environment :prod do
  set(include_erts: true)
  set(include_src: false)

  # TODO read from env if we go distributed
  set(cookie: :"6xzZ</I1YdT<1D6DR`7]7}Svj*P3)i}{J!)G,0|Mg1BFb!g1aGt`uzDSa5zn`hh4")

  set(
    overlays: [
      {:copy, "rel/etc/config.exs", "etc/config.exs"}
    ]
  )

  set(
    config_providers: [
      {Mix.Releases.Config.Providers.Elixir, ["${RELEASE_ROOT_DIR}/etc/config.exs"]}
    ]
  )
end

# You may define one or more releases in this file.
# If you have not set a default release, or selected one
# when running `mix release`, the first release in the file
# will be used by default

release :janus_ws_example do
  set(version: current_version(:janus_ws_example))

  set(
    applications: [
      :runtime_tools
    ]
  )
end
