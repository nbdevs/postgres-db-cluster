# Database backend for the apache-airflow ETL pipeline

This repository contains all of the database code (postgresql) and configuration files (bash scripts/dockerfiles) as well as postgresql specific configuration for networking and parameter tuning. Docker images are created from each of the components in the cluster to form the database cluster that airflow relies upon for the ETL pipeline.

## Getting Started

## Installation

Software dependencies:
su-exec
postgresql
docker-compose
docker

Docker Desktop for Mac is recommended for install in order to have access to the dockerd and in order to be able to use docker-compose.

You can then clone and pull the repo and install the local environment through:

## Project status

Ongoing - minor structural changes expected due to a few pending feature additions.

## License

Copyright © 2022 Nicholas Bojor.

The code in this repository is licensed under the MIT license.
