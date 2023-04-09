//+------------------------------------------------------------------+
//|                                                    SwingFlow.mqh |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"


#include "SwingBreak.mqh"
#include "Bar.mqh"
#include "Swing.mqh"
#include "SwingFactory.mqh"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CSwingFlow : public CObject
{
private:
    CSwing   *m_swing;
    CSwingFactory *m_swing_factory;
    CSwing   *m_highest;
    CSwing   *m_lowest;
    CSwing   *m_limit;

    bool   m_flow_direction;
    bool   m_started;

    CSwing  *m_continuation;
    bool   m_is_continuation;

    CSwing  *m_breakout;
    bool   m_is_breakout;

    double m_continuation_price;



    bool hasBrokenSwing(CBar *bar, CSwing *swing)
    {
        if(!swing || !bar)
        {
            return false;
        }
        double max_price = swing.maxExtension();
        double bar_close = bar.close();
        if(swing.isHigh() && bar_close > max_price)
        {
            return true;
        }
        else if(swing.isLow() && bar_close < max_price)
        {
            return true;
        }
        return false;
    }

    void setBreakout(CSwing *swing)
    {
        if((m_flow_direction && swing.isLow()) || (!m_flow_direction && swing.isHigh()))
        {
            m_breakout = swing;
        }
    }

    void setContinuation(CSwing *swing)
    {
        if((m_flow_direction && swing.isHH()) || (!m_flow_direction && swing.isLL()))
        {
            m_continuation = swing;
        }
    }

    bool isFlowContinued(CBar *bar)
    {
        return hasBrokenSwing(bar, m_continuation);
    }
    
    bool isFlowBreak(CBar *bar)
    {
        return hasBrokenSwing(bar, m_breakout);
    }


public:
    CSwingFlow(CSwing *start_swing, bool flow_direction, CSwingFactory *p_swing_factory)
    {
        m_swing_factory = p_swing_factory;

        m_flow_direction = flow_direction;
        m_continuation = NULL;
        m_breakout = NULL;
        m_is_breakout = false;
        m_is_continuation = false;

        // Start swing is the start of the leg of this flow
        // A new flow is created once we break the last HL of a flow up or the last LH of a flow down
        if(start_swing)
        {
            setContinuation(start_swing);
            setBreakout(start_swing);
            m_started = true;
        }
    }
    ~CSwingFlow()
    {
    }

    CSwing* addBar(CBar *bar)
    {
        m_swing = m_swing_factory.addBar(bar);
        m_is_continuation = false;

        // if we have a new swing, we add it to the flow
        if(m_swing)
        {
            // Update the limits of the flow to know where the next break or continuation will happen
            setContinuation(m_swing);
            setBreakout(m_swing);

            if(!m_started)
            {
                m_started = true;
                m_flow_direction = m_swing.isHH() || m_swing.isHL() || m_swing.isSLE();

                return m_swing;
            }
        }

        // Check if the current bar is breaking higher/lower in the same direction of the flow
        if(isFlowContinued(bar))
        {
            m_is_continuation = true;
        }

        // Check if the current bar will break the current flow
        if(isFlowBreak(bar))
        {
            m_is_breakout = true;
        }

        if(!m_continuation)
        {
            setContinuationPrice(bar);
        }

        return m_swing;
    }

    bool isFlowBroken()
    {
        return m_is_breakout;
    }

    bool isFlowContinuation()
    {
        return m_is_continuation;
    }

    bool direction()
    {
        return m_flow_direction;
    }

    CSwing* getContinuationSwing()
    {
        return m_continuation;
    }

    CSwing* getBreakoutSwing()
    {
        return m_breakout;
    }

    double getContinuationPrice()
    {
        if(m_continuation)
        {
            return m_continuation.maxExtension();
        }
        return m_continuation_price;
    }

    void setContinuationPrice(CBar *bar)
    {
        if(m_flow_direction && bar.isBullish())
        {
            m_continuation_price = bar.high();
        }
        else if (!m_flow_direction && bar.isBearish() )
        {
            m_continuation_price = bar.low();
        }
    }

    CSwing* getLastSwing(bool direction)
    {
        if(direction)
        {
            return m_swing_factory.getLastLow();
        }

        return m_swing_factory.getLastHigh();
    }

    CSwingFactory* swingFactory()
    {
        return m_swing_factory;
    }

};

//+------------------------------------------------------------------+
