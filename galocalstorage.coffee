( ->

	version = '1.0'
	IS_DEBUG = false

	localStorage = (key, initial_value) ->
		window.localStorage.setItem(key, initial_value) if window.localStorage.getItem(key) is null and initial_value isnt null

		@._get = ->
			window.localStorage.getItem(key)

		@._set = ->
			window.localStorage.setItem(key, value)

		@._remove = ->
			window.localStorage.removeItem(key)

		@.toString = ->
			@._get()

	# End -->

	ga_storage = =>
		initialized = false
		tracking_code_url = 'http://www.google-analytics.com/ga.js'
		beacon_url = 'http://www.google-analytics.com/__utm.gif'
		last_url = '/'
		last_nav_url = '/'
		last_page_title = '-'

		utmac = false
		utmhn = false
		utmwv = '4.3'
		utmcs = 'UTF-8'
		utul = 'en-us'
		utmdt = '-'
		utmt = 'event'
		utmhid = 0

		event_map =
			hidden:
				path: '/popup_hidden'
				event: 'PopupHidden'
			blurred:
				path: '/popup_blurred'
				event: 'PopupBlurred'
			focused:
				path: '{last_nav_url}'
				event: 'PopupFocused'

		uid = new LocalStorage('ga_storage_uid')
		uid_rand = new LocalStorage('ga_stored_uid_rand')
		session_cnt = new LocalStorage('ga_storage_session_cnt')
		f_session = new LocalStorage('ga_storage_f_session')
		l_session = new LocalStorage('ga_storage_l_session')
		visitor_custom_vars = new LocalStorage('ga_storage_visitor_custom_vars')

		c_session = 0
		custom_vars = if visitor_custom_vars._get() then JSON.parse(visitor_custom_vars._get()) else ['dummy']

		request_cnt = 0

		rand = (min, max) ->
			min + Math.floor(Math.random() * (max - min))

		get_random =->
			rand(10000000, 99999999)

		return_cookies = (source, mediu, campaign) ->
			source = source or '(direct)'
			medium = medium or '(none)'
			campaign = campaign or '(direct)'

			cookie = uid._get()
			ret = '__utma=' + cookie + '.' + uid_rand._get() + '.' + f_session._get() + '.' + l_session._get() + '.' + c_session + '.' + session_cnt._get() + ';'
			ret += '+__utmz=' + cookie + '.' + c_session + '.1.1.utmcsr=' + source + '|utmccn=' + campaign + '|utmcmd=' + medium + ';'
			ret += '+__utmc=' + cookie + ';'
			ret += '+__utmb=' + cookie + '.' + request_cnt + '.10.' + c_session + ';'
			return ret

		generate_query_string = (params) ->
			qa = []
			for key of params
				qa.push(key + '=' + encodeURIComponent(params[key]))
			return '?' + qa.join('&')

		reset_session = (c_session) ->
			console.log('resetting session') if IS_DEBUG
			l_session._set c_session
			request_cnt = 0
			utmhid = get_random()

		gainit = ->
			c_session = (new Date()).getTime()
			console.log('gainit', c_session) if IS_DEBUG
			request_cnt = 0
			utmhid = get_random()

			if uid._get() is null
				uid._set(rand(10000000,99999999))
				uid_rand._set(rand(1000000000,2147483647))

			if session_cnt._get() is null then session_cnt._set(1) else session_cnt._set(parseInt(session_cnt._get()) + 1)

			f_session._set(c_session) if f_session._get() is null

			l_session._set(c_session) if l_session._get() is null

		@._setAccount = (account_id) ->
			console.log(account_id) if IS_DEBUG
			utmac = account_id
			gainit()

		@._setDomain = (domain) ->
			console.log(domain) if IS_DEBUG
			utmhn = domain

		@._setLocale = (lng, country) ->
			lng = typeof lng is 'string' and if lng.match(/^[a-z][a-z]$/i) then lng.toLowerCase() else 'en'
			country = (typeof country is 'string' and if country.match(/^[a-z][a-z]$/i)) then country.toLowerCase() else 'us'
			utmul = lng + '-' + country
			console.log(utmul) if IS_DEBUG

		@._setCustomVar = (index, name, value, opt_scope) ->
			return false if index < 1 or index > 5

			params =
				name: name,
				value: value,
				scope: opt_scope

			custom_vars[index] = params

			if opt_scope is 1
				vcv = if visitor_custom_vars._get() then JSON.parse(visitor_custom_vars._get()) else ['dummy']
				vcv[index] = params
				visitor_custom_vars._set(JSON.stringify(vcv))

			console.log(custom_vars) if IS_DEBUG

			return true

		@._trackPageview = (path, title, source, medium, campaign) ->
			console.log('Track Page View', arguments) if IS_DEBUG

			clearTimeout(timer)

			request_cnt++

			path = '/' if not path
			title = utmdt if not title

			event = ''

			if custom_vars.length > 1
				names = ''
				values = ''
				scopes = ''

				i = 1
				while i < custom_vars.length
					names += custom_vars[i].name
					values += custom_vars[i].value
					#scopes += ( if not custom_vars[i].scope? then 3 else custom_vars[i].scope )
					scopes += ( if custom_vars[i].scope is null then 3 else custom_vars[i].scope )

					if i + 1 < custom_vars.length
						names += '*'
						values += '*'
						scopes += '*'

				i++

				event += '8(' + names + ')'
				event += '9(' + values + ')'
				event += '11(' + scopes + ')'

		# End -->

		last_url = path
		last_path_title = title
		if ([event_map.hidden.path, event_map.blurred.path].indexOf(path) < 0) then last_nav_url = path

		params =
			utmwv: utmwv
			utmn: get_random()
			utmhn: utmhn
			utmcs: utmcs
			utmul: utmul
			utmdt: title
			utmhid: utmhid
			utmp: path
			utmac: utmac
			utmcc: return_cookies(source, medium, campaign)

		params.utme = event if event isnt ''

		url = beacon_url + generate_query_string(param)
		img = new Image()
		img.src = url

	@._trackEvent = (category, action, label, value, source, medium, campaign) ->
		console.log('Track Event', arguments) if IS_DEBUG

		request_cnt++
		event = '5(' + category '*' + action
		if label
			event += '*' + label + ')'
		else
			event += ')'

		event += '(' + value + ')' if value

		if custom_vars.length > 1
			names = ''
			values = ''
			scopes = ''

			i = 1
			while i < custom_vars.length
				names += custom_vars[i].name
				values += custom_vars[i].value
				scopes += (if custom_vars[i].scope is null then 3 else custom_vars[i].scope)

				i++

				if i+1 < custom_vars.length
					names += '*'
					values += '*'
					scopes += '*'
			# End -->

			event += '8(' + names + ')'
			event += '9(' + values + ')'
			event += '11(' + scopes + ')'

		params =
			utmwv: utmwv
			utmn: get_random()
			utmhn: utmhn
			utmcs: utmcs
			utmul: utmul
			utmt: utmt
			utme: event
			utmhid: utmhid
			utmdt: last_page_title
			utmp: last_url
			utmac: utmac
			utmcc: return_cookies(source, medium, campaign)

		url = beacon_url + generate_query_string(params)
		img = new Image()
		img.src = url

)()