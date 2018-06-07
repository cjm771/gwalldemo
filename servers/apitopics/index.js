/***********
G related queries server api 
***********/
/*
 * A node api server for related queries since hot topics doesnt work v well. query like so:
 * http://localhost:3005/?keyword=seattle&startTime=2017-01-21&endTime=2017-01-21
 *
 * Copyright Chris Malcolm, NBBJ digital 2018
 * http://www.nbbj.com/about/digital-practice/
 *
 */


const googleTrends	 = require('google-trends-api');
const express = require('express');
const app = express();
//interest by region

app.get('/', (req, res) => {


	googleTrends.relatedTopics({
	keyword: req.query.keyword,
	startTime: new Date(req.query.startTime),
	endTime: new Date(req.query.endTime)
	})
	.then((results) => {
	  res.send(JSON.stringify({
	  	"status": "success",
	  	"data": JSON.parse(results).default.rankedList[0].rankedKeyword.map((v) => { return v.topic})
	  }));
	})
	.catch((err) => {
		console.log("req query parameters:",req.query)
	   res.send(JSON.stringify({
	  	"status": "error",
	  	"message": err
	  }));
	})

})



app.listen(3005, () => console.log('Example app listening on port 3005!'))