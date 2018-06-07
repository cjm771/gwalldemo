GWALL DEMO
==========
v. 0.38
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

Todo
----

	- Visuals
		- regional integration
			- similar tactic to look at month before delta
		- look day before look delta
			- 15-30 , 0 - 100
				- 5 states
				- 0 - 10 NOTHING - cool colors
				- 10- 20 some blues
				- 20 - 30
		- Parallax effect (bars go at different speeds)
			- fix rebuild of bars before regeneration..since shifting up and down.
			- shifting bars has the possibility of leaving stale bars in rotation from frame_0 or etc..how to update to current trends once not visible?
		- brightness changes (at tip of bar)
	- UI
		
		- downloadable screen captures to svg/jpg/png
		- interactive mobile app to draw on surface

Change Log
-----------

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