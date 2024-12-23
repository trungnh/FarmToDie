//+------------------------------------------------------------------+
//|                                                       Farmer.mq4 |
//|                                                    Trung đẹp zai |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#include<Strings\String.mqh>
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
  
enum ordType
  {
   ORIGIN_ORDER = 1,
   DUPLICATE_ORDER = 0,
  };
  
extern int MagicNumber = 179092;                                     // Magic Number

extern string ________General________ = "============== General ==============";
extern modetrade kieuTrade = BUY_AND_SELL;                           // Kieu Vao Lenh        
extern double lotsize = 0.01;                                        // Lot Size
extern double pipsDiff = 10;                                         // Khoang Cach Vao Lenh (Pips)
extern double multiple = 1;                                          // He So Nhan Lot
extern double pipTP = 23;                                            // TP (Pips)
extern int delayTime = 3;                                            // Khoang Gian Dung Giua 2 Lenh (Tính Theo Giay)
extern bool autoDegradeLotsize = false;                              // Tu Dong Giam Lotsize cac L cao
//extern double pipSL = 0;                                           // SL (Pips)

input string ______StopLoss_Settings______    = "========== StopLoss Settings ==========";   
extern double priceSLBuy = 0;                                          // SL Toan Bo Chuoi Lenh Buy
extern double priceSLSell = 0;                                         // SL Toan Bo Chuoi Lenh Sell

extern string ________DayOpen_Stop_Bot________ = "============== DayOpen Stop Bot ==============";
extern bool useDayOpenPrice = true;                                  // Su Dung Gia Mo Cua Tinh Toan Diem Dung Bot
extern double tamGia = 0;                                            // Tam Gia Tính Toan Diem Dung Bot (Thay Cho Gia Mo Cua)
extern double stopBuySellDiffFromDayOpen = 0;                        // Khoang Cach KO BUY/SELL - Tinh Tu Gia Mo Cua
extern double stopEADiffFromDayOpen = 0;                             // Khoang Cach Stop EA - Tinh Tu Gia Mo Cua
extern bool autoStartEA = true;                                      // Tu Dong Start EA Khi Vao Vùng Bien Gia

extern double stopEALowInp = 0;                                      // Gia STOP EA - Bien Duoi (Gia Di Xuong Auto StopEA)
extern double stopEAHighInp = 0;                                     // Gia STOP EA - Bien Tren (Gia Di Len Auto StopEA)

extern string ________Pause_Bot________ = "============== Pause Bot ==============";
extern int maxOrderBUY = 60;                                         // So Lenh BUY Toi Da
extern int maxOrderSELL = 60;                                        // So Lenh SELL Toi Da
extern double pauseBuyPrice = 0;                                     // Gia Pause BUY (Gia Di Xuong Auto Pause BUY)
extern double pauseSellPrice = 0;                                    // Gia Pause SELL (Gia Di Lên Auto Pause SELL)
extern bool autoPauseBuySell = false;                                 // Tu Dong Pause Khi Het Gio Trade

extern string ________Grid_TP________ = "============== Gop TP ==============";
extern bool useGridTP = false;                                      // Su Dung Gop TP Chuoi Lenh
extern int levelStartGridTP = 20;                                   // Level Bat Dau Gop TP
extern double gridLotsize = 0.01;                                   // Lot Size Chuoi
extern double gridMultiple = 1.1;                                   // He So Nhan Lot
extern double gridPipTP = 10;                                       // TP Chuoi (Pips)
extern bool dcaOffTime = true;                                      // Tiep Tuc DCA Ngoai Trading Time

extern string ________TimeFilter________ = "===== Time Filter (Setting Theo Gio Cua MT4) =====";
extern int StartHour = 0;                         // Gio Bat Dau Chay
extern int StartMinute = 0;                       // Phut Bat Dau Chay
extern int EndHour = 23;                          // Gio Ket Thuc
extern int EndMinute = 59;                        // Phut Ket Thuc

extern string ________Buttons________ = "===== Setting Buttons =====";
extern bool confirmClose = true;                  // Hoi Lai Khi Click Close Buttons
extern bool showHedgeBtn = false;                 // Hien Thi Button Hedge
extern bool showCloseBtn = false;                 // Hien Thi Button Close All
extern bool showBoudaryLine = false;              // Hien Thi Cac Duong Danh Dau Buy/Sell/StopEA

string cmt = "FarmToDie: ";
string orgString = "Org";
string dupString = "Dup";
string gridString = "Grid";

// ---- Button
string Font_Type = "Arial Bold";
color Font_Color = clrWhite;
int Font_Size = 10;

bool stopEAFlg = false;
color stopEAClr = clrTeal;
string stopEATxt = "Stop EA: OFF";

bool pauseBuyFlg = false;
color pauseBuyClr = clrTeal;
string pauseBuyTxt = "Pause BUY: OFF";

bool pauseSellFlg = false;
color pauseSellClr = clrTeal;
string pauseSellTxt = "Pause SELL: OFF";
// ---- Button

bool openOrder = true;
double p0w, currentLots;

// GetHigh_LowPrice_TotalOrder()
int totalOrder, totalOrdBuy, totalOrdSell;
int totalOrdBuyOrg, totalOrdSellOrg, totalOrdBuyDup, totalOrdSellDup, totalOrdBuyGrid, totalOrdSellGrid;
double totalLotsBuy, totalLotsSell;
double totalProfit;
int countOrd;

// GetHigh_LowPrice_TotalOrder()
double higPriceBuy, higPriceSell, lowPriceSell, lowPriceBuy;
double recentBuy, recentSell;
int tckLowSell, tckHigBuy;
double comSell, swapSell, lotsSell, profitSell, totalProfitSell;
double totalProfitBuy, profitBuy, comBuy, swapBuy, lotsBuy;

double accountBalance, accountEnquity;

double stopBuyPrice, stopSellPrice;
double stopEALow, stopEAHigh;

// GetNormalLotUnit()
int normalLotUnit = 2;

int PIPS_TO_POINT_MULTI = 10;
datetime trial_end_date = D'25.08.2024';

int OnInit()
  {
//---
   if (checkActivation() == 1) {
      CreateButtons();
      GetNormalLotUnit();
   } else {
      Draw("notif", "EA da het han su dung. Vui long lien he: https://t.me/gnurt28 | +84782390668", 12, "Calibri Bold", clrYellow, 4, 20, 20);
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
   ObjectsDeleteAll();
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
//---
   initVariables();
   
   if (stopEAHigh != 0 && stopEALow !=0) {
      if (
            (MarketInfo(Symbol(), MODE_BID) > stopEAHigh || 
            MarketInfo(Symbol(), MODE_ASK) < stopEALow) 
            && !stopEAFlg
         ) {
            stopEA();
      }
   }
   
   // Tu dong start EA neu su dung gia mo cua lam moc gia
   if (stopEAFlg && autoStartEA) {
      if ( (MarketInfo(Symbol(), MODE_BID) < stopEAHigh) && (MarketInfo(Symbol(), MODE_ASK) > stopEALow) ){
            startEA();
         }
   }
   
   if (pauseBuyPrice != 0 && !pauseBuyFlg && (MarketInfo(Symbol(), MODE_ASK) < pauseBuyPrice)) {
      pauseBuy();
   }
   if (pauseSellPrice != 0 && !pauseSellFlg && (MarketInfo(Symbol(), MODE_BID) > pauseSellPrice)) {
      pauseSell();
   }

   GetHigh_LowPrice_TotalOrder();
      
   if (!stopEAFlg) {  
      doAction();
   }
   
   // Auto Pause Buy Sell khi het gio trade
   if (!checkTradingTime() && autoPauseBuySell) {
      if (!pauseBuyFlg) {
         pauseBuy();
      }
      if (!pauseSellFlg) {
         pauseSell();
      }
      
   }
   
   showInfo();
   if (showBoudaryLine) {
      createStopEALine();
      createBuySellLine();
      moveStopEALine();
      moveBuySellLine();
   } else {
      deleteBoundaryLines();
   }
}
//+------------------------------------------------------------------+

int checkActivation()
{
   return (1);
   if(TimeCurrent() > trial_end_date)
   {
       Alert("EA Da Het Han! Vui Long Lien He +84782390668");
       ExpertRemove();
       
       return (-1);
   }
   
   return (1);
} // End void checkActivation()

void initVariables()
{   

   if (Digits == 3) {
      PIPS_TO_POINT_MULTI = 100; // EXNESS XAUDUSD
   }
   
   double tmpTamGia = getTamGia();
   stopBuyPrice = tmpTamGia + stopBuySellDiffFromDayOpen;
   stopSellPrice = tmpTamGia - stopBuySellDiffFromDayOpen;
   
   if (!useDayOpenPrice && tamGia == 0 && stopBuySellDiffFromDayOpen ==0) {
      stopBuyPrice = 0;
      stopSellPrice = 0;
   }
   
   stopEALow = tmpTamGia - stopEADiffFromDayOpen;
   stopEAHigh = tmpTamGia + stopEADiffFromDayOpen;
   
   if (stopEADiffFromDayOpen == 0) {
      stopEALow = stopEALowInp;
      stopEAHigh = stopEAHighInp;
   }
}

double getTamGia()
{
   if (useDayOpenPrice || tamGia == 0) {
      int shift = iBarShift(Symbol(),PERIOD_D1,Time[0]);
   
      return iOpen(Symbol(),PERIOD_D1,shift);
   }
   
   return tamGia;
}

//+------------------------------------------------------------------+
void doAction ()
{
   // Only Buy
   if (!pauseBuyFlg) {
      doActionBuy();
   }
   
   // Only Sell
   if (!pauseSellFlg) {
      doActionSell();
   }
   
   
}// End void doAction()

void doActionBuy()
{
   if (kieuTrade == ONLY_BUY || kieuTrade == BUY_AND_SELL) 
   {
      if (stopBuyPrice == 0 || (stopBuyPrice !=0 && MarketInfo(Symbol(), MODE_ASK) < stopBuyPrice)) {
         // Check buy order
         double price = MarketInfo(Symbol(), MODE_ASK);
         double tp = price + (pipTP * PIPS_TO_POINT_MULTI * MarketInfo(Symbol(), MODE_POINT));
         string cm = cmt + "BUY-" + (totalOrdBuy + 1);
         
         if (totalOrdBuy == 0 && checkTradingTime() == 1)
         {
            cm += "|" + orgString + "-1";
            openOrd (ORDER_TYPE_BUY, price, priceSLBuy, tp, cm, 1, lotsize);
         }
         else if (totalOrdBuy != 0 && totalOrdBuy < maxOrderBUY)
         {
            // ========== Bat dau TP gop ==========
            if (useGridTP && totalOrdBuy >= levelStartGridTP) 
            {
               // Checking DCA off time
               bool dcaFlg = false;
               if (checkTradingTime() == 1) {
                  dcaFlg = true;
               } 
               // Allow DCA off time
               if (checkTradingTime() == 0 && dcaOffTime) {
                  dcaFlg = true;
               }
               
               // If allow DCA off time
               if ( lowPriceBuy - price >= pipsDiff* PIPS_TO_POINT_MULTI *MarketInfo(Symbol(), MODE_POINT) && dcaFlg)
               {
                  cm += "|" + orgString + "-" + (totalOrdBuyOrg+1) + "|" + gridString + "-" + (totalOrdBuyGrid+1);
                  double gridTP = price + (gridPipTP * PIPS_TO_POINT_MULTI * MarketInfo(Symbol(), MODE_POINT));
                  
                  int tmp = openOrd (ORDER_TYPE_BUY, price, priceSLBuy, gridTP, cm, gridMultiple, gridLotsize, true);
                  if (tmp > 0) {
                     // Modify SL - TP
                     double BE_Buy = breakeven(Symbol(), ORDER_TYPE_BUY, MagicNumber, gridLotsize);
                     double buyAllTP = (BE_Buy + gridPipTP* PIPS_TO_POINT_MULTI *MarketInfo(Symbol(), MODE_POINT));
                     modifyTP (Symbol(), ORDER_TYPE_BUY, buyAllTP, priceSLBuy);
                  }
               }
            } // if (useGridTP && totalOrdBuy >= levelStartGridTP)  
            else 
            { // ========== Chua TP Gop ==========
               // Trading time
               if (checkTradingTime() == 1) {
                  if (lowPriceBuy - price >= pipsDiff* PIPS_TO_POINT_MULTI *MarketInfo(Symbol(), MODE_POINT))
                  {
                     cm += "|" + orgString + "-" + (totalOrdBuyOrg+1);
                     openOrd (ORDER_TYPE_BUY, price, priceSLBuy, tp, cm, multiple, lotsize);
                  }
                  
                  // Khi lenh buy chua tp thi du quang lai tiep tuc buy (buy lien tuc trong khoang lowBuy <=> TP
                  if (
                        (price < tp) &&
                        (price > lowPriceBuy)
                  ) {
                     // Gia di len tren lenh buy cuoi cung, du quang la buy
                     if (
                           (price > recentBuy) && 
                           (price - recentBuy >= pipsDiff* PIPS_TO_POINT_MULTI *MarketInfo(Symbol(), MODE_POINT))
                        ) {
                              cm += "|" + dupString + "-" + (totalOrdBuyDup+1);
                              
                              double buyDupLotSize = getDuplicateOrdLotSize(totalOrdBuyDup+1);
                              openOrd (ORDER_TYPE_BUY, price, priceSLBuy, tp, cm, 1, buyDupLotSize);
                     } 
                     // Gia di xuong duoi lenh buy cuoi cung, du quang la buy
                     else if (
                           (price < recentBuy) && 
                           (recentBuy - price >= pipsDiff* PIPS_TO_POINT_MULTI *MarketInfo(Symbol(), MODE_POINT))
                        ) {
                              cm += "|" + dupString + "-" + (totalOrdBuyDup+1);
                              
                              double buyDupLotSize = getDuplicateOrdLotSize(totalOrdBuyDup+1);
                              openOrd (ORDER_TYPE_BUY, price, priceSLBuy, tp, cm, 1, buyDupLotSize);
                     }
                  } // (price < tp) && (price > lowPriceBuy)
               } // if (checkTradingTime() == 1) {
            } // ========== END Ko TP Gop ==========
         }
      } //if (stopBuyPrice == 0 || (stopBuyPrice !=0 && MarketInfo(Symbol(), MODE_ASK) < stopBuyPrice))
      // Neu vuot qua bien trading nhung da bat dau dca gop TP thi cu tiep tuc DCA
      else if (
          stopBuyPrice !=0 && 
          MarketInfo(Symbol(), MODE_ASK) > stopBuyPrice && 
          useGridTP && 
          totalOrdBuy >= levelStartGridTP
      ) {
         // Checking DCA off time
         bool dcaFlg = false;
         if (checkTradingTime() == 1) {
            dcaFlg = true;
         } 
         // Allow DCA off time
         if (checkTradingTime() == 0 && dcaOffTime) {
            dcaFlg = true;
         }
         
         double price = MarketInfo(Symbol(), MODE_ASK);
         double tp = price + (pipTP * PIPS_TO_POINT_MULTI * MarketInfo(Symbol(), MODE_POINT));
         string cm = cmt + "BUY-" + (totalOrdBuy + 1);
         
         // If allow DCA off time
         if ( lowPriceBuy - price >= pipsDiff* PIPS_TO_POINT_MULTI *MarketInfo(Symbol(), MODE_POINT) && dcaFlg)
         {         
            cm += "|" + orgString + "-" + (totalOrdBuyOrg+1) + "|" + gridString + "-" + (totalOrdBuyGrid+1);
            double gridTP = price + (gridPipTP * PIPS_TO_POINT_MULTI * MarketInfo(Symbol(), MODE_POINT));
            
            int tmp = openOrd (ORDER_TYPE_BUY, price, priceSLBuy, gridTP, cm, gridMultiple, gridLotsize, true);
            if (tmp > 0) {
               // Modify SL - TP
               double BE_Buy = breakeven(Symbol(), ORDER_TYPE_BUY, MagicNumber, gridLotsize);
               double buyAllTP = (BE_Buy + gridPipTP* PIPS_TO_POINT_MULTI *MarketInfo(Symbol(), MODE_POINT));
               modifyTP (Symbol(), ORDER_TYPE_BUY, buyAllTP, priceSLBuy);
            }
         }
      }
   } // if (kieuTrade == ONLY_BUY || kieuTrade == BUY_AND_SELL) 
} // End doActionBuy()

void doActionSell()
{
   if (kieuTrade == ONLY_SELL || kieuTrade == BUY_AND_SELL) { 
      if (stopSellPrice == 0 || (stopSellPrice!=0 && MarketInfo(Symbol(), MODE_BID) > stopSellPrice)) 
      {
         // Check Sell order
         double price = MarketInfo(Symbol(), MODE_BID);
         double tp = price - (pipTP * PIPS_TO_POINT_MULTI * MarketInfo(Symbol(), MODE_POINT));
         string cm = cmt + "SELL-" + (totalOrdSell + 1);
         
         if (totalOrdSell == 0 && checkTradingTime() == 1)
         {
            cm += "|" + orgString + "-1";
            openOrd (ORDER_TYPE_SELL, price, priceSLSell, tp, cm, 1, lotsize);
         }
         else if ( totalOrdSell != 0 && totalOrdSell < maxOrderSELL)
         {
            // ========== TP gop ==========
            if (useGridTP && totalOrdSell >= levelStartGridTP) 
            {
               // Checking DCA off time
               bool dcaFlg = false;
               if (checkTradingTime() == 1) {
                  dcaFlg = true;
               } 
               // Allow DCA off time
               if (checkTradingTime() == 0 && dcaOffTime) {
                  dcaFlg = true;
               }
               
               // If allow DCA off time
               if ( price - higPriceSell >= pipsDiff* PIPS_TO_POINT_MULTI *MarketInfo(Symbol(), MODE_POINT) && dcaFlg)
               {
                  cm += "|" + orgString + "-" + (totalOrdSellOrg+1) + "|" + gridString + "-" + (totalOrdSellGrid+1);
                  double gridTP = price - (gridPipTP * PIPS_TO_POINT_MULTI * MarketInfo(Symbol(), MODE_POINT));
                  
                  int tmp = openOrd (ORDER_TYPE_SELL, price, priceSLSell, gridTP, cm, gridMultiple, gridLotsize, true);
                  if (tmp > 0) {
                     // Modify SL - TP
                     double BE_Sell = breakeven(Symbol(), ORDER_TYPE_SELL, MagicNumber, gridLotsize);
                     double sellAllTP = (BE_Sell - gridPipTP* PIPS_TO_POINT_MULTI *MarketInfo(Symbol(), MODE_POINT));
                     modifyTP (Symbol(), ORDER_TYPE_SELL, sellAllTP, priceSLSell);
                  }
               }
            } // if (useGridTP && totalOrdSell >= levelStartGridTP) 
            else 
            { // ========== Ko TP gop ==========
               if (checkTradingTime() == 1) {
                  if ( price - higPriceSell >= pipsDiff* PIPS_TO_POINT_MULTI *MarketInfo(Symbol(), MODE_POINT))
                  {
                     cm += "|" + orgString + "-" + (totalOrdSellOrg+1);
                     openOrd (ORDER_TYPE_SELL, price, priceSLSell, tp, cm, multiple, lotsize);
                  }
                  
                  // Khi lenh buy chua tp thi du quang lai tiep tuc buy (buy lien tuc trong khoang lowBuy <=> TP
                  if (
                        (price > tp) &&
                        (price < higPriceSell)
                  ) {
                     // Gia di len tren lenh sell cuoi cung, du quang la buy
                     if (
                           (price > recentSell) && 
                           (price - recentSell >= pipsDiff* PIPS_TO_POINT_MULTI *MarketInfo(Symbol(), MODE_POINT))
                        ) {
                           cm += "|" + dupString + "-" + (totalOrdSellDup+1);
                           
                           double sellDupLotSize = getDuplicateOrdLotSize(totalOrdSellDup+1);
                           openOrd (ORDER_TYPE_SELL, price, priceSLSell, tp, cm, 1, sellDupLotSize);
                     }
                     // Gia di xuong duoi lenh sell cuoi cung, du quang la buy
                     else if (
                           (price < recentSell) && 
                           (recentSell - price >= pipsDiff* PIPS_TO_POINT_MULTI *MarketInfo(Symbol(), MODE_POINT))
                        ) {
                           cm += "|" + dupString + "-" + (totalOrdSellDup+1);
                           
                           double sellDupLotSize = getDuplicateOrdLotSize(totalOrdSellDup+1);
                           openOrd (ORDER_TYPE_SELL, price, priceSLSell, tp, cm, 1, sellDupLotSize);
                     }
                  } // (price > tp) && (price < higPriceSell)
               } // if (checkTradingTime() == 1) {
            }
            // ========== END Ko TP gop ==========
            
         }
      } // if (stopSellPrice == 0 || (stopSellPrice!=0 && MarketInfo(Symbol(), MODE_BID) > stopSellPrice)) 
      else if (
         stopSellPrice!=0 && 
         MarketInfo(Symbol(), MODE_BID) < stopSellPrice &&
         useGridTP && 
         totalOrdSell >= levelStartGridTP
      ) {
         // Checking DCA off time
         bool dcaFlg = false;
         if (checkTradingTime() == 1) {
            dcaFlg = true;
         } 
         // Allow DCA off time
         if (checkTradingTime() == 0 && dcaOffTime) {
            dcaFlg = true;
         }
         
         // Check Sell order
         double price = MarketInfo(Symbol(), MODE_BID);
         double tp = price - (pipTP * PIPS_TO_POINT_MULTI * MarketInfo(Symbol(), MODE_POINT));
         string cm = cmt + "SELL-" + (totalOrdSell + 1);
            
         // If allow DCA off time
         if ( price - higPriceSell >= pipsDiff* PIPS_TO_POINT_MULTI *MarketInfo(Symbol(), MODE_POINT) && dcaFlg)
         {
            cm += "|" + orgString + "-" + (totalOrdSellOrg+1) + "|" + gridString + "-" + (totalOrdSellGrid+1);
            double gridTP = price - (gridPipTP * PIPS_TO_POINT_MULTI * MarketInfo(Symbol(), MODE_POINT));
            
            int tmp = openOrd (ORDER_TYPE_SELL, price, priceSLSell, gridTP, cm, gridMultiple, gridLotsize, true);
            if (tmp > 0) {
               // Modify SL - TP
               double BE_Sell = breakeven(Symbol(), ORDER_TYPE_SELL, MagicNumber, gridLotsize);
               double sellAllTP = (BE_Sell - gridPipTP* PIPS_TO_POINT_MULTI *MarketInfo(Symbol(), MODE_POINT));
               modifyTP (Symbol(), ORDER_TYPE_SELL, sellAllTP, priceSLSell);
            }
         }
      }
   }
} // End doActionSell()

//+------------------------------------------------------------------+
int openOrd ( int oP, double entry, double sL, double tP, string cm, double multi, double lot, bool gridTP = false)
{
   GetValLot (oP, multi, lot, gridTP);
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
         
         return (0);
      }
      
      return tk;
   }
   
   return (0);
}// End void openOrd()

void modifyTP(string symbol, int oP, double tp, double sl)
{
   for (int i = 0; i < OrdersTotal(); i++)
   {
      if (!OrderSelect(i,SELECT_BY_POS, MODE_TRADES)) { continue;}
      if (OrderSymbol() != symbol) { continue;}
      if (OrderMagicNumber() != MagicNumber) { continue;}
      
      if (OrderType() == oP) { 
         // Modify TP nhung lenh truoc do
         int tk = OrderModify(OrderTicket(), OrderOpenPrice(), sl, tp, 0, clrAliceBlue);
         if (tk <= 0) { Print("Error Modify Order DCA " + DoubleToStr(oP,0) + " : ",GetLastError());}
      }
   }
}// End void modifyTP()

void GetValLot(int oP, double Multi, double fixLots, bool gridTP = false)
{
   if (gridTP) {
      if (oP == OP_BUY)
      {
         p0w = totalOrdBuyGrid;
      }
      else if ( oP == OP_SELL)
      {
         p0w = totalOrdSellGrid;
      }
   } else {
      if (oP == OP_BUY)
      {
         p0w = totalOrdBuyOrg;
      }
      else if ( oP == OP_SELL)
      {
         p0w = totalOrdSellOrg;
      }
   }
   
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

//+------------------------------------------------------------------+
double getDuplicateOrdLotSize (int level)
{
   if (!autoDegradeLotsize) { return lotsize; }
   
   if (level >= 40) 
   {
      return lotsize * 0.6; // 60% lotsize 
   } else if (level >= 24) 
   {
      return lotsize * 0.4; // 40% lotsize 
   } else if (level >= 16) 
   {
      return lotsize * 0.6; // 60% lotsize 
   } else if (level >= 8) 
   {
      return lotsize * 0.8; // 80% lotsize 
   } else {
      return lotsize;
   }
} //End void getMultiple()

void GetHigh_LowPrice_TotalOrder()
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
   
   // Total order
   totalOrder = 0;
   totalOrdBuy = 0;
   totalOrdSell = 0;
   totalOrdBuyOrg = 0;
   totalOrdBuyDup = 0;
   totalOrdSellOrg = 0;
   totalOrdSellDup = 0;
   totalLotsBuy = 0;
   totalLotsSell = 0;
   totalOrdBuyGrid = 0;
   totalOrdSellGrid = 0;
   
   double profit = 0, swap = 0;
   
   accountBalance = AccountBalance();
   accountEnquity = AccountEquity();
   
   if (OrdersTotal() == 0)
   {   return; }
   
   for (int i = 0; i < OrdersTotal(); i++)
   {
      if (!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) { continue;}
      if (OrderSymbol() != Symbol()) { continue;}
      if (OrderMagicNumber() != MagicNumber) { continue;}
      
      totalOrder ++; 
      profit += OrderProfit();
      swap += OrderSwap();
      string ordCmt = OrderComment(); 
            
      if (OrderType() == OP_SELL)
      {
         /* === Dem tong so lenh nhoi am va lenh nhoi duong === */
         if (StringFind(ordCmt, orgString, 0) > -1) {
            totalOrdSellOrg++;
         }
         if (StringFind(ordCmt, dupString, 0) > -1) {
            totalOrdSellDup++;
         } 
         if (StringFind(ordCmt, gridString, 0) > -1) {
            totalOrdSellGrid++;
         } 
         /* === Dem tong so lenh nhoi am va lenh nhoi duong === */
         totalOrdSell++;
         totalLotsSell += OrderLots();
         
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
         /* === Dem tong so lenh nhoi am va lenh nhoi duong === */
         if (StringFind(ordCmt, orgString, 0) > -1) {
            totalOrdBuyOrg++;
         }
		   if (StringFind(ordCmt, dupString, 0) > -1) {
			   totalOrdBuyDup++;
			} 
			if (StringFind(ordCmt, gridString, 0) > -1) {
			   totalOrdBuyGrid++;
			}
			/* === Dem tong so lenh nhoi am va lenh nhoi duong === */
         totalOrdBuy++;
         totalLotsBuy += OrderLots();
               
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
   
   totalProfit = profit + swap;
   
} // End void GetHigh_LowPrice_TotalOrder()

//+------------------------------------------------------------------+
double breakeven(string symBE, int bTyp, int mNumber, double addLot)
{
   double equity = 0, lots = 0;
   int cnt = OrdersTotal(),   size = 0, ind = 0;
   for (int i=0; i<cnt; i++)
   {
      if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if ( OrderMagicNumber() != MagicNumber)   {  continue;   }
      int oType = OrderType();
      if (oType != OP_BUY && oType != OP_SELL) continue;
      if(OrderSymbol() == symBE) 
      {
         if (bTyp == OP_SELL) 
         {  if (oType == OP_SELL) 
            {  equity += OrderProfit() + OrderCommission() + OrderSwap();  lots -= OrderLots();  } }
         else if (bTyp == OP_BUY) 
         {  if (oType == OP_BUY) 
            {  equity += OrderProfit() + OrderCommission() + OrderSwap();  lots += OrderLots(); }  }
         else if(bTyp == OP_BUYSELL) 
         {  equity += OrderProfit() + OrderCommission() + OrderSwap();  if (oType == OP_BUY) lots += OrderLots(); if (oType == OP_SELL) lots -= OrderLots();   }
      }
   }
   double curPrice = bTyp == OP_SELL  ? MarketInfo(symBE, MODE_ASK) : MarketInfo(symBE, MODE_BID);
   double bre = 0;
   if (lots == 0) {  bre = 0; }
   else 
   {  double COP = lots*MarketInfo(symBE, MODE_TICKVALUE);  double val = curPrice - MarketInfo(Symbol(),MODE_POINT)*equity/COP;  bre = NormalizeDouble(val, _Digits);   }
   return bre;
} //End double breakeven()

//+------------------------------------------------------------------+
void showInfo()
{
   bool oneclick = ChartGetInteger(0,CHART_SHOW_ONE_CLICK);
   int x = 20;
   if (oneclick) {
      x = 220;
   }
   
   RectLabelCreate(0,"BG", 0, x - 10, 20, 300, 220, clrMidnightBlue, BORDER_RAISED, CORNER_LEFT_UPPER, clrMidnightBlue, STYLE_SOLID, 2, false, false, true, 0);
   Draw("Bot_Name", "============ Farm To Die ============", 12, "Calibri Bold", clrYellow, 4, x, 20);
      
   Draw("Balance", "Balance: " + FormatNumber(NormalizeDouble(accountBalance, 2), " "), 12, "Calibri Bold", clrYellow, 4, x, 160);
   Draw("Enquity", "Enquity: " + FormatNumber(NormalizeDouble(accountEnquity, 2), " "), 12, "Calibri Bold", clrYellow, 4, x, 180);
   
   if (totalProfit > 0) {
      Draw("Profit", "===== Total Profit: " + NormalizeDouble(totalProfit, 2), 12, "Calibri Bold", clrLime, 4, x, 120);
   } else {
      Draw("Profit", "===== Total Profit: " + NormalizeDouble(totalProfit, 2), 12, "Calibri Bold", clrTomato, 4, x, 120);
   }
   
   Draw("Total_Buy", "Buy: " + totalOrdBuy + " orders" + " / " + NormalizeDouble(totalLotsBuy, 2) + " lots", 12, "Calibri Bold", clrLime, 4, x, 100);
   Draw("Profit_Buy", "Profit Buy: " + NormalizeDouble(totalProfitBuy, 2), 12, "Calibri Bold", clrLime, 4, x, 80);
   Draw("Total_Sell", "Sell: " + totalOrdSell + " orders" + " / " + NormalizeDouble(totalLotsSell, 2) + " lots", 12, "Calibri Bold", clrRed, 4, x, 60);
   Draw("Profit_Sell", "Profit Sell: " + NormalizeDouble(totalProfitSell, 2), 12, "Calibri Bold", clrRed, 4, x, 40);
   
   datetime server_time = TimeCurrent();
   datetime gmt_time = TimeGMT();
     
   int offset_seconds=((int)server_time)-((int)gmt_time);
   int serverOffset = offset_seconds / 3600;
   
   int diffServerGMT7Offset = 7 - serverOffset;
   
   Draw("ServerTime", "TZ Diff From GMT7: -" + diffServerGMT7Offset, 12, "Calibri Bold", clrYellow, 4, x, 210);
}

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
void ButtonPressed (const long chartID, const string action)
{
   if (action == "stopEA") stopEAPressed (chartID, action);
   if (action == "pauseBuy") pauseBuyPressed (chartID, action);
   if (action == "pauseSell") pauseSellPressed (chartID, action);
   
   if (action == "closeAll") closeAllPressed (chartID, action);
   if (action == "closeBuy") closeBuyPressed (chartID, action);
   if (action == "closeSell") closeSellPressed (chartID, action);
   if (action == "closeNegative") closeNegativePressed (chartID, action);
   if (action == "closePositive") closePositivePressed (chartID, action);
   
   if (action == "hedge") hedgePressed (chartID, action);
   if (action == "clearTP") clearTPPressed (chartID, action);
   if (action == "updateTP") updateTPPressed (chartID, action);
   //Sleep (1000);
  
}

//+------------------------------------------------------------------+
int stopEAPressed (const long chartID, const string action)
{   
   if (stopEAFlg) {
      startEA();
   } else {
      stopEA();
   }
   
   return (0);
}

void stopEA()
{
   stopEAFlg = true;
   stopEAClr = clrRed;
   stopEATxt = "StopEA: ON";
   
   ObjectSetInteger (0, "stopEA", OBJPROP_BGCOLOR, stopEAClr);
   ObjectSetString  (0, "stopEA", OBJPROP_TEXT, stopEATxt);
   
   SendNotification("Stop EA");
}

void startEA()
{
   stopEAFlg = false;
   stopEAClr = clrTeal;
   stopEATxt = "StopEA: OFF";
   
   ObjectSetInteger (0, "stopEA", OBJPROP_BGCOLOR, stopEAClr);
   ObjectSetString  (0, "stopEA", OBJPROP_TEXT, stopEATxt);
}

//+------------------------------------------------------------------+
int pauseBuyPressed (const long chartID, const string action)
{   
   if (pauseBuyFlg) {
      startBuy();
   } else {
      pauseBuy();
   }
   
   return (0);
}

void pauseBuy()
{
   pauseBuyFlg = true;
   pauseBuyClr = clrRed;
   pauseBuyTxt = "Pause BUY: ON";
   
   ObjectSetInteger (0, "pauseBuy", OBJPROP_BGCOLOR, pauseBuyClr);
   ObjectSetString  (0, "pauseBuy", OBJPROP_TEXT, pauseBuyTxt);
   
   SendNotification("Pause Buy");
}

void startBuy()
{
   pauseBuyFlg = false;
   pauseBuyClr = clrTeal;
   pauseBuyTxt = "Pause BUY: OFF";
   
   ObjectSetInteger (0, "pauseBuy", OBJPROP_BGCOLOR, pauseBuyClr);
   ObjectSetString  (0, "pauseBuy", OBJPROP_TEXT, pauseBuyTxt);
}

//+------------------------------------------------------------------+
int pauseSellPressed (const long chartID, const string action)
{   
   if (pauseSellFlg) {
      startSell();
   } else {
      pauseSell();
   }
   
   return (0);
}

void pauseSell()
{
   pauseSellFlg = true;
   pauseSellClr = clrRed;
   pauseSellTxt = "Pause SELL: ON";
   
   ObjectSetInteger (0, "pauseSell", OBJPROP_BGCOLOR, pauseSellClr);
   ObjectSetString  (0, "pauseSell", OBJPROP_TEXT, pauseSellTxt);
   
   SendNotification("Pause Sell");
}

void startSell()
{
   pauseSellFlg = false;
   pauseSellClr = clrTeal;
   pauseSellTxt = "Pause SELL: OFF";
   
   ObjectSetInteger (0, "pauseSell", OBJPROP_BGCOLOR, pauseSellClr);
   ObjectSetString  (0, "pauseSell", OBJPROP_TEXT, pauseSellTxt);
}

//+------------------------------------------------------------------+
int closeNegativePressed (const long chartID, const string action)
{   
   if (confirmClose) {
      int CloseNegative = MessageBox("Close All (-)", "Close Order", IDOK);
   
      if (CloseNegative == IDOK) {
         closeNegativeOrders();
         
         return (0);
      }
   } else {
      closeNegativeOrders();
      
      return (0);
   }
   
   return (0);
}

int closeNegativeOrders ()
{   
   int ticket;
   if (OrdersTotal() == 0) return(0);
   for (int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if (OrderSelect (i, SELECT_BY_POS, MODE_TRADES) == true)
      {
         if (OrderMagicNumber() != MagicNumber) { continue; }
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

//+------------------------------------------------------------------+
int closePositivePressed (const long chartID, const string action)
{   
   if (confirmClose) {
      int ClosePositive = MessageBox("Close All (+)", "Close Order", IDOK);
   
      if (ClosePositive == IDOK) {
         closePositiveOrders();
         
         return (0);
      }
   } else {
      closePositiveOrders();
      
      return (0);
   }
   
   
   return (0);
}

int closePositiveOrders ()
{   
   int ticket;
   if (OrdersTotal() == 0) return(0);
   for (int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if (OrderSelect (i, SELECT_BY_POS, MODE_TRADES) == true)
      {
         if (OrderMagicNumber() != MagicNumber) { continue; }
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

//+------------------------------------------------------------------+
int closeBuyPressed (const long chartID, const string action)
{   
   if (confirmClose) {
      int CloseBuy = MessageBox("Close All BUY?", "Close Order", IDOK);
      
      if (CloseBuy == IDOK) {
         closeBuyOrders();
         
         return (0);
      }
   }else{
      closeBuyOrders();
      
      return (0);
   }
   
   
   return (0);
}

int closeBuyOrders ()
{   
   int ticket;
   if (OrdersTotal() == 0) return(0);
   for (int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if (OrderSelect (i, SELECT_BY_POS, MODE_TRADES) == true)
      {
         if (OrderMagicNumber() != MagicNumber) { continue; }
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

//+------------------------------------------------------------------+
int closeSellPressed (const long chartID, const string action)
{   
   if (confirmClose) {
      int CloseSell = MessageBox("Close All SELL?", "Close Order", IDOK);
   
      if (CloseSell == IDOK) {
         closeSellOrders();
         
         return (0);
      }
   } else {
      closeSellOrders();
      
      return (0);
   }
   
   
   return (0);
}

int closeSellOrders ()
{   
   int ticket;
   if (OrdersTotal() == 0) return(0);
   for (int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if (OrderSelect (i, SELECT_BY_POS, MODE_TRADES) == true)
      {
         if (OrderMagicNumber() != MagicNumber) { continue; }
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

//+------------------------------------------------------------------+
int closeAllPressed (const long chartID, const string action)
{   
   if (confirmClose) {
      int CloseAll = MessageBox("Close All?", "Close Order", IDOK);
      
      if (CloseAll == IDOK) {
         closeAllOrders();
         
         return (0);
      }
   } else {
      closeAllOrders();
      
      return (0);
   }
   
   
   return (0);
}

int closeAllOrders ()
{   
   int ticket;
   if (OrdersTotal() == 0) return(0);
   for (int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if (OrderSelect (i, SELECT_BY_POS, MODE_TRADES) && OrderSymbol() == Symbol() && OrderType() < 2)
      {
         if (OrderMagicNumber() != MagicNumber) { continue; }
         
         ticket = OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),1000);
         if (ticket == -1) Print ("Error : ", GetLastError());
         if (ticket >   0) Print ("Position ", OrderTicket() ," closed");
      }
   }
   
   return (0);
}

//+------------------------------------------------------------------+
int hedgePressed (const long chartID, const string action)
{
   if (totalLotsBuy != totalLotsSell) {
      if (totalLotsBuy > totalLotsSell) {
         // Sell hedging
         double diffLots = totalLotsBuy - totalLotsSell;
         double price = MarketInfo(Symbol(), MODE_BID);
         string cm = cmt + "Hedge - SELL";
         
         openOrd (ORDER_TYPE_SELL, price, 0, 0, cm, 1, diffLots);
      } else {
         // Buy hedging
         
         double diffLots = totalLotsSell - totalLotsBuy;
         double price = MarketInfo(Symbol(), MODE_ASK);
         string cm = cmt + "Hedge - BUY";
         
         openOrd (ORDER_TYPE_BUY, price, 0, 0, cm, 1, diffLots);
      }
   }
   
   return (0);
} //End int hedgePressed()

//+------------------------------------------------------------------+
int clearTPPressed (const long chartID, const string action)
{
   int ticket;
   if (OrdersTotal() == 0) return(0);
   for (int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if (OrderSelect (i, SELECT_BY_POS, MODE_TRADES) && OrderSymbol() == Symbol() && OrderType() < 2)
      {
         if (OrderMagicNumber() != MagicNumber) { continue; }
         
         ticket = OrderModify(OrderTicket(), OrderOpenPrice(), 0, 0, 0, 1000);
         
         if (ticket == -1) Print ("Error : ", GetLastError());
         if (ticket >   0) Print ("Position ", OrderTicket() ," cleared TP");
      }
   }
   
   return (0);
}

//+------------------------------------------------------------------+
int updateTPPressed (const long chartID, const string action)
{
   int ticket;
   if (OrdersTotal() == 0) return(0);
   for (int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if (OrderSelect (i, SELECT_BY_POS, MODE_TRADES) && OrderSymbol() == Symbol() && OrderType() < 2)
      {
         if (OrderMagicNumber() != MagicNumber) { continue; }
         if (OrderTakeProfit() != 0) {continue;}
         
         double curPrice;
         double tp;
         double ordPrice = OrderOpenPrice();
         
         if (OrderType() == ORDER_TYPE_SELL) {
            // Check Sell order
            curPrice = MarketInfo(Symbol(), MODE_BID);
            tp = ordPrice - (pipTP * PIPS_TO_POINT_MULTI * Point);
            if (tp > curPrice) {
               tp = curPrice - (pipTP * PIPS_TO_POINT_MULTI * Point);
            }
         }
         else if (OrderType() == ORDER_TYPE_BUY) {
            // Check Sell order
            curPrice = MarketInfo(Symbol(), MODE_ASK);
            tp = ordPrice + (pipTP * PIPS_TO_POINT_MULTI * Point);
            if (tp < curPrice) {
               tp = curPrice + (pipTP * PIPS_TO_POINT_MULTI * Point);
            }
         }
         
         // update TP
         ticket = OrderModify(OrderTicket(), OrderOpenPrice(), 0, tp, 0, 1000);
         
         if (ticket == -1) Print ("Error : ", GetLastError());
         if (ticket >   0) Print ("Position ", OrderTicket() ," updated TP");
      }
   }
   
   return (0);
}

//+------------------------------------------------------------------+
void createStopEALine()
{
   HLineCreate(0,"StopEA_High", 0, stopEAHigh, clrRed, STYLE_SOLID, 2, false, true, true, 0);
   HLineCreate(0,"StopEA_Low", 0, stopEALow, clrRed, STYLE_SOLID, 2, false, true, true, 0);
}

void moveStopEALine()
{
   HLineMove(0, "StopEA_High", stopEAHigh);
   HLineMove(0, "StopEA_Low", stopEALow);
}

void createBuySellLine()
{
   HLineCreate(0,"BuySell_High", 0, stopBuyPrice, clrGreen, STYLE_SOLID, 2, false, true, true, 0);
   HLineCreate(0,"BuySell_Low", 0, stopSellPrice, clrGreen, STYLE_SOLID, 2, false, true, true, 0);
}

void moveBuySellLine()
{
   HLineMove(0, "BuySell_High", stopBuyPrice);
   HLineMove(0, "BuySell_Low", stopSellPrice);
}

void deleteBoundaryLines()
{
   HLineDelete(0, "StopEA_High");
   HLineDelete(0, "StopEA_Low");
   HLineDelete(0, "BuySell_High");
   HLineDelete(0, "BuySell_Low");
}

//+------------------------------------------------------------------+
void CreateButtons()
{
   int Button_Height = (int)(Font_Size * 3.2);
   
   if (!ButtonCreate (0, "stopEA", 0, 300, 20, 270, Button_Height, 1, stopEATxt, Font_Type, Font_Size, Font_Color, stopEAClr, clrYellow)) return;
   if (!ButtonCreate (0, "pauseBuy", 0, 300, 60, 130, Button_Height, 1, pauseBuyTxt, Font_Type, Font_Size, Font_Color, pauseBuyClr, clrYellow)) return;
   if (!ButtonCreate (0, "pauseSell", 0, 160, 60, 130, Button_Height, 1, pauseSellTxt, Font_Type, Font_Size, Font_Color, pauseSellClr, clrYellow)) return;
   
   if (showCloseBtn) {
      if (!ButtonCreate (0, "closeAll", 0, 280, 120, 250, Button_Height, 3, "Close All", Font_Type, Font_Size, Font_Color, clrDarkGreen, clrYellow)) return;
      if (!ButtonCreate (0, "closeBuy", 0, 280, 80, 120, Button_Height, 3, "Close Buy", Font_Type, Font_Size, Font_Color, clrDarkGreen, clrYellow)) return;
      if (!ButtonCreate (0, "closeSell", 0, 150, 80, 120, Button_Height, 3, "Close Sell", Font_Type, Font_Size, Font_Color, clrDarkGreen, clrYellow)) return;
      if (!ButtonCreate (0, "closePositive", 0, 280, 40, 120, Button_Height, 3, "Close (+)", Font_Type, Font_Size, Font_Color, clrDarkGreen, clrYellow)) return;
      if (!ButtonCreate (0, "closeNegative", 0, 150, 40, 120, Button_Height, 3, "Close (-)", Font_Type, Font_Size, Font_Color, clrDarkGreen, clrYellow)) return;
   }
   
   if (showHedgeBtn) {
      if (!ButtonCreate (0, "hedge", 0, 420, 120, 120, Button_Height, 3, "Hedge", Font_Type, Font_Size, clrWhite, clrDarkCyan, clrYellow)) return;
      if (!ButtonCreate (0, "clearTP", 0, 420, 80, 120, Button_Height, 3, "Clear TP", Font_Type, Font_Size, clrWhite, clrDarkCyan, clrYellow)) return;
      if (!ButtonCreate (0, "updateTP", 0, 420, 40, 120, Button_Height, 3, "Update TP", Font_Type, Font_Size, clrWhite, clrDarkCyan, clrYellow)) return;
   }
   
   ChartRedraw();
}

//+------------------------------------------------------------------+
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

//+------------------------------------------------------------------+
//| Create the horizontal line                                       |
//+------------------------------------------------------------------+
bool HLineCreate(const long            chart_ID=0,        // chart's ID
                 const string          name="HLine",      // line name
                 const int             sub_window=0,      // subwindow index
                 double                price=0,           // line price
                 const color           clr=clrRed,        // line color
                 const ENUM_LINE_STYLE style=STYLE_SOLID, // line style
                 const int             width=1,           // line width
                 const bool            back=false,        // in the background
                 const bool            selection=true,    // highlight to move
                 const bool            hidden=true,       // hidden in the object list
                 const long            z_order=0)         // priority for mouse click
  {
//--- if the price is not set, set it at the current Bid price level
   if(!price)
      price=SymbolInfoDouble(Symbol(),SYMBOL_BID);
//--- reset the error value
   ResetLastError();
//--- create a horizontal line
   if(!ObjectCreate(chart_ID,name,OBJ_HLINE,sub_window,0,price))
     {
      Print(__FUNCTION__,
            ": failed to create a horizontal line! Error code = ",GetLastError());
      return(false);
     }
//--- set line color
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- set line display style
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style);
//--- set line width
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width);
//--- display in the foreground (false) or background (true)
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- enable (true) or disable (false) the mode of moving the line by mouse
//--- when creating a graphical object using ObjectCreate function, the object cannot be
//--- highlighted and moved by default. Inside this method, selection parameter
//--- is true by default making it possible to highlight and move the object
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
//--- hide (true) or display (false) graphical object name in the object list
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- set the priority for receiving the event of a mouse click in the chart
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- successful execution
   return(true);
  }
  
//+------------------------------------------------------------------+
//| Move horizontal line                                             |
//+------------------------------------------------------------------+
bool HLineMove(const long   chart_ID=0,   // chart's ID
               const string name="HLine", // line name
               double       price=0)      // line price
  {
//--- if the line price is not set, move it to the current Bid price level
   if(!price)
      price=SymbolInfoDouble(Symbol(),SYMBOL_BID);
//--- reset the error value
   ResetLastError();
//--- move a horizontal line
   if(!ObjectMove(chart_ID,name,0,0,price))
     {
      Print(__FUNCTION__,
            ": failed to move the horizontal line! Error code = ",GetLastError());
      return(false);
     }
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//| Delete a horizontal line                                         |
//+------------------------------------------------------------------+
bool HLineDelete(const long   chart_ID=0,   // chart's ID
                 const string name="HLine") // line name
  {
//--- reset the error value
   ResetLastError();
//--- delete a horizontal line
   if(!ObjectDelete(chart_ID,name))
     {
      Print(__FUNCTION__,
            ": failed to delete a horizontal line! Error code = ",GetLastError());
      return(false);
     }
//--- successful execution
   return(true);
  }  

//+------------------------------------------------------------------+
//| Create rectangle label                                           |
//+------------------------------------------------------------------+
bool RectLabelCreate(const long             chart_ID=0,               // chart's ID
                     const string           name="RectLabel",         // label name
                     const int              sub_window=0,             // subwindow index
                     const int              x=0,                      // X coordinate
                     const int              y=0,                      // Y coordinate
                     const int              width=50,                 // width
                     const int              height=18,                // height
                     const color            back_clr=C'236,233,216',  // background color
                     const ENUM_BORDER_TYPE border=BORDER_SUNKEN,     // border type
                     const ENUM_BASE_CORNER corner=CORNER_LEFT_UPPER, // chart corner for anchoring
                     const color            clr=clrRed,               // flat border color (Flat)
                     const ENUM_LINE_STYLE  style=STYLE_SOLID,        // flat border style
                     const int              line_width=1,             // flat border width
                     const bool             back=false,               // in the background
                     const bool             selection=false,          // highlight to move
                     const bool             hidden=true,              // hidden in the object list
                     const long             z_order=0)                // priority for mouse click
  {
  ObjectDelete(name);
//--- reset the error value
   ResetLastError();
//--- create a rectangle label
   if(!ObjectCreate(chart_ID,name,OBJ_RECTANGLE_LABEL,sub_window,0,0))
     {
      Print(__FUNCTION__,
            ": failed to create a rectangle label! Error code = ",GetLastError());
      return(false);
     }
//--- set label coordinates
   ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y);
//--- set label size
   ObjectSetInteger(chart_ID,name,OBJPROP_XSIZE,width);
   ObjectSetInteger(chart_ID,name,OBJPROP_YSIZE,height);
//--- set background color
   ObjectSetInteger(chart_ID,name,OBJPROP_BGCOLOR,back_clr);
//--- set border type
   ObjectSetInteger(chart_ID,name,OBJPROP_BORDER_TYPE,border);
//--- set the chart's corner, relative to which point coordinates are defined
   ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,corner);
//--- set flat border color (in Flat mode)
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- set flat border line style
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style);
//--- set flat border width
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,line_width);
//--- display in the foreground (false) or background (true)
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- enable (true) or disable (false) the mode of moving the label by mouse
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
//--- hide (true) or display (false) graphical object name in the object list
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- set the priority for receiving the event of a mouse click in the chart
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- successful execution
   return(true);
  }
  
//+------------------------------------------------------------------+  
template<typename T>
string NumberToString(T number,int digits = 0,string sep=",")
{
   CString num_str;
   string prepend = number<0?"-":"";
   number=number<0?-number:number;
   int decimal_index = -1;
   if(typename(number)=="double" || typename(number)=="float")
   {
      num_str.Assign(DoubleToString((double)number,digits));
      decimal_index = num_str.Find(0,".");
   }
   else
      num_str.Assign(string(number));
   int len = (int)num_str.Len();
   decimal_index = decimal_index > 0 ? decimal_index : len; 
   int res = len - (len - decimal_index);
   for(int i = res-3;i>0;i-=3)
      num_str.Insert(i,sep);
   return prepend+num_str.Str();
}  

string FormatNumber(string numb, string delim=",",string dec=".")
{
   int pos=StringFind(numb,dec);
   string nnumb=numb;
   string enumb="";
   if(pos!=-1)
      {
      nnumb=StringSubstr(numb,0,pos);
      enumb=StringSubstr(numb,pos);
      }
   int cnt=StringLen(nnumb);
   if (cnt<4)return(numb);
   int x=MathFloor(cnt/3);
   int y=cnt-x*3;
   string forma="";
   if(y!=0)forma=StringConcatenate(StringSubstr(nnumb,0,y),delim);
   for(int i=0;i<x;i++)
      {
      if(i!=x-1)forma=StringConcatenate(forma,StringSubstr(nnumb,y+i*3,3),delim);
      else forma=StringConcatenate(forma,StringSubstr(nnumb,y+i*3,3));
      }
   forma=StringConcatenate(forma,enumb); 
   return(forma);
}   