#include <iostream>
#include <iomanip>
#include <algorithm>
using namespace std;

void yhTriangle(int line){
    int** yh = new int*[line];
    //初始化二维数组
    for(int i = 0; i < line; ++i){
        yh[i] = new int[i+1];
        yh[i][0] = 1;
        yh[i][i] = 1;
    }
    //填充二维数组
    for(int i = 2; i < line; ++i){
        for(int j = 1; j < i; ++j){
            yh[i][j] = yh[i-1][j-1]+yh[i-1][j];
        }
    }
    //打印二维数组
    for(int i = 0; i < line; ++i){
        //左填充
        for(int m = 0; m < line - i; ++m){
            cout << setw(3) << " ";
        }
        for(int j = 0; j <= i; ++j){
            cout << setw(6) << yh[i][j];
        }
        cout << endl;
    }
    //释放内存
    for(int i = 0; i < line; ++i){
        delete[] yh[i];
    }
    delete[] yh;
}

class Math{
public:
    ~Math(){
        cout << this;
        cout << "被销毁了" << endl;
    }
};

int main() {
    int arr[5];
    int i = 0;
    while(i < 5 && cin >> arr[i]){
        if(++i < 5){
            cout << i+1;
        }
    }
}
