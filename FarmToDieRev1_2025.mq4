//+------------------------------------------------------------------+
//|                                                       Farmer.mq4 |
//|                                                    Trung đẹp zai |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property strict
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

#define OP_BUYSELL 999

enum modetrade
  {
   ONLY_BUY = 1,  // BUY
   ONLY_SELL = 2, // SELL
   BUY_AND_SELL = 3,       // BUY & SELL
  };

extern int MagicNumber = 179092;                                     // Magic Number

extern string ________General________ = "============== General ==============";
extern modetrade kieuTrade = 3;                                      // Kieu Vao Lenh        
extern double lotsize = 0.01;                                        // Lot Size
extern double pipsDiff = 10;                                         // Khoang Cach Vao Lenh (Pips)
extern double multiple = 1;                                          // He So Nhan Lot
extern double pipTP = 23;                                            // TP (Pips)
extern double pipSL = 0;                                             // SL (Pips)

extern string ________Stop_Bot________ = "============== Stop Bot ==============";
extern int maxOrderBUY = 60;
extern int maxOrderSELL = 60;
extern double stopBuyPrice = 0;                                      // Gia Ko BUY nua
extern double stopSellPrice = 0;                                     // Gia Ko SELL nua

extern double lowBuySL = 0;                                          // Gia SL thap nhat cua lenh Buy
extern double highSellSL = 0;                                        // Gia SL cao nhat cua lenh Sell

extern int delayTime = 3;                                           // Khoang gian dung giua 2 lenh (tính theo giay)

extern string ________TimeFilter________ = "============== Time Filter ==============";
extern int StartHour = 0;
extern int StartMinute = 0;
extern int EndHour = 23;
extern int EndMinute = 59;

string cmt = "FarmToDie: ";
string orgString = "Org";
string dupString = "Dup";

int minBoundMultiple;

// ---- Button
string Font_Type = "Arial Bold";
color Font_Color = clrWhite;
int Font_Size = 10;

bool stopEAFlg = false;
color stopEAClr = clrTeal;
string stopEATxt = "Stop EA: OFF";
// ---- Button

bool stopEA = false;
bool openOrder = true;
double p0w, currentLots;

// TotalOrder()
int totalOrder, totalOrdBuy, totalOrdSell;
int totalOrdBuyOrg, totalOrdSellOrg, totalOrdBuyDup, totalOrdSellDup;
double totalLotsBuy, totalLotsSell;
double totalProfit;
int countOrd;

// GetHigh_LowPrice()
double higPriceBuy, higPriceSell, lowPriceSell, lowPriceBuy;
double recentBuy, recentSell;
int tckLowSell, tckHigBuy;
double comSell, swapSell, lotsSell, profitSell, totalProfitSell;
double totalProfitBuy, profitBuy, comBuy, swapBuy, lotsBuy;

// GetNormalLotUnit()
int normalLotUnit = 2;

int OnInit()
  {
//---
   if (checkActivation() == 1) {
      Draw("BG", "gggg", 120, "Webdings", C'25,25,25', 4, 0, 20);
      Draw("Bot_Name", "============ Farm To Die ============", 12, "Calibri Bold", clrYellow, 4, 20, 20);
         
      CreateButtons();
   }
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
//---
   if (highSellSL != 0 && lowBuySL !=0) {
      if (
            MarketInfo(Symbol(), MODE_BID) > highSellSL && 
            MarketInfo(Symbol(), MODE_ASK) < lowBuySL
         ) {
            stopEA();
      }
   }

   TotalOrder();
   GetHigh_LowPrice();
   
   showInfo();
   
   if (checkTradingTime() && !stopEAFlg) {  
      //priceBoundary();
      doAction();
   }
}
//+------------------------------------------------------------------+

int checkActivation()
{
   datetime trial_end_date = D'01.01.2025';
   if(TimeCurrent() > trial_end_date)
   {
       Alert("EA Da Het Han! Vui Long Lien He Chu Nhan EA!");
       ExpertRemove();
       
       return (-1);
   }
   
   return (1);
} // End void checkActivation()

void doAction ()
{
   // Only Buy
   doActionBuy();
   
   // Only Sell
   doActionSell();
   
   
}// End void doAction()

void doActionBuy()
{
   if (kieuTrade == ONLY_BUY || kieuTrade == BUY_AND_SELL) 
   {
      if (stopBuyPrice !=0 && MarketInfo(Symbol(), MODE_ASK) < stopBuyPrice) {
         // Check buy order
         double price = MarketInfo(Symbol(), MODE_ASK);
         double tp = price + (pipTP * 10 * Point);
         double sl = price - (pipSL * 10 * Point);
         if (sl < lowBuySL) {
            sl = lowBuySL;
         }
         
         if (pipSL == 0) 
         {
            sl = 0;
         }
         string cm = cmt + "BUY-" + (totalOrdBuy + 1);
         
         if ( totalOrdBuy == 0)
         {
            cm += "|" + orgString + "-1";
            openOrd (ORDER_TYPE_BUY, price, sl, tp, cm, 1, lotsize, 1);
         }
         else if ( totalOrdBuy != 0 && totalOrdBuy < maxOrderBUY)
         {
            if ( lowPriceBuy - price >= pipsDiff*10*MarketInfo(Symbol(), MODE_POINT))
            {
               //double buyMultiple = getMultiple(totalOrdBuyOrg+1);
               cm += "|" + orgString + "-" + (totalOrdBuyOrg+1);
               openOrd (ORDER_TYPE_BUY, price, sl, tp, cm, multiple, lotsize, 1);
            }
            
            // Khi lenh buy chua tp thi du quang lai tiep tuc buy (buy lien tuc trong khoang lowBuy <=> TP
            if (
                  (price < tp) &&
                  (price > lowPriceBuy)
            ) {
               // Gia di len tren lenh buy cuoi cung, du quang la buy
               if (
                     (price > recentBuy) && 
                     (price - recentBuy == pipsDiff*10*MarketInfo(Symbol(), MODE_POINT))
                  ) {
                        cm += "|" + dupString + "-" + (totalOrdBuyDup+1);
                        openOrd (ORDER_TYPE_BUY, price, sl, tp, cm, 1, lotsize, 0);
               } 
               // Gia di xuong duoi lenh buy cuoi cung, du quang la buy
               else if (
                     (price < recentBuy) && 
                     (recentBuy - price == pipsDiff*10*MarketInfo(Symbol(), MODE_POINT))
                  ) {
                        cm += "|" + dupString + "-" + (totalOrdBuyDup+1);
                        openOrd (ORDER_TYPE_BUY, price, sl, tp, cm, 1, lotsize, 0);
               }
            }
         }
      }
   } 
} // End doActionBuy()

void doActionSell()
{
   if (kieuTrade == ONLY_SELL || kieuTrade == BUY_AND_SELL) { 
      if (stopSellPrice!=0 && MarketInfo(Symbol(), MODE_BID) > stopSellPrice) 
      {
         // Check Sell order
         double price = MarketInfo(Symbol(), MODE_BID);
         double tp = price - (pipTP * 10 * Point);
         double sl = price + (pipSL * 10 * Point);
         if (sl > highSellSL) {
            sl = highSellSL;
         }
         if (pipSL == 0) 
         {
            sl = 0;
         }
         string cm = cmt + "SELL-" + (totalOrdSell + 1);
         
         if ( totalOrdSell == 0)
         {
            cm += "|" + orgString + "-1";
            openOrd (ORDER_TYPE_SELL, price, sl, tp, cm, 1, lotsize, 1);
         }
         else if ( totalOrdSell != 0 && totalOrdSell < maxOrderSELL)
         {
            
            if ( price - higPriceSell > pipsDiff*10*MarketInfo(Symbol(), MODE_POINT))
            {
               //double sellMultiple = getMultiple(totalOrdSellOrg+1);
               cm += "|" + orgString + "-" + (totalOrdSellOrg+1);
               openOrd (ORDER_TYPE_SELL, price, sl, tp, cm, multiple, lotsize, 1);
            }
            
            // Khi lenh buy chua tp thi du quang lai tiep tuc buy (buy lien tuc trong khoang lowBuy <=> TP
            if (
                  (price > tp) &&
                  (price < higPriceSell)
            ) {
               // Gia di len tren lenh sell cuoi cung, du quang la buy
               if (
                     (price > recentSell) && 
                     (price - recentSell == pipsDiff*10*MarketInfo(Symbol(), MODE_POINT))
                  ) {
                     cm += "|" + dupString + "-" + (totalOrdSellDup+1);
                     openOrd (ORDER_TYPE_SELL, price, sl, tp, cm, 1, lotsize, 0);
               }
               // Gia di xuong duoi lenh sell cuoi cung, du quang la buy
               else if (
                     (price < recentSell) && 
                     (recentSell - price == pipsDiff*10*MarketInfo(Symbol(), MODE_POINT))
                  ) {
                     cm += "|" + dupString + "-" + (totalOrdSellDup+1);
                     openOrd (ORDER_TYPE_SELL, price, sl, tp, cm, 1, lotsize, 0);
               }
            }
            
         }
      }
   }
} // End doActionSell()

void openOrd ( int oP, double entry, double sL, double tP, string cm, double multi, double lot, int isOrgOrd)
{
   GetValLot (oP, multi, lot, isOrgOrd);
   string col;
   if (oP == OP_BUY)
   {
      col = DoubleToStr(clrGreen, 0);
   }
   else if (oP == OP_SELL)
   {
      col = DoubleToStr(clrRed, 0);
   }
   if ( openOrder == true)
   {
      int tk = OrderSend(Symbol(), oP, currentLots, entry, 5, sL, tP, cm, MagicNumber, 0, StringToColor(col));
      if (tk <= 0) { 
         Print("Error Open Order DCA " + DoubleToStr(oP,0) + " : ",GetLastError());
      }
      Sleep(delayTime*1000);
   }
}// End void openOrd()

void GetValLot(int oP, double Multi, double fixLots, int isOrgOrd)
{
   if (oP == OP_BUY)
   {
      p0w = totalOrdBuy;
      if (isOrgOrd == 1) {
         p0w = totalOrdBuyOrg - minBoundMultiple; // tinh tu vi tri level setting bat dau he so x lot
      }
   }
   else if ( oP == OP_SELL)
   {
      p0w = totalOrdSell;
      if (isOrgOrd == 1) {
         p0w = totalOrdSellOrg - minBoundMultiple; // tinh tu vi tri level setting bat dau he so x lot
      }
   }
   
   GetNormalLotUnit();
   
   double orderLot = fixLots * MathPow(Multi, p0w);
   
   if (orderLot <= 0) {
      orderLot = MarketInfo(Symbol(), MODE_MINLOT);
   }
   
   if (orderLot < MarketInfo(Symbol(), MODE_MINLOT)) {
      orderLot = MarketInfo(Symbol(), MODE_MINLOT);
   }
   
   if (orderLot > MarketInfo(Symbol(), MODE_MAXLOT)) {
      orderLot = MarketInfo(Symbol(), MODE_MAXLOT);
   }
   
   currentLots = NormalizeDouble(orderLot, normalLotUnit);
} // End void GetValLot()

void GetNormalLotUnit()
{
   if(MarketInfo(Symbol(), MODE_MINLOT)== 0.01)
   {
      normalLotUnit = 2;
   }
   if(MarketInfo(Symbol(), MODE_MINLOT)== 0.1)
   {
      normalLotUnit = 1;
   }
   if(MarketInfo(Symbol(), MODE_MINLOT)== 0.001)
   {
      normalLotUnit = 3;
   }
}// End void GetNormalLotUnit()

void GetHigh_LowPrice()
{  
   higPriceBuy = 0;
   higPriceSell = 0;
   lowPriceBuy = 0;
   lowPriceSell = 0;
   recentBuy = 0;
   recentSell = 0;
   totalProfitSell = 0;
   totalProfitBuy = 0;
   double tckSell = 0, tckBuy = 0;
   
   for (int i = 0; i < OrdersTotal(); i++)
   {
      if (!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) { continue;}
      if (OrderSymbol() != Symbol()) { continue;}
      if (OrderMagicNumber() != MagicNumber) { continue;}
      if (OrderType() == OP_SELL)
      {
         if (OrderOpenPrice() > higPriceSell || higPriceSell == 0)
         {
            higPriceSell = OrderOpenPrice();
         }
         if ( OrderOpenPrice() < lowPriceSell || lowPriceSell == 0)
         {
            lowPriceSell = OrderOpenPrice();
            tckLowSell = OrderTicket();
            profitSell = OrderProfit();
            comSell = OrderCommission();
            swapSell = OrderSwap();
            lotsSell = OrderLots();
            
            totalProfitSell += profitSell;
         }
         if ( OrderTicket() > tckSell)
         {
            tckSell = OrderTicket();
            recentSell = OrderOpenPrice();
         }
        
      } // End if (OrderType() == OP_BUY)
      if ( OrderType() == OP_BUY )
      {
         if (OrderOpenPrice() < lowPriceBuy || lowPriceBuy == 0)
         {
            lowPriceBuy = OrderOpenPrice();
         }
         if ( OrderOpenPrice() > higPriceBuy || higPriceBuy == 0)
         {
            higPriceBuy = OrderOpenPrice();
            tckHigBuy = OrderTicket();
            profitBuy = OrderProfit();
            comBuy = OrderCommission();
            swapBuy = OrderSwap();
            lotsBuy = OrderLots();
            
            totalProfitBuy += profitBuy;
         }
         if ( OrderTicket() > tckBuy)
         {
            tckBuy = OrderTicket();
            recentBuy = OrderOpenPrice();
         }
      }  // End if ( OrderType() == OP_BUY )
      
   } // End for (int i = 0; i < OrdersTotal(); i++)
   
} // End void GetHigh_LowPrice()

void TotalOrder()
{
   totalOrder = 0;
   totalOrdBuy = 0;
   totalOrdSell = 0;
   totalOrdBuyOrg = 0;
   totalOrdBuyDup = 0;
   totalOrdSellOrg = 0;
   totalOrdSellDup = 0;
   totalLotsBuy = 0;
   totalLotsSell = 0;
   
   double profit = 0, swap = 0;
   
   if (OrdersTotal() == 0)
   {   return; }
      
   for (int i = 0; i < OrdersTotal(); i ++)
   {
      if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) { continue; }
      if (OrderSymbol() != Symbol() ) { continue; }
      else if (OrderSymbol() == Symbol())
      {
         if (OrderMagicNumber() != MagicNumber) { continue; }
         else if (OrderMagicNumber() == MagicNumber)
         {          
            totalOrder ++; 
            profit += OrderProfit();
            swap += OrderSwap();
            string ordCmt = OrderComment(); 
              
            if (OrderType() == OP_BUY)
            {
               if (StringFind(ordCmt, orgString, 0) > -1) {
                  totalOrdBuyOrg++;
               }
   			   if (StringFind(ordCmt, dupString, 0) > -1) {
   				   totalOrdBuyDup++;
   				} 
               totalOrdBuy++;
               totalLotsBuy += OrderLots();
            }  
            if (OrderType() == OP_SELL)
            {
               if (StringFind(ordCmt, orgString, 0) > -1) {
                  totalOrdSellOrg++;
               }
               if (StringFind(ordCmt, dupString, 0) > -1) {
                  totalOrdSellDup++;
               } 
               totalOrdSell++;
               totalLotsSell += OrderLots();
            }
         }         
      }
   }  // End for (int cc = OrdersTotal() - 1; cc >= 0; cc--)
   
   totalProfit = profit + swap;
} //End void TotalOrder()

void showInfo()
{
   string diffHedging = "";
   double diffLots = 0;
   if (totalLotsBuy > totalLotsSell) {
      diffLots = totalLotsBuy - totalLotsSell;
      diffHedging = "SELL - " + NormalizeDouble(diffLots, 2) + " lots";
   } 
   if(totalLotsBuy < totalLotsSell){
      diffLots = totalLotsSell - totalLotsBuy;
      diffHedging = "BUY - " + NormalizeDouble(diffLots, 2) + " lots";
   }
   if (totalLotsBuy != totalLotsSell) {
      Draw("LotHedging", "========== Lots Hedging Needed: " + diffHedging, 12, "Calibri Bold", clrLime, 4, 20, 140);
   }
   
   if (totalProfit > 0) {
      Draw("Profit", "===== Total Profit: " + NormalizeDouble(totalProfit, 2), 12, "Calibri Bold", clrLime, 4, 20, 120);
   } else {
      Draw("Profit", "Profit: " + NormalizeDouble(totalProfit, 2), 12, "Calibri Bold", clrRed, 4, 20, 120);
   }
   
   Draw("Total_Buy", "Buy: " + totalOrdBuy + " orders" + " / " + totalLotsBuy + " lots", 12, "Calibri Bold", clrLime, 4, 20, 100);
   Draw("Profit_Buy", "Profit Buy: " + NormalizeDouble(totalProfitBuy, 2), 12, "Calibri Bold", clrLime, 4, 20, 80);
   Draw("Total_Sell", "Sell: " + totalOrdSell + " orders" + " / " + totalLotsSell + " lots", 12, "Calibri Bold", clrRed, 4, 20, 60);
   Draw("Profit_Sell", "Profit Sell: " + NormalizeDouble(totalProfitSell, 2), 12, "Calibri Bold", clrRed, 4, 20, 40);
}

void priceBoundary ()
{
   double monthHigh = iHigh(Symbol(),PERIOD_MN1,1); // prev month high
   double curMonthHigh = iHigh(Symbol(),PERIOD_MN1,0); // current month high
   double monthLow = iLow(Symbol(),PERIOD_MN1,1); // prev month low
   double curMonthLow = iLow(Symbol(),PERIOD_MN1,0); // current month low
   
   if (monthHigh < curMonthHigh)
   {
      monthHigh = curMonthHigh;
   }
   if (curMonthLow < monthLow)
   {
      monthLow = curMonthLow;
   }
   
   if (stopBuyPrice == 0) 
   {
      stopBuyPrice = monthHigh;
   }
   if (stopSellPrice == 0) 
   {
      stopSellPrice = monthLow;
   }
   
   // Tinh trung binh gia buy/sell
   double lowHighDiff = stopBuyPrice - stopSellPrice;
   double halfBuyHigh = stopBuyPrice - (lowHighDiff/4);
   double halfSellLow = stopSellPrice + (lowHighDiff/4);
   
}//End void priceBoundary()

int checkTradingTime () 
{
   if ((Hour() > StartHour && Hour() < EndHour) || (Hour() == StartHour && Minute() >= StartMinute) || (Hour() == EndHour && Minute() < EndMinute)) return (1);
   
   return (0);
}//End int checkTradingTime()

void OnChartEvent (const int id, const long &lparam, const double &dparam, const string &action)
{
   ResetLastError();
   if (id == CHARTEVENT_OBJECT_CLICK) {if (ObjectType (action) == OBJ_BUTTON) {ButtonPressed (0, action);}}
}
//+------------------------------------------------------------------+

void stopEA()
{
   stopEAFlg = true;
   stopEAClr = clrRed;
   stopEATxt = "StopEA: ON";
   
   ObjectSetInteger (0, "stopEA", OBJPROP_BGCOLOR, stopEAClr);
   ObjectSetString  (0, "stopEA", OBJPROP_TEXT, stopEATxt);
}

void startEA()
{
   stopEAFlg = false;
   stopEAClr = clrTeal;
   stopEATxt = "StopEA: OFF";
   
   ObjectSetInteger (0, "stopEA", OBJPROP_BGCOLOR, stopEAClr);
   ObjectSetString  (0, "stopEA", OBJPROP_TEXT, stopEATxt);
}

void ButtonPressed (const long chartID, const string action)
{
   if (action == "stopEA") stopEAPressed (chartID, action);
   if (action == "closeAll") closeAllPressed (chartID, action);
   if (action == "closeBuy") closeBuyPressed (chartID, action);
   if (action == "closeSell") closeSellPressed (chartID, action);
   if (action == "closeNegative") closeNegativePressed (chartID, action);
   if (action == "closePositive") closePositivePressed (chartID, action);
   //Sleep (1000);
  
}

int stopEAPressed (const long chartID, const string action)
{   
   if (stopEAFlg) {
      startEA();
   } else {
      stopEA();
   }
   
   return (0);
}

int closeNegativePressed (const long chartID, const string action)
{   
   int ticket;
   if (OrdersTotal() == 0) return(0);
   for (int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if (OrderSelect (i, SELECT_BY_POS, MODE_TRADES) == true)
      {
         if (OrderProfit() < 0 && OrderSymbol() == Symbol())
         {
            ticket = OrderClose (OrderTicket(), OrderLots(), MarketInfo (OrderSymbol(), MODE_BID), 3, clrNONE);
            if (ticket == -1) Print ("Error : ", GetLastError());
            if (ticket >   0) Print ("Position ", OrderTicket() ," closed");
         }
      }
   }
   
   return (0);
}

int closePositivePressed (const long chartID, const string action)
{   
   int ticket;
   if (OrdersTotal() == 0) return(0);
   for (int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if (OrderSelect (i, SELECT_BY_POS, MODE_TRADES) == true)
      {
         if (OrderProfit() >= 0 && OrderSymbol() == Symbol())
         {
            ticket = OrderClose (OrderTicket(), OrderLots(), MarketInfo (OrderSymbol(), MODE_BID), 3, clrNONE);
            if (ticket == -1) Print ("Error : ", GetLastError());
            if (ticket >   0) Print ("Position ", OrderTicket() ," closed");
         }
      }
   }
   
   return (0);
}

int closeBuyPressed (const long chartID, const string action)
{   
   int ticket;
   if (OrdersTotal() == 0) return(0);
   for (int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if (OrderSelect (i, SELECT_BY_POS, MODE_TRADES) == true)
      {
         if (OrderType() == OP_BUY && OrderSymbol() == Symbol())
         {
            ticket = OrderClose (OrderTicket(), OrderLots(), MarketInfo (OrderSymbol(), MODE_BID), 3, clrNONE);
            if (ticket == -1) Print ("Error : ", GetLastError());
            if (ticket >   0) Print ("Position ", OrderTicket() ," closed");
         }
      }
   }
   
   return (0);
}

int closeSellPressed (const long chartID, const string action)
{   
   int ticket;
   if (OrdersTotal() == 0) return(0);
   for (int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if (OrderSelect (i, SELECT_BY_POS, MODE_TRADES) == true)
      {
         if (OrderType() == OP_SELL && OrderSymbol() == Symbol())
         {
            ticket = OrderClose (OrderTicket(), OrderLots(), MarketInfo (OrderSymbol(), MODE_ASK), 3, clrNONE);
            if (ticket == -1) Print ("Error : ",  GetLastError());
            if (ticket >   0) Print ("Position ", OrderTicket() ," closed");
         }
      }
   }
   
   return (0);
}

int closeAllPressed (const long chartID, const string action)
{   
   int ticket;
   if (OrdersTotal() == 0) return(0);
   for (int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if (OrderSelect (i, SELECT_BY_POS, MODE_TRADES) && OrderSymbol() == Symbol() && OrderType() < 2)
      {
         ticket = OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),1000);
         if (ticket == -1) Print ("Error : ", GetLastError());
         if (ticket >   0) Print ("Position ", OrderTicket() ," closed");
      }
   }
   
   return (0);
}

void CreateButtons()
{
   int Button_Height = (int)(Font_Size * 2.8);
   
   if (!ButtonCreate (0, "stopEA", 0, 150, 20, 120, Button_Height, 1, stopEATxt, Font_Type, Font_Size, Font_Color, stopEAClr, clrYellow)) return;
   
   if (!ButtonCreate (0, "closeAll", 0, 280, 120, 250, Button_Height, 3, "Close All", Font_Type, Font_Size, Font_Color, clrDarkGreen, clrYellow)) return;
   if (!ButtonCreate (0, "closeBuy", 0, 280, 80, 120, Button_Height, 3, "Close Buy", Font_Type, Font_Size, Font_Color, clrDarkGreen, clrYellow)) return;
   if (!ButtonCreate (0, "closeSell", 0, 150, 80, 120, Button_Height, 3, "Close Sell", Font_Type, Font_Size, Font_Color, clrDarkGreen, clrYellow)) return;
   if (!ButtonCreate (0, "closePositive", 0, 280, 40, 120, Button_Height, 3, "Close (+)", Font_Type, Font_Size, Font_Color, clrDarkGreen, clrYellow)) return;
   if (!ButtonCreate (0, "closeNegative", 0, 150, 40, 120, Button_Height, 3, "Close (-)", Font_Type, Font_Size, Font_Color, clrDarkGreen, clrYellow)) return;
   
   ChartRedraw();
}

bool ButtonCreate (const long chart_ID = 0, const string name = "Button", const int sub_window = 0, const int x = 0, const int y = 0, const int width = 500,
                   const int height = 18, int corner = 0, const string text = "button", const string font = "Arial Bold",
                   const int font_size = 10, const color clr = clrBlack, const color back_clr = C'170,170,170', const color border_clr = clrNONE,
                   const bool state = false, const bool back = false, const bool selection = false, const bool hidden = true, const long z_order = 0)
{
   ResetLastError();
   if (!ObjectCreate (chart_ID,name, OBJ_BUTTON, sub_window, 0, 0))
     {
      Print (__FUNCTION__, " : failed to create the button! Error code : ", GetLastError());
      return(false);
     }
   ObjectSetInteger (chart_ID, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger (chart_ID, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger (chart_ID, name, OBJPROP_XSIZE, width);
   ObjectSetInteger (chart_ID, name, OBJPROP_YSIZE, height);
   ObjectSetInteger (chart_ID, name, OBJPROP_CORNER, corner);
   ObjectSetInteger (chart_ID, name, OBJPROP_FONTSIZE, font_size);
   ObjectSetInteger (chart_ID, name, OBJPROP_COLOR, clr);
   ObjectSetInteger (chart_ID, name, OBJPROP_BGCOLOR, back_clr);
   ObjectSetInteger (chart_ID, name, OBJPROP_BORDER_COLOR, border_clr);
   ObjectSetInteger (chart_ID, name, OBJPROP_BACK, back);
   ObjectSetInteger (chart_ID, name, OBJPROP_STATE, state);
   ObjectSetInteger (chart_ID, name, OBJPROP_SELECTABLE, selection);
   ObjectSetInteger (chart_ID, name, OBJPROP_SELECTED, selection);
   ObjectSetInteger (chart_ID, name, OBJPROP_HIDDEN, hidden);
   ObjectSetInteger (chart_ID, name, OBJPROP_ZORDER,z_order);
   ObjectSetString  (chart_ID, name, OBJPROP_TEXT, text);
   ObjectSetString  (chart_ID, name, OBJPROP_FONT, font);
   return(true);
}

void Draw(string name,string label,int size,string font,color clr,int corner,int x,int y)
{
   int windows=0;
   
   ObjectDelete(name);
   ObjectCreate(name,OBJ_LABEL,windows,0,0);
   ObjectSetText(name,label,size,font,clr);
   ObjectSet(name,OBJPROP_CORNER,corner);
   ObjectSet(name,OBJPROP_XDISTANCE,x);
   ObjectSet(name,OBJPROP_YDISTANCE,y);
}//End void Draw()