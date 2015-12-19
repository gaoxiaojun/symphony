

#ifndef ARENA_SIZE
#define ARENA_SIZE 64*1024
#endif

/*
 * arena management
 */



/*
 * cell & block manangement
 */


/*
 * mark management
 */

struct arena_meta {
    uint8_t blockbm[ARENA_SIZE/16/8];
    uint8_t markbm[ARENA_SIZE/16/8];
};

/* block allcator
 * 1.bump allcator
 * 2.fit allocator
 */
void *bump_block_alloc(arena_meta *arena, size_t gsize);
void  bump_block_free(arena_meta *arena, uint16_t block_index);

void *fit_block_alloc(arena_meta *arena, size_t gsize);
void  fit_block_free(arena_meta *arena, uint16_t block_index);
    
