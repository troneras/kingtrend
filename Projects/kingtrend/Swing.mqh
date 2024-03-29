//+------------------------------------------------------------------+
//|                                                        Swing.mqh |
//|                                                 Antonio Blázquez |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Antonio Blázquez"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Object.mqh>
#include "SwingType.mqh"
#include "Bar.mqh"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CSwing : public CObject
{
private:
    
    CBar             *m_bar_one;
    CBar             *m_bar_two;
    CBar             *m_bar_three;
    datetime          m_time;
    double            m_extreme;    
    int               m_index;
    SwingType         m_type;
    bool              m_is_broken;
    
    double            m_max_extension;
    int               m_max_extension_index;
    
    CSwing           *m_prev_swing_low;
    CSwing           *m_prev_swing_high;

    double getExtreme(CBar *bar)
    {
        if(bar.isBearish())
        {
            return bar.low();
        }
        
        return bar.high();        
    }
    
    bool isHigher(CBar *bar_one, CBar *bar_two) {
        return bar_one.high() > bar_two.high();
    }
    
    bool isLower(CBar *bar_one, CBar *bar_two) {
        return bar_one.low() < bar_two.low();
    }

public:
    ~CSwing()
    {
    }
    
     CSwing(CBar *bar_one, CBar *bar_two, CBar *bar_three, SwingType type)
    {
        m_bar_one = bar_one;
        m_bar_two = bar_two;
        m_bar_three = bar_three;
        m_type = type;
        m_is_broken = false;
        
        m_time = m_bar_two.time();          
        m_index = m_bar_two.index(); 
        
        if(type == SwingType::HH || type == SwingType::LH || type == SwingType::SHE)
        {
           m_extreme = m_bar_two.high();           
        } else {
           m_extreme = m_bar_two.low();        
        }   
        m_max_extension = m_extreme;
        m_max_extension_index = m_bar_two.index();    
    }
    
    void setPrevSwingLow(CSwing* swing) {
        m_prev_swing_low = swing;
    }
    void setPrevSwingHigh(CSwing* swing) {
        m_prev_swing_high = swing;
    }
    
    CSwing* prevSwingLow() {
        return m_prev_swing_low;
    }
    CSwing* prevSwingHigh() {
        return m_prev_swing_high;
    }
    
    double extreme() {
        return m_extreme;
    }
    
    datetime time() {
        return m_time;
    }
    
    int index() {
        return m_index;
    }
    
    SwingType type() {
        return m_type;
    }
    
    void setType(SwingType type) {    
        m_type = type;
    }
    
    double maxExtension() {
        return m_max_extension;
    }
    
    void setMaxExtension(double max, int index) {
        m_max_extension = max;
        m_max_extension_index = index;
    }
    
    bool isHH()
    {
        return m_type == SwingType::HH;
    }

    bool isLH()
    {
        return m_type == SwingType::LH;
    }

    bool isHL()
    {
        return m_type == SwingType::HL;
    }

    bool isLL()
    {
        return m_type == SwingType::LL;
    }
    
    bool isSLE()
    {
        return m_type == SwingType::SLE;
    }
    bool isSHE()
    {
        return m_type == SwingType::SHE;
    }
   

    bool isHigherThan(CSwing *swing)
    {
        return m_max_extension > swing.maxExtension();
    }
    
    bool isLowerThan(CSwing *swing)
    {
        return m_max_extension < swing.maxExtension();
    }
    
    bool isHigh() {
        return m_type == SwingType::HH || m_type == SwingType::LH || m_type == SwingType::SHE;
    }
    
    bool isLow() {
        return m_type == SwingType::LL || m_type == SwingType::HL || m_type == SwingType::SLE;
    }
    
    void setBroken() {
        m_is_broken = true;
    }
    
    bool isBroken() {
        return m_is_broken;
    }
};

//+------------------------------------------------------------------+
