//+------------------------------------------------------------------+
//|                                                   SwingBreak.mqh |
//|                                                                  |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright ""
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "Swing.mqh";
#include "Bar.mqh";

class CSwingBreak : public CObject
{
private:
    CBar    *m_bar;
    CSwing  *m_swing;
    CSwingBreak  *m_swing_break;

public:
    CSwingBreak(CBar *bar, CSwing *swing) {
        m_bar = bar;
        m_swing = swing;
    }
    ~CSwingBreak() {}
};

