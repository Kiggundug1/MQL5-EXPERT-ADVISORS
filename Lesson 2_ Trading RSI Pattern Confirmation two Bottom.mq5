//+------------------------------------------------------------------+
//|    Lesson 2_ Trading RSI Pattern Confirmation two Bottom MT5.mq5 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#include      <Trade\Trade.mqh>
#include      <Trade\SYmbolInfo.mqh>
#include      <Trade\PositionInfo.mqh>

// Declaration variable for librari trade function.
CTrade                            trade;
CSymbolInfo                       m_symbol;
CPositionInfo                     m_position;

string input aa = "-----------------------SETTINGS---------------------------";
string input BOT_NAME = "Lesson 2_ Trading RSI Pattern Confirmation two Bottom";
input    double                   lotsize=0.2;
input    double                   SL_factor=1000;// Stop loss factor
input    double                   TP_factor=2000; //Take profit factor
input  double           Trailling= 500;// Trailling Pipi
input  double           Trailling_Step=5;// Trailling step
input    ulong                    m_magicnumber=123456789;
input    ENUM_TIMEFRAMES      timeframe= PERIOD_M15;

// Input parameter of indicator RSI 
input     int                     Period_RSI=14;// Period of RSI
 // Global variable declaration
 
double                            Extstoploss;// stoploss return point value   
double                            Exttakeprofit;// Take profit return point value   
double                            ExtTraill_Stop=0.0;
double                            ExtTraill_Step=0.0;
double                            m_adjustpoint;
ulong                             Slippage;// Slippage 
// Global indicator RSI
int                               Handle_RSI;
double                              RSI[];


  //+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
if(!m_symbol.Name(_Symbol))
return  INIT_FAILED;

// Set Trade parameter
trade.SetTypeFillingBySymbol(m_symbol.Name());
trade.SetExpertMagicNumber(m_magicnumber);
trade.SetDeviationInPoints(Slippage);

// Turning 3 or 5 Digit
int    adjustdigit=1;
if(m_symbol.Digits()==3 || m_symbol.Digits()==5)
{
adjustdigit=10;
}

m_adjustpoint=adjustdigit*m_symbol.Point();
Extstoploss= m_adjustpoint*SL_factor;
Exttakeprofit= m_adjustpoint*TP_factor;
ExtTraill_Stop=m_adjustpoint*Trailling;
ExtTraill_Step=m_adjustpoint*Trailling_Step;

// Indicator RSI declaration

Handle_RSI= iRSI(m_symbol.Name(),timeframe,Period_RSI,PRICE_CLOSE);
if(Handle_RSI==INVALID_HANDLE)
return  INIT_FAILED;

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
 // Candle declaration
 double Open[],Close[],High[],Low[];
 ArraySetAsSeries(Close,true); ArraySetAsSeries(Open,true);ArraySetAsSeries(High,true);ArraySetAsSeries(Low,true);
 CopyClose(Symbol(),timeframe,0,1000,Close);CopyOpen(Symbol(),timeframe,0,1000,Open);CopyHigh(Symbol(),timeframe,0,1000,High);CopyLow(Symbol(),timeframe,0,1000,Low);
 // Count bjuy and count sell
 int count_buy=0; int count_sell=0;
count_position(count_buy,count_sell);
 // RSI array declaration
 RSI(0,1000,0,RSI);
 
 int Prve_bottom= ArrayMinimum(Low,2,26);
 int Cur_bottom = ArrayMinimum(Low,2,10);
 
 int  Pre_peak  =ArrayMaximum(High,2,26);
 int  Cur_peak  =ArrayMaximum(High,2,10);
 
       //+------------------------------------------------------------------+
      //|   Broker parameter                                               |
      //+------------------------------------------------------------------+
      
double point = SymbolInfoDouble(_Symbol,SYMBOL_POINT);
double ask= SymbolInfoDouble(_Symbol,SYMBOL_ASK);
double bid= SymbolInfoDouble(_Symbol,SYMBOL_BID);
double spread=ask-bid;
double stoplevel= (int)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL);
int freezerlevel= (int)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_FREEZE_LEVEL);
 // Main condition for buy and sell
 
 if(OpenBar(Symbol()))
   {
    if(count_buy==0 && CheckVolumeValue(lotsize) )
      {
       if(RSI[Prve_bottom]<30 && RSI[Prve_bottom]<RSI[Cur_bottom] && Low[Prve_bottom]<Low[Cur_bottom] && bullish(Open,Close,High,Low,1))
        {
         double   entryprice= SymbolInfoDouble(Symbol(),SYMBOL_ASK);
         double   sl        =entryprice-Extstoploss;
         double   tp        =entryprice+Exttakeprofit;
         if(  bid-sl>stoplevel && tp-bid>stoplevel )
          {
          trade.Buy(lotsize,Symbol(),entryprice,sl,tp, " BUy Mr.Tan ");
          }
         

        }
      }
    if(count_sell==0 && CheckVolumeValue(lotsize))
      {
       if(RSI[Pre_peak]>70 && RSI[Pre_peak]>RSI[Cur_peak] && High[Pre_peak]>High[Cur_peak] && bearlish(Open,Close,High,Low,1))
        {
         double   entryprice= SymbolInfoDouble(Symbol(),SYMBOL_BID);
         double   sl        =entryprice+Extstoploss;
         double   tp        =entryprice-Exttakeprofit;
         if( sl-ask>stoplevel && ask-tp>stoplevel)
         {
         trade.Sell(lotsize,Symbol(),entryprice,sl,tp, " BUy Mr.Tan ");
         }
        }
      
      }
   
   
   }
 
 
  }
//+------------------------------------------------------------------+
//|Count position and Trailling Functiom                              |
//+------------------------------------------------------------------+

void  count_position(int &count_buy, int &count_sell)

  {
   count_buy=0; count_sell=0;
   int total_postion=PositionsTotal();
   double cp=0.0, op=0.0, sl=0.0,tp=0.0; ulong ticket=0.0;
   for ( int i=total_postion-1; i>=0; i--)
     {
     if(m_position.SelectByIndex(i))
      {
      if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()== m_magicnumber)
       cp=m_position.PriceCurrent();op=m_position.PriceOpen();sl=m_position.StopLoss();tp=m_position.TakeProfit();ticket=m_position.Ticket();
       {       
       if(m_position.PositionType()== POSITION_TYPE_BUY)
        {
        count_buy++;
        double Traill= cp- ExtTraill_Stop;
        if(cp>sl+ExtTraill_Step && Traill>sl&& PositionModifyCheck(ticket,Traill,tp,_Symbol))
         {
          trade.PositionModify(ticket,Traill,tp);
         }
        }
      else
       if(m_position.PositionType()== POSITION_TYPE_SELL)
        {
         count_sell++;
        double Traill= cp+ ExtTraill_Stop;
        if(cp<sl-ExtTraill_Step && Traill<sl && PositionModifyCheck(ticket,Traill,tp,_Symbol))
         {
          trade.PositionModify(ticket,Traill,tp);
         }
        }
         
       }
      }
     
     }
  }
    
 // Only buy or sell at new candle
 datetime    mprevBar; 
 bool    OpenBar(string  symbol)
 
 {
  datetime     CurBar=iTime(symbol,timeframe,0);
  if(  CurBar==mprevBar)
    {
     return   false;
    }
    mprevBar=CurBar;
    return  true;
 }
 
 
 bool  RSI(int  shift, int  Count,int buff, double  &rsi[])
   {
     if(!ArraySetAsSeries(rsi,true)) return false;
     if(CopyBuffer(Handle_RSI,0,shift,Count,rsi)==-1)return false;
     return   true;
   }
   
  // Condition Buy
  
  bool bullish(double &open[], double  &close[], double  &high[], double  &low[], int index)
  
   {
    double midle_candle= MathAbs((close[index+1]-open[index+1])/2);
    bool   downtrend   =(close[index+1]<open[index+1] && close[index+2]<open[index+2] && close[index+3]<open[index+3]);
    
    //if(downtrend)
     {
      if(close[index]>open[index] && close[index]>(close[index+1]+midle_candle))
      return true;
     }
   return  false;
   
   }
   
   
     // Condition sell
  
  bool bearlish(double &open[], double  &close[], double  &high[], double  &low[], int index)
  
   {
    double midle_candle= MathAbs((close[index+1]-open[index+1])/2);
    bool   uptrend   =(close[index+1]>open[index+1] && close[index+2]>open[index+2] && close[index+3]>open[index+3]);
    
    //if(uptrend)
     {
      if(close[index]<open[index] && close[index]<(close[index+1]-midle_candle))
      return true;
     }
   return  false;
   
   }
   
//+------------------------------------------------------------------+
//| Checking the new values of levels before order modification      |
//+------------------------------------------------------------------+
bool PositionModifyCheck(ulong ticket,double sl,double tp,string symbol)
  {
   CPositionInfo pos;
   COrderInfo    order;
   if (PositionGetString(POSITION_SYMBOL) == symbol)
   {
//--- select order by ticket
   if(pos.SelectByTicket(ticket))
     {
      //--- point size and name of the symbol, for which a pending order was placed
      double point=SymbolInfoDouble(symbol,SYMBOL_POINT);
      //--- check if there are changes in the StopLoss level
      bool StopLossChanged=(MathAbs(pos.StopLoss()-sl)>point);
      //--- if there are any changes in levels
      if(StopLossChanged)// || TakeProfitChanged)
         return(true);  // position can be modified      
      //--- there are no changes in the StopLoss and Takeprofit levels
      else
      //--- notify about the error
         PrintFormat("Order #%d already has levels of Open=%.5f SL=.5f TP=%.5f",
                     ticket,order.StopLoss(),order.TakeProfit());
     }
    }
//--- came to the end, no changes for the order
   return(false);       // no point in modifying 
  }

//+------------------------------------------------------------------+
//| Check the correctness of the order volume                        |
//+------------------------------------------------------------------+
bool CheckVolumeValue(double volume) {

//--- minimal allowed volume for trade operations
  double min_volume=SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   if(volume < min_volume)
     {
      //description = StringFormat("Volume is less than the minimal allowed SYMBOL_VOLUME_MIN=%.2f",min_volume);
      return(false);
     }

//--- maximal allowed volume of trade operations
   double max_volume=SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   if(volume>max_volume)
     {
      //description = StringFormat("Volume is greater than the maximal allowed SYMBOL_VOLUME_MAX=%.2f",max_volume);
      return(false);
     }

//--- get minimal step of volume changing
   double volume_step=SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   int ratio = (int)MathRound(volume/volume_step);
   if(MathAbs(ratio*volume_step-volume)>0.0000001)
     {
      //description = StringFormat("Volume is not a multiple of the minimal step SYMBOL_VOLUME_STEP=%.2f, the closest correct volume is %.2f", volume_step,ratio*volume_step);
      return(false);
     }
      
   return(true);
}
  
//+------------------------------------------------------------------+
//|CHECK SL AND TP                                                   |
//+------------------------------------------------------------------+

bool CheckStopLoss(double price, double SL, double TP) {

//--- get the SYMBOL_TRADE_STOPS_LEVEL level
   int stops_level = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   if(stops_level != 0)
     {
      PrintFormat("SYMBOL_TRADE_STOPS_LEVEL=%d: StopLoss and TakeProfit must"+
                  " not be nearer than %d points from the closing price", stops_level, stops_level);
     }
//---
   bool SL_check = true;
   bool TP_check = true;
   
   if(SL != 0)
   {
      SL_check = MathAbs(price - SL) > (stops_level * _Point);
   }
   
   if(TP != 0)
   {
      TP_check = MathAbs(price - TP) > (stops_level * _Point);
   }
      //--- return the result of checking
      return(TP_check&&SL_check);  
}