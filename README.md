GWALL DEMO
==========
v. 0.40
----------
A demo for G wall

![preview](https://i.imgur.com/dSXLCKVg.png)

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
	- Visuals
		- look day before look delta
			- how does speed of animation correllate with delta
			- determine 3 states (min, middle, max) and they get reversed if + and -
				0-20 = [100,0], 0
				20-30 = [80,20], 20
				30-40 = [20,80],30
				40+ = [0,100],40
			- make it so different micro speeds ex. 0.25, 1.25 (basically fix jaggedyness)
				- 0.25 would be 25% of the time aka every 4th frame it would move the next one up..so 1 pixel extra 1/4 of the time. 1.25 would be 2 pixels 1/4 of the time.
		x brightness changes (at tip of bar)
	- UI
		- zoom issues on Mac OS X
		- resort categories
		- interactive mobile app to draw on surface / recieve info

Change Log
-----------
	v0.40
	-----
	- day based on delta (WIP)
	x Parallax effect (bars go at different speeds)
	- brighter at tips of bar
	x reset zoom mode
	x fix export settings
	x pan in super zoom mode make more sensitive

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