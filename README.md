<h1 align="center"> A simple blog using jekyll and docker </h1> <br>

<p align="center">
  <a href="https://jekyllrb.com/">
    <img src="./jekyll_logo.png" alt="Jekyll Logo" width="200" height="100" align="middle">
  </a>
  <a href="https://www.docker.com/">
    <img src="./docker_logo.png" alt="Docker Logo" width="400" height="300" align="middle">
  </a>
</p>


# Usage

In order to start jekyll and preview the blog locally make sure you have [docker] and [docker-compose] installed and running.

After the installation is done and docker is up and running execute the following commands to get blog running on your system.

Get the uid and gid from your system.

```sh
source docker_env
```

Build the dockerfile and start jekyll.

```sh
docker-compose up --build
```

Your blog should be available on localhost and every change that you do locally will be reflected inside the docker and automatically refreshed by jekyll.

http://localhost:5000

[docker]: https://docs.docker.com/install
[docker-compose]: https://docs.docker.com/compose/install/
