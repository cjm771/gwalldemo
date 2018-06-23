GWALL DEMO
==========
v. 0.45
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
	- UI
		- zoom issues on Mac OS X
		- interactive mobile app to draw on surface / recieve info
			- server active indicator

Change Log
-----------
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