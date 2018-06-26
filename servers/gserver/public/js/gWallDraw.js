const gWallDraw = {
	data: {},
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
      $(window).on("hashchange", function(){
      	that.changeTabActive();
      });
      //first tab init
      that.changeTabActive();
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
		$("#tabs li a[href='#"+path+"']").parent().addClass("active");
	},
	pxltrInit: function(){
		var that = this;
		//get height of view port
  		var height = $("#container").height() - $("#menu").height()- $("#miniToolbar").height()-20;
  		//get width based on 440/820 ratio
  		var width = (this.defaultRatio.width/this.defaultRatio.height)*height;
 
		if (this.pxltr){
			this.pxltr.clearBoard();
			$(this.pxltr.el).unwrap("#pxltr_wpr")
		}
		//reset it
		this.pxltr = new Pixelator({
			element: "#myCanvas",
		    width: width,
		    height: height,
		    pixelSize: width/this.defaultRatio.rows,
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
	//add pixel info
	appendToSketch(pixel, pixelModule){
		this.currentSketch.push({
			coord: this.getRelativePixelCoords(pixel, pixelModule),
			timestamp: Date.now()-this.sketchStartedAt
		});
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

gWallDraw.init();