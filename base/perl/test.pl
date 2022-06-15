#!/usr/bin/env /opt/zmanda/amanda/perl/bin/perl
	 eval 'exec /opt/zmc-1.0/perl/bin/perl -S $0 ${1+"$@"}'
		  if $running_under_some_shell;
		  use LWP::Simple;
		  use Expect;
		  use DBI;
		  use XML::RSS;
		  use DBD::mysql;
		  use HTML::Entities;
		  use Thread;
		  use FileHandle;
		  use Shell;
		  use Socket;
		  use POSIX;
		  use Switch;
		  use IPC::Shareable;
		  use Tie::IxHash;
		  use IPC::SysV;
		  print "hello World!\n";
