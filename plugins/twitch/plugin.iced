request = require 'request'

Mikuia.Events.on 'twitch.followcheck', (data) =>
	Channel = new Mikuia.Models.Channel data.to

	message = null
	targetChannel = Channel.getName()
	targetUser = data.user.username

	if data.tokens.length > 1
		targetUser = data.tokens[1].toLowerCase().trim()

	User = new Mikuia.Models.Channel targetUser
	await User.getDisplayName defer err, displayName

	if targetChannel != targetUser
		await request 'https://api.twitch.tv/kraken/users/' + targetUser + '/follows/channels/' + targetChannel, defer error, response, body
		if !error
			if response.statusCode == 200
				try
					jsonData = JSON.parse body
				catch parseError
					if parseError
						console.log parseError

				if !parseError
					message = Mikuia.Format.parse data.settings.format,
						dateFollowed: jsonData.created_at
						displayName: displayName

			else
				message = displayName + ' is not following this channel.'

		if message
			Mikuia.Chat.handleResponse data.user.username, data.to, message, data.settings._target, data.details