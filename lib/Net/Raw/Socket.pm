package Net::Raw::Socket;

use strict;
use warnings;

our $VERSION = '0.1';

require XSLoader;
XSLoader::load('Net::Raw::Socket', $Net::Raw::Socket::VERSION);

1;
