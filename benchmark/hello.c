#include <stdio.h>
#include <stddef.h>
#include <stdlib.h>
// #include <conio.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

int radix_sort_string(char **strings, char **copy_strings, size_t lo, size_t hi, size_t *strlens, size_t pos) {
	// size_t maxlen;
 //    unsigned int c;

	// printf("starting to sort position %d from %d to %d\n", pos, lo, hi);
	unsigned int s;
	for (s = lo; s < hi; s++) {
        // printf("%s\n", strings[s]);
    }

    // pointer to counter
    size_t bins[256];

	for (int j = 0; j < 256; j++) {
		bins[j] = 0;
	}
	
	// count the number occurences of each byte

	for (int j = lo; j < hi; j++) {
		size_t ci = 0;
		if (strlen(strings[j]) >= pos) {
			ci = strings[j][pos];
		}
		bins[ci]++;
	}


	// compute the cumulative sum that represents the correct location
	for (int j = 1; j < 256; j++) {
		bins[j] = bins[j-1] + bins[j];
	}

	// make a copy for easy recursion later
	size_t copy_bins[256];
	for (int i = 0; i < 256; ++i) {
		copy_bins[i] = bins[i] + lo;
	}

	for (int j = 255; j >= 1; j--) {
		bins[j] = bins[j-1] + lo;
	}
	bins[0] = lo;

	
	// now go through the strings again and place them in the right order
	for (int i = lo; i < hi; i++) {
		size_t ci = 0;
		if (strlen(strings[i]) >= pos) {
			ci = strings[i][pos];
		}
		copy_strings[bins[ci]] = strings[i];
		bins[ci]++;
	}

	
	// printf("after sorting position: %d\n", pos);
	for (s = lo; s < hi; s++) {
		strings[s] = copy_strings[s];
        // printf("%s\n", strings[s]);
    }

  

	for (int i = 1; i < 256; i++) {
    	if(copy_bins[i] - copy_bins[i-1] > 1) {
    		// printf("%d %d\n", copy_bins[i-1], copy_bins[i]);
    		// for (int j = copy_bins[i-1]; j < copy_bins[i]; j++) {
    		// 	strings[j] = copy_strings[j];
    		// }
    		// free(bins);
    		lo = copy_bins[i-1];
    		hi = copy_bins[i];
    		// free(copy_bins);
    		radix_sort_string(strings, copy_strings, lo, hi, strlens, pos + 1);
    		// return 0;
    	}
	}
    
    return 0;
}

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