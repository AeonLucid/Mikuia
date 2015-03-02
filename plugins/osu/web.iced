cli = require 'cli-color'

codes = {}

Mikuia.Web.get '/dashboard/plugins/osu/auth', (req, res) =>
	res.render '../../plugins/osu/views/auth',
		verifyCommand: @Plugin.getSetting 'verifyCommand'

Mikuia.Web.post '/dashboard/plugins/osu/auth', (req, res) =>
	if req.body.authCode?

		await Mikuia.Database.get 'plugin:osu:auth:code:' +  req.body.authCode, defer error, username
		console.log username

		if username?
			Channel = new Mikuia.Models.Channel req.user.username

			await Channel.setSetting 'osu', 'name', username, defer err, data
			@Plugin.Log.info 'Authenticated ' + cli.yellowBright(username) + '.'
			await Mikuia.Database.del 'plugin:osu:auth:code:' + req.body.authCode, defer error, whatever

	res.redirect '/dashboard/settings'

# np! continuing the old path so people don't have to reconfigure osu!np
Mikuia.Web.post '/plugins/osu/post/:username', (req, res) ->
	res.send 200