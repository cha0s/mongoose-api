mongoose = require 'mongoose'

globalOptions =
	root: '/'

serveJson = (res, code, object) ->

	# http://en.wikipedia.org/wiki/Cross-origin_resource_sharing
	res.set
		'Access-Control-Allow-Origin': '*'
		'Access-Control-Allow-Headers': 'X-Requested-With'
	
	res.json code, object
	
	return

serveError = (res, error) ->
	
	serveJson res, 500, message: error.message
	
	error

serveIndex = (app, Model) ->
	
	{collection, schema} = Model
	
	attributeKeys = Object.keys schema.paths
	
	path = "#{globalOptions.root}#{collection.name}"
	
	app.post path, (req, res, next) ->
		
		attributesObject = {}
		for key, value of req.body
			if -1 isnt attributeKeys.indexOf key
				attributesObject[key] = value
				
		Model.create attributesObject, (error, model) ->
			
			return next serveError res, error if error?
			
			serveJson res, 201, message: "Resource created."
	
	app.get path, (req, res, next) ->
		
		Model.find (error, models) ->
			
			return next serveError res, error if error?
			
			if models?
				serveJson res, 200, models
			else
				serveJson res, 200, []
	
	app.put path, (req, res, next) ->
		
		serveJson res, 405, message: "Posting bulk resources isn't supported. Try posting to each resource instead."
		
	app.delete path, (req, res, next) ->
		
		Model.remove (error, models) ->
			
			return next serveError res, error if error?
			
			serveJson res, 200, message: "Resources deleted."

	return

serveResource = (app, Model) ->

	{collection, schema} = Model
	
	attributeKeys = Object.keys schema.paths
	
	path = "#{globalOptions.root}#{collection.name}/:id"
	
	app.post path, (req, res, next) ->
		
		serveJson res, 405, message: "Posting to a resource isn't supported. Try posting to the index instead."
	
	app.get path, (req, res, next) ->
		
		Model.findById req.params.id, (error, model) ->
			
			return next serveError res, error if error?
			
			if model?
				serveJson res, 200, model
			else
				serveJson res, 404, message: "Resource not found."
	
	app.put path, (req, res, next) ->
		
		Model.findById req.params.id, (error, model) ->
			
			return next serveError res, error if error?
			
			if model?
				
				for key, value of req.body
					model[key] = value if -1 isnt attributeKeys.indexOf key
					
				model.save (error, model) ->
					
					return next serveError res, error if error?
					
					serveJson res, 200, message: "Resource updated."
				
			else
				serveJson res, 404, message: "Resource not found."
	
	app.delete path, (req, res, next) ->
		
		Model.findByIdAndRemove req.params.id, (error, model) ->
			
			return next serveError res, error if error?
			
			if model?
				serveJson res, 200, message: "Resource deleted."
			else
				serveJson res, 404, message: "Resource not found."
	
	return

serveAttributes = (app, Model) ->
	
	{collection, schema} = Model
	
	attributeKeys = Object.keys schema.paths
	
	path = "#{globalOptions.root}#{collection.name}/:id/:fields"
	
	app.post path, (req, res, next) ->
		
		serveJson res, 405, message: "Posting to a resource attribute isn't supported. Try posting to the index instead."
	
	app.get path, (req, res, next) ->
		
		getKeys = req.params.fields.split '+'
		
		Model.findById req.params.id, getKeys.join(' '), (error, model) ->
			
			return next serveError res, error if error?
			
			return serveJson res, 404, message: "Resource not found." unless model?
			
			attributesObject = null
			for getKey in getKeys
				if -1 isnt attributeKeys.indexOf getKey
					(attributesObject ?= {})[getKey] = model[getKey] 
				
			if attributesObject?
				serveJson res, 200, attributesObject
			else
				serveJson res, 404, message: "Resource attributes not found."
	
	app.put path, (req, res, next) ->
		
		serveJson res, 405, message: "Modifying a resource attribute isn't supported. Try modifying the resource instead."
	
	app.delete path, (req, res, next) ->
		
		serveJson res, 405, message: "Deleting a resource attribute isn't supported. Try deleting the resource instead."
	
	return

@serveModel = (app, Model) ->
    serveIndex app, Model
    serveResource app, Model
    serveAttributes app, Model
    return

@serveModels = (app, Models) =>
    Models = (Model for name, Model of mongoose.models) unless Models?
    @serveModel app, Model for Model in Models
    return

module.exports = (root) =>
    if root
        globalOptions.root = root
    functions =
        serveModel : @serveModel
        serveModels : @serveModels

    return functions
