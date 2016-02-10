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

# Upload Data
Login into the service by sending a _post_ request to <server_address>/api/v1/login with the proper headers and body. The username and password are what you created above.

```bash
$ curl -data "{\"username\": \"your_username\", \"password\": \"your_password\"}" -H "content-type:application/json" http://your_servername_and_port/api/v1/login
```

This will return a token (i.e. eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJleHAiOjE0NTU3MjMzMjU2Nzh9.mSxuNXskc2kFAwGjCecAK6UHwLma8Zi2hg-cFckVdxo) that should be used in future requests.

An example upload would be:

```bash
$ curl -data "{\"type\":\"ils-checkout\",\"rows\":[{\"original_id\":\"14099318\",\"library_code\":\"st\",\"action_date\":\"2016-02-10T08:48:14-06:00\",\"metrics\":{\"day\":3,\"hour\":8,\"statgroup\":\"221\",\"statgroupname\":\"ST Circulation\",\"owninglocation\":"st",\"locationcode\":\"stdvd\",\"format\":"DVD/VIDEODISC\",\"itype\":\"65\",\"act150\":\"468\",\"act150_loc\":\"O Eastern Shores/LS/x\",\"homelibrary\":\"if\",\"age\":\"116\",\"icode2\":\"a\",\"ptype\":\"4\"}}]}" -H "x-access-token:eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJleHAiOjE0NTU3MjMzMjU2Nzh9.mSxuNXskc2kFAwGjCecAK6UHwLma8Zi2hg-cFckVdxo" -H "x-key:your_username" http://your_servername_and_port/api/v1/commands/upload
```

The body of this request is in json format and must include a _type_. You may upload more than one row at a time. Each row must have an _original_id_, _library\_code_, and _action\_date_. You may also include a number of optional metrics. These optional metrics can then be retrieved as noted below.

To determine where your next batch of transactions to upload should start, you can use the following request:

```bash
$ curl http://your_servername_and_port/api/v1/status/action-metric-types/<type>
```

For example

```bash
$ curl http://your_servername_and_port/api/v1/status/action-metric-types/ils-checkout
```

This would return

```json
{"maxID":"14100804","maxDate":"2016-02-10T15:45:02.000Z"}
```

_maxID_ corresponds to _original\_id_ in your upload and _maxDate_ corresponds to _action\_date_. 

# Retrieve Data
```bash
$ curl http://your_servername_and_port/api/v1/actions/<type>:<total or metric name>/<start_date YYYY-MM-DD>/<end_date YYYY-MM-DD>/<optional_library_code>
```

For example

```bash
$ curl http://localhost:3000/api/v1/actions/ils-checkout:total/04-01-2015/04-30-2015
$ curl http://localhost:3000/api/v1/actions/ils-checkout:format/04-01-2015/04-30-2015/al
```

The examples requests above would retrieve results like this

```json
{"url":"/api/v1/actions/ils-checkout:total/04-01-2015/04-30-2015","collection":"ils-checkout","metric":"total","start":"04-01-2015","end":"04-30-2015","labels":["total"],"data":[271745]}
```

and

```json
{"url":"/api/v1/actions/ils-checkout:format/04-01-2015/04-30-2015/al","collection":"ils-checkout","metric":"format","code":"al","start":"04-01-2015","end":"04-30-2015","labels":["","AUDIOBOOK/CASS","AUDIOBOOK/CD","BIG BOOK","BLU-RAY","BLU-RAY/DVD COMBO","BOARD BOOK","BOOK","BOOK AND AUDIO","CDROM/SOFTWARE","DVD/VIDEODISC","EQUIPMENT","GAME DISC/CART","GAME/TOY","GRAPHIC NOVEL","ILL ITEM","KIT","LARGE PRINT","MAGAZINE/NEWSPAPER","MP3","MUSIC CD","MUSICAL SCORE","VHS"],"data":[2,2,380,1,1,8,167,5026,32,4,1387,1,18,8,132,12,16,228,177,7,159,1,16]}
```
