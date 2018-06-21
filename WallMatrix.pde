/***********
 Wall Matrix  
 ***********/
/*
 * stores current wall cell data...
 * currentMatrix is a hashtable represeenting the current frame, each cell is given an id for ex.
 * ex:
 * -----
 * [0,0] = top left
 * [82,44] = bottom right
 *
 * Copyright Chris Malcolm, NBBJ digital 2018
 * http://www.nbbj.com/about/digital-practice/
 *
 */

import java.util.Hashtable;
import java.util.Set;
import java.util.Random;
import java.util.Arrays;


class WallMatrix {

  //currentMatrix 
  Hashtable<String, MatrixCell> currentMatrix = new Hashtable();
  //bounds 
  int totalRows, totalColumns;
  //settings
  int[] lengthRange;
  int matrixId = 0; //deckId to pair with vertical bar id..incrementall grows
  int[] randSpeeds;
  float popularityFactor = 0; //0.0-1.0 number representing popularity
  float[] catBreakdown;
  color[] cr, crHot;
  //color states are the possible states
  float[][] colorStates = new float[][]{
    new float[]{0,   1.0}, //delta @ +5 = 100% blue, @ -5 = 0% red
    new float[]{20,  0.8}, //delta @ +20 = 80% blue, @ -20 = - additional 20% red
    new float[]{30,  0.2}, //delta @ +30 = 20% blue, @ -30 = - additonal 40% red
    new float[]{40,  0.0} //delta @ +40 =  0% blue,  @ -40 = - additional 100% red
  };
    
  String ANIMATION_MODE = "down"; //up or down..animation mode


  // generateColorRange(c1, c2, steps): generates color array based on 2 colors and steps
  private color[] generateColorRange(color c1, color c2, int steps) {
    color[] colorArr = new color[steps];
    for (int i=0; i<steps; i++) {
      //generate 
      int[] rgbVals = new int[]{
        (int)(red(c1)+((red(c2)-red(c1))/steps)*i), 
        (int)(green(c1)+((green(c2)-green(c1))/steps)*i), 
        (int)(blue(c1)+((blue(c2)-blue(c1))/steps)*i)};
      colorArr[i] =  color(rgbVals[0], rgbVals[1], rgbVals[2]);
    }
    return colorArr;
  }
  //generateMatrix(lengthRange, catBreakdown, colorRange, colorRangeHot): generates a new matrix
  //ex generateMatrix([1,2], [15%,10%,40%,..], [color(1,2,3), color(1,2,5)], [color(2,4,6), color(2,4,5)])
  public Hashtable generateMatrix(Hashtable Matrix) {
    Hashtable<String, MatrixCell> tmpMatrix = Matrix;
    //log(new Object[]{"length range: ", lengthRange, "catBreakdown: ", catBreakdown});
    // log(new Object[]{"cr: ", cr, "crHot: ", crHot});
    int steps = catBreakdown.length;
    color[] colorRangeCool = generateColorRange(cr[0], cr[1], steps);
    int verticalBarId = 0;
    int maxIters = 9000;
    int count=0;
   
    while (!matrixIsFull(tmpMatrix) && count<maxIters) {
     
      //first fill with random amounts until full
      for (int ci=0; ci<totalColumns; ci++) {
        if (!columnIsFull(tmpMatrix, ci)) {
          //get color and number
          tmpMatrix = insertVerticalBarAtColIndex(tmpMatrix, ci, createBarId(matrixId, verticalBarId),(int)random(colorRangeCool.length), (int)random(lengthRange[0], lengthRange[1]+1));
           
        //log(new Object[]{"matrix:\n",tmpMatrix,"\n\n"});
          verticalBarId++;
        }
      }
      count++;
    }
    //log(new Object[]{"total bars:", getBarIdsByMatrixId(tmpMatrix, matrixId).length,"\n", getBarIdsByMatrixId(tmpMatrix, matrixId)});
    
    //TODO: get count of bars for newly generated matrix id 
    //Object[] distroTest = getListByDistributionBreakdown(new Object[]{0,1}, 21, new float[]{.7,.3}); 
    //log(new Object[]{"you got it dawggg...", distroTest});
    //then .. run various distribution routines for cells, and apply coloration + tones, than return that damn matrix
    
    tmpMatrix = reColorizeMatrix(tmpMatrix);
   
    
    return tmpMatrix;
    
  }
  
  //this looks at any unseen bars + recolorizes them before they start to appear given the latest id..
  public Hashtable reColorizeMatrix(Hashtable tmpMatrix){
    
    //before we setwarmcool, lets reId the bars that are not visible currently to the current verticalBarId
    tmpMatrix = reIdUnseenBars(tmpMatrix);
    //apply warmcoolfactor to current new matrix ids.
    tmpMatrix = setWarmCool(tmpMatrix, matrixId);
    //apply category tones
    tmpMatrix = setCatTones(tmpMatrix, matrixId);
     matrixId++;
    return tmpMatrix;
  }
  
  public boolean isStartOfBar(Hashtable matrix, int rowIndex, int colIndex){
   String tmpId = getIdStr(rowIndex,colIndex);
    if (matrix.containsKey(tmpId)){
        MatrixCell cell = (MatrixCell)matrix.get(tmpId);
        if (cell.pixelId==0){
           return true;
        }else{
          return false;
        }
    }else{
      return false;
    }
  }
  
  public Hashtable updateMatrixId(Hashtable matrix, int rowIndex, int colIndex, int matrixId){
        String tmpId;
        MatrixCell tmpCell;
       //then update this cell
       tmpId = getIdStr(rowIndex, colIndex);
       tmpCell = (MatrixCell)matrix.get(tmpId);
       //log(new Object[]{"id change:", tmpCell.verticalBarId, "--> ", matrixId});
       tmpCell.verticalBarId = updateBarId(tmpCell.verticalBarId, matrixId);
       //log(new Object[]{"id change (new):", tmpCell.verticalBarId});
       matrix.put(tmpId, tmpCell);
       return matrix;
  }
  
  public Hashtable reIdUnseenBars(Hashtable matrix){
     //first check the first unseen row, less than -1 for down, totalRows for up
        int firstUnseenRow;
      
       if (ANIMATION_MODE.equals("up")){
         firstUnseenRow = totalRows; //up routine
       }else{
          firstUnseenRow = -1; //down routine
       }
      
       //go through each column and get first bar that is unseen...aka first cell where pixelId==0..that is start of a vertical bar
       //...once there, any other rows beyond..we should change id to current vertical bar
       for (int colIndex=0; colIndex<totalColumns; colIndex++){
         int[] rowDomain = getRowDomain(matrix, colIndex);
         boolean firstBarFound = false;
        
         if (ANIMATION_MODE.equals("up")){
             //up routine
             for (int rowIndex = firstUnseenRow; rowIndex<=rowDomain[1]; rowIndex++){
               if (firstBarFound==false){
                 if (isStartOfBar(matrix, rowIndex,colIndex)){
                   firstBarFound = true;
                   log(new Object[]{"!!!!!!!!!!!!!!!!first unseen is :", rowIndex});
                 }
               }
               
               if (firstBarFound){
                 log(new Object[]{"updating :", rowIndex, colIndex});
                matrix = updateMatrixId(matrix, rowIndex, colIndex, matrixId);
               }
             }
           
         }else{
             //down routine
            for (int rowIndex = firstUnseenRow; rowIndex>=rowDomain[0]; rowIndex--){
              if (firstBarFound==false){
                 if (isStartOfBar(matrix, rowIndex, colIndex)){
                   firstBarFound = true;
                 }
               }
               
               if (firstBarFound){
                matrix = updateMatrixId(matrix, rowIndex, colIndex, matrixId);
               }
            }
         }
       }
       return matrix;
    
     
  }
  
  
  //rand int from bank of options
  public int[] randIntArr(int[] bank, int count){
    int[] result = new int[count];
    for (int i=0; i<count; i++){
      result[i] = bank[floor(random(0,bank.length))];
    }
    return result;
  }
  //get range
  public int[] range(int st, int end){
    int[] arr = new int[end+1-st];
    for (int i =0; i<end+1-st; i++){
      arr[i] = st+i;
    }
    return arr;
  }
  //set warm and cool given the currentMatrix and mId 
  public Hashtable<String, MatrixCell> setCatTones(Hashtable<String, MatrixCell> matrix, int mId){
    Set<String> keys = matrix.keySet();
    Hashtable<String, Object> barDictionary = getListByDistributionBreakdown(range(0,catBreakdown.length+1), getBarIdsByMatrixId(matrix, mId), catBreakdown);
    for (String key : keys) {
      MatrixCell cell = matrix.get(key);
      if (barDictionary.containsKey(cell.verticalBarId)){
          matrix.get(key).colorIndex = (int)barDictionary.get(cell.verticalBarId);
        }
    }
    return matrix;
  }
    
  
  //set warm and cool given the currentMatrix and mId 
  public Hashtable<String, MatrixCell> setWarmCool(Hashtable<String, MatrixCell> matrix, int mId){
      Set<String> keys = matrix.keySet();
    //look at states...and find it depending on delta
      float[] currState = new float[2];
      float[] currStateNext = new float[2];
      float ratio = 0;
      for (int i=0; i<colorStates.length; i++){
        currState = colorStates[i];
        currStateNext = (i+1!=colorStates.length) ? colorStates[i+1] : new float[]{100, 0}; //if last make a new one at 100
        log(new Object[]{"testing...",currState[0], "<",abs(gt.delta),"<",currStateNext[0]});
        //check if it exists in range..if so..get ratio
        if (currState[0]<=abs(gt.delta) && abs(gt.delta)<= currStateNext[0]){
          log(new Object[]{"winner!!"});
          ratio = currState[1];
        }
      }
      log(new Object[]{"ratio determined is: ",ratio}); 
      //determine ratio
      
      
      if (gt.delta<0){
        log(new Object[]{"reversing ratio..", ratio, "-->", (1-ratio)});
        ratio = 1-ratio; //reverse it then
      }
      
      
      Hashtable<String, Object> barDictionary = getListByDistributionBreakdown(new Object[]{false,true}, getBarIdsByMatrixId(matrix, mId), new float[]{ratio,1-ratio});
      //log(new Object[]{"bar dictionary:", barDictionary});
      for (String key : keys) {
        MatrixCell cell = matrix.get(key);
        if (barDictionary.containsKey(cell.verticalBarId)){
            matrix.get(key).isWarm = (boolean)barDictionary.get(cell.verticalBarId);
            
          }
      }
      return matrix;
  }
  
  public String updateBarId(String barId, int newMatrixId){
    return createBarId(newMatrixId, explodeBarId(barId)[1]); 
  }
  public int[] explodeBarId(String barId){
    String[] pieces = barId.split("_");
    return new int[]{Integer.parseInt(pieces[0]), Integer.parseInt(pieces[1])};
  }
  public String createBarId(int mId, int bId){
    return mId+"_"+bId;
  }

  //count amount of bars in the matrix
  public String[] getBarIds(Hashtable<String, MatrixCell> matrix) {
    ArrayList<String> uniqueIds = new ArrayList();
    Set<String> keys = matrix.keySet();
    MatrixCell tmpCell;
    for (String key : keys) {
      tmpCell = matrix.get(key);
      if (uniqueIds.indexOf(tmpCell.verticalBarId)==-1){
        uniqueIds.add(tmpCell.verticalBarId);
      }
    }
    String[] newArr = uniqueIds.toArray(new String[uniqueIds.size()]);
     Arrays.sort(newArr);
     return newArr;
  }
  
  public String[] getBarIdsByMatrixId(Hashtable<String, MatrixCell> matrix, int mId){
     ArrayList<String> filteredIds = new ArrayList();
    String[] uniqueBars = getBarIds(matrix);
    for (int i=0; i<uniqueBars.length; i++){
     if (explodeBarId(uniqueBars[i])[0]==mId){
       filteredIds.add(uniqueBars[i]);
     }
    }
    String[] newArr = filteredIds.toArray(new String[filteredIds.size()]);
    return newArr;
  }



  //get random hashtable of items(indices) given an amount needed and disribution ratio breakdown
  public Hashtable<String, Object> getListByDistributionBreakdown(Object[] items, String[] keys, float[] distribution) {
    Hashtable<String,Object> hashtable = new Hashtable();
    ArrayList<Object> list = new ArrayList();
    for (int i=0; i<distribution.length; i++){
      for (int j=0; j<distribution[i]*(float)keys.length; j++){
        list.add(items[i]);
      }
    }
    Object[] tmpArr  = shuffle(list.toArray(new Object[list.size()]));
    for (int i=0; i< keys.length; i++){
      hashtable.put(keys[i], tmpArr[i]);
    }
    return hashtable;
  }
    //overload for ints
    public Hashtable<String, Object> getListByDistributionBreakdown(int[] items, String[] keys, float[] distribution) {
      Object[] objArr = new Object[items.length];
      for (int i=0; i<items.length; i++){
        objArr[i] = items[i];
      }
      return getListByDistributionBreakdown(objArr, keys, distribution);
    }
  
  public Object[] shuffle(Object[] array){
    Random rgen = new Random();  // Random number generator      
 
    for (int i=0; i<array.length; i++) {
        int randomPosition = rgen.nextInt(array.length);
        Object temp = array[i];
        array[i] = array[randomPosition];
        array[randomPosition] = temp;
    }
 
    return array;
  }

  //prettyprint wall matrix
  public String prettyPrint() {
    String resStr = "";
    for (int i =0; i<totalColumns; i++) {
      for (int j=0; j<totalRows; j++) {
        if (cellExists(getIdStr(j, i))) {
          resStr+=".  ";
        } else {
          resStr+="#  ";
        }
      }
      resStr+="\n";
    }
    return resStr;
  }

  //basis for inserting a cell
  private Hashtable insertCell(
      Hashtable matrix, //matrix
      int rowIndex, //row to add to bar to 
      int colIndex, //col to add to
      int pixelIndex, //pixel to add to 
      int colorIndex, //colorIndex
      int pixelLength, //pixelLength
      boolean isWarm, //warm or cool tone
      String verticalBarId //vertical bar id
   ){
    //we build the pixel up
    int modifier;
    if (ANIMATION_MODE.equals("up")) { //going up
      modifier = 1; //we're building the bar upstream (index wise)
    } else {
      modifier = -1; //we're building the bar downstream (index wise)
    }
     //log(new Object[]{"key exists?", matrix.containsKey(getIdStr(rowIndex+(pixelIndex*modifier), colIndex))});
     matrix.put(getIdStr(rowIndex+(pixelIndex*modifier), colIndex), new MatrixCell(
      colorIndex, 
      pixelLength,
      pixelIndex,
      isWarm, 
      verticalBarId
      ));
      return matrix;
  }
  
  
  private Hashtable insertVerticalBarAtColIndex(Hashtable matrix,  int colIndex,String verticalBarId, int colorIndex, int pixelLength) {
    //insert random bar at last empty spot
    int nextIndex = getNextEmpty(matrix, colIndex);
   // log(new Object[]{"next index:",nextIndex});
    if (nextIndex==-1) {
      log(new Object[]{"safety net issue! column:", colIndex, "next index:", nextIndex});
    }
    

    for (int i =0; i<pixelLength; i++) {
      /*
      matrix.put(getIdStr(nextIndex+(i*modifier), colIndex), new MatrixCell(
      colorIndex, 
      pixelLength,
      i,
      false, 
      verticalBarId
      ));
      */
      //insert cell given a row + bar pixel index
      matrix = insertCell(matrix, nextIndex, colIndex, i, colorIndex, pixelLength, false,verticalBarId);
    }

    return matrix;
    
  }

  //turns row + col into an id for hash table
  private String getIdStr(int row, int col) {
    return str(row)+":"+str(col);
  }

    public int[] parseIdStrToIntArr(String idStr) {
    int[] idArr = new int[2];
    String[] pieces = idStr.split(":");
    for (int i = 0; i<pieces.length; i++) {
      idArr[i] = Integer.parseInt(pieces[i]);
    }
    return idArr;
  }

  //matrixIsFull(matrix): test if all columns have reached capacity
  private boolean matrixIsFull(Hashtable matrix) {
    boolean isFull = true;
    int start, end;
    start = 0;
    end= totalColumns;
    for (int i =start; i<end; i++) {
      if (!columnIsFull(matrix, i)) {
        isFull = false;
      }
    }
    return isFull;
  }

  //columnIsFull(matrix, colIndex)
  private boolean columnIsFull(Hashtable matrix, int colIndex) {
  
    //determine last row , based on shifting mode.
    int lastRowIndex;
    if (ANIMATION_MODE.equals("up")) {
      lastRowIndex = totalRows-1;
    } else {
      lastRowIndex = 0;
    }
    //if its not null its full.
    return (matrix.containsKey(getIdStr(lastRowIndex, colIndex)));
  }


  //get the row that is considered to be the last empty matrix.
  private int getLastEmptyIndex(Hashtable matrix){
    //get domain of domains basically
   
    int[][] rowDomains = getRowDomains(matrix);
    //we need to find the largest min and smallest max actually...
     int[] minMaxDomain = new int[]{rowDomains[0][0], rowDomains[0][1]};
    for (int i=0; i<rowDomains.length; i++){
      if (rowDomains[i][0]>minMaxDomain[0]){ //largest min of all the domains
         minMaxDomain[0] = rowDomains[i][0];
      }
       if (rowDomains[i][1]<minMaxDomain[1]){ //smallest max of all the domains
         minMaxDomain[1] = rowDomains[i][1];
      }  
    }
    log(new Object[]{"new min max is: ", minMaxDomain});
    //return beginning domain if down, return end domain if up
    if (ANIMATION_MODE.equals("up")) {
      return minMaxDomain[1];
    }else{
     return minMaxDomain[0];
    }
  }
  
  //remapMatrixRowOrigin: take a matrix (truncated one for instance, and remap the ids row counterpart to new origin)
  private Hashtable remapMatrixRowOrigin(Hashtable matrix, int newOrigin){
    Hashtable newMatrix = new Hashtable(); // new store
    //so first we get min max domain
    int[] minMaxDomain = getDomainOfDomains(getRowDomains(matrix));
    int domainLength =  getDomainLength(minMaxDomain);
    int sourceStart, sourceEnd,targetStart, targetEnd;
    targetStart = newOrigin;
    if (ANIMATION_MODE.equals("up")) { //going up
     sourceStart = minMaxDomain[0]; //0
     sourceEnd = minMaxDomain[1]; //length-1
     targetEnd =  targetStart+(domainLength-1);
    }else{
     sourceStart = minMaxDomain[1]; //length-1
     sourceEnd = minMaxDomain[0]; //0
     targetEnd = targetStart-(domainLength-1);
    }
    Set<String> keys = matrix.keySet();
    for (String key : keys) {
        int[] idIntArr = parseIdStrToIntArr(key);
        //this should be the remapping to the new index
        int newRow = (int)map(idIntArr[0], sourceStart, sourceEnd, targetStart, targetEnd);
        newMatrix.put(getIdStr(newRow, idIntArr[1]), matrix.get(key));
    }
  
    return newMatrix;
  }
  //transferMatrixOverflow(sourceMatrix): move stuff past max to new matrix
  private Hashtable[] transferMatrixOverflow(Hashtable sourceMatrix) {
    Hashtable<String, MatrixCell> tmpMatrix = new Hashtable();
    Hashtable<String,MatrixCell> newMatrix = new Hashtable();
    //anything over totalrows..
    int lastEmptyIndex = getLastEmptyIndex(sourceMatrix);
    log (new Object[]{"last empty index is :", lastEmptyIndex});
    Set<String> keys = sourceMatrix.keySet();
    for (String key : keys) {
      int[] idIntArr = parseIdStrToIntArr(key);
      boolean isOverflow;
      int newFixedIndex;
      if (ANIMATION_MODE.equals("up")) {
        isOverflow = (idIntArr[0]>lastEmptyIndex); // above totalrow index
        newFixedIndex =idIntArr[0]; //fix so starts at 0 and builds down
      } else {
        isOverflow = (idIntArr[0]<lastEmptyIndex); // below 0 index
        newFixedIndex = idIntArr[0]; //fix so -1 starts at length-1 and builds up
      }
      if (isOverflow) {
        //_log(new Object[]{"overflow: ", idIntArr," --> ", newFixedIndex});
        tmpMatrix.put(getIdStr(newFixedIndex, idIntArr[1]), (MatrixCell)sourceMatrix.get(key));
      } else {
        newMatrix.put(key, (MatrixCell)sourceMatrix.get(key));
      }
    }
   //remap truncated to real base (bc we use it to generate new matrix later),...depending on animation up = 0, down = length-1
    tmpMatrix =  remapMatrixRowOrigin(tmpMatrix, (ANIMATION_MODE.equals("up") ? 0 : totalRows-1));
    return new Hashtable[]{newMatrix,tmpMatrix};
  }

  /*
    //emptyMatrix(matrix): clear out a matrix
   private void emptyMatrix(Hashtable matrix){
   matrix.clear();
   }
   */

  //getNextEmpty(matrix, colIndex): get the next row index that is empty given column index
  private int getNextEmpty(Hashtable matrix, int colIndex) {
    //nextempty depends on animation mode
    int start, end;
    //lets get domain which can exceed 0-totalRows domain
    int[] domain = new int[]{0,totalRows};
    //log(new Object[]{"domain..", domain});
    if (ANIMATION_MODE.equals("up")) { //going up
      start = domain[0]; //0
      end=  domain[1]; //totalRows
      for (int i=start; i<end; i++) {
        if (!matrix.containsKey(getIdStr(i, colIndex))) {
          return i;
        }
      }
    } else { //going down
      start = domain[1]-1; //totalRows-1
      end= domain[0]; //0
      for (int i=start; i>=end; i--) {
        if (!matrix.containsKey(getIdStr(i, colIndex))) {
          return i;
        }
      }
    }


    //safety net
    return -1;
  }


  public boolean cellExists(String id) {
    return (currentMatrix.containsKey(id));
  }
  //getCells(cellIds)
  //getCell(cellId)
  public MatrixCell getCell(String cellId) {
    return currentMatrix.get(cellId);
  }
  //setCells(cellIds, cellValues)
  //setCell(cellId, cellValue)
  public void setCell(String cellId, MatrixCell cellValue) {
    currentMatrix.put(cellId, cellValue);
  }

  //pop indivud

  //popRow(matrix): pop off last row in matrix
  public Hashtable popRow(Hashtable matrix) {
    int lastRowIndex;
    if (ANIMATION_MODE.equals("up")) {
      lastRowIndex = 0; // last row is 0 when shifting up
    } else {
      lastRowIndex = totalRows-1; // last row is 0 when shifting up
    }
    //remove last row added
    for (int i=0; i<totalColumns; i++) {
      matrix.remove(getIdStr(lastRowIndex, i));
    }
    //iterate through hastable and pop everything up by 1.
    Hashtable<String, MatrixCell> tmpMatrix = new Hashtable();
    Set<String> keys = matrix.keySet();
    for (String key : keys) {
      int[] rowColArr = parseIdStrToIntArr(key);
      //put everyone up 1
      int shiftFactor;
      if (ANIMATION_MODE.equals("up")) {
        shiftFactor = -1; //  -1 means shift up 1
      } else {
        shiftFactor = 1; // 1 means move down 1
      }
      tmpMatrix.put(getIdStr(rowColArr[0]+shiftFactor, rowColArr[1]), (MatrixCell)matrix.get(key));
    }
  
    return tmpMatrix;
  }
  public Hashtable combineMatrices(Hashtable m1, Hashtable m2) {
    //get through each collumnn
    //testing this should start at 6 now
    for (int colIndex = 0; colIndex<totalColumns; colIndex++){
      //get domain of colindex of m1..we need 
        int nextRow = getNextEmpty(m1, colIndex);
        //get column of next
        Hashtable rowsInCurrentColumn = getRowsInAColumn(m2, colIndex);
        //remap to last index
        rowsInCurrentColumn = remapMatrixRowOrigin(rowsInCurrentColumn, nextRow);
        //place them in hashtable..
        m1.putAll(rowsInCurrentColumn);
    }
    return m1;
    /*
    Set<String> keys = m2.keySet();
    for (String key : keys) {
      int[] rowColArr = parseIdStrToIntArr(key);
      int indexModifier;
      if (ANIMATION_MODE.equals("up")) {
        indexModifier = totalRows-1; //append to last row so 0 -> 85, 1 -> 86
      } else {
        indexModifier =  -1*(totalRows-1); //append to first row so if (rows = 85), 84-> -1 83 --> -2
        //log(new Object[]{"from tmp matrix:", rowColArr[0], " --> ", rowColArr[0]+indexModifier});
      }
      //append to end of of lastRowIndex
      m1.put(getIdStr(rowColArr[0]+indexModifier, rowColArr[1]), (MatrixCell)m2.get(key));
    }
    return m1;
    */
  }

  //get all Row Domains
  public int[][] getRowDomains(Hashtable matrix){
     int[][] rowDomains = new int[totalColumns][2];
    for (int i=0; i<totalColumns; i++){
      rowDomains[i] = getRowDomain(matrix, i);
    }
    return rowDomains;
  }
  //get the row domain (based on index)
  public int[] getRowDomain(Hashtable matrix, int colIndex){
    int[] domain = new int[]{99999,-99999};
    //restrict to a specific column
    Hashtable rowsInAColumn = getRowsInAColumn(matrix, colIndex);
    Set<String> keys = rowsInAColumn.keySet();
    for (String key : keys) {
      //get row index and compare to our current domain
      int currentRow = parseIdStrToIntArr(key)[0];
      //peep domain
      if (currentRow<domain[0]){
        domain[0] = currentRow;
      }else if (currentRow>domain[1]){
        domain[1] = currentRow;
      }
    }
    return domain;
  }
  
  //given a set of domains [start, end]...compute the min and max domain..
  public int[] getDomainOfDomains(int[][] domains){
    int min = domains[0][0];
    int max = domains[0][1];
    for (int i=0; i< domains.length; i++){
      if (domains[i][0]<min){
        min = domains[i][0];
      }
      if (domains[i][1]>max){
        max = domains[i][1];
      }
    }
    return new int[]{min, max};
  }
  
  //compute domain length of a domain
  public int getDomainLength(int[] domain){
    return domain[1]-domain[0];
  }
  
  //get value within a domain, given an index...so if domain is -2 --> 2 than @index 0 = -5, @index 2 =0
  public int getValueFromDomainByIndex(int[] domain, int index){
    int count = 0;
    for (int i=domain[0]; i<=domain[1]; i++){
      if (count==index){
        return i;
      }
      count++;
    }
    return -999999999; //safety net
  }
  
  //get rows of a specified column as a single dim hashtable (like a filter).
  public Hashtable getRowsInAColumn(Hashtable matrix, int colIndex){
   Hashtable result = new Hashtable();
   Set<String> keys = matrix.keySet();
    for (String key : keys) {
      int[] idPieces = parseIdStrToIntArr(key);
      if (idPieces[1]==colIndex){
        result.put(key, matrix.get(key));
      }
    }
    return result;
  }
  

  //way to typecast generic shiftarr..
  public MatrixCell[] shiftArrayMatrix(Object[] arr, int shiftAmount){
    Object[] tmpArr = shiftArray(arr, shiftAmount);
    MatrixCell[] resultArr = new MatrixCell[tmpArr.length];
    for (int i =0; i<tmpArr.length; i++){
      resultArr[i] = (MatrixCell)tmpArr[i];
    }
    return resultArr;
  }
  
  //shift a single array, -1 shift back 1 = pop
  public Object[] shiftArray(Object[] arr, int shiftAmount){
    Object[] newArr = new Object[arr.length-abs(shiftAmount)];
    int oldIndex = -1;
    for (int i = 0; i < newArr.length; i++) { 
        int newIndex = i;
        if (shiftAmount<0){
          //-1 , for up animation remove from beginning (index=0)
         oldIndex = i+abs(shiftAmount);
         
        }else{
          //1, for down animation remove from end (index=length-1)
          oldIndex = i;
        }
    
         newArr[newIndex] = arr[oldIndex];
         //log(new Object[]{"shift amount:", shiftAmount, "i:", i, "new arr index: ", (newIndex)+"/"+newArr.length,  "old arr index:", oldIndex,"/", arr.length});
     }
   
     return newArr;
  }
  

  
  public void shiftColumnsAdditionalSpeed(){
    for (int colIndex=0; colIndex<randSpeeds.length; colIndex++){ //columns
        int amountToShift = randSpeeds[colIndex]; //could be 0 , 1 , or 2
        popOffColumn(colIndex, amountToShift);
    }
  }

  //true workerbee for forcepadding..use if character not a space
  public String forcePaddingSpecific(Object obj, int desiredPadding, String character){
    String str = obj.toString();
    for (int i=0; i<desiredPadding; i++){
      if (i>=str.length()){
        str+=character;
      }
    }
    return str;
  }
  //to be used with visualize matrix..pad text with minimum amount of character lengths.
  public String forcePadding(Object obj, int desiredPadding){
   return forcePaddingSpecific(obj, desiredPadding, " ");
  }

  //visualize matrix as text...for debugging..
  public String matrixVisualize(Hashtable matrix){
    String finalText = "\n";
    int paddingForce = 3;
    String tabSize =   " ";
    String breakLine = "-"; //1 more than tab size length
    //get domains
    int[][] rowDomains = getRowDomains(matrix);
    //get min max of all the domains 
    int[] rowMinMax = getDomainOfDomains(rowDomains);
    log(new Object[]{"row min max:", rowMinMax});
    //print column indices
    //go through each rowindex
   
   finalText += forcePadding(" ", paddingForce)+tabSize; //blank row id for these guys
   for (int colIndex = 0; colIndex<totalColumns; colIndex++){
     finalText += forcePadding(colIndex, paddingForce) +tabSize;
   }
   finalText += "\n";
    for (int rowIndex=rowMinMax[0]; rowIndex<=rowMinMax[1]; rowIndex++){
      //Indivate column header and breaks for visible area 
        if (rowIndex==0 || rowIndex==totalRows){
             String tmpBreakStr =  forcePaddingSpecific("-", paddingForce,"-")+breakLine;
            finalText += tmpBreakStr; //blank row id for these guys
            for (int colIndex = 0; colIndex<totalColumns; colIndex++){
             finalText +=  tmpBreakStr; //if its not the beginning of the row min..then its just to show a break line for visibile stuff
           }
           finalText += "\n";
        }
     
       //print row id
      finalText+= forcePadding(rowIndex, paddingForce)+tabSize;
     
     //indicate if cell is "empty","null",or "filled"
      for (int colIndex = 0; colIndex<totalColumns; colIndex++){
        //grab the value there ..it exist?
        String symbol="  "; //nothing..
        String id = getIdStr(rowIndex, colIndex);
        if (matrix.containsKey(id)){
          if (matrix.get(id)!=null){
            symbol = "# "; //matrix cell value !
          }else{
            symbol = ". "; //null! uh oh..shouldnt exist
          }
        }
        //now print row
        finalText+=  forcePadding(symbol, paddingForce)+tabSize;
      }
      finalText+= "\n";
    }
    return finalText;
  }
  
  
  //pop off specified amount depeding on column..
  public void popOffColumn(int colIndex, int amountToShift){
        int modifier;
        int[] rowDomain = getRowDomain(currentMatrix, colIndex);
         
        //depending on animation mode
         if (ANIMATION_MODE.equals("up")) {
           modifier= 1; 
        } else {
           modifier = -1;
        }
   
          String[] idsToRemove = new String[amountToShift];
          String targetId, sourceId;
          int count = 0;
          //make a copy
          Hashtable<String, MatrixCell> currentMatrixOrig = (Hashtable<String, MatrixCell>)currentMatrix.clone();
          for (int i=rowDomain[0]; i<=rowDomain[1]; i++){
               //check if need to remove
               targetId = getIdStr(i, colIndex);
               sourceId = getIdStr(i+amountToShift*modifier, colIndex); //- modifier = shift up, + modifer = shift down
               boolean addToRemoved = (ANIMATION_MODE.equals("up")) ? i>(rowDomain[1]-amountToShift) : i<rowDomain[0]+amountToShift;
               if (addToRemoved){ //these will need to be removed after a shift
                 idsToRemove[count] = targetId;
                 count++;
               }
               
               if ( currentMatrixOrig.get(sourceId)!=null){
                 //log(new Object[]{"targetId: ", targetId, " sourceId:", sourceId});
                 currentMatrix.put(targetId, currentMatrixOrig.get(sourceId)); //start from bottom and go backwards  
               }
            
           }
          // log(new Object[]{"to remove:", amountToShift});
          // log(new Object[]{"domain after shift:", getRowDomain(currentMatrix, colIndex)});
            for (int i=0; i<idsToRemove.length; i++) {
            //  log(new Object[]{"removing..", idsToRemove[i]});
              currentMatrix.remove(idsToRemove[i]);
            } 
          
         //  log(new Object[]{"new domain for col index #", colIndex,":", getRowDomain(currentMatrix, colIndex),"\n-------\n"});   
  }  


  //do shifting animation
  public void shift() {
     /*
      Object[] arrToShift = new Object[]{0,1,2,3,4};
      log(new Object[]{"shift test of 2",arrToShift,"-->", shiftArray(arrToShift, 2)});
      log(new Object[]{"shift test of -2",arrToShift,"-->", shiftArray(arrToShift, -2)});
      
    */  
  //log(new Object[]{"matrix prepop:", matrixVisualize(currentMatrix)});
    currentMatrix = popRow(currentMatrix);
   //log(new Object[]{"matrix after pop:", matrixVisualize(currentMatrix)});
    //then shift column..cells..if up do one thing if not do another thing..overall id remains same, but matrix switches
     
     shiftColumnsAdditionalSpeed();
     //stop();
    //log(new Object[]{"matrix after additional shift:", matrixVisualize(currentMatrix)});
   
    //see if we need to make another matrix "deck"
    if (!matrixIsFull(currentMatrix)) {
       //log (new Object[]{"**********************oh shnapppp matrix is fullll...gotta fix!!!!"});
      //log(new Object[]{"matrix is not full: current:", matrixVisualize(currentMatrix)});
      //transfer matrix overflow returns an array, index 0=truncatedcurrent matrix, 1=leftover portions that exceeded the frame
      Hashtable[] pieces = transferMatrixOverflow(currentMatrix);
      //log(new Object[]{"truncated to 0:", matrixVisualize(pieces[0])});
      //log(new Object[]{"leftover:", matrixVisualize(pieces[1])});
      //now we take out truncated matrix, and make a new frame using the leftover portions as a base (creating a seamless transition)
      currentMatrix = combineMatrices(pieces[0], generateMatrix(pieces[1]));
      //log(new Object[]{"recombined:", matrixVisualize(currentMatrix)});
    }
    
  }

  public void setSettings(int[] _lengthRange, float _popularityFactor, float[] _catBreakdown, color[] _cr, color[] _crHot) {
    lengthRange= _lengthRange;
    catBreakdown = _catBreakdown;
    popularityFactor = _popularityFactor;
    cr = _cr;
    crHot  = _crHot;
  }


  public WallMatrix(int _totalRows, int _totalColumns, float _popularityFactor, int[] _lengthRange, float[] _catBreakdown, color[] _cr, color[] _crHot) {
    //bounds represent total
    totalRows = _totalRows; //add extra to hide seam
    totalColumns = _totalColumns;
    //get random set of numbers for amount of columns
    randSpeeds = randIntArr(new int[]{0,1,2}, totalColumns); //additional speed 
    log(new Object[]{"random speeds..", randSpeeds});
    setSettings( _lengthRange, _popularityFactor, _catBreakdown, _cr, _crHot);
    currentMatrix = generateMatrix(new Hashtable());

  }
}

/******* MATRIX CELL ********/

//each cell houses a color index, warm/cool,bar id
class MatrixCell {
  int colorIndex, pixelLength, pixelId;
  String verticalBarId;
  boolean isWarm;
  public MatrixCell(int _colorIndex, int _pixelLength, int _pixelId, boolean _warmCool, String _verticalBarId) {
    isWarm = _warmCool;
    colorIndex = _colorIndex;
    verticalBarId = _verticalBarId;
    pixelId = _pixelId;
    pixelLength = _pixelLength;
  }
}
