docker-moodle-dev
=============
A Dockerfile that installs and runs the desired Moodle version, with external MySQL Database.

## Installation

```
git clone https://github.com/jmhardison/docker-moodle
cd docker-moodle
```

## Usage
Copy dump of your current DB (if exists) into **moodle-upgrader/upgrade/** and rename the file **dbDump.sql**
Copy your moodle-data folder (if exists) into **moodle-files/mood**
To spawn a new instance of Moodle:

```
docker-compose up -d
```

You can visit the following URL in a browser to get started:

```
http://localhost:8080
```

### Production Deployment

For a production deployment of moodle, use of a FQDN is advised. This FQDN should be created in DNS for resolution to your host. For example, if your internal DNS is company.com, you could leverage moodle.company.com and have that record resolve to the host running your moodle container. The moodle url would then be, `MOODLE_URL=http://moodle.company.com`
In the following steps, replace MOODLE_URL with your appropriate FQDN.

In some cases when you are using an external SSL reverse proxy, you should enable `SSL_PROXY=true` variable.

* Deploy With Docker
```
docker run -d --name DB -p 3306:3306 -e MYSQL_DATABASE=moodle -e MYSQL_ROOT_PASSWORD=moodle -e MYSQL_USER=moodle -e MYSQL_PASSWORD=moodle mysql:5
docker run -d -P --name moodle --link DB:DB -e MOODLE_URL=http://moodle.company.com -p 80:80 jhardison/moodle
```

* Deploy with Docker Compose

Pull the latest source from GitHub:
```
git clone https://github.com/jmhardison/docker-moodle.git
```

Update the `moodle_variables.env` file with your information. Please note that we are using v3 compose files, as a stop gap link env variable are manually filled since v3 no longer automatically fills those for use.

Once the environment file is filled in you may bring up the service with:
`docker-compose up -d`



## Caveats
The following aren't handled, considered, or need work:
* moodle cronjob (should be called from cron container)
* log handling (stdout?)
* email (does it even send?)

## Credits

This is a fork of [Jade Auer's](https://github.com/jda/docker-moodle) Dockerfile.
This is a reductionist take on [sergiogomez](https://github.com/sergiogomez/)'s docker-moodle Dockerfile.
