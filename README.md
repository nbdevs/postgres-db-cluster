# Database backend for the apache-airflow ETL pipeline

<div id="Language of database backend." align="center">
    <img width="755" src=https://github.com/nbdevs/dag-development/assets/75015699/42c99f53-32e3-4d0f-aab1-6bece4537836/>
</div>

This repository contains all of the database code - postgresql - and configuration files (bash scripts/dockerfiles) as well as specific configuration settings for networking and parameter tuning. Docker images are created from each of the components in the cluster to form the database cluster that airflow relies upon for the ETL pipeline.

## Summary of Database System

E-R diagram constructed in 3rd normalised form representing all the entity relationships and multiplicities.

<img width="1232" alt="Screenshot 2023-08-02 at 13 06 34" src="https://github.com/nbdevs/dag-development/assets/75015699/9a386528-19c0-4aa4-997c-9235614ffac9">

 A database was chosen for implementation over an operational data store, because the data collected for this project has been sourced from a single API and lacks heterogeneity of data sources.  

 An overview of the final entity descriptions for those names represented in the diagram are displayed below:

 <img width="426" alt="Screenshot 2023-08-02 at 13 29 09" src="https://github.com/nbdevs/dag-development/assets/75015699/e1595501-ee7b-43bf-a0c9-1440803fda6e">


 Entity names shown above were categorised by brainstorming all the potential occurrences of things that would be expected to be stored within the database system. Doing so, reoccurring entities revealed themselves, and any potential aliases were documented to group those aliases with one general term.

<img width="528" alt="Screenshot 2023-08-02 at 13 27 33" src="https://github.com/nbdevs/dag-development/assets/75015699/06dd101d-b129-4ad0-a51b-41787f6676ee">

In addition to this, the process for identifying the relations between entities was to give relationship names to the entity descriptions that connected them to one another. Multiplicities of the entity occurrences involved in the relationships were then identified via close referral with FIA regulations to accurately represent the domain.

As displayed within the metadata descriptions, the primary and foreign keys of each entity were also identified at this point, and the resulting full description of the final entity relationships and multiplicities can be seen below in a few different examples:

<div>
  <img src="https://github.com/nbdevs/dag-development/assets/75015699/8b6fe89e-dafc-4bf3-841a-fe52e8420fb4" title="Driver Championship VIEW" alt="Driver Championship" width="180" height="290"/>&nbsp;
  <img src="https://github.com/nbdevs/dag-development/assets/75015699/7403689f-6cae-4aa1-a3e0-837197e91a23" title="Grid Metadata" alt="Grid" width="193" height="290"/>&nbsp;
  <img src="https://github.com/nbdevs/dag-development/assets/75015699/d62d8fcb-06d3-4cde-94b1-3c291f9ff241" title="Pit Metadata" alt="Pit" width="193" height="290"/>&nbsp;
  <img src="https://github.com/nbdevs/dag-development/assets/75015699/7857f81e-ef45-410d-8253-8f35744bab77" title="Driver Championship Metadata" alt="Driver Champ Stand" width="193" height="290"/>&nbsp;
</div>

## Requirements related to Database System

| **Requirements**| **Description**| **Rationale**|
| -------- | -------- | -----|
|Proxy Server|An authentication method shall be provided for use of PgBouncer to authenticate users against those allowed into the database system.|This is so that the database is not exposed to malicious insiders or threats from hackers.|
|Database - Privileges|The system shall limit the CRUD functionality of the users on the database based on designated privilege levels.|This is to ensure the integrity of the database and prevent unauthorised users from accessing the database and corrupted the contents, hence destroying the system.|
|Data constraints – Airflow webserver|Airflow webserver shall make use of DAG serialisation to store DAGs in the metadata database.|This is to stop the webserver from processing DAGs, and prevent airflow being the point of leakage of data, as by default the webserver UI is accessible from any external network.|
|Network Security – Airflow Images| Airflow components should run on security proven container images verified by Docker Trust Registry.|Provides security against man in the middle attacks.|
|Access Management - Database|Access to the database shall be authenticated via PgBouncer authentication method as an unprivileged user.|This way existing connections are reused and the computational resource to fire up new connections each time is avoided.|
|Metadata|Metadata shall be stored for both the DBMS and the data warehouse.|So that prior and intermediary states of data can be logged before, during and after any data transformations.|
|DBMS Backup, Replicability and Failover|The system may run a standby node for the database to ensure high availability of the DBMS in case of system failures or crashes.|To prevent loss of data and metadata.| 
|Choice of Database - Metadata|The system shall use PostgreSQL as the backend database used to store the metadata of the system.|Relational database which has plenty of open-source support and is necessary to model entity-relationships in the metadata model in preparation for the data warehouse. Here the metadata model, job templates for python DAG creation and synchronisation as well as PostgreSQL jobs via templates will be stored.|

## Installation

Software dependencies:

Docker Desktop for Mac is recommended for install in order to have access to the dockerd and in order to be able to use docker-compose.

- su-exec
- postgresql
- docker-compose
- docker

You can then clone and pull the repo and install the environment following these steps:

1. Open terminal app in desktop
2. Change the current working directory to the location which you want to directory to be cloned to.
3. Use the git clone command, and the URL type you require (This example uses HTTPS).   
    ```Bash
    git clone https://github.com/nbdevs/postgres-db-cluster.git
    ```
4. Once you click enter you should see the following to confirm success.
    ```Bash
    $ git clone https://github.com/nbdevs/postgres-db-cluster.git
    > Cloning into `Project-Folder`...
    > remote: Counting objects: 10, done.
    > remote: Compressing objects: 100% (8/8), done.
    > remove: Total 10 (delta 1), reused 10 (delta 1)
    > Unpacking objects: 100% (10/10), done.
    ```


## Project status

Ongoing - minor structural changes expected due to a few pending feature additions.

## License

Copyright © 2022 Nicholas Bojor.

The code in this repository is licensed under the MIT license.
