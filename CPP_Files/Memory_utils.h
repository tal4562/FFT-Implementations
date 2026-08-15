// cross flatform memory allocation
#ifndef MEMORY_UTILS_H
#define MEMORY_UTILS_H

#ifdef _WIN32
    #include <malloc.h>
    #define malloc_64(s) _aligned_malloc(s, 64)
    #define free_64(p)   _aligned_free(p)
#else
    #include <stdlib.h>
    #define malloc_64(s) ({ void* p; posix_memalign(&p, 64, s) == 0 ? p : nullptr; })
    #define free_64(p)   free(p)
#endif

#endif