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
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.io.UnsupportedEncodingException;
class GTrends{
  
    private String APIKEY = "***REMOVED***";
    private String ENDPOINT_PREFIX = "https://www.googleapis.com/trends/v1beta/";
    JSONObject jsonResp;
     Hashtable<String, Integer> CATEGORIES= new Hashtable();
    JSONArray mapData = new JSONArray(); //raw map data (last query)
    Hashtable<String, Country> countries = new Hashtable(); //refined country data hashtables key is country code (last query)
    JSONArray popularityData = new JSONArray(); //last query 
    float countryValue = 0;
    int countriesInvolved = 0;
    float[]  countryPopRange = new float[]{100,0};
    boolean waitingForResults = true;
    int currentDateValue = 0;
    int currentDateIndex = 0;
    //make sure these are all true before executing initial matrix
    int initPopQuery = 0;
    int initCatQuery = 0;
    int initRegionQuery = 0;
   Hashtable<String, Integer> categoryBreakdown = new Hashtable(); //last category breakdown
    
  
    
   public GTrends(){
       //load categories
       loadCategories();
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
      return total;
  
   }
   
   public void loadCategories(){
     CATEGORIES.put("Sports",20); //Sports
     CATEGORIES.put("Business",12); //Business
     CATEGORIES.put("Arts",3); //Arts
     CATEGORIES.put("Technology",5); //Sports
     CATEGORIES.put("RealEstate",29); //Real estate
     CATEGORIES.put("Social",14); //Social
     CATEGORIES.put("Politics", 19); //politics
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

  //generic query to google server
  //ex. query("graph", {terms: "seattle", restrictions.geo: "blah"});
   public JSONObject query(String endpoint_suffix, Hashtable params){
       String paramString = "";
       Set<String> keys = params.keySet();
       int count = 0;
        for (String key: keys){
          if (count!=0){
             paramString += "&";
          }
          paramString += key+"="+URLEncode(params.get(key).toString());
          count++;
        }
      String url = ENDPOINT_PREFIX+endpoint_suffix+"?"+paramString+"&key="+APIKEY;
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
    ex. https://www.googleapis.com/trends/v1beta/regions?restrictions.geo=US-CA&term=seattle&key=***REMOVED***
  
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
  
  public Hashtable<String, Integer> getCategoryBreakdown(final String term, final String regionRestriction, final String startDate,final String endDate, final String specificDay){
       JSONArray tmpData;  
       Hashtable<String, Integer> catBreakdown = new Hashtable();
      Set<String> keys = CATEGORIES.keySet();
      for (String key: keys){
       JSONObject results =  queryPopularity( term, CATEGORIES.get(key), regionRestriction, startDate,endDate, specificDay);
       if (results.getString("status")=="success"){
           tmpData = results.getJSONObject("data").getJSONArray("lines").getJSONObject(0).getJSONArray("points");
           catBreakdown.put(key, getDateValue(tmpData, specificDay, false));
       }
      }
      categoryBreakdown = catBreakdown;
      log(new Object[]{"cat breakdown boiii:", categoryBreakdown});
      return catBreakdown;
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
    ex. https://www.googleapis.com/trends/v1beta/graph?terms=seattle&restrictions.geo=US-WA&key=***REMOVED***
  
  */
     public JSONObject queryPopularity(final String term, final int category, final String regionRestriction, final String startDate,final String endDate, final String specificDay){
          JSONObject results = query("graph", new Hashtable<String, Object>(){
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
