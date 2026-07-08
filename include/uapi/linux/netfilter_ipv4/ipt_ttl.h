/* SPDX-License-Identifier: GPL-2.0 WITH Linux-syscall-note */
/* IP tables module for matching the value of the TTL
 * (C) 2000 by Harald Welte <laforge@gnumonks.org> */

#ifndef _IPT_TTL_H
#define _IPT_TTL_H

#include <linux/types.h>

enum {
	IPT_TTL_EQ = 0,		/* equals */
	IPT_TTL_NE,		/* not equals */
	IPT_TTL_LT,		/* less than */
	IPT_TTL_GT,		/* greater than */
};


struct ipt_ttl_info {
	__u8	mode;
	__u8	ttl;
};

struct ipt_TTL_info {
	__u8	mode;
	__u8	ttl;
};

#define IPT_TTL_SET 0
#define IPT_TTL_INC 1
#define IPT_TTL_DEC 2
#define IPT_TTL_MAXMODE IPT_TTL_DEC

#endif
