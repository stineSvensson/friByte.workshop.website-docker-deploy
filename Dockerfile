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
