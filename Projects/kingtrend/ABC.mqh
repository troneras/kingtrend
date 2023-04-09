//+------------------------------------------------------------------+
//|                                                          ABC.mqh |
//|                                                                  |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright ""
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Object.mqh>
#include "FlowManager.mqh"
#include "SwingFlow.mqh"
#include "Swing.mqh"
#include "Bar.mqh"
#include <Arrays/List.mqh>

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CABC : public CObject
{
private:
    CFlowManager    *m_flow_manager;

    bool            m_abc_direction;
    double          m_continuation_price;
    double          m_breakout_price;

    CSwing          *m_continuation;
    bool            m_is_continuation;

    CSwing          *m_breakout;
    bool            m_is_broken;;

    CSwing          *m_swing;
    bool            m_started;
    bool            m_is_new_abc;
    bool            m_has_continuation;

    CBar            *m_start_bar;
    double          m_bo_price;
    CSwing          *m_swing_extreme;
    CBar            *m_engulf_bo_bar;
    CBar            *m_breakout_bar;
    double          m_engult_price;

    void setBreakout(CSwing *swing)
    {
        if(m_has_continuation && ((m_abc_direction && swing.isLow()) || (!m_abc_direction && swing.isHigh())))
        {
            m_breakout = swing;
            m_breakout_price = swing.maxExtension();
            m_has_continuation = false;
        }
    }

    void setContinuation(CSwing *swing)
    {
        if((m_abc_direction && swing.isHH() && (!m_continuation || m_continuation.maxExtension() < swing.maxExtension()))
                || (!m_abc_direction && swing.isLL() && (!m_continuation || m_continuation.maxExtension() > swing.maxExtension())))
        {
            m_continuation = swing;
            if(!m_continuation_price
                    || ((m_abc_direction && m_continuation_price < swing.maxExtension())
                        || (!m_abc_direction && m_continuation_price > swing.maxExtension())))
            {
                m_continuation_price = swing.maxExtension();
            }

        }
    }

    bool isAbcContinuation(CBar *bar)
    {
        return (m_abc_direction && bar.close() > m_continuation_price) || (!m_abc_direction && bar.close() < m_continuation_price);
    }

    bool isAbcBreak(CBar *bar)
    {
        return (m_abc_direction && bar.close() < m_breakout_price) || (!m_abc_direction && bar.close() > m_breakout_price);
    }

    void updateEngulfingBar(CBar *bar)
    {
        double bar_close = bar.close();
        if((m_abc_direction && bar_close < m_engult_price) || (!m_abc_direction && bar_close > m_engult_price))
        {
            m_engulf_bo_bar = bar;
        }
        else
        {
            m_engult_price = m_abc_direction ? bar.low() : bar.high();
        }
    }

public:
    CABC(CSwing *start_swing, bool direction, CFlowManager *flow_manager)
    {
        m_flow_manager = flow_manager;

        m_has_continuation = true;// setting this to true so the first swing is valid
        m_abc_direction = direction;
        m_is_broken = false;
        m_breakout_price = NULL;
        m_continuation_price = NULL;
        m_engulf_bo_bar = NULL;

        if(start_swing)
        {
            setContinuation(start_swing);
            setBreakout(start_swing);
            m_started = true;
            m_has_continuation = false;
        }
    }


    ~CABC()
    {

    }

    CSwing* onNewBar(CBar *bar)
    {
        m_swing = m_flow_manager.onNewBar(bar);

        if(m_swing)
        {
            // update the limits of the ABC
            setContinuation(m_swing);

            if(!m_started)
            {
                m_started = true;
                m_abc_direction = m_swing.isHH() || m_swing.isHL() || m_swing.isSLE();

                return m_swing;
            }
        }

        if(isAbcContinuation(bar))
        {
            m_has_continuation = true;

            CSwing *last_swing = getLastSwing(m_abc_direction);
            if(last_swing)
            {
                m_breakout = last_swing;
                m_breakout_price= m_breakout.maxExtension();
            }

        }

        if(isAbcBreak(bar))
        {
            m_is_broken = true;
            m_swing_extreme = m_continuation; // the furthest that price has traveled on the current swing
            m_breakout_bar = bar;
        }
        else
        {
            // check for range extensions
            setContinuationPrice(bar);
            setBreakoutPrice(bar);
        }

        updateEngulfingBar(bar);

        return m_swing;
    }


    void setContinuationPrice(CBar *bar)
    {
        if(m_abc_direction && (!m_continuation_price || m_continuation_price < bar.high()))
        {
            m_continuation_price = bar.high();
        }
        else if (!m_abc_direction && (!m_continuation_price || m_continuation_price > bar.low()))
        {
            m_continuation_price = bar.low();
        }
    }

    void setBreakoutPrice(CBar *bar)
    {
        if(m_abc_direction && (!m_breakout_price || m_breakout_price > bar.low()))
        {
            m_breakout_price = bar.low();
        }
        else if (!m_abc_direction && (!m_breakout_price || m_breakout_price < bar.high()))
        {
            m_breakout_price = bar.high();
        }
    }

    double getContinuationPrice()
    {
        return m_continuation_price;
    }

    double getBreakoutPrice()
    {
        return m_breakout_price;
    }

    bool direction()
    {
        return m_abc_direction;
    }

    CSwing* getLastSwing(bool direction)
    {
        CSwingFlow* flow = m_flow_manager.getFlow();

        if(flow)
        {
            return flow.getLastSwing(direction);
        }
        return NULL;
    }

    bool isBroken()
    {
        return m_is_broken;
    }

    void setBreakouInfo(CBar *bar, double breakout_price)
    {
        m_start_bar = bar;
        m_engult_price = m_abc_direction ? bar.low() : bar.high();
        m_bo_price = breakout_price;
    }

    double getStartPrice()
    {
        return m_bo_price;
    }

    CBar* getStartBar()
    {
        return m_start_bar;
    }
    
    CBar* getBreakoutBar()
    {
        return m_breakout_bar;
    }

    bool hasEngulfedStartBar()
    {
        return m_engulf_bo_bar != NULL;
    }
    
    CBar* getEngulfBar()
    {
        return m_engulf_bo_bar;
    }
};

//+------------------------------------------------------------------+
