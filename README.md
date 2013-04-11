raven-auth
==========

[ ![Codeship Status for alexkalderimis/raven-auth](https://www.codeship.io/projects/137f0580-800b-0130-06f3-22000a1c844f/status?branch=master)](https://www.codeship.io/projects/2377)

Connect authentication middleware for connect

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
var conf = {...}; // Your raven configuration here...

var app = connect()
    .use(connect.bodyParser())
    .use(connect.query())
    .use(connect.queryParser())
    .use(connect.session({secret: 'foo'})) // Or any API compatible session library.
    .use(raven(conf))
    .use(routes);

app.listen(3000);
```


