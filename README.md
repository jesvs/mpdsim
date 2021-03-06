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
  duplicates: false
  shuffle: false
```

## Examples

Print usage

    $ mpdsim.rb -h

Get similar tracks to the currently playing song and `--limit` last.fm results to 20:

    $ mpdsim.rb -l 20

Specify the `--artist` and `--title` to get similar songs:

    $ mpdsim.rb -a "Pink Floyd" -t "Wish You Were Here"

The default behavior is to create a playlist titled "Similar to [Artist] - [Song]",
you can skip creating the playlist with the `--no-playlist` option:

    $ mpdsim.rb --no-playlist

The results will be added to the queue, unless the `--replace` option is given, which
replaces the current queue with the results:

    $ mpdsim.rb --replace

Query for 50 similar tracks and replace the current queue with songs similar to
Zero 7 - In the Waiting Line:

    $ mpdsim.rb --limit 50 --replace --no-playlist --artist "zero 7" --title "in the waiting line"

By default duplicates are not added to the queue/playlist, this behaviour can be
changed with the `--duplicates` option:

    $ mpdsim.rb --duplicates

Found similar tracks are added in similarity order to the queue/playlist,
using the `--shuffle` option the order is randomized.

    $ mpdsim.rb --shuffle

Get a random track from the database and create a similar playlist from it:

    $ mpdsim.rb --random

Same as above but replaces current queue and doesn't create a playlist:

    $ mpdsim.rb --random --no-playlist --replace

Append similar tracks to the queue based on what is currently playing

    $ mpdsim.rb --append
