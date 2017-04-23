//+------------------------------------------------------------------+
//|                                                      A.Rena2.mq4 |
//|                           Copyright 2017, Palawan Software, Ltd. |
//|                             https://coconala.com/services/204383 |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Palawan Software, Ltd."
#property link      "https://coconala.com/services/204383"
#property description "Author: Kotaro Hashimoto <hasimoto.kotaro@gmail.com>"
#property version   "1.00"
#property strict

//--- input parameters
input int Magic_Number = 1;

input double Entry_Lot = 0.1;
input double Ryodate_Lot = 0.1;

input double StopLoss = 0.2;

string thisSymbol;

double minLot;
double maxLot;
double lotSize;
double lotStep;

const string hLineID1 = "1st high";
const string lLineID1 = "1st low";

const string hLineID2 = "2nd high";
const string lLineID2 = "2nd low";


double high1st;
double high2nd;
double low1st;
double low2nd;

int direction;
double nampinPos;

enum Size {
  M1 = PERIOD_M1,
  M5 = PERIOD_M5,
  M15 = PERIOD_M15,
  M30 = PERIOD_M30,
  H1 = PERIOD_H1,
  H4 = PERIOD_H4,
  D1 = PERIOD_D1,
  W1 = PERIOD_W1,
  MN1 = PERIOD_MN1
};

input Size Candle_Stick_Size = M5;
input int Candle_Stick_Period = 14;

int searchHighTime(int start = 0) {
  
  double highPrice = 0.0;
  int anchor = start + 1;

  for(int i = 0; i < Candle_Stick_Period; i++) {
    if(highPrice < iHigh(thisSymbol, Candle_Stick_Size, anchor + i)) {
      highPrice = iHigh(thisSymbol, Candle_Stick_Size, anchor + i);
      anchor = anchor + i;
      i = 0;
    }
  }
  
  return anchor;
}


int searchLowTime(int start = 0) {
  
  double lowPrice = 1000000000.0;
  int anchor = start + 1;

  for(int i = 0; i < Candle_Stick_Period; i++) {
    if(iLow(thisSymbol, Candle_Stick_Size, anchor + i) < lowPrice) {
      lowPrice = iLow(thisSymbol, Candle_Stick_Size, anchor + i);
      anchor = anchor + i;
      i = 0;
    }
  }
  
  return anchor;
}


void drawHLine(string id, double pos, string label, color clr = clrYellow, int width = 1, int style = 1, bool selectable = False) {

  if(style < 0 || 4 < style) {
    style = 0;
  }
  if(width < 1) {
    width = 1;
  }

  ObjectCreate(id, OBJ_HLINE, 0, 0, pos);
  ObjectSet(id, OBJPROP_COLOR, clr);
  ObjectSet(id, OBJPROP_WIDTH, width);
  ObjectSet(id, OBJPROP_STYLE, style);
  ObjectSet(id, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
  
  ObjectSetInteger(0, id, OBJPROP_SELECTABLE, selectable);
  ObjectSetText(id, label, 12, "Arial", clr);
}

void moveHLine(string id, double pos) {
  ObjectSet(id, OBJPROP_PRICE1, pos);
}

enum Direction {
  PLUS = 1,
  MINUS = 2
};

Direction direction(int i) {

  if(iOpen(thisSymbol, Candle_Stick_Size, i) < iClose(thisSymbol, Candle_Stick_Size, i)) {
    return PLUS;
  }
  else {
    return MINUS;
  }
}

double getBottomHige(int i) {

  double real = MathAbs(iOpen(thisSymbol, Candle_Stick_Size, i) - iClose(thisSymbol, Candle_Stick_Size, i));

  double hige;
  if(direction(i) == PLUS) {
    hige = iOpen(thisSymbol, Candle_Stick_Size, i) - iLow(thisSymbol, Candle_Stick_Period, i);
  }
  else {
    hige = iClose(thisSymbol, Candle_Stick_Size, i) - iLow(thisSymbol, Candle_Stick_Period, i);
  }
  
  if(0.0 < real) {
    return hige / real;
  }
  else {
    return 0.0;
  }
}

double getTopHige(int i) {

  double real = MathAbs(iOpen(thisSymbol, Candle_Stick_Size, i) - iClose(thisSymbol, Candle_Stick_Size, i));

  double hige;
  if(direction(i) == PLUS) {
    hige = iHigh(thisSymbol, Candle_Stick_Period, i) - iClose(thisSymbol, Candle_Stick_Size, i);
  }
  else {
    hige = iHigh(thisSymbol, Candle_Stick_Period, i) - iOpen(thisSymbol, Candle_Stick_Size, i);
  }
  
  if(0.0 < real) {
    return hige / real;
  }
  else {
    return 0.0;
  }
}

int getSignal() {

  if(low1st < low2nd && Ask < high1st && Ask < high2nd) {
    if(direction(4) == MINUS && direction(3) == MINUS && direction(2) == MINUS && 0.9 < getBottomHige(2)) {
      if(direction(1) == PLUS && 1.0 < getBottomHige(1)) {
        return OP_BUY;
      }
    }
  }

  if(high1st > high2nd && Bid > low1st && Bid > low2nd) {
    if(direction(4) == PLUS && direction(3) == PLUS && direction(2) == PLUS && 0.9 < getTopHige(2)) {
      if(direction(1) == MINUS && 1.0 < getTopHige(1)) {
        return OP_SELL;
      }
    }
  }
  
  return -1;
}

double getProfit() {

  double profit = 0.0;

  for(int i = 0; i < OrdersTotal(); i++) {
    if(OrderSelect(i, SELECT_BY_POS)) {
      if(!StringCompare(OrderSymbol(), thisSymbol) && OrderMagicNumber() == Magic_Number) {
        profit += OrderProfit();
      }
    }
  }
  
  return profit;
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{  
  thisSymbol = Symbol();

  int highTime = searchHighTime();
  high1st = iHigh(thisSymbol, Candle_Stick_Size, highTime);
  drawHLine(hLineID1, high1st, hLineID1);

  int lowTime = searchLowTime();
  low1st = iLow(thisSymbol, Candle_Stick_Size, lowTime);
  drawHLine(lLineID1, low1st, lLineID1);
  
  highTime = searchHighTime(highTime);
  high2nd = iHigh(thisSymbol, Candle_Stick_Size, highTime);
  drawHLine(hLineID2, high2nd, hLineID2, clrCyan);

  lowTime = searchLowTime(lowTime);
  low2nd = iLow(thisSymbol, Candle_Stick_Size, lowTime);
  drawHLine(lLineID2, low2nd, lLineID2, clrCyan);

  minLot = MarketInfo(Symbol(), MODE_MINLOT);
  maxLot = MarketInfo(Symbol(), MODE_MAXLOT);
  lotStep = MarketInfo(Symbol(), MODE_LOTSTEP);
  lotSize = MarketInfo(Symbol(), MODE_LOTSIZE);
  
  //---
  return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
  ObjectDelete(0, hLineID1);
  ObjectDelete(0, lLineID1);
  ObjectDelete(0, hLineID2);
  ObjectDelete(0, lLineID2);

  //---   
}

void closeAll() {

  for(int i = 0; i < OrdersTotal(); i++) {
    if(OrderSelect(i, SELECT_BY_POS)) {
      if(OrderMagicNumber() == Magic_Number) {
        if(OrderType() == OP_BUY) {
          if(!OrderClose(OrderTicket(), OrderLots(), NormalizeDouble(Bid, Digits), 0)) {
            Print("Error on closing long order: ", GetLastError());
          }
          else {
            i = -1;
          }
        }
        else if(OrderType() == OP_SELL) {
          if(!OrderClose(OrderTicket(), OrderLots(), NormalizeDouble(Ask, Digits), 3)) {
            Print("Error on closing short order: ", GetLastError());
          }
          else {
            i = -1;
          }
        }
        else if(OrderType() == OP_BUYSTOP) {
          if(!OrderDelete(OrderTicket())) {
            Print("Error on deleting buy stop order: ", GetLastError());
          }
          else {
            i = -1;
          }
        }
        else if(OrderType() == OP_SELLSTOP) {
          if(!OrderDelete(OrderTicket())) {
            Print("Error on deleting sell stop order: ", GetLastError());
          }
          else {
            i = -1;
          }
        }
      }
    }
  }
}

bool touched3Signa() {

  double Band20_U = iBands(Symbol(), PERIOD_M5, 20, 3, 0, PRICE_CLOSE, MODE_UPPER, 0);
  double Band20_L = iBands(Symbol(), PERIOD_M5, 20, 3, 0, PRICE_CLOSE, MODE_LOWER, 0);

  if(Bid < Band20_L || Band20_U < Ask) {
    return True;
  }
  else {
    return False;
  }
}


int getIndSignal() {

  string indName = "No1System";  

  double s0 = iCustom(NULL, PERIOD_CURRENT, indName, 0, 0);
  double s1 = iCustom(NULL, PERIOD_CURRENT, indName, 1, 0);
  double s2 = iCustom(NULL, PERIOD_CURRENT, indName, 2, 0);
  
  if(s0 == s1) {
    return OP_BUY;
  }
  else if(s0 == s2) {
    return OP_SELL;
  }
  else {
    return -1;
  }
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
  int highTime = searchHighTime();
  high1st = iHigh(thisSymbol, Candle_Stick_Size, highTime);
  moveHLine(hLineID1, high1st);
  
  int lowTime = searchLowTime();
  low1st = iLow(thisSymbol, Candle_Stick_Size, lowTime);
  moveHLine(lLineID1, low1st);
  
  highTime = searchHighTime(highTime);
  high2nd = iHigh(thisSymbol, Candle_Stick_Size, highTime);
  moveHLine(hLineID2, high2nd);

  lowTime = searchLowTime(lowTime);
  low2nd = iLow(thisSymbol, Candle_Stick_Size, lowTime);
  moveHLine(lLineID2, low2nd);
  
  if(OrdersTotal() == 0) {
    int signal = getSignal();
    
    if(signal == OP_BUY) {
      int ticket = OrderSend(thisSymbol, OP_BUY, Entry_Lot, NormalizeDouble(Ask, Digits), 3, 0, 0, NULL, Magic_Number);
      direction = OP_BUY;
    }
    else if(signal == OP_SELL) {
      int ticket = OrderSend(thisSymbol, OP_SELL, Entry_Lot, NormalizeDouble(Bid, Digits), 3, 0, 0, NULL, Magic_Number);
      direction = OP_SELL;
    }
  }
  else if(0 < getProfit()){
    closeAll();    
  }
  else if(touched3Signa() && OrdersTotal() == 1) {
    if(direction == OP_BUY) {
      int ticket = OrderSend(thisSymbol, OP_BUY, Entry_Lot * 2.0, NormalizeDouble(Ask, Digits), 3, 0, 0, NULL, Magic_Number);
      nampinPos = Ask - Point * 50;
    }
    else if(direction == OP_SELL) {
      int ticket = OrderSend(thisSymbol, OP_SELL, Entry_Lot * 2.0, NormalizeDouble(Bid, Digits), 3, 0, 0, NULL, Magic_Number);
      nampinPos = Bid + Point * 50;
    }
  }
  else if(OrdersTotal() == 2) {
    if(direction == OP_BUY) {
      if(Ask < nampinPos) {
        int ticket = OrderSend(thisSymbol, OP_SELL, Ryodate_Lot, NormalizeDouble(Bid, Digits), 3, 0, 0, NULL, Magic_Number);    
      }      
      if(getIndSignal() == OP_BUY) {
        int ticket = OrderSend(thisSymbol, OP_BUY, Entry_Lot * 4.0, NormalizeDouble(Ask, Digits), 3, 0, 0, NULL, Magic_Number);
      }
    }
    else if(direction == OP_SELL) {
      if(nampinPos < Bid) {
        int ticket = OrderSend(thisSymbol, OP_BUY, Ryodate_Lot, NormalizeDouble(Ask, Digits), 3, 0, 0, NULL, Magic_Number);    
      }          
      if(getIndSignal() == OP_SELL) {
        int ticket = OrderSend(thisSymbol, OP_SELL, Entry_Lot * 4.0, NormalizeDouble(Bid, Digits), 3, 0, 0, NULL, Magic_Number);
      }
    }
    
    
  }
}

