/* I/O port access on the ARM is something of a fiction */

#ifndef	_SYS_IO_H
#define	_SYS_IO_H	1

#include <features.h>

__BEGIN_DECLS

static __inline int
ioperm (unsigned long int __from, unsigned long int __num, int __turn_on)
{
  return 0;
}

static __inline int
iopl (int __level)
{
  return 0;
}

static __inline unsigned char
inb (unsigned short int __port)
{
  return 0;
}

static __inline unsigned char
inb_p (unsigned short int __port)
{
  return 0;
}

static __inline unsigned short int
inw (unsigned short int __port)
{
  return 0;
}

static __inline unsigned short int
inw_p (unsigned short int __port)
{
  return 0;
}

static __inline unsigned int
inl (unsigned short int __port)
{
  return 0;
}

static __inline unsigned int
inl_p (unsigned short int __port)
{
  return 0;
}

static __inline void
outb (unsigned char __value, unsigned short int __port)
{
}

static __inline void
outb_p (unsigned char __value, unsigned short int __port)
{
}

static __inline void
outw (unsigned short int __value, unsigned short int __port)
{
}

static __inline void
outw_p (unsigned short int __value, unsigned short int __port)
{
}

static __inline void
outl (unsigned int __value, unsigned short int __port)
{
}

static __inline void
outl_p (unsigned int __value, unsigned short int __port)
{
}

static __inline void
insb (unsigned short int __port, void *__addr, unsigned long int __count)
{
}

static __inline void
insw (unsigned short int __port, void *__addr, unsigned long int __count)
{
}

static __inline void
insl (unsigned short int __port, void *__addr, unsigned long int __count)
{
}

static __inline void
outsb (unsigned short int __port, const void *__addr,
       unsigned long int __count)
{
}

static __inline void
outsw (unsigned short int __port, const void *__addr,
       unsigned long int __count)
{
}

static __inline void
outsl (unsigned short int __port, const void *__addr,
       unsigned long int __count)
{
}


__END_DECLS
#endif /* _SYS_IO_H */
