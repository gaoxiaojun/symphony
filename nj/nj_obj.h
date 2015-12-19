#ifndef _NJ_OBJ_H
#define _NJ_OBJ_H

#include "lua.h"


typedef uint32_t MSize;

#if NJ_GC64
typedef uint64_t GCSize;
#else
typedef uint32_t GCSize;
#endif


#endif // _NJ_OBJ_H

