---
excerpt: It takes 20 years to build a reputation and few minutes of cyber-incident to ruin it.
layout: page
title: Docker image security practices
permalink: docker-image-security-practices
tags: docker security-practices security cyber-security containers-security docker-image image containers namespaces cgroups
published: true
---

<br/>
<p align="center">
  <a href="https://blank-canvas.itch.io/parallax-pixel-art-background-desert">
    <img alt="Pixel_art_desert_day" title="Pixel art desert day" src="assets/images/2020_06_01_desert_day.png" width="800px" height="400px" align="middle">
  </a>
</p>

<br/>
> It takes 20 years to build a reputation and few minutes of cyber-incident to ruin it.<br/> - Stephane Nappo

<br/>

### [The state of cyber security today](#the-state-of-cyber-security-today)

Security usually means inconvenience, inconvenience brings hindrance, how do we move fast yet stay as secure as possible in this technological present. There's no universal answer for this subject, but what we should always do at least strive, is to adhere to certain standards and principles which will reduce the risk in the unlikely case of a breach of security. Applying best security practices would be our most dependable remedy against malicious actors of any kind. As an example let's take today's container technologies, namely the most popular one, docker. They are fast, lightweight and immutable, but come with a tradeoff. The border that isolates the host and the container is very thin, alas thinner than the conventional bulky and slow Virtual Machines. The tradeoff, in this case, is very clear, we've gained enhanced utilization of resources but because the container technology shares a lot of components with the host system if we do not employ well-defined security precautions we will be putting the host system along with the other containers running on it at risk. If we can employ as many security safeguards as we can, rest assured that running a container would be more secure than the traditional Virtual Machine.

How hard is it to misspell the name of the Docker registry image URL combination and get a third-party image with possible malevolent software packaged?
Or even worse, what if you mount your docker socket or run the container with full privileges?

In the unfortunate event of a security breach, there's no guessing on what will be the scope of the potential damages. The old proverb by the Irish Novelist Samuel Lover *"Better safe than sorry"* is invaluable. There are so many tools out there that can help us build and create wonderful technologies, but when one thinks about it, everything is based on trust which we are placing on the creators and community of said tools to implement the best security practices. Sadly, in reality, that often turns out not to be the case.

Looking on the positive side, we can and we should do something about it, by conforming and adhering to a set of security practices that will lower or nullify the blast radius in a potential breach, which I will elaborate further in this blog post.

I will be focusing on docker mostly as it is one of the most widely used container solutions nowadays.

For the examples I am using this simple golang web server code.

```golang
package main

import (
    "fmt"
    "log"
    "net/http"
)

func handler(w http.ResponseWriter, r *http.Request) {
    fmt.Fprintf(w, "Hi there, I love %s!", r.URL.Path[1:])
}

func main() {
    http.HandleFunc("/", handler)
    log.Fatal(http.ListenAndServe(":8080", nil))
}
```

### [Do not use the root user at container runtime](#do-not-use-the-root-user-at-container-runtime)

This is not at all hard to elaborate, since ages even with traditional computing, running services as root was and still is exceptionally bad. Security has improved vastly since, and container technologies offer isolation through kernel namespaces, in which processes running on the container are unbeknownst from processes running on the host system. Kernel namespaces have been around since July 2008, meaning that they've had quite a few improvements and iterations, but nothing justifies running the application as the root user.

I will point out a few examples of why this is bad.

#### *The attack surface is vastly enlarged*

The root user can do much more harm in the unlikely event of breaking out of the system during a breach. Depending on the end goal of the malicious party it can range from deletion of assets to blackmail, extortion, identity theft, invasion of privacy, fraud, part of a DDoS botnet and more.

#### *Additional applications can be installed on the running container*

Imagine we are running a container as the root user, and unfortunately, the application had an old third-party module that was unpatched. The attacker was able to exploit it, and has gained root access within the container. Kernel namespaces have us protected with isolation, nevertheless, the attacker can now install anything on the running container. E.g. a network scanning tool like `nmap` which can potentially map out the network and thereby giving our imaginary vile agent a wealth of valuable information which can be used against our favor.

#### *The root user can delete any file*

If we have a container that needs to persist a state on a mounted volume, in the case of a breach all the files can be deleted from the container because there are no constraints for a user with UID and GID 0.

#### *Remediation - Specify a dedicated user in Docker*

We should create and have a dedicated user that will run the application during container runtime:

```docker
ARG USERNAME="webserver"
RUN adduser -HD -s /bin/noshell ${USERNAME} ${USERNAME}
USER ${USERNAME}:${USERNAME}
```

**Full example:**

*Make sure you have the golang webserver sample in the same directory as the following dockerfile*

```docker
FROM golang:alpine

# All of these are arguments so that they can be overridden per use case basis.
ARG USERNAME="webserver"
ARG WORKDIR="/go/src/app"
ARG GOCACHE="/tmp/go_cache"

# -s SHELL  Login shell
# -D        Don't assign a password
# -H        Don't create home directory
RUN adduser -HD -s /bin/noshell ${USERNAME} ${USERNAME}
WORKDIR ${WORKDIR}
USER ${USERNAME}:${USERNAME}
RUN mkdir -p ${GOCACHE}
COPY . .
RUN go get -d -v . &&\
    go install -v .

CMD ["app]
```

Now lets build and start the webserver.

```sh
docker build -t golang_webserver . && docker run --name golang_webserver -p 8080:8080 golang_webserver
```

Spawning a shell inside the running container

```sh
$ docker exec -it golang_webserver sh
```
and checking the running processes gives us the following output:

```sh
/go/src/app $ ps aux
PID   USER     TIME  COMMAND
    1 webserve  0:00 app
   26 webserve  0:00 sh
   31 webserve  0:00 ps aux
```

The `$ ps` output clearly shows that the simple golang web server is running as a non-root user that we have previosly created and specified.

### [Be vary when mounting the docker socket](#be-vary-when-mounting-the-docker-socket)

Many examples on the internet casually mention that the docker socket should be mounted inside the container in particular installation instructions, which I find very alarming considering this is the main entry point for the docker API. The container that has access to the docker socket `/var/run/docker.sock` can control all the running containers on the host and as an added bonus the host is most probably compromised because the Docker daemon runs as root by default.

We can see that by querying the docker socket and getting the list of images on our system(a running docker daemon, curl and jq are required).

```sh
$ curl --unix-socket /var/run/docker.sock http://localhost/images/json | jq
```

This will give us all the images that are present on the host where the docker daemon is running currently.

### [Do not run containers with full container capabilities also known as the privileged flag](#do-not-run-containers-with-full-container-capabilities-also-known-as-the-privileged-flag)

Running a container with the `--privileged` flag gives all capabilities to it plus it lifts all the limitations enforced by the cgroup controller. E.g. the container can now read the host's `/dev` and `/proc` folder. It has "super capabilities" that will allow it to control the host's devices, processes and kernel parameters. In combination with the processes running as the root user, the damage can be disastrous.

### [Do not pass secrets into arguments or enviroment variables during build time](#do-not-pass-secrets-into-arguments-or-enviroment-variables-during-build-time)

There is a common misconception/anti-pattern regarding the `ARG` parameter within Dockerfiles, at least I have made the grave mistake thinking that passing a secret with the `ARG` parameter won't be persisted to the final image. The Docker documentation somewhat implies that when using arguments they will be present only for build time 

The following excerpt is taken from [https://docs.docker.com/engine/reference/commandline/build/]

> Set build-time variables (--build-arg)<br/>
You can use ENV instructions in a Dockerfile to define variable values. These values persist in the built image. However, often persistence is not what you want. Users want to specify variables differently depending on which host they build an image on.

For the `ENV` parameter it is very clear that it will be persisted in the final image. Yet it turns out that for the `ARG` the behavior is identical.

Consider the following example:

```docker
FROM golang:alpine

ARG USERNAME="webserver"
ARG WORKDIR="/go/src/app"
ARG GOCACHE="/tmp/go_cache"
ARG API_SECRET_KEY
# -s SHELL Login shell
# -D       Don't assign a password
# -H       Don't create home directory
RUN adduser -HD -s /bin/noshell ${USERNAME} ${USERNAME}
WORKDIR ${WORKDIR}
USER ${USERNAME}:${USERNAME}
COPY . .
RUN go get -d -v . &&\ 
    go install -v .
CMD ["app"]
```

What happens here is that we are passing an argument in the container build stage, which we would think it will only be present in the build stage. Unfortunately it will be persisted, and packed in the image.

Let's reproduce this behavior.

```sh
$ docker build -t build_arg_example --build-arg API_SECRET_KEY="VERY_SECRET_KEY" .
```

Checking the layers of the freshly built image we can see that the "very secret key" is present on the second line from the output.

```sh
$ docker history build_arg_example:latest
IMAGE               CREATED             CREATED BY                                      SIZE                COMMENT
fd4fb8c4d4d9        31 seconds ago      /bin/sh -c #(nop)  CMD ["app"]                  0B
b59927c7a0ea        32 seconds ago      |4 API_SECRET_KEY=VERY_SECRET_KEY GOCACHE=/t…   7.46MB
afd082c6f60d        34 seconds ago      /bin/sh -c #(nop) COPY dir:2511c5768dd12dce0…   668B
6af096231a1e        36 seconds ago      /bin/sh -c #(nop)  USER webserver:webserver     0B
1560adadd916        37 seconds ago      /bin/sh -c #(nop) WORKDIR /go/src/app           0B
7ccef7155352        38 seconds ago      |4 API_SECRET_KEY=VERY_SECRET_KEY GOCACHE=/t…   4.85kB
d05b1045eb6b        39 seconds ago      /bin/sh -c #(nop)  ARG API_SECRET_KEY           0B
1ef26b6f7772        3 days ago          /bin/sh -c #(nop)  ARG GOCACHE=/tmp/go_cache    0B
a09dbe8447f7        3 days ago          /bin/sh -c #(nop)  ARG WORKDIR=/go/src/app      0B
5ba770850e29        3 days ago          /bin/sh -c #(nop)  ARG USERNAME=webserver       0B
69cf534c966a        2 weeks ago         /bin/sh -c #(nop) WORKDIR /go                   0B
<missing>           2 weeks ago         /bin/sh -c mkdir -p "$GOPATH/src" "$GOPATH/b…   0B
<missing>           2 weeks ago         /bin/sh -c #(nop)  ENV PATH=/go/bin:/usr/loc…   0B
<missing>           2 weeks ago         /bin/sh -c #(nop)  ENV GOPATH=/go               0B
<missing>           2 weeks ago         /bin/sh -c set -eux;  apk add --no-cache --v…   353MB
<missing>           2 weeks ago         /bin/sh -c #(nop)  ENV GOLANG_VERSION=1.13.5    0B
<missing>           2 months ago        /bin/sh -c [ ! -e /etc/nsswitch.conf ] && ec…   17B
<missing>           2 months ago        /bin/sh -c apk add --no-cache   ca-certifica…   551kB
<missing>           2 months ago        /bin/sh -c #(nop)  CMD ["/bin/sh"]              0B
<missing>           2 months ago        /bin/sh -c #(nop) ADD file:fe1f09249227e2da2…   5.55MB
```


#### *[Remediation - Buildkit, Multi Stage Builds](#remediation---buildkit-multi-stage-builds)*

There are multiple methods on how can we remove secrets from the docker image during the build. I will only describe the ones that I have trialed and have been using for a while in a production-ready setup.

**Buildkit.**

This is the latest iteration of the docker build process. According to docker, it is the "[much-needed overhaul of the build architecture]". I prefer this method the most because it truly is an enhacement over the traditional docker build.

Enabling it requires a few extra steps.

First we need to create a file that will hold our "very secret key":
```sh
$ echo 'VERY_SECRET_KEY' > very_secret_key.txt
```

Then we need to overide the default docker frontend (notice the commented line at the beggining), also expose the secret inside the Dockerfile:
```sh
# syntax = docker/dockerfile:1.0-experimental
FROM alpine
RUN --mount=type=secret,id=very_secret_key cat /run/secrets/very_secret_key
```

Lastly we need to build the imagel and mount the secret during the build process:

```sh
$ DOCKER_BUILDKIT=1 docker build --no-cache --progress=plain --secret id=very_secret_key,src=very_secret_key.txt .
```

Buildkit offers many other improvements which are out of the scope for now, head on to [https://docs.docker.com/develop/develop-images/build_enhancements/] to learn more.

**Multi Stage Builds.**

Each instruction in the Dockerfile adds a layer to the image, and all of the artifacts, arguments and environment variables are present in the final image along with the aforementioned layers. With multi-stage build, we can selectively copy artifacts and erase everything else including sensitive data. This way we can have final images that are small, secure and do not contain any delicate information.

Consider the following example:

```docker
# 1st stage
FROM golang:alpine as builder

ARG USERNAME="webserver"
ARG WORKDIR="/go/src/app"
ARG GOCACHE="/tmp/go_cache"
ARG API_SECRET_KEY
# -s SHELL Login shell
# -D       Don't assign a password
# -H       Don't create home directory
RUN adduser -HD -s /bin/noshell ${USERNAME} ${USERNAME}
WORKDIR ${WORKDIR}
USER ${USERNAME}:${USERNAME}
COPY . .
RUN go get -d -v . &&\
    go install -v .

# 2nd stage
FROM alpine:latest
ARG WORKDIR="/app"
WORKDIR ${WORKDIR}
# Copy the executable from the first stage.
COPY --from=builder /go/bin/app /usr/local/bin
CMD ["app"]
```

What I've done here, is I got already built binary from the former image labeled as "builder", to the latter, which doesn't contain any of the artifacts nor environment variables. We can confirm this easily by building the multi-stage dockerfile and seeing the image history:

```sh
$ docker build -t multi_stage  .
$ docker history multi_stage:latest
IMAGE               CREATED             CREATED BY                                      SIZE                COMMENT
d9ffea8de0f2        19 minutes ago      /bin/sh -c #(nop)  CMD ["app"]                  0B
a303bc8586b3        19 minutes ago      /bin/sh -c #(nop) COPY file:99e2ea856b1ad652…   7.45MB
dbe76a8816f2        21 minutes ago      /bin/sh -c #(nop) WORKDIR /app                  0B
96125fcf5377        21 minutes ago      /bin/sh -c #(nop)  ARG WORKDIR=/app             0B
965ea09ff2eb        2 months ago        /bin/sh -c #(nop)  CMD ["/bin/sh"]              0B
<missing>           2 months ago        /bin/sh -c #(nop) ADD file:fe1f09249227e2da2…   5.55MB
```

#### [Image vulnerability scanner](#image-vulnerability-scanner)

It is always a good practice to check the container that is running the app for any known vulnerabilities. At present, the major cloud providers provide this ability out of the box. An image vulnerability scanner works by scanning the container images in a docker repository and reports on any found and known vulnerabilities. This can be incorporated in a CI/CD pipeline with ease. One such tool is [clair].

#### [Slim or container optimized images](#slim-or-container-optimized-images)

Small container images contain fewer packages, fewer packages means reduced attack surface. The current and most excellent container distribution is without a doubt [Alpine Linux]. Most of the ready to use docker images currently offer an alpine Linux variation.


#### [Use official container images only](#use-official-container-images-only)

Needless to say, if the image we intend to use is provided by a third-party we do not have any way to know what might be installed on it, coupled with a mounted filesystem or [docker socket](#be-vary-when-mounting-the-docker-socket) the potential for harm ascends.

#### Conclusion
There's no all-in-one solution for being secure, what it takes is persistence, discipline, and above all cybersecurity culture!

If you enjoyed this blog post, or you found it helpful I'd be very grateful if you'd help by sharing it.

Over and out.

[https://docs.docker.com/engine/reference/commandline/build/]:https://docs.docker.com/engine/reference/commandline/build/
[much-needed overhaul of the build architecture]:https://docs.docker.com/develop/develop-images/build_enhancements/
[https://docs.docker.com/develop/develop-images/build_enhancements/]:https://docs.docker.com/develop/develop-images/build_enhancements/
[clair]:https://github.com/quay/clair
[Alpine Linux]:https://alpinelinux.org/
