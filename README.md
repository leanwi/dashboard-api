# Library Statistical Dashboard - Backend

This NodeJS backend is meant to work with [Library Statistical Dashboard - Frontend](https://github.com/glfalkenberg/dashboard-www). Feel free to roll your own.

## Installation
Install prerequisites:
1. [nodejs](https://nodejs.org/en/)
2. [MongoDB](https://www.mongodb.org) (this can be installed on a different server)

Clone this repository to a directory on your server.

```bash
$ git clone https://github.com/glfalkenberg/dashboard-api.git /opt/dashboard/api
```

Enter the directory.

```bash
$ cd /opt/dashboard/api
```

Run `npm` to install the dependencies.

```bash
$ npm install
```

Run the setup program (defaults are in parentheses).

```bash
$ node setup.js
Dashboard: What port should the API run on?: (3000)
Dashboard: MongoDB server fqdn or ip address:  (127.0.0.1)
Dashboard: MongoDB server port:  (27017)
Dashboard: MongoDB server database name:  (dashboard)
Dashboard: MongoDB server username - optional:
Dashboard: MongoDB server password - optional:
Dashboard: Please enter a secret string - used for authentication:
Writing the config and secret files.
The config files have been created.
```
Add a user (use to authenticate restricted areas of the api).

```bash
$ node adduser.js
Dashboard: Dashboard administrator username:
Dashboard: Dashboard administrator password:
Dashboard: Dashboard administrator email address:
Adding the default user to the database
One user added.
```

Import your library list. The script will prompt you for the location of the CSV file containing your library definitions. The CSV file should follow this format where the "name" is the display name and "code" is the code that is associated with that library in all the data that's uploaded. Multiple codes can be assigned separated by commas. This can be useful for branch libraries or grouping libraries by county, etc.

```
"name","code"
"Local Library","aa,ab"
"--Branch One","aa"
"--Branch Two","ab"
```

```bash
$ node addlibraries.js
Dashboard: Where is the csv file with library information?:  (libraries.csv)
Adding the library list to the database.
```

Start the server.

```bash
$ node server.js
```

You will probably want to run the server as a service. How to do this varies by platform, but here's a simple sample [upstart](http://upstart.ubuntu.com) script for Ubuntu:

```
# Start the service after everything loaded
start on (local-filesystems and net-device-up IFACE=eth0)
stop on shutdown
# Automatically restart service
respawn
respawn limit 99 5
script
    # Navigate to your app directory
    cd /opt/dashboard/api

    # Run the script with Node.js and output to a log
    exec su -s /bin/sh -c 'exec "$0" "$@"' dashboard -- /usr/bin/nodejs server.js 2>&1 >> /var/log/dashboard/api.log
end script
```

