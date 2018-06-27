/***********
gwallDraw v0.25
***********/
/*
 * Web app for drawing and getting info from gwall.2	
 *
 * Copyright Chris Malcolm, NBBJ digital 2018
 * http://www.nbbj.com/about/digital-practice/
 *
 */

const gWallDraw = {
	data: { version: 0.25 },
	defaultRatio: {width: 440, height: 820, rows: 44, cols: 82},
	castle: false,

	sketchStartedAt: false,
	currentSketch: [],
	pxltr: false,
	init: function(){
		//initiate castle
		var that = this;
		console.log(that.rootController);
		this.castle = new Castle({
		      data: that.data,
		      controllers: {
		        "root" : that.rootController,
		        "info": that.infoController
		      }
		});
		//initiate ui
    	this.initializeUI()
	},
	initializeUI: function(){
	  //tabs stuff
      var that = this;
      $(".version").html("v"+this.data.version);
      $(window).on("hashchange", function(){
      	that.changeTabActive();
      });
      //first tab init
       $(window).trigger("hashchange");

      //handle resize
      $(window).on("resize", function(){
      	if (that.castle.currentController=="root"){
      			that.pxltrInit();
      	}else{
      	}
      });

	},
	getPath: function(){
		var ret = location.hash;
		return (ret.trim()=="" || ret.trim()=="#") ? "" : ret.slice(1).trim();
	},
	changeTabActive: function(){
		$("#tabs li").removeClass("active");
		var path = this.getPath().split("/")[0];
		console.log("path:", path);
		$("#tabs li a[href='#"+path.trim()+"']").parent().addClass("active");
	},
	pxltrInit: function(){
		var that = this;
		//get height of view port
  		var height = $("#container").outerHeight() - $("#menu").outerHeight()- $("#miniToolbar").outerHeight()-20;
  		//get width based on 440/820 ratio
  		var width = (this.defaultRatio.width/this.defaultRatio.height)*height;
 		//if width is larger..readjust
 		var buffer =20;
 		var controlWidth = $("#container").width()-buffer;
 		console.log(controlWidth);
 		//if width exceeds control width
 		console.log("width: ",width, "controlWidth: ", controlWidth);
 		if (width>controlWidth){
 			width = controlWidth;
 			height = (this.defaultRatio.height/this.defaultRatio.width)*width;
 		}
		if (this.pxltr){
			this.pxltr.clearBoard();
			$(this.pxltr.el).unwrap("#pxltr_wpr")
		}
		console.log("width: ",width, "height: ", height);
		//pixel width
		pixelSize = Math.floor(width/this.defaultRatio.rows);
		finalWidth  = this.defaultRatio.rows*pixelSize;
		finalHeight  = this.defaultRatio.cols*pixelSize;
		console.log("pixel size:",pixelSize, "finalWidth: ", finalWidth,"finalHeight: ", finalHeight );
		//reset it
		this.pxltr = new Pixelator({
			element: "#myCanvas",
		    width: finalWidth,
		    height: finalHeight,
		    pixelSize: pixelSize,
		    currentColor: "#fff",
		    gridBGCellColor: "#333",
		    onMouseDown: function(mode, pixel, pxltr){
		    	if (that.sketchStartedAt===false)
		    		that.sketchStartedAt = Date.now();
		    	that.appendToSketch(pixel, pxltr.opts.pixelSize);
		    },
		    onMouseMove: function(mode, pixel, pxltr){
		    	that.appendToSketch(pixel, pxltr.opts.pixelSize);
		    },
		    onMouseUp: function(mode, pixel, pxltr){
		    	that.appendToSketch(pixel, pxltr.opts.pixelSize);
		    }

		});
	},
	//get pixel coord depending on
	getRelativePixelCoords(pixel, pixelModule){
		return [Math.floor(pixel[0]/pixelModule), Math.floor(pixel[1]/pixelModule)];
	},
	alreadyAdded(pixel, pixelModule){
		for (var i=0; i<this.currentSketch.length;i++){
			if (JSON.stringify(this.getRelativePixelCoords(pixel, pixelModule))===JSON.stringify(this.currentSketch[i].coord)) {
				return true;
			}
		}
		return false;
	},
	//add pixel info
	appendToSketch(pixel, pixelModule){
		if (!this.alreadyAdded(pixel, pixelModule)){
			this.currentSketch.push({
				coord: this.getRelativePixelCoords(pixel, pixelModule),
				timestamp: Date.now()-this.sketchStartedAt
			});
		}
		console.log(this.currentSketch);
	},	
	rootController: function(data){

		this.afterLoad = function(data){
			console.log("woop woop!");
			gWallDraw.pxltrInit();
		     //handle clear canvas
		      $("#sendSketch").on("click", function(){
		      		//do something to server..socket.io?
		      		console.log("click");
		      		$.ajax({
		      			url: "/sendSketch",
		      			method: "POST",
		      			data: {sketch: JSON.stringify(gWallDraw.currentSketch)}
		      		})
		      		gWallDraw.sketchStartedAt = false;
		      		gWallDraw.currentSketch = [];
		      		gWallDraw.pxltr.clearBoard();
		      });
		      //handle clear canvas
		      $("#clearSketch").on("click", function(){
		      		gWallDraw.sketchStartedAt = false;
		      		gWallDraw.currentSketch = [];
		      		console.log("click2");
		      		gWallDraw.pxltr.clearBoard();
		      });
		}
	},
	infoController: function(data){

	}

}
$(function(){
	gWallDraw.init();
})
