#include <stddef.h>
#include <stdio.h>

int main() {
	printf("%d", sizeof(int));
	size_t x = 1000000;
	printf("%d", x);
	return 1;
}