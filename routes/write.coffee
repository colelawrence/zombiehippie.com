module.exports = class Write
	constructor: (@app, @db)->
		@app.get '/write/:slug?', @get
		@app.post '/write/:slug?', @post
	get: (req,res) =>
		#return res.redirect('/login') if not req.session.user
		article = null
		render = (article = {title:"",description:"",slug:"",md:"", article_script:"", article_styles:""}) ->
			res.render 'write.jade', {
					title: 'Write on Inkblur'
					user: req.session.user
					article
					isNew: true}
			
		if req.params.slug?
			@db.getArticle req.params.slug, true, (err, article)->
				if err
					res.end(err)
				else
					render article
		else
			render()

	post: (req,res) =>
		return res.redirect('/') if not req.session.user
		@write req.body, req.session.user.name, (err, post)->
			console.log {err} if err
			if post
				console.log "Wrote new post:"+post.title
				res.redirect('/article/' + post.slug)
			else
				res.redirect '/write?failed'
	write: (body, user, fn) =>
		body.date = (new Date()).getTime()
		body.author = user
		force = if body.editing? and body.editing.length then body.editing else null
		delete body.editing
		@db.writeArticle body, force, fn