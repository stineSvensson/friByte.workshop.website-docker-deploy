=============================================

# Fork this repository before you start!

- By clicking the fork button on the top right corner of this page, you will then have your own copy of this repository to work on. This way you can make changes to the code and save them without affecting the original repository.
  - When forking using GitHub Desktop select `For my own purposes` when asked what you are planning to use this fork for.

=============================================

# Build and deploy your own website using Docker!

A step by step guide on how to deploy a website using docker images and host on a server with docker compose.

## Topics

- Basic javascript website
- Pack a website into a docker image
- Run a docker image locally
- Github Actions
- Deploy a website to a server with custom domain name and SSL certificate using docker compose

## Prerequisites

- A computer
- NodeJs installed
- Docker (optional)
- Internet

## Guide

This guide will walk you through the steps to build and deploy a website using docker images.

- If you ever get stuck, feel free to ask for help or look in the solutions folder for the solution.

### Basic javascript website

This repository contains a basic [Astro website](https://astro.build/). (Same Javascript framework we use on https://boskonf.no) You can run the website locally by following the steps below.

1. Open this repository in Visual Studio Code
2. Open a terminal in Visual Studio Code
3. Run `npm install` to install the dependencies
4. Run `npm start` to start the website
5. Open a browser and go to `http://localhost:4321`

You can now modify the website to your liking. You can change the text, the images, the colors, and the layout. You can also add new pages, new components, and new styles.
For example change your name in the about page in `src/pages/about.astro`.

When you save the changes, the website will automatically reload in the browser. This is called hot reloading.

### Pack a website into a docker image

#### What is docker

https://docs.docker.com/get-started/docker-overview/

You can look at docker as a way to pack your website into a box. This box contains everything your website needs to run. This includes the code, the dependencies, the environment, and the configuration. This box is called a docker image.

- In order to run this website you had to install NodeJs and run `npm install`. This is not necessary when you run the website in a docker image. The docker image contains everything the website needs to run.
  - Which make it super simple to deploy the website on any server that has docker installed.

#### Dockerfile

A Dockerfile is a file that contains the instructions to build a docker image. You can think of it as a recipe to bake a cake. The Dockerfile contains the ingredients and the steps to bake the cake.

1. Create a file called `Dockerfile` in the root of the repository
2. Add the following content to the `Dockerfile`-file

```Dockerfile
# First decide what image you want to use as a base. In this case, we are using the node-alpine image. This is a lightweight Linux distribution including Node.js.
FROM node:lts-alpine AS build
WORKDIR /app

# Then we copy all the files from the current directory to the /app directory in the container.
COPY . /app

# Next, we install the dependencies and build the project.
RUN npm install
RUN npm run build

# Now we use a second stage to create a new image that only contains the build output.
# This image will be even smaller and without all the node_modules and other build dependencies.
# We also need a small web server to serve the built html + js files. We will use the nginx image for this.
FROM nginx:stable-alpine
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]

```

#### Run a docker image locally

You can now build and test the docker image locally by running the following commands (requires Docker installed)

```bash
docker build --tag first-docker-website .

# -p => Opens a port 80 in the docker container and maps it to port 8000 on your machine
docker run -p 8000:80 --detach --name first-docker-website first-docker-website
```

1. Open a browser and go to `http://localhost:8000`
2. You should now see the same website running in a docker container

To stop and remove the docker container run `docker rm -f first-docker-website`

### Github Actions

Github Actions is a way to automate tasks in your repository. You can think of it as a robot that does things for you. In this case, we will use Github Actions to build and push the docker image to the Github Container Registry.

1. Create a folder called `.github/workflows` in the root of the repository
2. Create a file called `build.yml` in the `.github/workflows` folder
3. Add the following content to the `build.yml`-file (Fetched from https://docs.github.com/en/packages/managing-github-packages-using-github-actions-workflows/publishing-and-installing-a-package-with-github-actions#publishing-a-package-using-an-action)

```yml
name: Build and push Docker image

on:
  push:
    branches:
      - main
# Defines two custom environment variables for the workflow. These are used for the Container registry domain, and a name for the Docker image that this workflow builds.
env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

# There is a single job in this workflow. It's configured to run on the latest available version of Ubuntu.
jobs:
  build-and-push-image:
    runs-on: ubuntu-latest
    # Sets the permissions granted to the `GITHUB_TOKEN` for the actions in this job.
    permissions:
      contents: read
      packages: write
      attestations: write
      id-token: write

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
      # Uses the `docker/login-action` action to log in to the Container registry registry using the account and password that will publish the packages. Once published, the packages are scoped to the account defined here.
      - name: Log in to the Container registry
        uses: docker/login-action@65b78e6e13532edd9afa3aa52ac7964289d1a9c1
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      # This step uses [docker/metadata-action](https://github.com/docker/metadata-action#about) to extract tags and labels that will be applied to the specified image. The `id` "meta" allows the output of this step to be referenced in a subsequent step. The `images` value provides the base name for the tags and labels.
      - name: Extract metadata (tags, labels) for Docker
        id: meta
        uses: docker/metadata-action@9ec57ed1fcdbf14dcef7dfbe97b2010124a938b7
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
      # This step uses the `docker/build-push-action` action to build the image, based on your repository's `Dockerfile`. If the build succeeds, it pushes the image to GitHub Packages.
      # It uses the `tags` and `labels` parameters to tag and label the image with the output from the "meta" step.
      - name: Build and push Docker image
        id: push
        uses: docker/build-push-action@f2a1d5e99d037542a71f64918e516c093c6f3fc4
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
```

#### Test the Github Action

Push the changes of the repository to your Github repository. This will trigger the Github Action to run, follow the progress in the Actions tab on Github.

Now you should have a docker image in the Github Container Registry which you can test locally by running following commands:

```bash
docker rm -f first-docker-website
docker run -p 8000:80 --name first-docker-website ghcr.io/<your-github-username>/first-docker-website
```

### Deploy a website to a server with custom domain name and SSL certificate using docker compose

For this part we want you to go in groups of 3-4 people and create a virtual machine on the Proxmox server. And then all of you can deploy your website to the same server.

Please follow https://wiki.fribyte.no/docs/instrukser/ny-vm/ to create a new virtual machine.

When the machine is created, connect to it using SSH and install docker

```bash
ssh root@andeby.s.fribyte.no
ssh skaftetrynet.fribyte.no
ssh fribyte@<your-server-ip>
```

When inside the server, install docker

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh ./get-docker.sh
```

#### Docker Compose

Docker Compose is a tool for defining and running multi-container Docker applications. With Compose, you use a YAML file to configure your application's services. Then, with a single command, you create and start all the services from your configuration.

1. Create a file called `docker-compose.yml` in the home folder of the server
2. Add the following content to the `docker-compose.yml`-file (Replace `<person-A-github-username>`, `<person-B-github-username>`, and `<DOMENE-NAVN>` with your own desired values)

- To open the file in the terminal you can use `nano docker-compose.yml`

```yml
services:
  nginx-proxy:
    image: jwilder/nginx-proxy
    container_name: nginx-proxy
    restart: always
    ports:
      - "80:80"
      - "443:443"
    expose:
      - 80
      - 443
    volumes:
      - /var/run/docker.sock:/tmp/docker.sock:ro
      - /home/fribyte/nginx-proxy/nginx/certs:/etc/nginx/certs
      - /home/fribyte/nginx-proxy/nginx/vhost.d:/etc/nginx/vhost.d
      - /home/fribyte/nginx-proxy/nginx/html:/usr/share/nginx/html
      - /home/fribyte/nginx-proxy/nginx/dhparam:/etc/nginx/dhparam
    environment:
      DEFAULT_HOST: default.vhost

  letsencrypt:
    image: jrcs/letsencrypt-nginx-proxy-companion
    container_name: nginx-proxy-le
    restart: always
    environment:
      NGINX_PROXY_CONTAINER: nginx-proxy
    depends_on:
      - nginx-proxy
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - /home/fribyte/nginx-proxy/nginx/certs:/etc/nginx/certs
      - /home/fribyte/nginx-proxy/nginx/vhost.d:/etc/nginx/vhost.d
      - /home/fribyte/nginx-proxy/nginx/html:/usr/share/nginx/html
      - /home/fribyte/nginx-proxy/nginx/dhparam:/etc/nginx/dhparam

  person-A-website:
    depends_on:
      - letsencrypt
    image: ghcr.io/<person-A-github-username>/first-docker-website
    restart: always
    environment:
      VIRTUAL_HOST: <DOMENE-NAVN>.fribyte.no
      LETSENCRYPT_HOST: <DOMENE-NAVN>.fribyte.no

  person-B-website:
    depends_on:
      - letsencrypt
    image: ghcr.io/<person-B-github-username>/first-docker-website
    restart: always
    environment:
      VIRTUAL_HOST: <DOMENE-NAVN>.fribyte.no
      LETSENCRYPT_HOST: <DOMENE-NAVN>.fribyte.no
```

3. Start the docker-compose file by running the following command

```bash
docker compose up -d
```

4. View list of running containers by running `sudo docker ps -a`
5. Then look at logs by running `sudo docker compose logs --tail 100 -f`
6. You will now get some errors because we have not setup the domain name yet. But you should see that the containers are running.

#### Setup domain name

Follow https://wiki.fribyte.no/docs/instrukser/domener/ to setup a domain name for your website. Please take care to not edit the file at the same time as multiple other people as this can cause conflicts.

- Add the domain name under `;; fjern disse en gang`

Go back to your server and run `sudo docker compose restart` to restart the containers. You should now be able to access your website by going to the domain name you just added.

## Live deployment of updates

In order to automatically update docker images on the server when you push changes to the repository, you can use a service called https://containrrr.dev/watchtower/ which automatically updates the docker images when a new version is available.

To install it modify the `docker-compose.yml` file to include the watchtower service

```yml
watchtower:
  image: containrrr/watchtower
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock
```

Then run `docker compose up -d` to start the watchtower service.

## Conclusion

🎉 Tada you just built and deployed your own website!
