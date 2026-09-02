import json
import os
from datetime import datetime

def update_rates():
    rates_data = {
        "last_updated": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "rates": [
            {"currency": "USD (دالر)", "buy": "70.50", "sell": "70.70", "unit": "AFN"},
            {"currency": "EUR (یورو)", "buy": "76.00", "sell": "76.40", "unit": "AFN"},
            {"currency": "IRR (تومان)", "buy": "1.12", "sell": "1.15", "unit": "AFN (هر هزار تومان)"},
            {"currency": "PKR (کلدار)", "buy": "250", "sell": "252", "unit": "AFN (هر هزار کلدار)"},
            {"currency": "طلا (یک گرام عیار ۷۵۰)", "buy": "4500", "sell": "4550", "unit": "AFN"},
            {"currency": "طلا (یک مثقال عیار ۷۵۰)", "buy": "20700", "sell": "20900", "unit": "AFN"},
            {"currency": "نقره (یک مثقال)", "buy": "350", "sell": "370", "unit": "AFN"}
        ]
    }
    
    os.makedirs('assets', exist_ok=True)
    with open('assets/rates.json', 'w', encoding='utf-8') as f:
        json.dump(rates_data, f, ensure_ascii=False, indent=2)

if __name__ == "__main__":
    update_rates()
