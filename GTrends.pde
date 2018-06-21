/***********
GTrends 
***********/
/*
 * a processing class for connecting to gtrends api
 *
 * Copyright Chris Malcolm, NBBJ digital 2018
 * http://www.nbbj.com/about/digital-practice/
 *
 */

import java.util.Hashtable;
import java.util.Arrays;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.io.UnsupportedEncodingException;
class GTrends{
  
    private String APIKEY = "[FILL IN APIKEY HERE]";
    private String ENDPOINT_PREFIX = "https://www.googleapis.com/trends/v1beta/"; //standard gapi
    private String RELATEDTOPICS_ENDPOINT ="https://gtrends-api-rpqxouujom.now.sh"; //related topics api, if dies replace with apitopics server..server/apitopics
    JSONObject jsonResp;
     boolean waitingForResults = true;
     Hashtable<String, String> CATEGORIES= new Hashtable();
    JSONArray mapData = new JSONArray(); //raw map data (last query)
    Hashtable<String, Country> countries = new Hashtable(); //refined country data hashtables key is country code (last query)
    //popularity metrics
    int[] popularityClamp = new int[]{60,100}; //clamp to determine when red stuff starts happening..so 60-100 would mean blue until 60%. than starts to get red
    JSONArray popularityData = new JSONArray(); //last query 
    int delta = 0; //delta from popularity of day before to popularity of today .. could be -30 or +10
    int currentDateValue = 0; //popularity number 0-100 (actual number)
    int prevDateValue = 0; //popularity numer 0-100 (of previous day)
    int clampedCurrentDateValue = 0; //clamped percentage (blue/red tone);
    int currentDateIndex = 0; //date index of month..
    //hot topics api metrics
    ArrayList<String> hotTopics = new ArrayList(); //store latest topcs based on month
    String[] hotTopicsBlacklist = new String[]{"Washington", "Seattle", "The Seattle Times", "The Times"}; //ignore the generic terms people be searchin.
    //country regional metrics
    float countryValue = 0; // value from 2 to 8. influences countryBarRange
    int countriesInvolved = 0;
    int[]  countryClamp = new int[]{2,8}; //clamp on calculated value..normally country value = 200-800
    float[]  countryPopRange = new float[]{100,0}; //min max domain of country popularity..set by query..could be 100-20 or 80-10...not used?
    int[] countryBarRange = new int[]{4,10};  //store bar lengths here..set by query WE USE THIS!
   

    //make sure these are all true before executing initial matrix
    int initPopQuery = 0;
    int initCatQuery = 0;
    int initRegionQuery = 0;
   Hashtable<String, Integer> categoryBreakdown = new Hashtable(); //last category breakdown
    
  
    
   public GTrends(){
     
       //load categories
       loadCategories();
   }
   
   public int getWorldPercentageInterest(){
       return ceil(map(countryValue, countryClamp[0],countryClamp[1],0,100)); 
   }
   public float calcCountryValue(){
     float total = 0;
       Set<String> keys = countries.keySet();
      for (String key: keys){  
          Country country = countries.get(key);
          if (!country.countryCode.equals("as")){
            countryPopRange[0] = min(countryPopRange[0], country.value);
            countryPopRange[1] = max(countryPopRange[1], country.value);
            if (!country.countryCode.equals("us")){
              total+=country.value;
              if (country.value>1){
                countriesInvolved++;
              
            }
          }
        }
      }
      countryValue = total;
      
      log(new Object[]{"orig country value:", countryValue});
      countryValue = floor(max(countryClamp[0]*100, min(countryClamp[1]*100, countryValue))/100); //we get a number from 2-8
      log(new Object[]{"new country value (2-8):", countryValue});
      //reverse numbers to get smaller bars for higher number
      int reverseCountryValue = (int)((countryClamp[0]+countryClamp[1])-countryValue);
      //bars for 8-->4 to 10, bars for 2 --> 1 --> 3
      
      countryBarRange = new int[]{ceil(reverseCountryValue*1.25), ceil(reverseCountryValue*2.25)};
      log(new Object[]{"country bar range:", countryBarRange});
      return total;
   }
   
   public void loadCategories(){
     CATEGORIES.put("1_Sports","Sports"); //Sports_1
     CATEGORIES.put("3_Social", "Police"); //politics + social_3
     CATEGORIES.put("5_Real Estate","Housing"); //Real estate_5
      
     CATEGORIES.put("2_Business","Business"); //Business_2
     CATEGORIES.put("4_Arts","Arts"); //Arts_4
    
   }
   
   String URLEncode(String string){
     String output = new String();
     try{
       byte[] input = string.getBytes("UTF-8");
       for(int i=0; i<input.length; i++){
         if(input[i]<0)
           output += '%' + hex(input[i]);
         else if(input[i]==32)
           output += '+';
         else
           output += char(input[i]);
       }
     }
     catch(UnsupportedEncodingException e){
       e.printStackTrace();
     }
     return output;
  }

  //generic query to specified server
  //ex.  "graph", {terms: "seattle", restrictions.geo: "blah"});
   public JSONObject query(String endpoint_suffix, Hashtable params){
       String paramString = "";
       String endpointServer = ENDPOINT_PREFIX+endpoint_suffix; //default google server..supply endpointServer in params hashtable to override...: )
       Set<String> keys = params.keySet();
       int count = 0;
        for (String key: keys){
        //if this is a special parameter ie endpoint, swapout
        if (key=="endpointServer"){
          endpointServer = (String)params.get(key);
        }else{
          //if not first param use the &
          if (count!=0){
             paramString += "&";
          }
          
          paramString += key+"="+URLEncode(params.get(key).toString());
          count++;
          }
      }
        
      String url = endpointServer+"?"+paramString+"&key="+APIKEY;
      //log(new Object[]{"final url to query:", url});
     try{
       return success(loadJSONObject(url));
     }catch (Exception e){
         return error(e.toString());
     }
   }
   
  //we got data, throw the result up
  public JSONObject success(JSONObject obj){
    JSONObject _success = new JSONObject();
    _success.setString("status", "success");
    _success.setJSONObject("data",obj);
    return _success;
  }
  
  //json throw an error
  public JSONObject error(String msg){
    JSONObject _error = new JSONObject();
    _error.setString("status", "error");
    _error.setString("message", msg);
    return _error;
  }

  /**** QUERY REGIONS **** 
  
   gets region code, name, and value..0 to 100
 
  
  ex.
    ...{
        regionCode: "NZ",
        regionName: "New Zealand",
        value: 6
    },
    {
        regionCode: "SG",
        regionName: "Singapore",
        value: 6
    },...
  
    start/end date format
    -----------------------
    date should follow YYYY-MM,e.g. 2010-01
    restrictions.startDate + restrictions.endDate
    
    region restrictions...(optional)...  
    -------------------------------------
    region code for countries: blank, returns countries
    region code for united states: "US", returns states
    region code for california: "US-CA, returns counties?
  
    //seattle term popularity in california
    ex. https://www.googleapis.com/trends/v1beta/regions?restrictions.geo=US-CA&term=seattle&key=[APIKEY]
  
  */
  
  //extract data from last query as hashtable 
  public Hashtable extractCountryValueData(){
       String regionCode, regionName;
       Float value;
       for (int key=0;  key<mapData.size(); key++){
          //contains regionCode, regionName, value
          regionCode = mapData.getJSONObject(key).getString("regionCode").toLowerCase();
          regionName = mapData.getJSONObject(key).getString("regionName");
          value = mapData.getJSONObject(key).getFloat("value");
          countries.put(regionCode, new Country(regionCode, regionName, value));
       }   
       //calculate an arbitrary value
       calcCountryValue();
       return countries;
     
   }

  //extract from our typical date format to googles.
  public int getDateValue(JSONArray popularityData, String dateString, boolean setMainData){
    String[] pieces = dateString.split("/");
    String toFind =  pieces[2]+"-"+pieces[0]+"-"+pieces[1];
    if (popularityData.size()>0){
      for (int key=0;  key<popularityData.size(); key++){
        if (popularityData.getJSONObject(key).getString("date").equals(toFind)){
          //store in our variables
          
          if (setMainData==true){
            currentDateValue = popularityData.getJSONObject(key).getInt("value");
            prevDateValue = (key-1>=0) ? popularityData.getJSONObject(key-1).getInt("value") : currentDateValue; //well..we'll have to query api again if its the 1st date of every month..so just return no delta for now
            delta = currentDateValue-prevDateValue;
            log(new Object[]{"delta bruh:", delta});
            //clamp
            clampedCurrentDateValue = (int)map(min(max(currentDateValue, popularityClamp[0]), popularityClamp[1]),popularityClamp[0], popularityClamp[1],0,100); //clamp to new range...than get new breakdown based on that
            currentDateIndex = key;
          }
          return popularityData.getJSONObject(key).getInt("value");
        }
      }
    }
    return -1;
  }
  
  //get all values just as a list.
  public int[] getDateValuesAsList(){
    int[] values = new int[popularityData.size()];
    if (popularityData.size()>0){
      for (int key=0;  key<popularityData.size(); key++){
         values[key] = popularityData.getJSONObject(key).getInt("value");
      }
    }
    return values;

  }
  
   //get all names just as a list.
  public String[] getDateStringsAsList(){
    String[] values = new String[popularityData.size()];
    if (popularityData.size()>0){
      for (int key=0;  key<popularityData.size(); key++){
         values[key] = popularityData.getJSONObject(key).getString("date");
         String[] pieces = values[key].split("-");
         values[key] = pieces[1]+"/"+pieces[2];
      }
    }
    return values;

  }
  
  public String generateMultipleTermsString(String[] terms){
    String finalStr = "";
    for (int i=0; i<terms.length; i++){
      if (i==0){
        finalStr+=URLEncode(terms[i]);
      }else{
        finalStr+="&terms="+URLEncode(terms[i]);
      }
    }
    return finalStr;
  }
  
  public Hashtable<String, Integer> getCategoryBreakdown(final String term, final String regionRestriction, final String startDate,final String endDate, final String specificDay){
       JSONArray tmpData;  
       Hashtable<String, Integer> catBreakdown = new Hashtable();
      Set<String> keys = CATEGORIES.keySet();
      
      //get categories as an array
      String[] termsArr = new String[CATEGORIES.size()];
      String[] keysArr = new String[CATEGORIES.size()];
      int count = 0;
      for (String key: keys){
        termsArr[count] = term+" "+CATEGORIES.get(key);
        keysArr[count] = key;
        count++;
      }
      
       JSONObject results =  graphQuery( generateMultipleTermsString(termsArr), -1, regionRestriction, startDate,endDate);
       if (results.getString("status")=="success"){
           for (int i=0; i<results.getJSONObject("data").getJSONArray("lines").size(); i++){
              tmpData = results.getJSONObject("data").getJSONArray("lines").getJSONObject(i).getJSONArray("points");
              catBreakdown.put(keysArr[i], getDateValue(tmpData, specificDay, false));
           }

       
      }
      categoryBreakdown = catBreakdown;
      return catBreakdown;
  }
  
   public float[] getCategoryRatiosAsArray(){
     
     Hashtable<String, Float> percentages = getCategoryPercentages();
     float[] result = new float[percentages.size()]; 
     Set<String> keys =  percentages.keySet();
     int count=0;
     for (String key: keys){
       result[count] = percentages.get(key)/100.0;
       count++;
     }
     return result;

  }
  
   public float[] getCategoryPercentagesAsArray(){
     
     Hashtable<String, Float> percentages = getCategoryPercentages();
     float[] result = new float[percentages.size()]; 
     Set<String> keys =  percentages.keySet();
     int count=0;
     for (String key: keys){
       result[count] = percentages.get(key);
       count++;
     }
     return result;

  }
  
  public Hashtable<String, Float> getCategoryPercentages(){
     Set<String> keys =  categoryBreakdown.keySet();
     Hashtable<String, Float> percentages = new Hashtable();
       float total = 0;
      for (String key: keys){
        total += categoryBreakdown.get(key);
      }
     for (String key: keys){
       percentages.put(key,(float) 100*(((float)categoryBreakdown.get(key))/total));
     }
     return percentages;

  }
  
  public JSONObject queryRegions(final String term, final String regionRestriction, final String startDate, final String endDate){
    JSONObject results = query("regions", new Hashtable<String, Object>(){
      { 
        put("term", term);
        put("restrictions.regionRestriction", regionRestriction);
        put("restrictions.startDate", startDate);
        put("restrictions.endDate", endDate);
      }
    });
    //just get the regions..remove additional object wrapper..if success of course
    if (results.getString("status")=="success"){
     // results.setJSONArray("data", results.getJSONObject("data").getJSONArray("regions"));
       //store raw json array
       mapData = results.getJSONObject("data").getJSONArray("regions");
       //store country data
       extractCountryValueData();
    }
    return results;
  }
  
  /**** QUERY POPULARITY **** 
  
   gets overall popularity of term from 0 to 100 for specified amount of months
  
  ex.
    lines: [
        {
        term: "seattle",
        points: [
        {
        date: "2004-01-01",
        value: 85
        },
        {
        date: "2004-02-01",
        value: 79
        },
      ]..
  
    start/end date format
    -----------------------
    date should follow YYYY-MM,e.g. 2010-01
    restrictions.startDate + restrictions.endDate
    
    region restrictions...(optional)...  
    -------------------------------------
    region code for countries: blank, returns countries
    region code for united states: "US", returns states
    region code for california: "US-CA, returns counties?
  
    //seattle search term popularity (in washington region)
    ex. https://www.googleapis.com/trends/v1beta/graph?terms=seattle&restrictions.geo=US-WA&key=[APIKEY]
  
  */
    //shorthand for graph query
    public  JSONObject graphQuery(final String term, final int category, final String regionRestriction, final String startDate,final String endDate){
     return query("graph", new Hashtable<String, Object>(){
          { 
            put("terms", term);
            if (category>0){
              put("restrictions.category", category);
            }
            put("restrictions.regionRestriction", regionRestriction);
            put("restrictions.startDate", startDate);
            put("restrictions.endDate", endDate);
          }
        });
    }
    
    //get top topics from google, while avoiding blacklisted (boring) terms
    public  JSONObject queryTopTopics(final String term,  final String startDate,final String endDate){
      JSONObject results =  query("topTopics", new Hashtable<String, Object>(){
          { 
            put("endpointServer", RELATEDTOPICS_ENDPOINT); //we use a different endpoint here
            put("keyword", term);
            put("startTime", startDate);
            put("endTime", endDate);
          }
        });
        if (results.getString("status")=="success"){
          //store latest in instance
            hotTopics.clear();
            JSONArray unfilteredTopics = results.getJSONObject("data").getJSONArray("data");
            for (int i=0; i<unfilteredTopics.size(); i++){
                JSONObject keywordObj = unfilteredTopics.getJSONObject(i);
                String title = keywordObj.getString("title");
                if (Arrays.asList(hotTopicsBlacklist).indexOf(title)==-1){
                  //if not in there add to array list
                  hotTopics.add(title);
                }
            }
        }
        return results;
        
    }
    
    //return hot topics as an array (its stored as an arraylist)
    public String[] getHotTopics(){
     return hotTopics.toArray(new String[hotTopics.size()]);
    }
  
     public JSONObject queryPopularity(final String term, final int category, final String regionRestriction, final String startDate,final String endDate, final String specificDay){
          JSONObject results = graphQuery(term, category, regionRestriction, startDate, endDate);
        
        //just get the regions..remove additional object wrapper..if success of course
        if (results.getString("status")=="success"){
         // results.setJSONArray("data", results.getJSONObject("data").getJSONArray("regions"));
           //store raw json array
           
  
           if (category<0){
              //this is generic all categories so store current day value info.. true flag for storing to main instance
             popularityData = results.getJSONObject("data").getJSONArray("lines").getJSONObject(0).getJSONArray("points");
             getDateValue(popularityData, specificDay, true);
           }
        }
    
      return results;
  }
}

class Country{
  String countryCode;
  String countryName;
  Float value;
  
  public Country(String _countryCode, String _countryName, Float _value){
      countryCode = _countryCode.toLowerCase();
      countryName = _countryName;
      value = _value;
  }
}
