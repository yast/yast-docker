# YaST Docker Module

[![Build Status](https://travis-ci.org/yast/yast-docker.svg?branch=master)](https://travis-ci.org/yast/yast-docker)
[![Coverage Status](https://coveralls.io/repos/github/yast/yast-docker/badge.svg?branch=master)](https://coveralls.io/github/yast/yast-docker?branch=master)

This module provides access to a Docker daemon running on the server.

## Features

The module provides the following features:

  * List Docker images available on the system.
  * Delete Docker images from the system.
  * Start Docker containers.
  * List Docker container running on the system.
  * Stop a running Docker container.
  * Kill a running Docker container.
  * Show changes made to a running Docker container compared to its original
    image.
  * Inject a shell into a running container.
  * Commit a running Docker container.

## The images tab

This section of the module lists all the Docker images available on the system.

<p align="center">
  <img src="doc/images_tab.png" alt="Docker Images Tab">
</p>


### Start containers

Docker containers can be started by selecting an image from this tab and pressing
the *"Run"* button.

The run dialog allows you to specify the following options:

  * Share a volume between the Docker host and the container.
    Details about this Docker feature can be found inside of the [official documentation](https://docs.docker.com/userguide/dockervolumes/#mount-a-host-directory-as-a-data-volume).
  * Map services listening inside of the container to the public network.
    Details about this Docker feature can be found inside of the [official documentation](https://docs.docker.com/installation/mac/#container-port-redirection).

<p align="center">
  <img src="doc/run_container.png" alt="Start a Docker container">
</p>


## The containers tab

This section of the module lists all the Docker containers running on the system.

<p align="center">
  <img src="doc/containers_tab.png" alt="Docker Container Tab">
</p>

## List changes made to the container

It is possible to list all the changes made to a running container compared to
the image from which it has been created.

<p align="center">
  <img src="doc/show_changes_dialog.png" alt="Changes to container">
</p>


### Commit container changes

It is possible to commit a running container and select or type the
Image's repository, name and version.

<p align="center">
  <img src="doc/commit_container.png" alt="Commit Docker container">
</p>


### Inject terminal inside of a running container

Sometimes it can be useful to have a terminal inside of a running container.
This operation can be accomplished by using the `docker exec` feature available
since docker 1.3.

By pressing the *"Inject terminal"* button a new terminal window is started.
Exiting from the new shell session **does not** affect the running
container.

<p align="center">
  <img src="doc/injected_terminal.png" alt="Inject terminal into Docker container">
</p>


## Installation

Right now the package is available only for openSUSE Factory and can be
installed from [here](http://software.opensuse.org/package/yast2-docker?search_term=yast2-docker).


## Code status

[![Coverage Status](https://coveralls.io/repos/yast/yast-docker/badge.png)](https://coveralls.io/r/yast/yast-docker)
[![Code Climate](https://codeclimate.com/github/yast/yast-docker.png)](https://codeclimate.com/github/yast/yast-docker)
[![Inline Docs](http://inch-ci.org/github/yast/yast-docker.png?branch=master)](http://inch-ci.org/github/yast/yast-docker)
[![License GPL-2.0](http://b.repl.ca/v1/license-GPL--3.0-blue.png)](http://www.gnu.org/licenses/gpl-3.0-standalone.html)
![Development Status](http://b.repl.ca/v1/status-development-yellow.png)
