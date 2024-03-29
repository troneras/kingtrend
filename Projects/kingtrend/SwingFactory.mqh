//+------------------------------------------------------------------+
//|                                                 SwingFactory.mqh |
//|                                                 Antonio Blázquez |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Antonio Blázquez"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "Swing.mqh"
#include "Bar.mqh"
#include <Arrays/List.mqh>

#define  MAX_SWING_LIST_SIZE 100
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CSwingFactory
{
private:
    CBar             *m_bar_one;
    CBar             *m_bar_two;
    CSwing           *m_last_high;
    CSwing           *m_last_low;   
    CList            *m_swing_list;

    bool hasBrokenSwing(CBar *bar, CSwing *swing) {
       double max_price = swing.maxExtension();
       double bar_close = bar.close();
       if(swing.isHigh() && bar_close > max_price)
        {
            return true;
        } else if(swing.isLow() && bar_close < max_price)
        {
            return true;
        }
        return false;
   }
   
   bool hasExtendedSwing(CBar *bar,CSwing *swing) {
        if(hasBrokenSwing(bar, swing))
       {
           return false;
       }
       
       double max_price = swing.maxExtension();
       
       if(swing.isHigh() && bar.high() > max_price)
        {
            return true;
        } else if(swing.isLow() && bar.low() < max_price)
        {
            return true;
        }
        return false;
   }
   bool isSH(CBar *bar) {
     return m_bar_two.isHigherThan(m_bar_one) && bar.high() < m_bar_two.high();
   }
   
   bool isSL(CBar *bar) {
     return m_bar_two.isLowerThan(m_bar_one) && bar.low() > m_bar_two.low();
   }
   
   void addToList(CSwing *swing) {
        m_swing_list.Add(swing);
        
        if(m_swing_list.Total() > MAX_SWING_LIST_SIZE)
        {
           int to_delete = MAX_SWING_LIST_SIZE / 2;
           for(int i=0;i<to_delete;i++)
           {
              m_swing_list.Delete(0);
           }
        }
   }

public:
    CSwingFactory()
    {
        m_bar_one = NULL;
        m_bar_two = NULL;
        
        m_last_high = NULL;
        m_last_low = NULL;
        m_swing_list = new CList();
        m_swing_list.FreeMode(true);
    }
    
    
    ~CSwingFactory()
    {
        m_swing_list.Clear();
        delete m_swing_list;
        // I don't want to remove pointers objects here as they should be removed by a higher order component
    }


    // Adds a new bar to produce a new Swing
    CSwing* addBar(CBar *bar)
    {
        // Check first if first bar is null, is the first bar of the swing
        if(!m_bar_one)
        {
            m_bar_one = bar;
            return NULL;
        }        
           
        
        // Check first if second bar is null, is the second bar of the swing
        if(!m_bar_two)
        {
            if(bar.isInsideBar(m_bar_one))
            {
               return NULL;
            }
            m_bar_two = bar;
            return NULL;
        } 
        //if(bar.index() > 99138 && bar.index() < 99145)
        //{
        //    Print("Bar1: " + m_bar_one.index() + " H: " + m_bar_one.high() + " L: " + m_bar_one.low() + " O: " + m_bar_one.open() + " C: "+ m_bar_one.close() + " T: " + bar.time());
        //    Print("Bar2: " + m_bar_two.index() + " H: " + m_bar_two.high() + " L: " + m_bar_two.low() + " O: " + m_bar_two.open() + " C: "+ m_bar_two.close());
        //    Print("Bar: " + bar.index() + " H: " + bar.high() + " L: " + bar.low() + " O: " + bar.open() + " C: "+ bar.close());
        //}
        
        
        // We don't want inside bars 
        if(m_bar_two && bar.isInsideBar(m_bar_two))
        {       
            return NULL;
        }    
        
        // We check if this bar has extended/broken previous swings   
        if (m_last_high && hasExtendedSwing(bar, m_last_high))
        {
            m_last_high.setMaxExtension(bar.high(), bar.index());
            
        } else if(m_last_high && hasBrokenSwing(bar, m_last_high))
        {
            m_last_high.setBroken();   
            bar.setSwingBreaker();             
        }
        
        if (m_last_low && hasExtendedSwing(bar, m_last_low))
        {
            m_last_low.setMaxExtension(bar.low(), bar.index());
        } else if(m_last_low && hasBrokenSwing(bar, m_last_low))
        {
            m_last_low.setBroken();   
            bar.setSwingBreaker();   
        }
        
               
        // two consecutive bullish/bearish bars, we update the first component of the swing
        if( (m_bar_one.isLowerThan(m_bar_two) && m_bar_two.isLowerThan(bar)) 
        || (bar.isLowerThan(m_bar_two) && m_bar_two.isLowerThan(m_bar_one) && !isSH(bar))
        || (bar.isHigherThan(m_bar_two) && m_bar_two.isHigherThan(m_bar_one) && !isSL(bar)) 
        || (m_bar_one.isHigherThan(m_bar_two) && m_bar_two.isHigherThan(bar)) 
        || bar.isOutsideBar(m_bar_two)
        || (m_bar_one.isLowerThan(m_bar_two) && bar.high() == m_bar_two.high()) // edge cases where two bars have the same low/high
        || (m_bar_two.isLowerThan(m_bar_one) && bar.low() == m_bar_two.low())
        )
        {
            m_bar_one = m_bar_two;
            m_bar_two = bar;
            return NULL;
        }

        // If one is bullish and two is bearish, then it's a SH, viceversa for SL
        if(isSH(bar))
        {
            // create a new Swing High
            CSwing *new_swing = new CSwing(m_bar_one, m_bar_two, bar, SwingType::HH);
            if(!new_swing)
            {
                return NULL;
            }

            if(m_last_high)
            {
                // Check if the type is correct
                if(m_last_high.isHigherThan(new_swing))
                {
                   new_swing.setType(SwingType::LH);
                }                
                 else {
                    if(!m_last_high.isBroken())
                    {
                       new_swing.setType(SwingType::SHE);     
                    }
                    
                }
                
                // set a reference to the prev swing high to ease later calculations
                new_swing.setPrevSwingHigh(m_last_high);                
            }
            if(m_last_low)
            {
               // set a reference to the prev swing low to ease later calculations
                new_swing.setPrevSwingLow(m_last_low);
            }            
            
            // If it's not an extension, keep the reference to the new swing as the last swing high
            if(new_swing.type() != SwingType::SHE)
            {            
                m_last_high = new_swing;
            }
                        
            // we reset bars to start a new swing on next addBar invocation  
            // bar is now the first candidate for a new swing
            m_bar_one = m_bar_two; 
            m_bar_two = bar;
            
            addToList(new_swing);

            return new_swing;
        }
        // if we have a bar followed by a lower bar, and then a higher bar, then it's a swing low
        else if(isSL(bar))
        {
            
            // create a new Swing Low
            CSwing *new_swing = new CSwing(m_bar_one, m_bar_two, bar, SwingType::LL);
            if(!new_swing)
            {
                return NULL;
            }

            // Check if the type is correct
            if(m_last_low)
            {
                if(m_last_low.isLowerThan(new_swing))
                {
                   new_swing.setType(SwingType::HL);
                }                 
                else {
                    if(!m_last_low.isBroken())
                    {
                       new_swing.setType(SwingType::SLE);     
                    }
                }
                
                // set a reference to the prev swing low to ease later calculations
                new_swing.setPrevSwingLow(m_last_low);
            }    
            if(m_last_high)
            {
               // set a reference to the prev swing high to ease later calculations 
               new_swing.setPrevSwingHigh(m_last_high);  
            }        

            // keep the reference to the new swing as the last swing low
            if(new_swing.type() != SwingType::SLE)
            {
               m_last_low = new_swing;
            }
            
            // bar is now the first candidate for a new swing
            m_bar_one = m_bar_two; 
            m_bar_two = bar;
            
            addToList(new_swing);
            return new_swing;
        }
        
        // Print("bars are equals");

        // extreme case where two bars are equals
        return NULL;
    }
    
    
    CSwing *getLastLow() {
        return m_last_low;
    }
    
    CSwing *getLastHigh() {
        return m_last_high;
    }

};


//+------------------------------------------------------------------+
