#include <iostream>
using namespace std;

struct {
	int bar;
} anon;

namespace example {
	struct {
		int foo;
	};

	struct {
		int bar;
	};

	enum {
		FOO
	};

	enum {
		BAR
	};
}

namespace {
	enum {
		BAZ
	};
}

int
main(void)
{
	return 0;
}
