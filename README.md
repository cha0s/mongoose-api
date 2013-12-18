# mongoose-api

Automatic REST API generation using Mongoose and Express

I had trouble finding a good solution for serving my [Mongoose](http://mongoosejs.com/) models as a REST API.
This module can discover and serve your models automatically, or you can serve one or more of them manually.

## Install

    npm install mongoose-api
    
## Usage

First, our definitions:

    var express = require('express');
    var mongoose = require('mongoose');
    var mongooseApi = require('mongoose-api');

Let's say you define a module like so:

    mongoose.connect('mongodb://localhost/test');
    
    var TestSchema = new mongoose.Schema({
    	name: String,
    	description: String
    });

    var TestModel = mongoose.model('Test', TestSchema);

and an [Express](http://expressjs.com/) server defined like so:

    app = express();
    app.configure(function () {
      app.use(express.bodyParser())
      app.use(app.router)
    });

***Note:*** *You must include the bodyParser and router middleware into express to handle PUT/POST requests, and to
implement the served routes, respectively.*

Lastly, set up the serving routes for your models, connect to the database, and start the express server.

    // Create apis off of root (/). 
    mongooseApi('/').serveModels(app);
    
    var db = mongoose.connection;
    db.on('error', console.error.bind(console, 'connection error:'));
    db.once('open', function() {
      http.createServer(app).listen(app.get('port'), function() {
        console.log("Express server listening on port " + app.get('port'));
      });
    });

Note that mongoose-api can and will automatically discover and serve routes for all your Mongoose models by default.

## REST API examples

Resource index:

    $ curl -X GET localhost:5000/tests
    []

Create a resource:

    $ curl -X POST --data "name=Hello&description=Bonjour" localhost:5000/tests
    {
      "message": "Resource created."
    }

Resource index:

    $ curl -X GET localhost:5000/tests
    [
      {
        "name": "Hello",
        "description": "Bonjour",
        "_id": "50eb66aaedd55a0a03000001",
        "__v": 0
      }
    ]

Resource:

    $ curl -X GET localhost:5000/tests/50eb66aaedd55a0a03000001
    {
      "name": "Hello",
      "description": "Bonjour",
      "_id": "50eb66aaedd55a0a03000001",
      "__v": 0
    }

Resource attribute(s):

    $ curl -X GET localhost:5000/tests/50eb66aaedd55a0a03000001/description
    {
      "description": "Bonjour"
    }

    $ curl -X GET localhost:5000/tests/50eb66aaedd55a0a03000001/name+description
    {
      "name": "Hello",
      "description": "Bonjour"
    }

etc...

## TODO

Better docs.

