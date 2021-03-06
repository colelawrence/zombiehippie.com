fs = require 'fs'

repath = (path) ->
	path.replace(/[\\\/]+/g, '/')
repathFileURL = (path) ->
	path.replace(/article/i, "file")
ensureDataFolders = ->
	for dir in ["data", "data/articles", "data/files"]
		if not fs.existsSync dir
			fs.mkdirSync dir
sortedSlugs = (articles, property) ->
	props = []
	propToSlug = {}
	for slug, article of articles
		prop = article[property]
		props.push prop
		propToSlug[prop.toString()] = article.slug
	do props.sort
	slugs = []
	slugs.push(propToSlug[prop.toString()]) for prop in props
	return slugs

module.exports = class jsondb
	constructor:(@dbpath)->
		ensureDataFolders()
		alreadyMade = fs.existsSync @dbpath
		if not alreadyMade
			@db = {articles:{},users:{}}
			do @writeDB
		else
			@db = JSON.parse(fs.readFileSync @dbpath)
		do @sortArticles
		console.log @slugsByDate
	writeArticle:(article, overwrite, fn) =>
		if not overwrite
			if @db.articles[article.slug]?
				article.slug += "_"
				return writeArticle article, overwrite, fn
		mdContent = article["md-content"]
		delete article["md-content"]
		@db.articles[article.slug] = article
		if overwrite and article.slug isnt overwrite
			delete @db.articles[overwrite]
			fs.unlinkSync repath("data/articles/" + overwrite + ".md")
		do @sortArticles
		do @writeDB
		fs.writeFileSync(repath("data/articles/" + article.slug + ".md"), mdContent)
		fn null, article
	getFilenames: (slug) ->
		if slug is ""
			return []
		else
			try
				return fs.readdirSync(repath("data/files/" + slug))
			catch e
				return []
			
	uploadFile: (slug, filename, data)->
		fs.writeFileSync(repath("data/files/" + slug + "/" + filename), data)
	sortArticles: ->
		@slugsByDate = sortedSlugs @db.articles, "date"
		@slugsByTitle = sortedSlugs @db.articles, "title"
	getArticle: (slug, fn)->
		if article = @db.articles[slug]
			console.log article
			article.md = String(fs.readFileSync("data/articles/" + article.slug + ".md"))
			fn null, article
		else
			fn "Article with slug:#{slug} does not exist!"
	deleteArticle: (slug) ->
		if @db.articles[slug]
			delete @db.articles[slug]
			@sortArticles()
	getArticlesBy: (prop, count, fn) =>
		if not fn?
			fn = count
			count = no
		articles = []
		slugs = undefined
		switch prop
			when "date"
				slugs = @slugsByDate
			when "title"
				slugs = @slugsByTitle
			else
				fn "Unrecognized sorting property:#{prop}"
		if count
			slugs = slugs[...count]
		for slug in slugs
			articles.push @db.articles[slug]
		fn null, articles
	getUser: (name, fn) =>
		user = @db.users[name]
		if user?
			fn null, user
		else
			fn "User:#{name} does not exist!"
	writeUser: (name, salt, hash, fn) =>
		if @db.users[name]?
			fn "User:#{name} already exists!"
		else
			fn null, @db.users[name] = {name, salt, hash}
		do @writeDB
	writeDB: =>
		fs.writeFileSync @dbpath, JSON.stringify(@db, null, 4)