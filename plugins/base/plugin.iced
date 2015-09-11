addDummy = (username, channel, tokens, whisper) =>
	Channel = new Mikuia.Models.Channel channel
	isMod = checkMod channel, username

	if isMod
		if tokens.length == 1 || tokens.length == 2
			Mikuia.Chat.say channel, 'You failed D:'
		else if tokens.length > 2
			command = tokens[1]
			message = ''
			text = tokens.slice(2, tokens.length).join ' '

			await
				Channel.addCommand command, 'base.dummy', defer err, data
				Channel.setCommandSetting command, 'message', text, defer err2, data

			if not err and not err2
				message = 'Command "' + command + '" probably added.'
			else
				message = 'Um, something failed. Oops.'

			if whisper
				Mikuia.Chat.whisper username, message
			else
				Mikuia.Chat.say channel, message

removeCommand = (username, channel, tokens, whisper) =>
	Channel = new Mikuia.Models.Channel channel
	isMod = checkMod channel, username

	if isMod
		if tokens.length == 1 || tokens.length > 2
			Mikuia.Chat.say channel, 'Fail.'
		else if tokens.length == 2
			command = tokens[1]
			message = ''

			await Channel.removeCommand command, defer err, data

			if not err
				message = 'Command "' + command + '" probably removed.'
			else
				message = 'I probably screwed something up... oh well.'

			if whisper
				Mikuia.Chat.whisper username, message
			else
				Mikuia.Chat.say channel, message
			
Mikuia.Events.on 'base.add.dummy', (data) =>
	addDummy data.user.username, data.to, data.tokens, data.settings._whisper

Mikuia.Events.on 'base.dummy', (data) =>
	args = data.tokens.slice(1, data.tokens.length).join ' '

	Channel = new Mikuia.Models.Channel data.to
	Viewer = new Mikuia.Models.Channel data.user.username
	await
		Channel.getSetting 'base', 'dummyCustomFormat', defer err, dummyCustomFormat
		Channel.getSetting 'base', 'dummyCustomMessage', defer err, dummyCustomMessage
		Viewer.getDisplayName defer err, viewerDisplayName

	dummyMessage = Mikuia.Format.parse data.settings.message,
		args: args
		color: data.user.color
		displayName: viewerDisplayName
		message: data.message
		username: data.user.username

	if data.settings._whisper
		Mikuia.Chat.whisper data.user.username, dummyMessage
	else
		if dummyCustomFormat
			dummyMessage = Mikuia.Format.parse dummyCustomMessage,
				args: args
				color: data.user.color
				displayName: viewerDisplayName
				dummyMessage: dummyMessage
				message: data.message
				username: data.user.username
			
		Mikuia.Chat.say data.to, dummyMessage

Mikuia.Events.on 'base.levels', (data) =>
	Channel = new Mikuia.Models.Channel data.user.username
	if Channel.getName() != data.to.replace('#', '')
		await
			Channel.getDisplayName defer err, displayName
			Channel.getExperience data.to.replace('#', ''), defer err2, experience
			Mikuia.Database.zrevrank 'levels:' + data.to.replace('#', '') + ':experience', data.user.username, defer err3, rank

		if !experience
			experience = 0

		level = Mikuia.Tools.getLevel experience
		message = displayName + ': #' + (rank + 1) + ' - Lv ' + level + ' (' + experience + ' / ' + Mikuia.Tools.getExperience(level + 1) + ' XP)'

		if data.settings._whisper
			Mikuia.Chat.whisper data.user.username, message
		else
			Mikuia.Chat.say data.to, message

Mikuia.Events.on 'base.remove', (data) =>
	removeCommand data.user.username, data.to, data.tokens, data.settings._whisper

Mikuia.Events.on 'base.uptime', (data) =>
	Channel = new Mikuia.Models.Channel data.to
	await Channel.isLive defer err, isLive

	message = ''

	if isLive
		await Mikuia.Streams.get Channel.getName(), defer err, stream
		if !err && stream?
			startTime = (new Date(stream.created_at)).getTime() / 1000
			endTime = Math.floor((new Date()).getTime() / 1000)

			totalTime = endTime - startTime

			seconds = totalTime % 60
			minutes = ((totalTime - seconds) / 60) % 60
			hours = ((totalTime - seconds) - (60 * minutes)) / 3600

			if minutes < 10
				minutes = '0' + minutes

			if seconds < 10
				seconds = '0' + seconds

			message = 'Uptime: ' + hours + 'h ' + minutes + 'm ' + seconds + 's'
		else
			message = 'Something went wrong, try again!'
	else
		message =  'The stream is not live.'

	if data.settings._whisper
		Mikuia.Chat.whisper data.to, message
	else
		Mikuia.Chat.say data.to, message

Mikuia.Events.on 'twitch.message', (from, to, message, isWhisper) =>
	globalCommand = @Plugin.getSetting 'globalCommand'
	if message.indexOf(globalCommand) == 0 and not isWhisper
		if message.trim() == globalCommand
			Mikuia.Chat.say to, 'Hey, I\'m Mikuia, and I\'m a bot made by Hatsuney! Learn more about me at http://mikuia.tv'
		else
			tokens = message.trim().split ' '
			trigger = tokens[1]

			Channel = new Mikuia.Models.Channel to
			User = new Mikuia.Models.Channel from.username
			isAdmin = User.isAdmin()
			isMod = checkMod to, from.username

			if isAdmin
				isMod = true
				
			switch trigger
				when 'commands'
					Mikuia.Chat.say to, 'Commands for this channel: http://mikuia.tv/user/' + Channel.getName()
				when 'dummy'
					addDummy from.username, to, tokens.slice 1, false
				when 'emit'
					if isAdmin
						type = tokens[2]
						switch type
							when 'handler'
								handler = tokens[3]
								if tokens.length > 4
									dataRaw = tokens[4]

								data =
									user: from.username
									to: to
									message: ''
									tokens: []
									settings: {}

								if dataRaw?

									if dataRaw.indexOf('{') == 0
										try
											jsonData = JSON.parse dataRaw
										catch error
											if error
												Mikuia.Log.error error

										if jsonData?
											for key, value of jsonData
												data[key] = value
									else
										for value in dataRaw.split(';')
											args = value.split '='
											data[args[0]] = args[1]

								console.log data
								Mikuia.Events.emit handler, data

							else
								# nope for now ;P

				when 'levels'
					Mikuia.Chat.say to, 'Levels for this channel: http://mikuia.tv/levels/' + Channel.getName()
				when 'mods'
					if isMod
						moderators = Mikuia.Chat.mods to
						if moderators?
							Mikuia.Chat.say to, 'This is what I know:' + JSON.stringify(moderators)
				when 'rating'
					await
						Mikuia.Leagues.getFightCount User.getName(), defer err, fights
						Mikuia.Leagues.getRating User.getName(), defer err, rating
						User.getDisplayName defer err, displayName
					if fights < 10
						Mikuia.Chat.say to, displayName + ' > Unranked (' + fights + ' fights, ' + rating + ' elo)'
					else
						Mikuia.Chat.say to, displayName + ' > ' + Mikuia.Leagues.getLeagueFullText(rating) + ' (' + fights + ' fights, ' + rating + ' elo)'
				when 'remove'
					removeCommand from.username, to, tokens.slice 1, false
				when 'say'
					if isAdmin
						Mikuia.Chat.sayUnfiltered to, tokens.slice(2).join(' ')
				when 'status'
					Mikuia.Chat.say to, 'Current Mikuia status: https://p.datadoghq.com/sb/AF-ona-ccd2288b29'
				else
					# do nothing

checkMod = (channel, username) ->
	if channel == '#' + username
		return true
	else
		moderators = Mikuia.Chat.mods channel
		if moderators? && username in moderators
			return true
		else
			return false