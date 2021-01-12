#include <iostream>
#include "util/PointUtil.h"
using namespace std;

int main()
{
    int a = 1;
    int b = (4 + a++) + (6 + a++);
    cout << b << endl;
    // int a = 125;
    // int *pn = new int;
    // int *pa = &a;
    // showValue<int>(pa,"pa");
    // cout << "pn:" << pn << "--value:" << *pn << endl;
    // cout << "pa:" << pa << "--value:" << *pn << endl;
}