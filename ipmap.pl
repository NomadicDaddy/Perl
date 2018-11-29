=for PDK_OPTS
   --exe ipmap.exe
   --use awtools.dll
   --trim-implicit --shared private --force --dyndll --runlib "." --verbose --freestanding --nologo --icon "d:/adminware/artwork/aw.ico"
   --info "CompanyName      = Phillip Beazley;
           FileDescription  = ipmap - the Windows LAN IP Address mapper;
           Copyright        = Copyright � 2003-2005 Phillip Beazley;
           LegalCopyright   = Copyright � 2003-2005 Phillip Beazley;
           SupportURL       = http://www.adminware.com/tools/;
           InternalName     = ipmap;
           OriginalFilename = ipmap;
           ProductName      = ipmap;
           Language         = English;
           FileVersion      = 0.91.1.1;
           ProductVersion   = 0.91.1.1"
   ipmap.pl
=cut

our $awp = 'ipmap';
our $ver = '0.91.1.1';
our $cpy = 'Copyright � 2003-2005 Phillip Beazley';

use strict;
#use warnings;
use Getopt::Long;
use vars qw($awp $ver $cpy $log $help $man $version $quiet $test $server $svtype $expand $computer $domain @servers);

# App-Specific Modules
use Win32::Lanman;
use Win32::IPConfig;

# Global Sub Defs
sub version;
sub usage;
sub man;
sub _log($);
sub _err($);
sub startup;
sub puke($;$);

# App-Specific Sub Defs
sub genOutput;
sub getServers($);

# Global Option Defaults
our $test = 0;

# App-Specific Option Defaults
our $svtype = 'ALL';
our @servers = ();

our %optionMappings = ('log' => \$log, 'help' => \$help, 'man' => \$man, 'version' => \$version, 'quiet' => \$quiet, 'test' => \$test,
	'server' => \$server, 'svtype' => \$svtype, 'expand' => \$expand);
our @options = ("log=s", "help|?", "man", "version", "quiet!", "test!",
	"server=s", "svtype:s", "expand!");
GetOptions(\%optionMappings, @options) || usage;
version if $version;
usage if $help;
man if $man;

# Catch Missing/Invalid Parameter Failures

startup;

# App-Specific Subs
&getServers($svtype);
&genOutput;

puke(0);

# ----- Global Sub Defs

# Show Syntax & Usage
sub usage {
	print <<EOF;
\n$awp v$ver\n$cpy\n\n$awp {options}

  -server        Process Specified Server
  -svtype        Enumerate Specific Type       ['ALL']
  -expand        One Line Per IP: ON
  -noexpand      One Line Per IP: OFF          [on]

  -test          Test Mode: ON
  -notest        Test Mode: OFF                [on]

  -noquiet       Output Verbosity: Verbose     [on]
  -quiet         Output Verbosity: Terse
  -log           Output to Specified Logfile   []

  -help | ?      Show This Help Text
  -man           Display Documentation
  -version       Show Version
EOF
	$test = 0;
	puke(0);
}

# Display Documentation
sub man { if (open(MAN,"$awp.txt")) { print <MAN>; close(MAN); } else { _err "Documentation not found." } $quiet = 1; puke(1); }

# Show Version
sub version { print $ver; exit(0); }

# Logging
sub _log($) { if ($log) { open(LOGFILE, ">>$log") or die "ERROR:  Could not open $log: $!"; print LOGFILE "@_"; close(LOGFILE) } else { print STDERR "@_" } }
sub _err($) { print STDERR "ERROR:  @_" }

# Startup
sub startup {
	print "\n$awp v$ver\n$cpy\n\n" unless $quiet;
	_log "--- TEST MODE ---\n\n" if $test;
}

# Shutdown
sub puke($;$) {
	my $status = $_[0];
	my $message = $_[1];
	_log "\n--- TEST MODE ---\n" if $test;
	_err $message if $message;
	exit $status;
}

# ----- App-Specific Sub Defs

# Enumerate Server List
sub getServers($) {
	my ($svtype) = $_[0];
	unless ($computer = Win32::NodeName) { puke(1, "Cannot determine computer name.\n"); }
	unless ($domain = Win32::DomainName) { puke(1, "Cannot determine the domain/workgroup name.\n"); }
	my (@info);
	if (!Win32::Lanman::NetServerEnum($computer, $domain, \'SV_TYPE_ALL', \@info)) {
		puke(1, "Cannot retrieve computer list.  Windows Error #" + Win32::Lanman::GetLastError());
	}
	if ($server) {
		push (@servers, $server);
	}
	else {
		foreach my $server (@info) {
			push (@servers, ${$server}{'name'});
		}
	}
}

# Generate IP Address Map
sub genOutput {
	if (@servers) {
		_log "server_name,domain,adapter_id,adapter_desc,dhcp_enabled,ip_address_list,gateway_list,dns_server_list,wins_server_list";
		foreach my $server (@servers) {
			print "Processing: $server\n";
			my $ipconfig = Win32::IPConfig->new($server);
			if ($ipconfig) {
				if (my @adapters = @{$ipconfig->get_adapters}) {
					foreach my $adapter (@adapters) {
						my $logLine = "\n$ipconfig->get_hostname, $ipconfig->get_domain, $adapter->get_id, $adapter->get_description,";
						if ($adapter->is_dhcp_enabled) {
							$logLine += 'Y,';
						} else {
							$logLine += 'N,';
						}
						_log $logLine;

						my @ipaddresses = @{$adapter->get_ipaddresses};
						if ($expand) {
							_log ",,,,,@ipaddresses,";
						} else {
							_log "@ipaddresses,";
						}

						my @gateways = @{$adapter->get_gateways};
						_log "@gateways,";
						my @dns = @{$adapter->get_dns};
						_log "@dns,";
						my @wins = @{$adapter->get_wins};
						_log "@wins";
					}
				}
				_log "\n";
			}
			else {
				_err "Can't enumerate $server.  Possibly XP?\n";
			}
		}
	} else {
		puke(1, "No servers found.\n");
	}
}

1;
