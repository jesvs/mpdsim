In order to query last.fm you will need an [API account](http://www.last.fm/api/account/create).

Create a config file in `~/.config/mpdsim.conf` to store your key and other configurations:

```yaml
---
mpdsim:
  api_key: 'YOUR_API_KEY'
  api_secret: 'YOUR_API_SECRET'

  mpd_host: 'localhost'
  mpd_port: '6600'

  limit: 50
  replace: false
  playlist: true
```

## Examples

Get similar tracks to the currently playing song and `--limit` last.fm results to 20:

    $ mpdsim.rb -l 20

Specify the `--artist` and `--track` to get similar songs:

    $ mpdsim.rb -a "Pink Floyd" -t "Wish You Were Here"

The default behavior is to create a playlist titled "Similar to <Artist> - <Song>",
you can skip creating the playlist with the `--no-playlist` option:

    $ mpdsim.rb --no-playlist

The results will be added to the queue, unless the `--replace` option is given, which
replaces the current queue with the results:

    $ mpdsim.rb --replace
