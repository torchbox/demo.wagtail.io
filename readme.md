demo.wagtail.io
===============

This repository contains configuration and data for the demo.wagtail.io site. This is an instance of (torchbox.com)[https://github.com/torchbox/wagtail-torchbox] which runs within a Docker container.

Reseting the database/media is achieved by putting them inside the Docker image so any changes made while the container is running will be reverted whenever the container is re created.

Building the image
------------------

After you've checked out the code locally, run the following commands to fetch the site code (which is linked with a git submodule):

    git submodule init
    git submodule update

Run the following command to build the image:

    docker build -t demowagtail .


This will pull down the python:2.7 image (approx 700MB) and execute the instructions in the Dockerfile on it.

Running it
----------

The image runs uwsgi on port 5000, which needs to be forwarded to a host port in order to be accessed externally.

You can run this image both interactively (for development) or as a daemon (for hosting)

For development:

    docker run --rm -ti -p 8000:5000 demowagtail

For hosting:

    docker run --name demowagtail -d -p 127.0.0.1:8000:5000

To reset the container back to its initial state, just recreate it:

In development, press Ctrl+C and rerun the above command
In hosting, run "docker rm -f demowagtail" and rerun the above command

Warning
-------

The Docker configuration in this project intentionally breaks a couple of best-practises. Please don't copy them unless you know what you're doing!

1) It runs PostgreSQL in the application container
2) It bundles media in the base image
