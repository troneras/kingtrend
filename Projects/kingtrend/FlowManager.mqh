//+------------------------------------------------------------------+
//|                                                  FlowManager.mqh |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "SwingFactory.mqh"
#include "Swing.mqh"
#include "Bar.mqh"
#include "SwingFlow.mqh"
#include <Arrays/List.mqh>

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CFlowManager
{
private:
    CList           *m_bar_list;
    CList           *m_flow_list;
    CSwingFactory   *m_swing_factory;
    
    // auxiliary variables
    CSwingFlow      *m_flow;
    CSwing          *m_swing;
    bool            m_new_flow;


public:
    CFlowManager()
    {
        m_swing_factory = new CSwingFactory();
        m_flow_list = new CList();
        m_flow_list.FreeMode(true);
        m_bar_list = new CList();
        m_bar_list.FreeMode(true);

        m_flow = new CSwingFlow(NULL, false, m_swing_factory);
        m_flow_list.Add(m_flow);
    }
    ~CFlowManager()
    {
        m_flow_list.Clear();
        delete m_flow_list;
        m_bar_list.Clear();
        delete m_bar_list;
        delete m_swing_factory;
    }

    CSwing* onNewBar(CBar *bar)
    {
        m_new_flow = false;       
        // Add the new bar to the swing
        m_swing = m_flow.addBar(bar);

        if(m_flow.isFlowBroken())
        {
            m_new_flow = true;
            bool new_flow_direction = !m_flow.direction();
            CSwing *start_swing = m_flow.getLastSwing(new_flow_direction);
            if(m_swing && (!start_swing || (start_swing.index() < m_swing.index())))
            {
                start_swing = m_swing;
            }

            m_flow = new CSwingFlow(start_swing, new_flow_direction, m_flow.swingFactory());
            m_flow_list.Add(m_flow);

            m_flow.setContinuationPrice(bar);
        }
        
        return m_swing;
    }
    
    bool isFlowChange() {
        return m_new_flow;
    }
    
    bool getFlowDirection() {
        return m_flow.direction();
    }
    
    double getContinuationPrice() {
        return m_flow.getContinuationPrice();
    }
    
    double getBreakoutPrice() {
        CSwing *bo_swing = m_flow.getBreakoutSwing();
        if(bo_swing)
        {
           return bo_swing.maxExtension();
        }
        
        return 0.0;
    }
    
    CSwingFlow* getFlow() {
        return m_flow;
    }
};
//+------------------------------------------------------------------+
