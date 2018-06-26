var Castle = function(opts){
	var that = this
	this.rootDir =  ""
	this.paramRegex = /:([^\/:]+)/g
	this.views = {}
	this.data = {}
	this.debugMode = false
	this.privateAttributePrefix = "_"
	this.views = {
		//stores the html
	}
	this.DISABLE_AUTORENDER = false
	this.controllers = {
		/*
		controllers need to return an object like the following
			{view: viewname, params: params, data: dataObject}
		*/
	
	}
	//array of registered partials so they only do it once
	this.registeredPartials = []
	//helpers are snippets of code ran after template engine has been rendered
	this.helpers = {
		//###link projectPage "v1" "v2" (my sweet Project) ###
		//###link projectPage (mySweetProject), `b` => something `c` => something  ###
		link: {
			r: /\[\[\[\s+LINK:\s+(.+?)\s+(?:\((.+?)\))*\s*,\s*(.+?)\s*\]\]\]/g,
			evaluate : function(m,controller, parenthesis,vars){
				var varsRegex  = /\s*`(.+?)`\s*=>\s*([^`]+)\s*/g //variables
				var linkNameRegex =  /\(\s*(.+?)\s*\)/ //parenthesis
				var cleanRouteReplaceRegex = /[^a-zA-Z0-9-\/_:]/g;
				var matches 
				var varObj = {}
				that.debugLog("executing link helper",arguments)
				var controllerName = that.getTrueControllerName(controller)
				that.debugLog("contorllerName = "+controllerName+"?")
				while (matches = varsRegex.exec(that.decodeHtmlEntities(vars))){
					varObj[matches[1]] = 	matches[2].trim()
				}
				that.debugLog("varObj",varObj)
				matches = false

				if (controllerName){
					controllerName= controllerName.replace(cleanRouteReplaceRegex,'').replace(that.paramRegex, function(m,m1){
						return varObj[m1] || false
					})
				}
				var $ret = $("<a></a>")
				$ret.attr("href", "#"+controllerName)
				$ret.html((parenthesis) ? parenthesis : controllerName) 
				return $($ret).clone().wrap('<p>').parent().html();
			
			}
		}
	}


	 this.debugLog =  function(){

	    var category = false
	     var newArguments = []
	    for (var i =0; i<arguments.length; i++){
	      newArguments.push(arguments[i])
	    }
	   
	    //feed last element as #TEST_CATEGORY for example 
	    debugCategoryRegex = /^[#A-Z0-9_]+$/
	    if (this.debugMode){
	      var lastElement = newArguments.shift()
	      if (typeof lastElement=="string" && debugCategoryRegex.test(lastElement)){
	        category = lastElement
	        newArguments.unshift("DEBUG["+category+"]: ")
	      }else{
	      }
	      if (typeof this.debugMode == "string"){
	        if (category!=false && this.debugMode==category)         
	          console.log.apply(console, newArguments)
	      }else{
	        console.log.apply(console, newArguments)
	      }
	      
	    }
	  }


	this.getData =  function(data){
		return $.extend({}, this.data)
	}
	this.removePrivateData = function(data){
		var that = this
		var cleaned = {}
		$.each(data, function(k,v){
			that.debugLog("k:"+k)
			if (!k.startsWith(that.privateAttributePrefix))
				cleaned[k] = v
		})
		return cleaned
	}
	
	this.setData =  function(data){
		this.data = data
	}
	this.getRegexRoute = function(route, includeColon){
		includeColon = includeColon || false
		var paramRegexReplacement = "([^\\/:]+)"
		if (includeColon){
			paramRegexReplacement =+ ":"
		}
		var dynRegex = new RegExp(route.replace(this.paramRegex, paramRegexReplacement))
		return dynRegex
	}
	this.getTrueControllerName =  function(controllerName, db){
		controllerName = controllerName.trim()
		var found = false
		var db = db || this.controllers
		var that = this
		that.debugLog("blah:","controllerName =",controllerName)
		//its a root
		if (controllerName=="" || controllerName=="#"){
			return "root"
		}

		//id it the name?
		if ($(".castle-view[data-id='"+controllerName+"']").length){
			return  $(".castle-view[data-id='"+controllerName+"']").attr("data-route")
		}

		//is it in controllers?
		if (db[controllerName]!=undefined){
			return controllerName
		}
		//go through each controller
		for (k in db){
			var dynRegex = that.getRegexRoute(k)
			that.debugLog(controllerName + " matches regex:" + that.getRegexRoute(k) + "?" + dynRegex.test(controllerName))
			if (dynRegex.test(controllerName))
				found = k
		}
		that.debugLog("found:"+found)
		return found
	}
	this.getTrueViewName =  function(viewName){
		return this.getTrueControllerName(viewName, this.views)
	}
	this.parseRoute =  function(){
			this.debugLog("TEST:","PARSING LE ROUTE>.....")
			var that = this
			var path = this.getPath()
			that.debugLog("path: '","the path is:",path)
			if (path=="" || path=="#"){
				this.controller("root")
			}else{
		   
			   var found = false
			   that.debugLog("test","current controllers:",$.extend({},this.controllers))
			   for (k in this.controllers){
 					var dynRegex = that.getRegexRoute(k)
			   		that.debugLog("RUNNING test:","testing controller:",k, dynRegex)
			   		that.debugLog("TEST:","testing regex:",path,"dynregex:",dynRegex,"result test:",dynRegex.test(path))
			   		 if (dynRegex.test(path)){
			   		 	that.debugLog("TEST_REGEX_PATH:", path, 'DYNREGEX:',dynRegex," has passed")
			   			//lets grab the params from the template
			   			paramObj = {}
			   			var match
			   			var match2 = dynRegex.exec(path)
			   			var count = 1
			   			while (match = that.paramRegex.exec(k)){
			   				paramObj[match[1]] = match2[count]
			   				count++
			   			}
			   			found = true
			   			that.debugLog("PATH THING:","path that has one is:",path)
			   			that.controller(path, paramObj)
			   			return false;
			   		}
			   }
			   /*
			   $.each(this.controllers, function(k,v){
			   		var dynRegex = that.getRegexRoute(k)
			   		that.debugLog("RUNNING test:","testing controller:",k, dynRegex)
			   		that.debugLog("TEST:","testing regex:",path,"dynregex:",dynRegex,"result test:",dynRegex.test(path))
			   		 if (dynRegex.test(path)){
			   		 	that.debugLog("TEST_REGEX_PATH:", path, 'DYNREGEX:',dynRegex," has passed")
			   			//lets grab the params from the template
			   			paramObj = {}
			   			var match
			   			var match2 = dynRegex.exec(path)
			   			var count = 1
			   			while (match = that.paramRegex.exec(k)){
			   				paramObj[match[1]] = match2[count]
			   				count++
			   			}
			   			found = true
			   			that.controller(path, paramObj)
			   			return false;
			   		}
			   	})
			   	*/
			   that.debugLog("test:", "was a path found?", found)
			   if (found == false)
			   	this.throw404("The page '"+path+"' doesn't exist")
			}
	}
	this.getRootDir =  function(){

    	
		 var pathName =  window.location.pathname
		 var index = pathName.lastIndexOf('/')
		this.rootDir = pathName.slice(0, index)+"/"

	}
	this.setPath =  function(pageName){
		try{
		history.pushState({}, null, this.rootDir+"#"+this.getPath());
		}catch(e){

		}
		
	}
	this.getPath = function(){
		var ret = location.hash
		return (ret.trim()=="" || ret.trim()=="#") ? "" : ret.slice(1)
	}
	this.generateUUID = function() {
	    var d = new Date().getTime();
	    var uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
	        var r = (d + Math.random()*16)%16 | 0;
	        d = Math.floor(d/16);
	        return (c=='x' ? r : (r&0x3|0x8)).toString(16);
	    })
		return uuid
	}
	this.controller =  function(controllerName, params){
		this.debugLog("controllerName:","Now running controller:",controllerName)
		var alias = controllerName
		params = params || {}
		var that = this
		var trueControllerName = false
		//controllorName is actually dataId attribute
		 if ($(".castle-view[data-id='"+controllerName+"']").length){
			var trueControllerName = $(".castle-view[data-id='"+controllerName+"']").attr("data-route")
		}

		
		var defaultData = {
			data: this.data,
			view: controllerName,
			controllerAlias: alias,
			controller: controllerName,
			params: params
		}
		if (alias == controllerName)
			delete defaultData.controllerAlias
		//controllerName is not valid

		if (!trueControllerName)
			trueControllerName = this.getTrueControllerName(controllerName)

		this.currentController = trueControllerName;
		this.debugLog("true controller Name:","true controller name:",trueControllerName)
		if (!trueControllerName){	
			this.throw404("Controller '"+controllerName+"' doesn't exist",params)
		}else{
			defaultData.controller = trueControllerName
			//defaultData.view = trueControllerName
			//run controller (data, params, path, castleInstance)
			var controllerObject = new that.controllers[that.getControllerFunctionName(controllerName)](this.data, params, trueControllerName, that)

			that.debugLog("truecontrollername:",trueControllerName)
			that.debugLog("available controllers: ",that.controllers)
			that.debugLog("controllerObject: ", controllerObject)
			var controllerData =  controllerObject.data
			// and render
			
			
			if (controllerData !=false){
				defaultData.data =  this.data

				var data = $.extend(defaultData, controllerData)
				
				//merge obj as main thing
				data = $.extend(data, data.data)

				delete data.data
			}
				that.debugLog("controller Data:", data)
				this.render(data.view, this.removePrivateData(data))
			

			/*
			//analyze for sync partials
			that.debugLog("view name for this:"+data.view)
			that.debugLog("view check for:"+this.getViewHTML(data.view))
			var $content =  $("<div>"+this.getViewHTML(data.view)+"</div>")
			var $partials = $content.find("[data-livePartial]")
			that.debugLog("length of partials:",$partials.length)
			$partials.each(function(){
				that.debugLog("tracking something..")
				var trackedVars = $(this).attr("data-livePartial").split(",")
				that.debugLog("tracked vars:",trackedVars)
				var id = $(this).attr("id")
				var htmlTmpl = $(this).html()
				that.debugLog("LIVEPARTIAL", 'live partial found:',$(this).html())
				that.debugLog("LIVEPARTIAL", 'trackedvars  found:', trackedVars)
				$.each(trackedVars, function(k,v){
					that.debugLog("LIVEPARTIAL","setting up tracking for.. ",v)
					that.debugLog("LIVEPARTIAL","currently registered partials.. ",that.registeredPartials)
						that.debugLog("LIVEPARTIAL","partial registered to watch! ",v)
						//watch(that.data,v,watchCallback,0,true)
						that.addWatcher(that.data,v, function(){
							that.debugLog("LIVEPARTIAL", "data changed!:", that.data)
							that.debugLog("LIVEPARTIAL","reloading.."+"#"+id+" with new data, "+v+" has changed")
							that.updatePartial(id, htmlTmpl, that.data)
						})
				
				})
				//run for first run
				that.updatePartial(id, htmlTmpl, that.data)

			})
			*/

			//look at view for any 
			if (controllerObject.afterLoad!=undefined){
				that.debugLog("EVENT","afterload!")
				controllerObject.afterLoad()
			}else{
				that.debugLog("EVENT","afterload not defined!", controllerObject)
			}

		}
	}

	this.watchers = []
	//get controller function 
	this.getControllerFunctionName = function(controllerAliasOrTrue){
		var  trueControllerName	
		if (this.controllers[controllerAliasOrTrue]!= undefined	)
			trueControllerName = controllerAliasOrTrue
		else
			trueControllerName = this.getTrueControllerName(controllerAliasOrTrue)
		return trueControllerName;
	}
	this.addWatcher = function(obj, prop, callback){
		this.watchers.push({"obj": obj, "prop": prop})
		watch(obj, prop, callback,undefined,true)
	}

	this.updatePartial = function(id, html, data){
			var that = this
			$("#"+id).html(that.templateEngine(html, data, that))
	}
	this.getViewHTML = function(view){
			var trueViewName =this.getTrueViewName(view)
			var viewHTML  = this.views[trueViewName]
			return viewHTML
	}
	this.templateEngine =  function(txt, data,_self){
		return _self.simpleTmplParser(txt, data)
	}
	this.throw404 = function(errorMessage, params){
		params = params || {}
		params.errorMessage = errorMessage
		this.controller("404", params)
	}
	this.render = function(viewName, data,el){
		el = el || false
		//viewName is actually dataId attribute
		 if ($(".castle-view[data-id='"+viewName+"']").length){
			var trueViewName = $(".castle-view[data-id='"+viewName+"']").attr("data-route")
			that.debugLog("viewName is an alias and exists.."+viewName)

		}else{
			var trueViewName = this.getTrueViewName(viewName)
		}
			that.debugLog("true viewName: ",trueViewName)
		if (!trueViewName){	
			this.throw404("View '"+viewName+"' doesn't exist", data.params)
		}else if (!$("[data-route='"+trueViewName+"']").length && !el){
			this.throw404("View Container '"+trueViewName+"' doesn't exist", data.params)
		}else if (el && !$(el).length){
			this.throw404("DOM Element '"+el+"' could not be found.", data.params)
		}else{
			el =(el) ? el : "[data-route='"+trueViewName+"']"
			var renderedView = this.templateEngine(this.views[trueViewName], data, this)
			
			//run helpers after we ran through template engine
			$.each(this.helpers, function(k,v){
				if (v.r!=undefined && v.evaluate!=undefined)
					renderedView = renderedView.replace(v.r, v.evaluate)
			})
			$(el).html(renderedView).show()
		// 	that.debugLog("RENDER","successfully rendered!",$(el).html())

		}
		
		
	}
	this.decodeHtmlEntities = function(value){
    return String(value)
        .replace(/&quot;/g, '"')
        .replace(/&#39;/g, "'")
        .replace(/&lt;/g, '<')
        .replace(/&gt;/g, '>')
        .replace(/&amp;/g, '&');
	}
	this.encodeHtmlEntities = function(str){
		    return String(str)
		        .replace(/&/g, '&amp;')
		        .replace(/"/g, '&quot;')
		        .replace(/'/g, '&#39;')
		        .replace(/</g, '&lt;')
		        .replace(/>/g, '&gt;');

	}
	this.init =  function(opts){
		var that = this
		var autoMakePages = {
			404: "<h2>Error 404</h2>Page not found. {{params.errorMessage}}",
			root: "<p>Welcome to Castle! You're seeing this page because you haven't made a root page yet. Make one by adding the following to your file:"+
			"<pre>"+this.encodeHtmlEntities("<div data-route='root' class='castle-view' >My root page</div>")+"</pre></p>"
		}
		var wpr = ($(".castle-view").length) ? ($(".castle-view:first").parent()) : $(document.body)
		//add 404 if page couldnt be found
		$.each(autoMakePages, function(k,v){
			if (!$("[data-route="+k+"]").length){
				var page = $("<div data-route="+k+" class='castle-view' ></div>").html(v)
			$(wpr).append(page)
		}
		})
		
		$(".castle-view").each(function(){
			$(this).hide()
			var route = $(this).attr("data-route")
			//add stuff to live partial elements
			$(this).find("[data-livePartial]").each(function(){
				if (!$(this).attr("id"))
					$(this).attr("id", "castlelp-"+that.generateUUID())
			})
			//store views
			that.views[route] = $(this).html()
			//create default controllers
			if (that.controllers[route] == undefined){
				that.debugLog("creating controller for "+route)
				that.controllers[route] = function(){return {}}
			}

		})

		var defaultOpts = {
			controllers: this.controllers, //custom controllers,
			views: this.views, //additional views,
			helpers: this.helpers, //helpers
			data: this.data, //data object
			privateAttributePrefix: "_", //used to automatically hide object attribtues from rendered views
			templateEngine: false, //custom/different template engine

		}
		//set it up
		var options = $.extend(true, defaultOpts,opts)
		that.debugLog(JSON.stringify(options))
		this.controllers = $.extend(this.controllers, options.controllers)
		that.debugLog("setup options",options)
		this.views = $.extend(this.views, options.views)
		this.helpers = $.extend(this.helpers, options.helpers)
		this.data = options.data
		this.privateAttributePrefix = options.privateAttributePrefix
		if (options.templateEngine){
			this.templateEngine = options.templateEngine
		}


		$(window).on("hashchange", function(){
			//hide all stuff
			$(".castle-view").hide()
			that.debugLog("HASHCHANGE", "the hash has been changed!", that.getPath())
			//parse route and render
			that.parseRoute()
		})
		//initial one
		that.debugLog("INITPARSE", "initial parse", that.getPath())
		that.parseRoute()
	}
	

	//kind of like a simple handlebars
	this.simpleTmplParser = function(text,obj,extraData, intermParse){
		extraData = extraData || {}
		var that = this
		intermParse = intermParse || false
		extraData._helpers = extraData._helpers || {}
		var helpersRegex = /([^0-9%$-+\/\*~!(\s]+)\((.*)\)/g
		var quoteRegex = /("(.*?)"|'(.*?)')/g
		var strLiteralRegex = /!!!(.+?)!!!/g
		extraData._partials = extraData._partials || {}

		var _log = function(){
			//do nothing 
			return false
		}

		var toggleEscapeBracketsinObj = function(obj, escOrUnEsc){
			var newObj
			//its an object or arr
			if ($.isPlainObject(obj) || $.isArray(obj)){
				//initialize if array
				if ($.isArray(obj)){
					newObj = []
					var x
					for (x=0;x<obj.length; x++){
						newObj.push(false)
					}
				}else{
					newObj = {}
				}
				$.each(obj, function(k, v){
					newObj[k] = toggleEscapeBracketsinObj(v,escOrUnEsc)
				})
			
			}
			//its a
			else if (typeof obj == "string"){
				if (escOrUnEsc=="escape")
					newObj = obj.replace(/\{\{/g, "[DOUBLE_BRACKET_OPEN]").replace(/\}\}/g, "[DOUBLE_BRACKET_CLOSE]")
				else{
					newObj = obj.replace(new RegExp("\\[DOUBLE_BRACKET_OPEN\\]", 'g'), "{{").replace(new RegExp("\\[DOUBLE_BRACKET_CLOSE\\]", 'g'), "}}")
				}
			}else{
				newObj = obj
			}
		
			return newObj
		}

		var replaceHelperForRealFuncs = function(str){
			str = str.replace(helpersRegex, function(m,m1,m2){
				return "extraData._helpers['"+m1+"']("+replaceHelperForRealFuncs(m2)+")";
			})
			return str
		}



		//find each variable and transform to real
		var swapForTrueVars = function(str){
			var matches
			str = $(document.createElement('div')).html(str).text()

			//swap out helpers for actual functions
			str = replaceHelperForRealFuncs(str)

			//replace quotes with !!!0!!!!
			var stringLiterals = []
			str = str.replace(quoteRegex, function(m,m1,m2){
				_log("quoteRegex Results from ",str," to ---> ",m,m1,m2)
				var id = stringLiterals.length
				stringLiterals[id] = m
				return "!!!"+id+"!!!"
			})

			var newStr2 = str+""
			//find variables
			var varblRegex = /([a-zA-Z_~\.$@]+[-0-9.a-zA-Z_]*)/g
			var blacklist = ["true", "false", "extraData","obj"]
			var prefixBlackList = ["extraData."]
			var regexBlackList
			
			matches = false 
			/*
			while (matches = varblRegex.exec(str)){
				//if not in blacklist and we find a match
				if (matches && blacklist.indexOf(matches[1].toLowerCase())==-1){
					$.each(prefixBlackList, function(k,v){
						if (matches[1].substring(0, v.length) === v)

					})
				}
			}
			*/

			newStr2 = newStr2.replace(varblRegex, function(m){
				var ok = true
				$.each(prefixBlackList, function(k,v){
						//in blacklist so ignore
						if (m.substring(0, v.length) === v)
							ok = false
					})
				//if not already have a prefix..and not on the blackList
				if (ok && blacklist.indexOf(m.toLowerCase())==-1){
					_log("looking up..",m)
					return getVar(m, true)
				}else{

					//no need to edit
					return m
				}

			})
			//put back the stringLiterals
			newStr2 = newStr2.replace(strLiteralRegex, function(m,m1){
				_log(m, "m1:",m1)
				return stringLiterals[Number(m1)]
			})
			_log("newVarStr2 = ",str," to ",newStr2)
			return newStr2
		}

		//get a value from a string..could be a variable or expression 
		var resolveStrToVal = function(str){
			 str = str || ""
			var str = str.replace(/"/g, '\"').replace(/'/g, "\'")
			_log("obj:",obj)
			_log(obj.name)
			_log("resolving...",str)
			var expression = swapForTrueVars(str)
			_log("we got..",expression)
			return eval(expression)
		}


		var throwError = function(message){
				this.SelectorException.prototype = Object.create(Error.prototype)
				throw new function(){
	  		 		Error.captureStackTrace(this);
	  				this.message =  message,
		   			this.name = "TemplateException"
  				}
		}
		//this takes a command and text and parses the goodness
		var parseCmd = function(text, cmd){
		 

		    var grabSubTexts = function(k,segment){
		      
		      var computeRegexes = function(regex, text){
		        var tmpMatches, tmpRes
		        if (regex!=undefined && regex.constructor==RegExp){
		          if (regex.global){
		             tmpRes = []
		            while (tmpMatches = regex.exec(text)){
		              tmpRes.push(tmpMatches)
		            }
		          }else{
		             tmpRes = regex.exec(text)
		          }
		        }
		        return tmpRes

		      }

		        var startingIndex =positionNumbersAll.indexOf(segment.indexExclusive)
		       var ret = {
		          cmdArgs: segment.cmdArgs,
		          text: (cmd.endCmd==undefined) ? "" :  text.slice(positionNumbersAll[startingIndex],positionNumbersAll[startingIndex+1] )
		        }
		        //ADD REGEX MATCHES
		        //cmdRegex + regex for main command
		        if (k==cmd.cmd){
		          if (cmd.cmdRegex)
		             ret.cmdMatches = computeRegexes(cmd.cmdRegex, ret.cmdArgs)
		          if (cmd.regex)
		             ret.matches = computeRegexes(cmd.regex, ret.text)
		        }else{
		          //cmd regex for segments
		          if (cmd.extraCmdRegex)
		            ret.cmdMatches = computeRegexes(cmd.extraCmdRegex[k], ret.cmdArgs)
		          //regex for segments
		           if (cmd.extraCmdRegex)
		            ret.matches = computeRegexes(cmd.extraRegex[k], ret.text)
		        }
		        //delete the following keys if there are none 
		        var toDeleteIfBlank = ["cmdArgs", "cmdMatches", "matches"]
		        for (var i=0; i<toDeleteIfBlank.length; i++){
		          if (toDeleteIfBlank[i] in ret){
		            if (ret[toDeleteIfBlank[i]] == undefined ||
		                (ret[toDeleteIfBlank[i]] == false)
		              )
		              delete ret[toDeleteIfBlank[i]] 
		          }
		        }
		      return ret
		    }
		  var retObj = {
		    segments: {}
		  }
		  //find each

		 
		  
		  var matches
		  var positionNumbersAll = []
		  
		  var level = 0
		 var count = 0 
		  var positions = {
		   startInclusive: 0,
		    endInclusive: 0,
		    startExclusive: 0,
		    endExclusive: 0,
		    segments: {}
		  }
		  var foundEnd = false
		   var m
		   positions.segments[cmd.cmd] = {}

		   //cmd endCmd!! Here we create the end and middle position objects to hold numbers we find
		   if (cmd.endCmd != undefined){

		        if (cmd.extraSegments){
		          $.each(cmd.extraSegments.split(","), function(index, segment){
		            if ( m = /(.+)\*$/.exec(segment)){
		              positions.segments[m[1]] = []
		            }else{
		              positions.segments[segment] = {}
		            }
		          })
		        }
		         positions.segments[cmd.endCmd] = {}
		  }



		 	startIndex = 0
		   //var balancingRegex = new RegExp("\{\{\\s*("+Object.keys(positions.segments).join("|")+")\\s*(.+)*\}\}","g")
		  // var balancingRegex = new RegExp("\{\{\\s*("+Object.keys(positions.segments).join("|")+")\\s*([^{\\n]+)*\}\}","g")
			var balancingRegex = new RegExp("\{\{\\s*("+Object.keys(positions.segments).join("|")+")\\s*([^{\\n]*)\\s*\}\}","g")
		   //NO END CMD
 			_log("balancingRegex: ",balancingRegex)
		   
		    if (cmd.endCmd==undefined){
			    foundEnd = true
			     matches = balancingRegex.exec(text)
			
			     var segmentPositionObj = {
			          index: matches.index, 
			          indexExclusive:  matches.index+matches[0].length, 
			          val: matches[0], 
			          cmd: matches[1],
			          cmdArgs: matches[2] || false
			      }

			     positions.segments[matches[1]] = segmentPositionObj
		         positions.startExclusive = matches.index+(matches[0].length)
		         positions.startInclusive  = matches.index
		         positions.endExclusive = matches.index+matches[0].length
		         positions.endInclusive  = matches.index+matches[0].length
  
		  
		  }
		   while ( count<50 && foundEnd==false && (matches = balancingRegex.exec(text))){
		    //nested
		    if (count>50)
		    	break;
		    if (matches[1]==cmd.cmd){
		      if (count==0){
		        
		        positions.startExclusive = matches.index+(matches[0].length)
		         positions.startInclusive  = matches.index+0
		        // positions.segments[cmd.cmd] =positions.startExclusive
		      }
		       level++
		      }else if (matches[1]==cmd.endCmd){
		        level--
		      }

		     //if in a command main level (level 1)..and the match is a middle .last segment...
		    if ((level==1 && Object.keys(positions.segments).indexOf(matches[1])!=-1 && cmd.endCmd!=matches[1] ) || 
		       (level==0 && cmd.endCmd==matches[1])){
		          var segmentPositionObj = {
		            index: matches.index, 
		            indexExclusive:  matches.index+matches[0].length, 
		            val: matches[0], 
		            cmd: matches[1],
		            cmdArgs: matches[2] || false
		          }
		          if ($.isArray( positions.segments[matches[1]]))
		              positions.segments[matches[1]].push( segmentPositionObj)
		          else{
		          		_log("level:",level)
		          		_log(matches[1], segmentPositionObj)
		               positions.segments[matches[1]] = segmentPositionObj
		          }
		           positionNumbersAll.push( segmentPositionObj.index)
		           positionNumbersAll.push( segmentPositionObj.indexExclusive)
		     }

		     //END OF COMMAND..wrap things up
		    if (level==0 && cmd.endCmd==matches[1]){

		      
		       positions.endExclusive = matches.index
		       positions.endInclusive  = matches.index+matches[0].length
		      retObj.all = text.slice(positions.startExclusive,positions.endExclusive)
		      retObj.allIncludingCmd =  text.slice(positions.startInclusive,positions.endInclusive)
		      foundEnd = true
		    }



		    count++
		   
		  } 


		    //GENERATE return object
		    //we have the position data now we need to navigate and create the return object
		    $.each(positions.segments, function(k,segment){
		      if (k!=cmd.endCmd){
		        if ($.isArray(segment) && segment.length>0){
		          retObj.segments[k] = []
		          $.each(segment, function(k2,v2){
		             retObj.segments[k].push(grabSubTexts(k,v2))
		          })
		        }else if (!$.isEmptyObject(segment)){
		          retObj.segments[k] = grabSubTexts(k,segment)
		        }
		      }
		    })

		    //ADD IN POSITIONS
		    retObj.positions = {
		      start: {
		        inclusive: positions.startInclusive,
		        exclusive: positions.startExclusive
		      },
		      end: {
		        inclusive: positions.endInclusive,
		        exclusive: positions.endExclusive
		      }
		      
		    }
		    //ADD IN RESULTS (whatever the first command non-segment is)
		    retObj.results = retObj.segments[cmd.cmd]
 
		    return retObj



		 } //<----END PARSE CMD

		//take a fake var and turn to real
		//just text returns the string of var, vs actual variable value
		var getVar = function(v, justText){
			justText = justText || false
			var tmp = undefined
			//var varblRegex = /^([a-zA-Z_~\.$@]+[-0-9]*)$/g


			var varblRegex = /^([a-zA-Z_~\.$@]+[-0-9.a-zA-Z_]*)$/g 
			var fakeIndexRegex = /\.([0-9]+)/g

			//does this var contain spaces or bad characters? wronggg
			if (/\s/g.exec(v) || !v.match(varblRegex))
				return false


			//~ is basically highest level of the object
			if (v=="~"){
				return (!justText) ? obj : "obj"
			}
			//replace wild card with NOTHING..this is a local property
			v = v.replace(/~\./g, "")

			////now we will replace indexes with their counterparts
			// i.e. a.0.blah --> a[0].blah, a.0 --> a[0]
			v = v.replace(fakeIndexRegex, function(m,m1){
				return "["+m1+"]"
			})

			_log("pre tests for v = ", v)
			//try as part of object
			_log("extraData\n-----\n",extraData)
			try{
				if (eval("obj."+v) !=undefined)
					tmp = (!justText) ? eval("obj."+v) : "obj."+v
			}catch(e){
			}
			//try as part of extraData
			try{
				
				if (tmp == undefined){
					if (eval("extraData."+v) !=undefined)
						tmp =(!justText) ? eval("extraData."+v) : "extraData."+v
				}
			}catch(e){
			}
			//must be false
			if (tmp == undefined)
				tmp = false


			
			return tmp
		}

		var newCommands = {
			
			comment: {
				cmd: "!--",
				endCmd: "--",
				evaluate: function(data){
					return ""
				}
			},
			setPartial: {
				cmd: "#setPartial",
				endCmd: "/setPartial",
				evaluate: function(data){
					//_log("setting partial!",data)
					extraData._partials[data.results.cmdArgs]=data.all;
					return ""
				}
			},
			replace: {
				cmd: '#replace',
				cmdRegex: /(.+),(.+),(.*)/, //arg1: text, arg2: to replace, arg3: replace with
				evaluate: function(data){
					var text = eval(swapForTrueVars(data.results.cmdMatches[1]))
					var regexReplace = new RegExp(data.results.cmdMatches[2], 'g')
					return text.replace(regexReplace,data.results.cmdMatches[3])
				}
			},
			partial: {
				cmd: "#partial",
				cmdRegex: /\s*(.+)\s*,\s*(.+)\s*/,
				evaluate: function(data){
					var partialId = data.results.cmdMatches[1]
					var objString = data.results.cmdMatches[2]
					if (extraData._partials[partialId]!=undefined){
						_log("running partial:",partialId,extraData._partials[partialId])
						return that.simpleTmplParser(extraData._partials[partialId],getVar(objString),extraData, true)
					}else{
						return ""
					}
				}
			},
			log: {
				cmd: "#log",
				evaluate: function(data){
					data.results.cmdArgs = data.results.cmdArgs.replace(/(^|\s)\$([^\s]+)/g, function(m){
						return JSON.stringify( getVar(m[2]))
					})
					_log("SOULPATCH LOG: "+data.results.cmdArgs)
					return ""
				}
			},
			join: {
				cmd: "#join",
				cmdRegex: /\s*([^,]+)\s*(?:,\s*(.+))?/, //arg1: , arg2: delimiter
				evaluate: function(data){
					var el = data.results.cmdMatches[1]
					var delimiter = data.results.cmdMatches[2]
					_log("joining:",swapForTrueVars(el))
					return eval(swapForTrueVars(el)).join(delimiter)
				}
			},
			 If: {
			    cmd: "#if",
			    endCmd: "/if",
			    extraSegments: "elif*,else", //do * for multiple?
			    //helperEvaluate: ["#if:args", "if:data", else:data"], //rework the helper args
			    evaluate: function(data){ //results

			    	var segments = data.segments
			    	var test
			    	var returnText = ""
			    	if (returnText=="" && segments["#if"]){
			    		_log("segments found", swapForTrueVars(segments["#if"].cmdArgs))
			    		test = eval(swapForTrueVars(segments["#if"].cmdArgs))
			    		if (test)
			    			returnText = segments["#if"].text
			    	}

			    	if (returnText=="" && segments["elif"]){
			    		$.each(segments["elif"], function(k,v){
			    			if (returnText == ""){
				    			test = eval(swapForTrueVars(v.cmdArgs))
					    		if (test)
					    			returnText = v.text
					    
	    					}
	    				})
			    	}

			    	if  (returnText=="" && segments["else"]){
			    			returnText = segments["else"].text
			    	}
			    
					_log("if data from evaluate",data)
					_log("returnTxt", returnText)
			    	return returnText//text to do something to

			    }
			     
			},
			each: {
				cmd: "#each",
				endCmd: "/each",
				//as Regex
				cmdRegex: /\s*(.+)\s+as\s+(.+)\s*/,
				evaluate: function(data){
					//  var tmp =
					  var ret = ""
					  var tmpobj,newExtraData
					  newExtraData = {}
					  var key,val,cmdMatchesPieces
					  
					  if (data.results.cmdMatches){
					  	  //we have an #each blah as k,v
					  	 tmpObj = getVar(data.results.cmdMatches[1])

						 if (data.results.cmdMatches[2]){
						  	 tmpObj = getVar(data.results.cmdMatches[1])
						  	cmdMatchesPieces = data.results.cmdMatches[2].split(",")
						  	if (data.results.cmdMatches[2].indexOf(",")!=-1){
						  		key = cmdMatchesPieces[0].trim()
						  		val = cmdMatchesPieces[1].trim()
						  	}else{
						  		val = data.results.cmdMatches[2].trim()
						  	}
						 }
					  }else{
					  	//just a #each blah
					  	tmpObj = getVar(data.results.cmdArgs)
					  }
				  	_log("tmpObj is ", tmpObj)
				  	if (tmpObj){
						  var count = 0
				  		 $.each(tmpObj, function(k,v){
				  		 	newExtraData["this"] = v
				  		 	if (key) newExtraData[key] = k
				  		 	if (val) newExtraData[val] = v
				  		 	newExtraData["$LENGTH"] = Object.keys(tmpObj).length
							newExtraData["$INDEX"] = Number(count)
							newExtraData["$COUNT"] = Number(count)+1
							newExtraData["$LAST"] = (Object.keys(tmpObj).length-1==count)
							newExtraData["$FIRST"] = (count==0)
							ret += that.simpleTmplParser(data.results.text,obj,$.extend($.extend({}, extraData),newExtraData),true)
							count++
							_log("newExtraData is", newExtraData)
				  		 })
				  	}
					  
					 
					  //_log("each command",data)
					  return ret
				} //<-- end evaluate
			}, //<-- end each
			boldify: {
				cmd: "#boldify",
				evaluate: function(data){
					return "<b>"+getVar(data.results.cmdArgs)+"</b>"
				}
			},
			underlineify: {
				cmd: "#underlineify",
				evaluate: function(data){
					return "<u>"+resolveStrToVal(data.results.cmdArgs)+"</u>"
				}
			},
			boldifyContents: {
				cmd: "#boldifyContents",
				endCmd: "/boldifyContents",
				evaluate: function(data){
					return "<b>"+data.results.text+"</b>"
				}
			},
			trim: {
				cmd: "#trim",
				evaluate: function(data){
					return resolveStrToVal(data.results.cmdArgs).trim()
				},
			
				helperEvaluate: function(){
					return "trimmmmmed..."+(arguments[0]).trim()
				}
			}, 
			set: {
				cmd: "#set",
				evaluate: function(data){
					if (data.results.cmdArgs.indexOf("=")==-1)
						return ""
					else{
						var pieces = data.results.cmdArgs.split("=",2)
						obj[pieces[0].trim()] = obj[pieces[0].trim()] || {}
						_log("pieces", pieces)
						obj[pieces[0].trim()] = resolveStrToVal(pieces[1])
						return ""
					}
				}
			},
			jsonify: {
				cmd: "#jsonify",
				evaluate: function(data){
					_log("woooooop")
					_log("jsonifying",data.results.cmdArgs," to ",resolveStrToVal(data.results.cmdArgs))
					return JSON.stringify(resolveStrToVal(data.results.cmdArgs))
				}
			}
		} //<--end new commands

			//setup  helpers automatically from commands..
			$.each(newCommands, function(cmdId,cmd){
				cmd.helperEvaluate = cmd.helperEvaluate || false
				//typ thing 
				//blam(args)
				//blam(args, enclosingData ) - single enclosed
				//blam(argsSeg1, enclosingData, segment1: elif, argSeg1, enclosingData1, segment2:else, argsSeg2,enclosingData2, etc.. ) - segmentEnclosed
				//if we defined it...then use that function
				if (cmd.helperEvaluate && $.isFunction(cmd.helperEvaluate)){
					extraData._helpers[cmd.cmd] = cmd.helperEvaluate
				//else we will make it automatically
				}else if(cmd.helperEvaluate && $.isString(cmd.helperEvaluate)){
					//do some crap
				}else{	
					extraData._helpers[cmd.cmd] =function(){
						//instantiate extraData._helperArgs
						extraData._helperArgs = []

						var text = ""
						arguments[0] = 	arguments[0] || ""
						arguments[1] = 	arguments[1] || ""
						arguments[2] = 	arguments[2] || ""

						for (var x=0; x<arguments.length; x++){
							extraData._helperArgs.push(arguments[x])
						}
						//here we should check to see if arguments is/contains another helper..
						//.....
						text += "{{"+cmd.cmd+" _helperArgs.0}}"
						//check if endCmd and no segments
						if (cmd.endCmd && (cmd.extraSegments == undefined || cmd.extraSegments == false)){
							text += arguments[1]
						}else if (cmd.endCmd && cmd.extraSegments){
							//has segments lets check each argument and make a thing for it	
							
							//enclosingData
							text += arguments[2]
							for (var x=3; x<arguments.length; x+=3){
								//ex: 3. segmentName
								if (cmd.extraSegments.split().indexOf(x.trim())!=-1){
									//args
									arguments[x+1] = arguments[x+1] || ""
									//enclosing data
									arguments[x+2] = arguments[x+2] || ""
									text += "{{"+x.trim()+" "+arguments[x+1]+"}}"
									text += (arguments[x+2]) 
								}
							}
							

						}
						if (cmd.endCmd){
							//end tag
							text+= "{{"+cmd.endCmd+"}}"
						}
						_log(extraData._helperArgs)
						_log(("text from "+cmd.cmd+":"),text)
						//check if segments

						var RET =  that.simpleTmplParser(text, obj, extraData,true )
						//delete extraData._helperArgs
						return RET
					}
				}
				
			})

			//1: cmdStr, 2:cmdText
			var commandRegex = /\{\{\s*([^\}\s]+)\s*([^\}]+)*\s*\}\}/
			var hbRegex = /\{\{\s*(.+)\s*\}\}/
			var noMoreCommands = false
			var commandMatch 
			var newText = text

			//escape brackets
			obj = toggleEscapeBracketsinObj(obj, "escape")
			while (noMoreCommands == false){
				noMoreCommands = true
				
					if (commandMatch = commandRegex.exec(text)){
						_log("m[1] = "+commandMatch[1])
						if (commandMatch){
							var cmdFound = false
							var RESULT = ""
							var parseData
							$.each(newCommands, function(k,cmd){
								_log(cmd.cmd + " = " + commandMatch[1] + "?")
								//found a handlebar and a command
								
								if ((cmd.cmd.trim())==commandMatch[1] && cmdFound == false){
									_log("read as a cmd?")
									
									parseData = parseCmd(text, cmd)
									_log("\n-----\n")
									_log(parseData)
									
									RESULT = that.simpleTmplParser(cmd.evaluate(parseData),obj,extraData,true)
								
									
									_log("new text\n-----\n"+text+"\n---end new text--\n")
									
									cmdFound = true
									noMoreCommands = false
								}
								
							}) //<-- END COMMAND FINDER
							

							//no command found (is it a variable?)
							//else ignore it and remove it
							if (cmdFound == false){
								parseData = {
									positions: {
										start: {
											inclusive: commandMatch.index
										},
										end: {
											inclusive:  commandMatch.index+commandMatch[0].length
										}
									}
								}
								var insides = hbRegex.exec(commandMatch[0])
								_log("BAMBAM INSIDES:", insides, "current RESULT:", RESULT)
								//is it a variable?
								if (getVar(insides[1])!=undefined && getVar(insides[1])!=false){
										_log("BAMBAM: read as a variable? '"+getVar(insides[1])+"'")
										RESULT = getVar(insides[1])
								}//try returning the text
								 else{
								 		try{
								 			_log("BAMBAM:",extraData,insides[1]," = ",swapForTrueVars(insides[1]))
								 		 	RESULT = (resolveStrToVal(insides[1]))
								 		 	_log("BAMBAM RES-->:",RESULT)
								 		}catch(e){
								 			for (var prop in e) 
										    {  
										       vDebug += "property: "+ prop+ " value: ["+ err[prop]+ "]\n"; 
										    } 
											_log("unknown cmd. stripping..")
											
											_log("Parse Exception  --> "+e)
											_log("Stack:",e.stack)
										}	
								}
								noMoreCommands = false
									
							}
							_log("woop")
							text  = text.slice(0, parseData.positions.start.inclusive)+
							RESULT+
							text.slice(parseData.positions.end.inclusive)
							
						}
						
						
					}

				/*
				_log("new round..with ",text)
				$.each(commands, function(cmdName, cmdObj){
					if (commandMatch = cmdObj.regex.exec(text)){
						_log("command found..",cmdName,commandMatch)
						_log("current extraFields",extraData)
						text = text.replace(cmdObj.regex, cmdObj.evaluate(commandMatch))
						_log("replacing ",cmdObj.regex," with ", cmdObj.evaluate(commandMatch),"new text:",text)
						noMoreCommands = false
					}
				})
				*/
				if (noMoreCommands==true){
						if (!intermParse){
							text = toggleEscapeBracketsinObj(text, "unescape")
						}
						return text
				}
			}

		
	} //<-- END SOULPATCH

	$(document).ready(function(){
		that.init(opts)
	})

	
}


//polyfill
if (!String.prototype.startsWith) {
    String.prototype.startsWith = function(searchString, position){
      position = position || 0;
      return this.substr(position, searchString.length) === searchString;
  };
}



//polyfill for watch
"use strict";(function(t){"object"===typeof exports?module.exports=t():"function"===typeof define&&define.amd?define(t):(window.WatchJS=t(),window.watch=window.WatchJS.watch,window.unwatch=window.WatchJS.unwatch,window.callWatchers=window.WatchJS.callWatchers)})(function(){function t(){u=null;for(var a=0;a<v.length;a++)v[a]();v.length=0}var k={noMore:!1,useDirtyCheck:!1},p=[],l=[],w=[],C=!1;try{C=Object.defineProperty&&Object.defineProperty({},"x",{})}catch(Y){}var x=function(a){var b={};return a&&"[object Function]"==b.toString.call(a)},g=function(a){return"[object Array]"===Object.prototype.toString.call(a)},y=function(a){return"[object Object]"==={}.toString.apply(a)},H=function(a,b){var c=[],d=[];if("string"!=typeof a&&"string"!=typeof b){if(g(a))for(var e=0;e<a.length;e++)void 0===b[e]&&c.push(e);else for(e in a)a.hasOwnProperty(e)&&void 0===b[e]&&c.push(e);if(g(b))for(var f=0;f<b.length;f++)void 0===a[f]&&d.push(f);else for(f in b)b.hasOwnProperty(f)&&void 0===a[f]&&d.push(f)}return{added:c,removed:d}},q=function(a){if(null==a||"object"!=typeof a)return a;var b=a.constructor(),c;for(c in a)b[c]=a[c];return b},R=function(a,b,c,d){try{Object.observe(a,function(a){a.forEach(function(a){a.name===b&&d(a.object[a.name])})})}catch(e){try{Object.defineProperty(a,b,{get:c,set:function(a){d.call(this,a,!0)},enumerable:!0,configurable:!0})}catch(f){try{Object.prototype.__defineGetter__.call(a,b,c),Object.prototype.__defineSetter__.call(a,b,function(a){d.call(this,a,!0)})}catch(h){I(a,b,d)}}}},J=function(a,b,c){try{Object.defineProperty(a,b,{enumerable:!1,configurable:!0,writable:!1,value:c})}catch(d){a[b]=c}},I=function(a,b,c){l[l.length]={prop:b,object:a,orig:q(a[b]),callback:c}},n=function(a,b,c,d){if("string"!=typeof a&&(a instanceof Object||g(a))){if(g(a)){if(K(a,"__watchall__",b,c),void 0===c||0<c)for(var e=0;e<a.length;e++)n(a[e],b,c,d)}else{var f=[];for(e in a)"$val"==e||!C&&"watchers"===e||Object.prototype.hasOwnProperty.call(a,e)&&f.push(e);B(a,f,b,c,d)}d&&L(a,"$$watchlengthsubjectroot",b,c)}},B=function(a,b,c,d,e){if("string"!=typeof a&&(a instanceof Object||g(a)))for(var f=0;f<b.length;f++)D(a,b[f],c,d,e)},D=function(a,b,c,d,e){"string"!=typeof a&&(a instanceof Object||g(a))&&!x(a[b])&&(null!=a[b]&&(void 0===d||0<d)&&n(a[b],c,void 0!==d?d-1:d),K(a,b,c,d),e&&(void 0===d||0<d)&&L(a,b,c,d))},S=function(a,b){if(!(a instanceof String)&&(a instanceof Object||g(a)))if(g(a)){for(var c=["__watchall__"],d=0;d<a.length;d++)c.push(d);E(a,c,b)}else{var e=function(a){var c=[],d;for(d in a)a.hasOwnProperty(d)&&(a[d]instanceof Object?e(a[d]):c.push(d));E(a,c,b)};e(a)}},E=function(a,b,c){for(var d in b)b.hasOwnProperty(d)&&M(a,b[d],c)},v=[],u=null,N=function(){u||(u=setTimeout(t));return u},O=function(a){null==u&&N();v[v.length]=a},F=function(a,b,c,d){var e=null,f=-1,h=g(a);n(a,function(d,c,r,m){var g=N();f!==g&&(f=g,e={type:"update"},e.value=a,e.splices=null,O(function(){b.call(this,e);e=null}));if(h&&a===this&&null!==e){if("pop"===c||"shift"===c)r=[],m=[m];else if("push"===c||"unshift"===c)r=[r],m=[];else if("splice"!==c)return;e.splices||(e.splices=[]);e.splices[e.splices.length]={index:d,deleteCount:m?m.length:0,addedCount:r?r.length:0,added:r,deleted:m}}},1==c?void 0:0,d)},T=function(a,b,c,d,e){a&&b&&(D(a,b,function(a,b,A,k){a={type:"update"};a.value=A;a.oldvalue=k;(d&&y(A)||g(A))&&F(A,c,d,e);c.call(this,a)},0),(d&&y(a[b])||g(a[b]))&&F(a[b],c,d,e))},K=function(a,b,c,d){var e=!1,f=g(a);a.watchers||(J(a,"watchers",{}),f&&U(a,function(c,e,f,h){P(a,c,e,f,h);if(0!==d&&f&&(y(f)||g(f))){var k,l;c=a.watchers[b];if(h=a.watchers.__watchall__)c=c?c.concat(h):h;l=c?c.length:0;for(h=0;h<l;h++)if("splice"!==e)n(f,c[h],void 0===d?d:d-1);else for(k=0;k<f.length;k++)n(f[k],c[h],void 0===d?d:d-1)}}));a.watchers[b]||(a.watchers[b]=[],f||(e=!0));for(f=0;f<a.watchers[b].length;f++)if(a.watchers[b][f]===c)return;a.watchers[b].push(c);if(e){var h=a[b];c=function(){return h};e=function(c,e){var f=h;h=c;if(0!==d&&a[b]&&(y(a[b])||g(a[b]))&&!a[b].watchers){var m,l=a.watchers[b].length;for(m=0;m<l;m++)n(a[b],a.watchers[b][m],void 0===d?d:d-1)}a.watchers&&(a.watchers.__wjs_suspend__||a.watchers["__wjs_suspend__"+b])?V(a,b):k.noMore||f===c||(e?P(a,b,"set",c,f):z(a,b,"set",c,f),k.noMore=!1)};k.useDirtyCheck?I(a,b,e):R(a,b,c,e)}},z=function(a,b,c,d,e){if(void 0!==b){var f,h=a.watchers[b];if(f=a.watchers.__watchall__)h=h?h.concat(f):f;f=h?h.length:0;for(var g=0;g<f;g++)h[g].call(a,b,c,d,e)}else for(b in a)a.hasOwnProperty(b)&&z(a,b,c,d,e)},Q="pop push reverse shift sort slice unshift splice".split(" "),W=function(a,b,c,d){J(a,c,function(){var e=0,f,h,g;if("splice"===c){g=arguments[0];h=a.slice(g,g+arguments[1]);f=[];for(e=2;e<arguments.length;e++)f[e-2]=arguments[e];e=g}else f=0<arguments.length?arguments[0]:void 0;g=b.apply(a,arguments);"slice"!==c&&("pop"===c?(h=g,e=a.length):"push"===c?e=a.length-1:"shift"===c?h=g:"unshift"!==c&&void 0===f&&(f=g),d.call(a,e,c,f,h));return g})},U=function(a,b){if(x(b)&&a&&!(a instanceof String)&&g(a))for(var c=Q.length,d;c--;)d=Q[c],W(a,a[d],d,b)},M=function(a,b,c){if(void 0===c&&a.watchers[b])delete a.watchers[b];else for(var d=0;d<a.watchers[b].length;d++)a.watchers[b][d]==c&&a.watchers[b].splice(d,1);for(d=0;d<p.length;d++){var e=p[d];e.obj==a&&e.prop==b&&e.watcher==c&&p.splice(d,1)}for(c=0;c<l.length;c++)d=l[c],e=d.object.watchers,(d=d.object==a&&d.prop==b&&e&&(!e[b]||0==e[b].length))&&l.splice(c,1)},V=function(a,b){O(function(){delete a.watchers.__wjs_suspend__;delete a.watchers["__wjs_suspend__"+b]})},G=null,P=function(a,b,c,d,e){w[w.length]={obj:a,prop:b,mode:c,newval:d,oldval:e};null===G&&(G=setTimeout(X))},X=function(){var a=null;G=null;for(var b=0;b<w.length;b++)a=w[b],z(a.obj,a.prop,a.mode,a.newval,a.oldval);a&&(w=[])},L=function(a,b,c,d){var e;e="$$watchlengthsubjectroot"===b?q(a):q(a[b]);p.push({obj:a,prop:b,actual:e,watcher:c,level:d})};setInterval(function(){for(var a=0;a<p.length;a++){var b=p[a];if("$$watchlengthsubjectroot"===b.prop){var c=H(b.obj,b.actual);if(c.added.length||c.removed.length)c.added.length&&B(b.obj,c.added,b.watcher,b.level-1,!0),b.watcher.call(b.obj,"root","differentattr",c,b.actual);b.actual=q(b.obj)}else{c=H(b.obj[b.prop],b.actual);if(c.added.length||c.removed.length){if(c.added.length)for(var d=0;d<b.obj.watchers[b.prop].length;d++)B(b.obj[b.prop],c.added,b.obj.watchers[b.prop][d],b.level-1,!0);z(b.obj,b.prop,"differentattr",c,b.actual)}b.actual=q(b.obj[b.prop])}}for(a in l){var b=l[a],c=b.object[b.prop],d=b.orig,e=c,f=void 0,g=!0;if(d!==e)if(y(d))for(f in d){if((C||"watchers"!==f)&&d[f]!==e[f]){g=!1;break}}else g=!1;g||(b.orig=q(c),b.callback(c))}},50);k.watch=function(){x(arguments[1])?n.apply(this,arguments):g(arguments[1])?B.apply(this,arguments):D.apply(this,arguments)};k.unwatch=function(){x(arguments[1])?S.apply(this,arguments):g(arguments[1])?E.apply(this,arguments):M.apply(this,arguments)};k.callWatchers=z;k.suspend=function(a,b){a.watchers&&(a.watchers["__wjs_suspend__"+(void 0!==b?b:"")]=!0)};k.onChange=function(){(x(arguments[2])?T:F).apply(this,arguments)};return k});

