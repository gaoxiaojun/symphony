New GC

1.概览
  新的垃圾收集器是一个基于区域的，四色增量，分代，非拷贝，高速，缓存优化的。

2.arena
arena是一个很大的对齐的内存块。arena直接使用系统特定代码向操作系统申请的。


==== GC ====
1.如何管理arena
  jemalloc管理的chunk大小为4M,每个chunk头有这个chunk的meta数据，对于GC大小为1M来说，这个方法就浪费了最后1M数据
  jemalloc管理chunk本身采用的是红黑树，对于64KB，这个是不是开销又大了？


