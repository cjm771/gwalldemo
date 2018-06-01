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
  float popularityFactor = 0; //0.0-1.0 number representing popularity
  float[] catBreakdown;
  color[] cr, crHot;
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
    color[] colorRangeHot = generateColorRange(crHot[0], crHot[1], steps);
    //log(new Object[]{"color range:", xolorRange, "color range hot:", colorRangeHot});

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
    //apply warmcoolfactor to current new matrix ids.
    tmpMatrix = setWarmCool(tmpMatrix, matrixId);
    matrixId++;
    
    return tmpMatrix;
    
  }
  
  //set warm and cool given the currentMatrix and mId 
  public Hashtable<String, MatrixCell> setWarmCool(Hashtable<String, MatrixCell> matrix, int mId){
      Set<String> keys = matrix.keySet();
      Hashtable<String, Object> barDictionary = getListByDistributionBreakdown(new Object[]{false,true}, getBarIdsByMatrixId(matrix, mId), new float[]{1-popularityFactor,popularityFactor});
      //log(new Object[]{"bar dictionary:", barDictionary});
      for (String key : keys) {
        MatrixCell cell = matrix.get(key);
        if (barDictionary.containsKey(cell.verticalBarId)){
         // log(new Object[]{"changing ", cell.verticalBarId," --> warm value old:",  cell.isWarm, "---> ", barDictionary.get(cell.verticalBarId)});
            matrix.get(key).isWarm = (boolean)barDictionary.get(cell.verticalBarId);
            
          }
      }
      return matrix;
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
    String tmpPieces;
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

  private Hashtable insertVerticalBarAtColIndex(Hashtable matrix,  int colIndex,String verticalBarId, int colorIndex, int pixelLength) {
    //insert random bar at last empty spot
    int nextIndex = getNextEmpty(matrix, colIndex);
    if (nextIndex==-1) {
      log(new Object[]{"safety net issue! column:", colIndex, "next index:", nextIndex});
    }
    //we build the pixel up
    int modifier;
    if (ANIMATION_MODE.equals("up")) { //going up
      modifier = 1; //we're building the bar upstream (index wise)
    } else {
      modifier = -1; //we're building the bar downstream (index wise)
    }
    for (int i =0; i<pixelLength; i++) {
      matrix.put(getIdStr(nextIndex+(i*modifier), colIndex), new MatrixCell(colorIndex, false, verticalBarId));
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


  //transferMatrixOverflow(sourceMatrix): move stuff past max to new matrix
  private Hashtable[] transferMatrixOverflow(Hashtable sourceMatrix) {
    Hashtable<String, MatrixCell> tmpMatrix = new Hashtable();
    Hashtable<String,MatrixCell> newMatrix = new Hashtable();
    //anything over totalrows..
    Set<String> keys = sourceMatrix.keySet();
    for (String key : keys) {
      int[] idIntArr = parseIdStrToIntArr(key);
      boolean isOverflow;
      int newFixedIndex;
      if (ANIMATION_MODE.equals("up")) {
        isOverflow = (idIntArr[0]>totalRows-1); // above totalrow index
        newFixedIndex = idIntArr[0]%(totalRows); //fix so larger indices are within new matrix 0-->84ish range
      } else {
        isOverflow = (idIntArr[0]<0); // below 0 index
        newFixedIndex = idIntArr[0]+totalRows; //fix so -1 becomes 84 or whatever
      }
      if (isOverflow) {
        //_log(new Object[]{"overflow: ", idIntArr," --> ", newFixedIndex});
        tmpMatrix.put(getIdStr(newFixedIndex, idIntArr[1]), (MatrixCell)sourceMatrix.get(key));
      } else {
        newMatrix.put(key, (MatrixCell)sourceMatrix.get(key));
      }
    }
    //now we revise verticalbar
    return new Hashtable[]{newMatrix, tmpMatrix};
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
    if (ANIMATION_MODE.equals("up")) { //going up
      start = 0;
      end= totalRows;
      for (int i=start; i<end; i++) {
        if (!matrix.containsKey(getIdStr(i, colIndex))) {
          return i;
        }
      }
    } else { //going down
      start = totalRows-1;
      end= 0;
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
  }

  //do shifting animation
  public void shift() {
    currentMatrix = popRow(currentMatrix);
    //see if we need to make another matrix "deck"
    if (!matrixIsFull(currentMatrix)) {
      //transfer matrix overflow returns an array, index 0=truncatedcurrent matrix, 1=leftover portions that exceeded the frame
      Hashtable[] pieces = transferMatrixOverflow(currentMatrix);
      //now we take out truncated matrix, and make a new frame using the leftover portions as a base (creating a seamless transition)
      currentMatrix = combineMatrices(pieces[0], generateMatrix(pieces[1]));
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
    setSettings( _lengthRange, _popularityFactor, _catBreakdown, _cr, _crHot);
    currentMatrix = generateMatrix(new Hashtable());
  }
}

/******* MATRIX CELL ********/

//each cell houses a color index, warm/cool,bar id
class MatrixCell {
  int colorIndex;
  String verticalBarId;
  boolean isWarm;
  public MatrixCell(int _colorIndex, boolean _warmCool, String _verticalBarId) {
    isWarm = _warmCool;
    colorIndex = _colorIndex;
    verticalBarId = _verticalBarId;
  }
}
