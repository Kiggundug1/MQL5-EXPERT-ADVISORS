//+------------------------------------------------------------------+
//|                                                PricePosition.mq5 |
//|                           Copyright 2016, Roberto Jacobs (3rjfx) |
//|                              https://www.mql5.com/en/users/3rjfx |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, Roberto Jacobs (3rjfx)"
#property link      "https://www.mql5.com/en/users/3rjfx"
#property version   "2.00"
#property indicator_chart_window
#property strict
#property description "PricePosition indicator provide the position of price in the point of angle"
#property description "when the price was rise or down, where the chance to buy or sell."
//--
/* Update 1 version "2.00" 18/10/2016
   ~ Add display options for corner position, at the LeftHand or at the RightHand
   ~ Add options to Turn On or Turn Off Alerts
*/
//--
#property indicator_chart_window
#property indicator_buffers  4
#property indicator_plots    1 
#property indicator_type1    DRAW_SECTION
#property indicator_style1   STYLE_SOLID 
#property indicator_width1   2
//--
//---
enum YN
 {
   Yes = 1,
    No = 0
 };
//--
enum corner
 {  
   RightHand=1,
   LeftHand=0
 };
//--
input corner corn           = RightHand;     // Corner Position
input YN     UseAlert       = Yes;           // Turn On Alert (Yes) or (No)
input color  SectionColor   = clrBlueViolet; // Color Section Line
input color  BuyColor       = clrAqua;       // BUY Color
input color  SellColor      = clrOrangeRed;  // SELL Color
input color  clrNT          = clrYellow;     // No Trend Color
//--
//--- buffers
double angle[],
       signal[],
       media1[],
       media2[];
//---
//--- MA handles
int media1Handle;
int media2Handle;
//--
//--
string day[]={"Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"};
string short_name;
//--
int cor=0,
    xdis=0,
    ydis=135;
//--
color clrfont;
//--
int cal,
    pal,
    prc,
    pdn;
//-----//
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
    //---
    SetIndexBuffer(0,angle,INDICATOR_DATA);
    SetIndexBuffer(1,signal,INDICATOR_CALCULATIONS);
    SetIndexBuffer(2,media1,INDICATOR_CALCULATIONS);
    SetIndexBuffer(3,media2,INDICATOR_CALCULATIONS);
    //--
    PlotIndexSetInteger(0,PLOT_LINE_COLOR,SectionColor);
    PlotIndexSetString(0,PLOT_LABEL,"Turn");
    PlotIndexSetString(1,PLOT_LABEL,NULL);
    PlotIndexSetString(2,PLOT_LABEL,NULL);
    PlotIndexSetString(3,PLOT_LABEL,NULL);
    PlotIndexSetString(4,PLOT_LABEL,NULL);
    //--
    PlotIndexSetInteger(0,PLOT_SHOW_DATA,true);
    //--
    short_name="PricePosition";
    IndicatorSetString(INDICATOR_SHORTNAME,short_name);
    IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
    //--
//--- get MAs handles
    media1Handle=iMA(_Symbol,PERIOD_CURRENT,26,0,MODE_SMMA,PRICE_MEDIAN);
    if(media1Handle==INVALID_HANDLE)
      {
       printf("Error creating Media1 MA indicator for ",_Symbol);
       return(INIT_FAILED);
      }
    //--
    media2Handle=iMA(_Symbol,PERIOD_CURRENT,20,0,MODE_SMA,PRICE_MEDIAN);
    if(media2Handle==INVALID_HANDLE)
      {
       printf("Error creating Media2 MA indicator for ",_Symbol);
       return(INIT_FAILED);
      }
    //--
    cor=corn==1 ? CORNER_RIGHT_UPPER : CORNER_LEFT_UPPER;
    xdis=corn==1 ? 133 : 30;
    //---
//---
   return(INIT_SUCCEEDED);
  }
//-----//
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//----
   ObjectsDeleteAll(ChartID(),0,-1);
   GlobalVariablesDeleteAll();
//----
   return;
  }
//---
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---
   int i,limit;
   limit=rates_total-prev_calculated;
   if(prev_calculated>0) {limit++;}
   //--
   ArraySetAsSeries(angle,true);
   ArraySetAsSeries(signal,true);
   ArraySetAsSeries(media1,true);
   ArraySetAsSeries(media2,true);
   ArraySetAsSeries(open,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);
   //--
//---
   int calculatedM1=BarsCalculated(media1Handle);
   //--- check if all data calculated
   if(calculatedM1<rates_total)
     {
       Print("Not all data of SMMA 26 is calculated (",calculatedM1,"bars ). Error",GetLastError());
       return(0);
     }
   //--
//--- we can copy not all data
   int to_copyM1;
   if(prev_calculated>rates_total || prev_calculated<0)
     {
       to_copyM1=rates_total;
     }
   else
     {
       to_copyM1=rates_total-prev_calculated;
       if(prev_calculated>0) to_copyM1++;
     }
   //--
//--- get SMMA 26 buffer
   if(IsStopped()) return(0); //Checking for stop flag
   if(CopyBuffer(media1Handle,0,0,to_copyM1,media1)<=0)
     {
       Print("Getting SMMA 26 buffers is failed! Error:",GetLastError());
       return(0);
     }
   //--
//---
   int calculatedM2=BarsCalculated(media2Handle);
   //--- check if all data calculated
   if(calculatedM2<rates_total)
     {
       Print("Not all data of SMA 20 is calculated (",calculatedM2,"bars ). Error",GetLastError());
       return(0);
     }
   //--
//--- we can copy not all data
   int to_copyM2;
   if(prev_calculated>rates_total || prev_calculated<0)
     {
       to_copyM2=rates_total;
     }
   else
     {
       to_copyM2=rates_total-prev_calculated;
       if(prev_calculated>0) to_copyM2++;
     }
   //--
//--- get SMA 20 buffer
   if(IsStopped()) return(0); //Checking for stop flag
   if(CopyBuffer(media2Handle,0,0,to_copyM2,media2)<=0)
     {
       Print("Getting SMA 20 buffers is failed! Error:",GetLastError());
       return(0);
     }
   //--
//--- get signal buffer
   for(i=limit-1; i>=0; i--)
     {signal[i]=(media1[i]+media2[i])/2;}
   //--
   for(i=limit-1; i>=0; i--)
     {
       if((open[i]<=signal[i])&&(close[i]>=signal[i])) {angle[i]=low[i];}
       else if((open[i]>=signal[i])&&(close[i]<=signal[i])) {angle[i]=high[i];}
       else {angle[i]=EMPTY_VALUE;}
     }
   //--
   double priceturn=0.0;  
   int seek=0;
   int s=0;
   //--
   while(seek<1)
     {
       if(angle[s]!=EMPTY_VALUE)
         {
           priceturn=angle[s];
           seek++;
         }
       s++;
     }
   //--
   //--- Create indicator section angles
   if(close[0]>priceturn)
     { 
      CreateLabel(0,"AngleDirection","BUY","Verdana",28,BuyColor,cor,xdis,ydis);
      CreateLabel(0,"AngleLevel","above "+DoubleToString(priceturn,_Digits),"Verdana",10,BuyColor,cor,xdis,ydis+45);
      //--
      clrfont=BuyColor;
      cal=1;
      if((cal!=pal)&&(UseAlert==1))
        {Alert("*"+short_name+": "+_Symbol+", TF: ",strTF(_Period)+", @ "+TimeToString(TimeCurrent(),TIME_DATE|TIME_MINUTES)+
         " --- BUY above --- ",DoubleToString(priceturn,_Digits)); pal=cal;}
     }
   //---
   if(close[0]<priceturn)
     {
      CreateLabel(0,"AngleDirection","SELL","Verdana",28,SellColor,cor,xdis,ydis);
      CreateLabel(0,"AngleLevel","below "+DoubleToString(priceturn,_Digits),"Verdana",10,SellColor,cor,xdis,ydis+45);
      //--
      clrfont=SellColor;
      cal=-1;
      if((cal!=pal)&&(UseAlert==1))
        {Alert("*"+short_name+": "+_Symbol+", TF: ",strTF(_Period)+", @ "+TimeToString(TimeCurrent(),TIME_DATE|TIME_MINUTES)+
         " --- SELL below --- ",DoubleToString(priceturn,_Digits)); pal=cal;}
     }
   //---
   //-- create indicator price direction arrow
   string bararw="";
   color barclr=0;
   if(close[0]>open[0]) {bararw=CharToString(241); barclr=BuyColor;}
   else if(close[0]<open[0]) {bararw=CharToString(242); barclr=SellColor;}
   else {bararw=CharToString(91); barclr=clrNT;}
   //--
   if(close[0]>open[0]) 
     {
       prc=1;
       if((prc!=pdn)&&(UseAlert==1))
        {Alert("*"+short_name+": "+_Symbol+", TF: ",strTF(_Period)+", @ "+TimeToString(TimeCurrent(),TIME_DATE|TIME_MINUTES)+
         " --- Rising --- "); pdn=prc;}
     }
   else if(close[0]<open[0]) 
     {
       prc=-1;
       if((prc!=pdn)&&(UseAlert==1))
        {Alert("*"+short_name+": "+_Symbol+", TF: ",strTF(_Period)+", @ "+TimeToString(TimeCurrent(),TIME_DATE|TIME_MINUTES)+
         " --- Down --- "); pdn=prc;}
     }
   else 
     {
       prc=0;
       if((prc!=pdn)&&(UseAlert==1))
        {Alert("*"+short_name+": "+_Symbol+", TF: ",strTF(_Period)+", @ "+TimeToString(TimeCurrent(),TIME_DATE|TIME_MINUTES)+
         " --- Wait --- "); pdn=prc;}
     }
   //--
   int da=corn==1 ? -78 : 78;
   int aj=corn==1 ? -2 : 2;
   //--
   CreateLabel(0,"DIRARROW",bararw,"Wingdings",25,barclr,cor,xdis+da,ydis-45);
   //---
   //--- create indicator OHLC price
   //--
   CreateLabel(0,"DIRARROW",bararw,"Wingdings",25,barclr,cor,xdis+da,ydis-45);
   //---
   //--- create indicator OHLC price
   CreateLabel(0,"OPEN","O: "+DoubleToString(open[0],_Digits),"Verdana",10,barclr,cor,xdis,ydis-57);
   
   CreateLabel(0,"HIGH","H: "+DoubleToString(high[0],_Digits),"Verdana",10,barclr,cor,xdis,ydis-44);
   //--
   CreateLabel(0,"LOW","L: "+DoubleToString(low[0],_Digits),"Verdana",10,barclr,cor,xdis+aj,ydis-31);
   //--
   CreateLabel(0,"CLOSE","C: "+DoubleToString(close[0],_Digits),"Verdana",10,barclr,cor,xdis,ydis-18);
   //--
   //--- create indicator labels time
   //--
   CreateLabel(0,"txDay",day[TimeDayOfWeek(TimeCurrent())],"Verdana",14,clrNT,cor,xdis,ydis+65);
   //--
   CreateLabel(0,"txTime",TimeToString(TimeCurrent(),TIME_SECONDS),"Verdana",14,clrNT,cor,xdis,ydis+87);
   //--
   //---
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//-----//

int TimeDayOfWeek(datetime date)
  {
    MqlDateTime tm;
    TimeToStruct(date,tm);
    return(tm.day_of_week);
  }
//----//

void CreateLabel(long   chart_id, 
                 string lable_name, 
                 string label_text,
                 string font_model,
                 int    font_size,
                 color  label_color,
                 int    chart_corner,
                 int    x_cor, 
                 int    y_cor) 
  { 
//--- 
   if(ObjectFind(chart_id,lable_name)<0)
     {
       if(ObjectCreate(chart_id,lable_name,OBJ_LABEL,0,0,0,0,0)) 
         { 
           ObjectSetString(chart_id,lable_name,OBJPROP_TEXT,label_text);
           ObjectSetString(chart_id,lable_name,OBJPROP_FONT,font_model); 
           ObjectSetInteger(chart_id,lable_name,OBJPROP_FONTSIZE,font_size);
           ObjectSetInteger(chart_id,lable_name,OBJPROP_COLOR,label_color);
           ObjectSetInteger(chart_id,lable_name,OBJPROP_CORNER,chart_corner);
           ObjectSetInteger(chart_id,lable_name,OBJPROP_XDISTANCE,x_cor);
           ObjectSetInteger(chart_id,lable_name,OBJPROP_YDISTANCE,y_cor);
         } 
       else 
          {Print("Failed to create the object OBJ_LABEL ",lable_name,", Error code = ", GetLastError());}
     }
   else
     {
       ObjectSetString(chart_id,lable_name,OBJPROP_TEXT,label_text);
       ObjectSetString(chart_id,lable_name,OBJPROP_FONT,font_model); 
       ObjectSetInteger(chart_id,lable_name,OBJPROP_FONTSIZE,font_size);
       ObjectSetInteger(chart_id,lable_name,OBJPROP_COLOR,label_color);
       ObjectSetInteger(chart_id,lable_name,OBJPROP_CORNER,chart_corner);
       ObjectSetInteger(chart_id,lable_name,OBJPROP_XDISTANCE,x_cor);
       ObjectSetInteger(chart_id,lable_name,OBJPROP_YDISTANCE,y_cor);
     }
  }
//---------//

string strTF(int period)
  {
   string periodcur;
   switch(period)
     {
       //--
       case PERIOD_M1: periodcur="M1"; break;
       case PERIOD_M5: periodcur="M5"; break;
       case PERIOD_M15: periodcur="M15"; break;
       case PERIOD_M30: periodcur="M30"; break;
       case PERIOD_H1: periodcur="H1"; break;
       case PERIOD_H4: periodcur="H4"; break;
       case PERIOD_D1: periodcur="D1"; break;
       case PERIOD_W1: periodcur="W1"; break;
       case PERIOD_MN1: periodcur="MN"; break;
       //--
     }
   //--
   return(periodcur);
  }  
//---------//
//---/
//+------------------------------------------------------------------+
