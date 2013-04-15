raven-auth
==========

[ ![Codeship Status for alexkalderimis/raven-auth](https://www.codeship.io/projects/137f0580-800b-0130-06f3-22000a1c844f/status?branch=master)](https://www.codeship.io/projects/2377)

Connect authentication middleware for the connect stack
---------------------------------------------------------

This module handles raven authentication for connect web-applications.
You might want to use this if you are developing web-apps for use within
the University of Cambridge.

```js

var raven = require('raven-auth');
var connect = require('connect');
var routes = function(req, res, next) {
    res.setHeader("Content-Type", "text/plain");
    res.write("Hello, " + req.session.principal);
    res.end();
};
// Your raven configuration here...
var conf = {
    logOutPath: '/logout', // If you want to provide log-out as well as log-in
    localHost: 'http://i.am.here',
    keyStore: '/path/to/where/my/keys/are' // Or a function of type: (string) -> string
}; 

var app = connect()
    .use(connect.bodyParser())
    .use(connect.query())
    .use(connect.cookieParser())           // If using cookies for sessions.
    .use(connect.session({secret: 'foo'})) // Or any API compatible session library.
    .use(raven(conf))
    .use(routes);

app.listen(3000);
```
 
Installation
--------------

Install from npm

```sh
npm install --save raven-auth
```

Or point at github directly (note that you must include a version ref to get a
usable package):

```sh
npm install --save git://github.com/alexkalderimis/raven-auth.git#0.0.1
```

Usage
------

This middleware can be used with any connect-style application system, such as `express`. This
authentication provider does not require any larger authentication framework, and does
not validate the principal provided by the authentication service, delegating that service
to your own middleware. It has a runtime requirement on parsing of the query-string, and
a session api which is compatible with the connect session mechanism (ie. it must provide
a session property on the request object which has a `#destroy()` method). Other than that
setting up authentication is fairly straightforward:

Define your configuration options (the defaults are shown below):

```js
var conf = {
  localHost: 'http://i.am.here', // [required = !] Absolute url of the site requesting authentication
  keyStore: '/path/to/where/my/keys/are', // [!] Or a function of type: (string) -> string
  logOutPath: '/logout', // [optional = ?] if provided then raven will log users out locally and remotely.
  ravenUrl: 'http://a.raven.compatible.wls/auth/authenticate.html', // [?] set which raven to use

  ravenLogOut: 'http://a.raven.compatible.wls/auth/logout.html', // [?] if handling log-out
  timeout: 60000, // [?] Users must re-authenticate if in-active for this length of time (ms)
  maxSessionLife: (24 * 60 * 60 * 1000), // [?] Cookie expiries are set for this at a minimum (ms)
  ver: 2, // [?] The version of the raven protocol we expect
  maxSkew: 1000, // [?] The maximum allowable difference in clocks between servers (ms)
  authTypes: ['pwd'] // [?] The acceptable kinds of authentication the server can perform
}; 
```

Then the middle ware can be applied to the application (note that it must be applied after
any of its run-time requirements).

For a global scope:

```js
var connect = require('connect');
var raven = require('raven-auth');

var app = connect()
    .use(connect.bodyParser())             // If you accept post parameters
    .use(connect.query())                  // Required - for parsing authentication responses
    .use(connect.cookieParser())           // If using cookies for sessions.
    .use(connect.session({secret: 'foo'})) // Or any API compatible session library.
    .use(raven(conf));
```

If you are using `express`, you can protect just some resources:

```js
var express = require('express');
var raven = require('raven-auth')(conf);

app = express();

app.get('/', raven, function(req, res) {
    res.write('A little birdy tells me you are ' + req.session.principal);
});
```

Running the Tests
------------------

`npm test` will run the test-suite, and `npm start` will start the test
application. These require that the dev dependencies are installed. Running the
start command with `REAL_RAVEN=1` will use the main raven authenticator as the
WLS, so you will need to fetch the keys, which may be done with `grunt fetch-keys`.

Similar Packages
-----------------

Oddly enough, this isn't even the only node.js raven-autentication package. I went to add this to
the wiki and saw https://github.com/ForbesLindesay/passport-raven already on there, completely
independently developed. So a brief listing of differences seems in order:

In favour of this libary:
* Is pure connect middle-ware, and not part of a larger authentication framework.
* Has a unit-test suite, as a well as a test-server.

In favour of `passport-raven`:
* Is part of a larger authentication framework
* Is developed by a rather bigger js fish (ForbesLindesay) than me.

The libraries have different open-source licences.

I haven't tested `passport-raven`, but it looks all-good; so both should work fine (I know
this one does).

Licence
--------

This software is free and open source under the LGPL (see LICENCE.txt)

Copyright
----------

The copyright on this work belongs to Alex Kalderimis.

Support
--------

Support may be requested by submitting issues to the github bug
tracker (https://github.com/alexkalderimis/raven-auth/issues).

