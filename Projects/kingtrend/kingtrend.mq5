//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+

#include "ABCManager.mqh"
#include "Swing.mqh"

#property copyright ""
#property link      ""
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 9
#property indicator_plots   3
#property indicator_label1  "ContinuationColorLine"
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrRed,clrBlue,clrNONE
#property indicator_style1  STYLE_DASH
#property indicator_width1  1

#property indicator_label2  "BreakoutColorLine"
#property indicator_type2   DRAW_COLOR_LINE
#property indicator_color2  clrRed,clrBlue,clrNONE
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1

//--- identical candles with a single color applied to them
#property indicator_label3  "Breakout candles"
#property indicator_type3   DRAW_COLOR_CANDLES
//--- only one color is specified, therefore all candles are of the same color
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1

#define indicator_name "kingtrend"

//--- input parameters
input string            label1 = "---- GENERAL SETTINGS ----"; // GENERAL SETTINGS
input int               IMaxLookback = 1000;
input bool              draw_swings = true; // Draw swings
input color             IBreakoutCandleColor = clrGreenYellow;
input bool              IHideContinuation = true; // Hide the continuation line
input bool              IHideBreakout = false; // Hide the breakout line

input string            label2 = "---- TEXT SETTINGS ----"; // Swings
input int               label_separation = 20; // label distance
input string            InpFont="Times New Roman";         // Font
input color             InpColorUp = clrGreen;
input color             InpColorDown = clrRed;
input color             InpColorExt = clrBlue;
input int               InpFontSize=10;          // Font size
input double            InpAngle=0.0;           // Slope angle in degrees
input ENUM_ANCHOR_POINT InpAnchor=ANCHOR_CENTER;   // Anchor type
input bool              InpBack=false;           // Background object
input bool              InpSelection=false;      // Highlight to move
input bool              InpHidden=true;          // Hidden in the object list
input long              InpZOrder=0;             // Priority for mouse click

//--- A buffer for plotting
double         ColorContinuationLineBuffer[];
double         ColorBreakoutLineBuffer[];
//--- A buffer for storing the line color on each bar
double         ColorContinuationLineColors[];
double         ColorBreakoutLineColors[];

// --- candle buffers
double         Candle1Buffer1[];
double         Candle1Buffer2[];
double         Candle1Buffer3[];
double         Candle1Buffer4[];
double         ColorCandlesColors[];


CABCManager *abc_manager;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("on init");
    clearAll();

    //--- Binding an array and an indicator buffer
    SetIndexBuffer(0,ColorContinuationLineBuffer,INDICATOR_DATA);
    SetIndexBuffer(1,ColorContinuationLineColors,INDICATOR_COLOR_INDEX);
    SetIndexBuffer(2,ColorBreakoutLineBuffer,INDICATOR_DATA);
    SetIndexBuffer(3,ColorBreakoutLineColors,INDICATOR_COLOR_INDEX);

    SetIndexBuffer(4,Candle1Buffer1,INDICATOR_DATA);
    SetIndexBuffer(5,Candle1Buffer2,INDICATOR_DATA);
    SetIndexBuffer(6,Candle1Buffer3,INDICATOR_DATA);
    SetIndexBuffer(7,Candle1Buffer4,INDICATOR_DATA);
    SetIndexBuffer(8,ColorCandlesColors,INDICATOR_COLOR_INDEX);
    PlotIndexSetInteger(2,PLOT_LINE_COLOR,0,IBreakoutCandleColor);
    /**
    ArrayInitialize(Candle1Buffer1,EMPTY_VALUE);
    ArrayInitialize(Candle1Buffer2,EMPTY_VALUE);
    ArrayInitialize(Candle1Buffer3,EMPTY_VALUE);
    ArrayInitialize(Candle1Buffer4,EMPTY_VALUE);
    ArrayInitialize(Candle1Buffer4,clrNONE);
    **/
    abc_manager = new CABCManager();

    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
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


    if(!isNewBar(prev_calculated))
    {
        return prev_calculated;
    }

    int  i=0;
//--- set position for beginning
    if(i<prev_calculated)
        i=prev_calculated-1;
    if(IMaxLookback < rates_total && i < rates_total - IMaxLookback)
    {
        i = rates_total - IMaxLookback - 1;
    }

//--- start calculations
    int total_bars = 0;
    int total_swings = 0;

    while(i<rates_total && !IsStopped())
    {

        //--- determine if we have a new swing
        if(i>0)
        {
            CSwing *swing = abc_manager.onNewBar(time[i], open[i], high[i], low[i], close[i], i);

            printSwing(swing, time);

            if(abc_manager.isAbcChange())
            {
                Candle1Buffer1[i] = open[i];
                Candle1Buffer2[i] = high[i];
                Candle1Buffer3[i] = low[i];
                Candle1Buffer4[i] = close[i];
            }

            ColorContinuationLineBuffer[i] = abc_manager.getContinuationPrice();
            if(IHideContinuation)
            {
                ColorContinuationLineColors[i] = 2;
            }
            else
            {
                ColorContinuationLineColors[i] = abc_manager.getAbcDirection();
            }

            ColorBreakoutLineBuffer[i] = abc_manager.getBreakoutPrice();
            
            if(IHideBreakout)
            {
               ColorBreakoutLineColors[i] = 2;
            } else {
                ColorBreakoutLineColors[i] = abc_manager.getAbcDirection();
            }
            
        }
        i++;

    }

    return(rates_total);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void printSwing(CSwing *swing, const datetime &time[])
{
    if(!draw_swings || !swing)
    {
        return;
    }
    int swing_index = swing.index();

    switch(swing.type())
    {
    case  SwingType::HH:
        drawText(time[swing_index], swing.extreme(), true, "HH", InpColorUp);
        break;
    case  SwingType::LH:
        drawText(time[swing_index], swing.extreme(), true, "LH", InpColorDown);
        break;
    case  SwingType::LL:
        drawText(time[swing_index], swing.extreme(), false, "LL", InpColorDown);
        break;
    case  SwingType::HL:
        drawText(time[swing_index], swing.extreme(), false, "HL", InpColorUp);
        break;
    case  SwingType::SHE:
        drawText(time[swing_index], swing.extreme(), true, "E", InpColorExt);
        break;
    case  SwingType::SLE:
        drawText(time[swing_index], swing.extreme(), false, "E", InpColorExt);
        break;
    default:
        break;
    }

}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    clearAll();

    delete abc_manager;


    Print("Indicator removed");
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void clearAll()
{
    for(int i = ObjectsTotal(0)   ; i >= 0; i--)
    {
        string obj_name = ObjectName(0, i);
        if (StringFind(obj_name, indicator_name) >= 0)
        {
            if(!ObjectDelete(0,obj_name))
            {
                Print(__FUNCTION__,
                      ": failed to delete \"Text\" object! Error code = ",GetLastError());
            }

        }
    }
    Sleep(2000);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isNewBar(int prev_calculated)
{
    static datetime lastbar=0;
    static int last_timeframe = Period();

    if(Period() != last_timeframe)
    {
        last_timeframe = Period();
        lastbar=(datetime)SeriesInfoInteger(_Symbol,_Period,SERIES_LASTBAR_DATE);
        return true;
    }

    if(prev_calculated == 0)
    {
        lastbar=(datetime)SeriesInfoInteger(_Symbol,_Period,SERIES_LASTBAR_DATE);
        return true;
    }
    else if(lastbar!=SeriesInfoInteger(_Symbol,_Period,SERIES_LASTBAR_DATE))
    {
        lastbar=(datetime)SeriesInfoInteger(_Symbol,_Period,SERIES_LASTBAR_DATE);
        return true;
    }

    return false;
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void drawText(datetime time, double price, bool top, string text, color clr)
{
    string name = indicator_name + ":" + text + ":" +(string)time;
    double anchor = price;
    if(top)
    {
        anchor += (label_separation * Point());

    }
    else
    {
        anchor -= (label_separation * Point());
    }
    TextCreate(0, name, 0, time, anchor, text, InpFont,InpFontSize, clr,-InpAngle,InpAnchor,InpBack,InpSelection,InpHidden,InpZOrder);
}

//+------------------------------------------------------------------+
//| Get value of buffers                                             |
//+------------------------------------------------------------------+
bool iGetArray(const int handle,const int buffer,const int start_pos,
               const int count,double &arr_buffer[])
{
    bool result=true;
    if(!ArrayIsDynamic(arr_buffer))
    {
        PrintFormat("ERROR! EA: %s, FUNCTION: %s, this a no dynamic array!",__FILE__,__FUNCTION__);
        return(false);
    }
    ArrayFree(arr_buffer);
//--- reset error code
    ResetLastError();
//--- fill a part of the iBands array with values from the indicator buffer
    int copied=CopyBuffer(handle,buffer,start_pos,count,arr_buffer);
    if(copied!=count)
    {
        //--- if the copying fails, tell the error code

        PrintFormat("ERROR! EA: %s, FUNCTION: %s, amount to copy: %d, copied: %d, error code %d",
                    __FILE__,__FUNCTION__,count,copied,GetLastError());
        //--- quit with zero result - it means that the indicator is considered as not calculated
        return(false);
    }
    return(result);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Creating Text object                                             |
//+------------------------------------------------------------------+
bool TextCreate(const long              chart_ID=0,               // chart's ID
                const string            name="Text",              // object name
                const int               sub_window=0,             // subwindow index
                datetime                time=0,                   // anchor point time
                double                  price=0,                  // anchor point price
                const string            text="Text",              // the text itself
                const string            font="Arial",             // font
                const int               font_size=10,             // font size
                const color             clr=clrRed,               // color
                const double            angle=0.0,                // text slope
                const ENUM_ANCHOR_POINT anchor=ANCHOR_LEFT_UPPER, // anchor type
                const bool              back=false,               // in the background
                const bool              selection=false,          // highlight to move
                const bool              hidden=true,              // hidden in the object list
                const long              z_order=0)                // priority for mouse click
{
//--- set anchor point coordinates if they are not set
    ChangeTextEmptyPoint(time,price);
//--- reset the error value
    ResetLastError();
//--- create Text object
    if(!ObjectCreate(chart_ID,name,OBJ_TEXT,sub_window,time,price))
    {
        Print(__FUNCTION__,
              ": failed to create \"Text\" object! Error code = ",GetLastError());
        return(false);
    }
//--- set the text
    ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);
//--- set text font
    ObjectSetString(chart_ID,name,OBJPROP_FONT,font);
//--- set font size
    ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size);
//--- set the slope angle of the text
    ObjectSetDouble(chart_ID,name,OBJPROP_ANGLE,angle);
//--- set anchor type
    ObjectSetInteger(chart_ID,name,OBJPROP_ANCHOR,anchor);
//--- set color
    ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- display in the foreground (false) or background (true)
    ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- enable (true) or disable (false) the mode of moving the object by mouse
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
//| Check anchor point values and set default values                 |
//| for empty ones                                                   |
//+------------------------------------------------------------------+
void ChangeTextEmptyPoint(datetime &time,double &price)
{
//--- if the point's time is not set, it will be on the current bar
    if(!time)
        time=TimeCurrent();
//--- if the point's price is not set, it will have Bid value
    if(!price)
        price=SymbolInfoDouble(Symbol(),SYMBOL_BID);
}

//+------------------------------------------------------------------+
//| Delete Text object                                               |
//+------------------------------------------------------------------+
bool TextDelete(const long   chart_ID=0,  // chart's ID
                const string name="Text") // object name
{
//--- reset the error value
    ResetLastError();
//--- delete the object
    if(!ObjectDelete(chart_ID,name))
    {
        Print(__FUNCTION__,
              ": failed to delete \"Text\" object! Error code = ",GetLastError());
        return(false);
    }
//--- successful execution
    return(true);
}

//+------------------------------------------------------------------+
//| Change the object text                                           |
//+------------------------------------------------------------------+
bool TextChange(const long   chart_ID=0,  // chart's ID
                const string name="Text", // object name
                const string text="Text") // text
{
//--- reset the error value
    ResetLastError();
//--- change object text
    if(!ObjectSetString(chart_ID,name,OBJPROP_TEXT,text))
    {
        Print(__FUNCTION__,
              ": failed to change the text! Error code = ",GetLastError());
        return(false);
    }
//--- successful execution
    return(true);
}
//+------------------------------------------------------------------+
