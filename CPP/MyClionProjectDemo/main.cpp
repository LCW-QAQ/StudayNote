#include <iostream>
#include <ctime>
#include <thread>
using namespace std;

void reverse_str(string& str){
    for(int i = 0, j = str.size()-1; i < j; i+=2, j-=2){
        char temp = str[i];
        str[i] = str[j-1];
        str[j-1] = temp;
        temp = str[i+1];
        str[i+1] = str[j];
        str[j] = temp;
    }
}

int main() {
//    char ch;
//    cout << "#结束" << endl;
//    cin >> ch;
//    int count = 0;
//    while(ch != '#'){
//        cout << ch;
//        count++;
//        cin >> ch;
//    }
//    cout << endl << "chars count:" << count << endl;
}
