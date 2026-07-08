/* SPDX-License-Identifier: GPL-2.0 WITH Linux-syscall-note */
/* ip6tables module for matching the Hop Limit value
 * Maciej Soltysiak <solt@dns.toxicfilms.tv>
 * Based on HW's ttl module */

#ifndef _IP6T_HL_H
#define _IP6T_HL_H

#include <linux/types.h>

enum {
	IP6T_HL_EQ = 0,		/* equals */
	IP6T_HL_NE,		/* not equals */
	IP6T_HL_LT,		/* less than */
	IP6T_HL_GT,		/* greater than */
};


struct ip6t_hl_info {
	__u8	mode;
	__u8	hop_limit;
};

struct ip6t_HL_info {
	__u8	mode;
	__u8	hop_limit;
};

#define IP6T_HL_SET 0
#define IP6T_HL_INC 1
#define IP6T_HL_DEC 2
#define IP6T_HL_MAXMODE IP6T_HL_DEC

#endif
