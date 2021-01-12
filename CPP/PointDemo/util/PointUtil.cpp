#include "PointUtil.h"

template <typename T>
void showValue(T *t, std::string name)
{
    std::cout << name << ":" << t << "--value:" << *t << std::endl;
}