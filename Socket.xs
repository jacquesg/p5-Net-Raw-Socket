#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <fcntl.h>

#include <linux/if_arp.h>
#include <linux/if_ether.h>
#include <linux/if_packet.h>

struct raw_socket
{
	int fd;
	struct sockaddr_ll send_address;
};

typedef struct raw_socket *Socket;

MODULE = Net::Raw::Socket		PACKAGE = Net::Raw::Socket

Socket
new (class, interface)
	SV *class
	const char *interface

	PREINIT:
		Socket sock;
		int fd, index;

	CODE:
		index = if_nametoindex (interface);
		if (index == 0)
			croak ("could not determine interface index for %s: %d", interface, errno);

		if ((fd = socket (AF_PACKET, SOCK_RAW, htons (ETH_P_ALL))) < 0)
			croak ("could not create raw socket");

		Newxz(sock, 1, struct raw_socket);
		sock->fd = fd;
		sock->send_address.sll_halen = ETH_ALEN;
		sock->send_address.sll_ifindex = index;
		sock->send_address.sll_family = AF_PACKET;
		sock->send_address.sll_protocol = htons (ETH_P_ALL);
		sock->send_address.sll_hatype = ARPHRD_ETHER;
		sock->send_address.sll_pkttype = PACKET_OTHERHOST;

		RETVAL = sock;

	OUTPUT:
		RETVAL

void
Send (self, packet)
	Socket self
	SV *packet

	PREINIT:
		struct sockaddr_ll socket_address;

		char *buffer;
		STRLEN len;

	CODE:
		buffer = SvPV (packet, len);

		if (sendto (self->fd, buffer, len, 0, (struct sockaddr *)&self->send_address, sizeof (self->send_address)) < 0)
		{
			croak ("could not send packet: %d", errno);
		}

void
DESTROY (self)
	Socket self

	CODE:
		if (self->fd)
			close (self->fd);
		Safefree(self);

