In order to query last.fm you will need an [API account](http://www.last.fm/api/account/create).

Create a config file in ~/.config/mpdsim.conf to store your key and other configurations:

```yaml
---
mpdsim:
  api_key: 'YOUR_API_KEY'
  api_secret: 'YOUR_API_SECRET'

  mpd_host: 'localhost'
  mpd_port: '6600'
```
