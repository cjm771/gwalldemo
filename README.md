GWALL DEMO
==========
v. 0.49.5
----------
A demo for G wall

![preview](https://i.imgur.com/gMKk4nqg.jpg)

Current Features
-----------------
	- supports both up and down animation styles (down is currently set)
	- G trends interaction via control panel
	- Edit date, keyword to recieve information on regional, overall popularity, + category popularity breakdown
	- Change color pallette for warm + cool color tones.
	- Zoom + pan on viewport
	- wall color pallete changes based on overall popularity
	- regional integration (to affect bar lengths)
	- category integration (to affect tonal changes)
	- change date based on clicking on graph 
	- hot topics per category? using a seperate endpoint (launch a node server from )
	- downloadable screen captures to pdf
	- Parallax effect (bars go at different speeds)
Todo
----

	x test states:
		state: 01
			- 2018-04-12, 78
			- 2018-04-13, 82
		state: 02
			- 2018-05-08, 88
			- 2018-05-09, 94
		state: 03
			- 2018-06-23, 90
			- 2018-06-24, 100
		state: 04
			- 2018-03-14, 83
			- 2018-03-15, 100

	- replace images with svgs
	- UI
		- default colors in swatch bar?
		- zoom issues on Mac OS X? only on my end
		- interactive mobile app to draw on surface / recieve info
			- MOBILE APP
				- info and stuff disabled / cleared when wall is not live
				- wall indicator (is wall active)
				- send info to web and render it
				- pixelator, edit timeout / speedier drawing
			- SERVER
				- server active indicator?
				- copy url to clipboard

Change Log
-----------
	v0.49.5
	-----
	- using absolute state changes
	- speed revised
	- bar size now driven by states instead of country
	x dont change when last date exceeds current date (for graph clicking)
	
	v0.49.2
	-----
	- using absolute state changes

	v0.49
	-----
	x saving
		x saving export out fails (put a try statement)
		x cancel saving should restore button and stuff
		x overrides.txt, list of dates to ovverride + static-ify
		- speed changes fix..fractions break it

	v0.48
	-----
	- interactive mobile portion has been started
	- server included  (if endpoint dies, deploy site from server/gserver folder..listens to 3000 port, for web app..and also has TCP )

	v0.45
	-----
	- reset colors button
	- delta / speed states change overhaul
	- default speeds now accept fractional numbers 1.25, 1.5 for instance
	- saving indicator

	v0.40
	-----
	- day based on delta (WIP)
	- Parallax effect (bars go at different speeds)
	- brighter at tips of bar
	- reset zoom mode
	- fix export settings
	- pan in super zoom mode make more sensitive

	v0.38
	-----
	- date validation (turns red if invalid date format or beyond time)
	- added pause/play button
	- specific hot topics
		- using a seperate endpoint for actual topics goin on that day (if endpoint dies, deploy hottopics api from server/apitopics folder..listens to 3005 port)
	- metrics
		x clamp color from 60 to 100 for popularity (seattle is too popular too often)
		- reevaluate country value (too fine grain,, increased smallest bar size..)

	v0.35
	------
	- change date based on clicking on graph 
	- regional integration (to affect bar lengths)
	- category integration (to affect tonal changes)
	- category barchart
	- color pallete changes

	v0.25
	------
	- category integration (to affect tonal changes)
	- supports both up and down animation styles (down is currently set)