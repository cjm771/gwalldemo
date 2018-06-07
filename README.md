GWALL DEMO
==========
v. 0.38
----------
A demo for G wall

![preview](https://i.imgur.com/3rtom4fr.png)

Current Features
-----------------
	- supports both up and down animation styles (down is currently set)
	- G trends interaction via control panel
	- Edit date, keyword to recieve information on regional, overall popularity, + category popularity breakdown
	- Change color pallette for warm + cool color tones.
	- Zoom + pan on viewport
	- wall color pallete changes based on overall popularity
	x regional integration (to affect bar lengths)
	x category integration (to affect tonal changes)
	x change date based on clicking on graph 
	x hot topics per category? using a seperate endpoint (launch a node server from )

Todo
----

	- Visuals
		- Parallax effect (bars go at different speeds)
		- brightness changes (at tip of bar)
	- UI
		- date validation (turns red if invalid date format or beyond time)
		- downloadable screen captures to svg/jpg/png
		- interactive mobile app to draw on surface

Change Log
-----------

	v0.38
	-----
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