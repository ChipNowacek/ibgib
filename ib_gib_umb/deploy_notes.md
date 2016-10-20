### Command lines that I'm using a bit

I run all of these commands inside the root of the umbrella app.

* Distillery
  * `PORT=80 MIX_ENV=prod mix release --env=prod`
    * Builds the release.
    * `PORT` is used in WebGib's `prod.exs` config file:
      * `http: [port: {:system, "PORT"}]`
    * `PORT=80 MIX_ENV=prod mix release --env=prod`
      * deprecated for SSL-only

* Using `docker-compose`
  * `VERSION=0.1.0 docker-compose build`
  * `VERSION=0.1.0 docker-compose up`
  * `VERSION=0.1.0 docker-compose down`
    * Not sure if `VERSION` is necessary here, but I get a warning.

* Individual `docker` container
  * `sudo docker build -t ib_gib_umb .`
    * OLD: Using docker compose now
    * Builds the individual app's docker image
    * Not sure if `sudo` is required.
  * `docker run -d -p 80:80 ib_gib_umb`
    * OLD: Using docker compose now
    * runs ib_gib_umb docker container
    * Not sure if `sudo` is required.
