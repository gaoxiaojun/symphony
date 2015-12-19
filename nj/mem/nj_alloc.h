#ifndef _NJ_ARENA_H
#define _NJ_ARENA_H

#define MAX_SIZE_T (~(size_t)0)
#define MALLOC_ALIGNMENT ((size_t)16U)

#define DEFAULT_ARENA_SIZE 1*1024*1024 

struct arena_meta_t {
    uint8_t[] black;
    uint8_t[] mark;
}


#endif
