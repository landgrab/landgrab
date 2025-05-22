# SETUP

You'll need [Docker](https://www.docker.com/) installed.

Checkout this repo and navigate to the directory.

Create an `.env` file to hold required environment variables.

```sh
cp .env.sample .env
```

Build the services via docker;

```sh
docker compose build
```

Run the server...

```sh
docker compose up
```

Open the site at [localhost:3000](http://localhost:3000)!

Register in the UI, then set yourself (the first user) as admin;

```sh
docker compose exec app bin/rails runner 'User.first.update!(admin: true)'
```

Access the Rails console (for any other changes);

```sh
docker compose exec app bin/rails c
```

## Troubleshooting

### Crash when trying to view plots

Check that RGeo is configured with Geos;

```sh
RGeo::Geos.supported?
```

and if not, see [these instructions](https://github.com/rgeo/rgeo/blob/main/doc/Enable-GEOS-and-Proj4-on-Heroku.md).

### Database filling up (> 8,000 rows with no records);

```sh
heroku pg:psql
SELECT COUNT(srid) FROM spatial_ref_sys WHERE srid <> 4326;
DELETE FROM spatial_ref_sys WHERE srid <> 4326;
```

### Error when starting the container: "A server is already running."

```sh
docker compose run app rm /usr/app/landgrab/tmp/pids/server.pid
```

### Could not find xxx in locally installed gems

```sh
docker compose exec app bin/bundle install
```
