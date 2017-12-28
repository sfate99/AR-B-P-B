#include "stdlib.h"
#include "unistd.h"
int main(int argc, char **argv) {
        if(argc == 2) { usleep(atoi(argv[1])); }
        return 0;
}
