/*
 * Copyright (C) 2006-2007 Google. All Rights Reserved.
 * Amit Singh <singh@>
 */

#ifndef _FUSE_KLUDGES_H_
#define _FUSE_KLUDGES_H_

#include "fuse.h"
#include "fuse_sysctl.h"

#include <sys/cdefs.h>
#include <sys/mount.h>
#include <sys/types.h>

#ifndef LK_NOWAIT
#define LK_NOWAIT 0x00000010
#endif

#endif /* _FUSE_KLUDGES_H_ */
