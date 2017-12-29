#include <stdio.h>
#include <stddef.h>
#include <stdlib.h>
// #include <conio.h>
#include <string.h>
#include <time.h>
#include <unistd.h>


void random_string(char * string, unsigned length)
{
  /* Seed number for rand() */
  // srand((unsigned int) time(0) + getpid());
   
  /* ASCII characters 32 to 126 */
  int i;  
  for (i = 0; i < length; ++i)
    {
      string[i] = rand() % 95 + 32;
    }
 
  string[i] = '\0';  
}

int main(void) {
	const size_t ranlen = 10;
    char *strings[ranlen];

    for (int i = 0; i < ranlen; ++i) {
    	strings[i] = malloc(sizeof(char*) * 3);
    	random_string(strings[i], 3);
    }

    const size_t len = sizeof(strings) / sizeof(char*);

    char *copy_strings[len];

    unsigned int s;
    printf("initially:\n");
    for (s = 0; s < len; s++) {
    	copy_strings[s] = strings[s];
        printf("%s\n", strings[s]);
    }
    printf("\n");

    // compute the lenght of strings once
    size_t strlens[len];
    for (int i = 0; i < len; ++i) {
    	strlens[i] = strlen(strings[i]);
    }
    radix_sort_string(strings, copy_strings, 0, len, strlens, 0);


	printf("finally:\n");
    for (s = 0; s < len; s++) {
        printf("%s\n", strings[s]);
    }
    

    return 0;
}