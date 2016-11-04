### Command lines that I'm using a bit

NOTE: These were the ORIGINAL commands I used. I am keeping this around only
for historical purposes. I now have commands that I save outside of version
control for convenience.

I run all of these commands inside the root of the umbrella app.

* Distillery
  * `REPLACE_OS_VARS=true PORT=443 MIX_ENV=prod POSTGRES_USER= POSTGRES_PASSWORD= PG_WEBGIB_DB= PG_IBGIB_DB= PG_PORT=5432 WEBGIB_SECRET_KEY_BASE= MG_DOMAIN= MG_KEY= mix release --env=prod`
    * Builds the release.
    * Be sure to add in the actual values for the PG env vars.

* Using `docker-compose`
  * `VERSION=0.1.0 PORT=443 MIX_ENV=prod POSTGRES_USER= POSTGRES_PASSWORD= PG_WEBGIB_DB= PG_IBGIB_DB= PG_PORT=5432 WEBGIB_SECRET_KEY_BASE= MG_DOMAIN= MG_KEY= docker-compose build`
  * I just use the same commandlines for `docker-compose up/down`
  * Fill in ENV variables

* To remove dangling images
  * `docker rmi $(docker images -f "dangling=true" -q)`
  * Thanks http://www.projectatomic.io/blog/2015/07/what-are-docker-none-none-images/

* Individual `docker` container
  * `sudo docker build -t ib_gib_umb .`
    * OLD: Using docker compose now
    * Builds the individual app's docker image
    * Not sure if `sudo` is required.
  * `docker run -d -p 80:80 ib_gib_umb`
    * OLD: Using docker compose now
    * runs ib_gib_umb docker container
