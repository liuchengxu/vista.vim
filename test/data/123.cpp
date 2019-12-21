#include <iostream>

using std::cout;
using std::endl;

namespace foo::bar {
	static const int x = 1;
};

void print_x(void)
{
	cout << foo::bar::x << endl;
}

namespace foo::bar {
	static const int y = 2;
};

void print_y(void)
{
	cout << foo::bar::y << endl;
}

int main(void)
{
	print_x();
	print_y();

	return 0;
}
