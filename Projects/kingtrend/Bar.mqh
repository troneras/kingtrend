//+------------------------------------------------------------------+
//|                                                          Bar.mqh |
//|                                                 Antonio Blázquez |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Antonio Blázquez"
#property link      "https://www.mql5.com"
#property version   "1.00"


#include <Object.mqh>

class CBar : public CObject {
private:
   datetime m_time;
   double m_high;
   double m_low;
   double m_open;
   double m_close;
   int    m_index;
   
   bool   m_swing_breaker;

public:
   CBar() {
      m_time = 0;
      m_high = 0;
      m_low = 0;
      m_open = 0;
      m_close = 0;
      m_swing_breaker = false;
   };
   
   CBar(const datetime time, const double open, const double high, const double low, const double close, int index) {
      m_time = time;
      m_high = high;
      m_low = low;
      m_open = open;
      m_close = close;
      m_index = index;
      m_swing_breaker = false;
   };
   
   bool isBullish() {
      return m_close > m_open;
   }
   
   bool isBearish() {
      return m_close < m_open;
   }
   bool isPinbar() {
     return m_close == m_open;
   }
   
   double high() {return m_high;}
   double close() {return m_close;}
   double low() {return m_low;}
   double open() {return m_open;}
   datetime time() {return m_time;}
   int index() {return m_index;}
   
   void increaseIndex() {
      m_index += 1;
   }
   
   bool isHigherThan(CBar *other) {
      return other.high() < m_high;
   }
   bool isLowerThan(CBar *other) {
      return other.low() > m_low;
   }
   bool isOutsideBar(CBar *other) {
      return m_high > other.high() && m_low < other.low();
   }
   
   // Checks if this bar has broken the other bar
   bool hasBroken(CBar *other, bool direction) {
      return (direction && other.high() < m_close) || (!direction && other.low() > m_close);             
   }
   
   // Checks If this bar has extended the other bar
   bool hasExtended(CBar *other, bool direction) {
      return !hasBroken(other, direction) && ( (direction && other.high() < m_high) || (!direction && other.low() > m_low));
   }
   
   // Checks if this bar is an inside bar of the otherS
   bool isInsideBar(CBar *other) {
      if(!other)
        {
         return false;
        }
      return other.high() >= m_high && other.low() <= m_low;
   }
   
   void setSwingBreaker() {
      m_swing_breaker = true;
   }
   
   bool isSwingBreaker() {
     return m_swing_breaker;
   }
   
   ~CBar(){
    
   }
};
