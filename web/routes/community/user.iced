module.exports = (req, res) ->
	if not req.params.userId?
		res.render 'community/error',
			error: 'No user specified.'
	else
		Channel = new Mikuia.Models.Channel req.params.userId
		
		await Channel.exists defer err, exists
		if err
			res.render 'community/error',
				error: err
		else if not exists
			res.render 'community/error',
				error: 'User does not exist.'
		else

			channel =
				name: Channel.getName()
			displayNames = {}
			ranks = {}

			await
				Channel.getAllExperience defer err, channel.experience
				Channel.getBadgesWithInfo defer err, channel.badges
				Channel.getBio defer err, channel.bio
				Channel.getCleanDisplayName defer err, channel.display_name
				Channel.getCommands defer err, commands
				Channel.getEnabledPlugins defer err, channel.plugins
				Channel.getLogo defer err, channel.logo
				Channel.getProfileBanner defer err, channel.profileBanner
				Channel.getSetting 'coins', 'name', defer err, coinName
				Channel.getSetting 'coins', 'namePlural', defer err, coinNamePlural
				Channel.getTotalLevel defer err, channel.level
				Channel.isBanned defer err, channel.isBanned
				Channel.isBot defer err, channel.isBot
				Channel.isLive defer err, channel.isLive

			for data in channel.experience
				chan = new Mikuia.Models.Channel data[0]
				await chan.getDisplayName defer err, displayNames[data[0]]
				await Mikuia.Database.zrevrank 'levels:' + data[0] + ':experience', Channel.getName(), defer err, ranks[data[0]]

			for name, rank of ranks
				ranks[name]++

			if req.params.subpage?
				switch req.params.subpage
					when 'levels'
						res.render 'community/userLevels',
							Channel: channel
							displayNames: displayNames
							ranks: ranks
					when 'inventory'
						await
							Mikuia.Items.getUserInventory Channel.getName(), defer err, items

						res.render 'community/inventory',
							Channel: channel
							items: items
					else
						res.render 'community/error',
							error: 'No subpage specified.'					
			else
				channel.commands = []
				sorting = []
				for commandName, commandHandler of commands
					sorting.push commandName

				sorting.sort()
				for command in sorting
					description = Mikuia.Plugin.getHandler(commands[command]).description
					codeText = false

					await Channel.getCommandSettings command, true, defer err, settings

					if commands[command] == 'base.dummy'
						description = settings.message
						codeText = true
					
					channel.commands.push
						name: command
						description: description
						plugin: Mikuia.Plugin.getManifest(Mikuia.Plugin.getHandler(commands[command]).plugin).name
						settings: settings
						coin:
							coinName: coinName
							coinNamePlural: coinNamePlural
						codeText: codeText

				if channel.isLive
					await Mikuia.Streams.get Channel.getName(), defer err, channel.stream

				splashButtons = []
				for element in Mikuia.Element.getAll 'userPageSplashButton'
					if channel.plugins.indexOf(element.plugin) > -1
						splashButtons = splashButtons.concat element

				for element, i in splashButtons
					for button, j in element.buttons
						if button.setting?
							await Channel.getSetting element.plugin, button.setting, defer err, value
							if value
								button.link = button.linkFunction value
							else
								button.link = false

				res.render 'community/user',
					Channel: channel
					displayNames: displayNames
					splashButtons: splashButtons




			

			
			