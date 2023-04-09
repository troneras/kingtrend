//+------------------------------------------------------------------+
//|                                                   ABCManager.mqh |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "Bar.mqh"
#include <Arrays/List.mqh>
#include "ABC.mqh"
#include "FlowManager.mqh"
#include <Arrays/List.mqh>
#define  MAX_BAR_LIST_SIZE 100

class CABCManager
{
private:
    CBar    *m_bar;
    CList   *m_bar_list;
    CList   *m_abc_list;
    CABC    *m_abc;
    CSwing  *m_swing;
    CFlowManager *m_flow_manager;   
    bool    m_new_abc;
    
    void addToList(CBar *bar) {
        m_bar_list.Add(bar);
        if(m_bar_list.Total() > MAX_BAR_LIST_SIZE)
        {
           int to_delete = MAX_BAR_LIST_SIZE / 2;
           for(int i=0;i<to_delete;i++)
           {
              m_bar_list.Delete(0);
           }
        }
    }

public:
    CABCManager() {
        m_bar_list = new CList();
        m_bar_list.FreeMode(true);
        m_abc_list = new CList();
        m_abc_list.FreeMode(true);
        
        m_flow_manager = new CFlowManager();
        
        m_abc = new CABC(NULL, false, m_flow_manager);
        m_abc_list.Add(m_abc);        
    }
    
    ~CABCManager() {
        m_bar_list.Clear();
        delete m_bar_list;
        
        delete m_flow_manager;
         
        m_abc_list.Clear();
        delete m_abc_list;
    }
    
    CSwing* onNewBar(const datetime time, const double open, const double high, const double low, const double close, int index) {
        m_bar = new CBar(time, open, high, low, close, index);
        addToList(m_bar);
        m_new_abc = false;
        
        m_swing = m_abc.onNewBar(m_bar);
        
        if(m_abc.isBroken())
        {
            m_new_abc = true;
            double breakout_price = m_abc.getBreakoutPrice();
            bool new_abc_direction = !m_abc.direction();
            CSwing *start_swing = m_abc.getLastSwing(new_abc_direction);
            if(m_swing && (!start_swing || (start_swing.index() < m_swing.index())))
            {
                start_swing = m_swing;
            }
            m_abc = new CABC(start_swing, new_abc_direction, m_flow_manager);
            m_abc.setContinuationPrice(m_bar);
            m_abc.setBreakouInfo(m_bar, breakout_price);
            m_abc_list.Add(m_abc);
        }        
                
        return m_swing;
    }
    
    bool isAbcChange() {
        return m_new_abc;
    }
    
    bool getAbcDirection() {
        return m_abc.direction();
    }
    
    double getContinuationPrice() {
        return m_abc.getContinuationPrice();
    }
    
    double getBreakoutPrice() {
        return m_abc.getBreakoutPrice();
    }
};

