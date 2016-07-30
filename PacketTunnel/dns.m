//
//  dns.c
//  Potatso
//
//  Created by LEI on 11/11/15.
//  Copyright © 2015 TouchingApp. All rights reserved.
//

#include "dns.h"
#include <sys/types.h>
#include <netinet/in.h>
#include <arpa/nameser.h>
#include <resolv.h>
#include <arpa/inet.h>

@implementation DNSConfig

+(NSArray *)getSystemDnsServers{
    res_state res = malloc(sizeof(struct __res_state));
    int result = res_ninit(res);
    NSMutableArray *servers = [[NSMutableArray alloc] init];
    if (result == 0) {
        union res_9_sockaddr_union *addr_union = malloc(res->nscount * sizeof(union res_9_sockaddr_union));
        res_getservers(res, addr_union, res->nscount);
        for (int i = 0; i < res->nscount; i++) {
            if (addr_union[i].sin.sin_family == AF_INET) {
                char ip[INET_ADDRSTRLEN];
                inet_ntop(AF_INET, &(addr_union[i].sin.sin_addr), ip, INET_ADDRSTRLEN);
                NSString *dnsIP = [NSString stringWithUTF8String:ip];
                [servers addObject:dnsIP];
            }
        }
    }
    res_nclose(res);
    free(res);
    return [NSArray arrayWithArray:servers];
}

@end
