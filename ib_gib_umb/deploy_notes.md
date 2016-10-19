### Command lines that I'm using a bit

I run all of these commands inside the root of the umbrella app.

* `PORT=80 MIX_ENV=prod mix release --env=prod`
  * Builds the release.

* `sudo docker build -t ib_gib_umb .`
  * Builds the app's docker image

* `docker run -d -p 80:80 ib_gib_umb`
  * runs ib_gib_umb docker container
