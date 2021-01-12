#include <iostream>
using namespace std;

enum Color{
    red,
    blue,
    pink,
    orange
};

void test_enum()
{
    Color c;
    c = red;
    cout << c << endl;
    c = pink;
    cout << c << endl;
    int temp = c;
    cout << c << endl;
    int ctemp = 1 + c;
    cout << ctemp << endl;
    Color cc;
    cc = static_cast<Color>(red + 1);
    cout << cc << endl;
}