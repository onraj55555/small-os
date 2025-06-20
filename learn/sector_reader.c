#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>

unsigned char sector[521] = { 0 };

int main(int argc, char ** argv) {
    printf("Opening file %s\n", argv[1]);
    FILE * fp = fopen(argv[1], "r");

    if(!fp) {
        perror("Failed to open file");
        exit(1);
    }

    long sector_nr = atol(argv[2]);
    printf("Reading sector %ld\n", sector_nr);

    if(fseek(fp, 512 * sector_nr, SEEK_SET) != 0) {
        perror("Failed to seek");
        exit(1);
    }

    size_t count = fread(sector, 512, 1, fp);

    if(count != 1) {
        printf("Count does not match: %ld\n", count);
        exit(1);
    }

    printf("Printing...\n");

    for(int i = 0; i < 512; i++) {
        unsigned char c = sector[i];
        if(i % 16 == 0) puts("");
        if(isprint(c)) {
            printf("%c    ", c);
        } else {
            printf("0x%02x ", c);
        }
    }
    puts("");
}