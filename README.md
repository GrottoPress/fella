# Fella

**Fella** is an expressive HTTP log handler for *Crystal*.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     fella:
       github: GrottoPress/fella
   ```

1. Run `shards update`

1. Require *Fella*:

   ```crystal
   # ...
   require "fella"
   # ...
   ```

## Usage

Pass an instance of `Fella::Handler` to the web server:

```crystal
# ...
require "http/server"
require "fella"

Fella.configure do |settings|
  settings.skip_if = ->(request : HTTP::Request) do
    request.query_params.any? do |key, _|
      !key.match(/code|password|secret|token/i).nil?
    end
  end
end

server = HTTP::Server.new([
  Fella::Handler.new(log: Log.for(MyApp)),
  # ...
])

server.bind_tcp("127.0.0.1", 8080)
server.listen
# ...
```

## Development

Run tests with `crystal spec`.

## Contributing

1. [Fork it](https://github.com/GrottoPress/fella/fork)
1. Switch to the `master` branch: `git checkout master`
1. Create your feature branch: `git checkout -b my-new-feature`
1. Make your changes, updating changelog and documentation as appropriate.
1. Commit your changes: `git commit`
1. Push to the branch: `git push origin my-new-feature`
1. Submit a new *Pull Request* against the `GrottoPress:master` branch.
