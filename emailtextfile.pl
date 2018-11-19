=for PDK_OPTS
   --exe emailtextfile.exe
   --use awtools.dll
   --trim-implicit --shared private --force --dyndll --runlib "." --verbose --freestanding --nologo --icon "d:/adminware/artwork/aw.ico"
   --info "CompanyName      = adminware, llc;
           FileDescription  = emailtextfile - the textfile emailer;
           Copyright        = Copyright � 1999-2007 adminware, llc;
           LegalCopyright   = Copyright � 1999-2007 adminware, llc;
           LegalTrademarks  = adminware is a trademark of adminware, llc;
           SupportURL       = http://www.adminware.com/tools/;
           InternalName     = emailtextfile;
           OriginalFilename = emailtextfile;
           ProductName      = emailtextfile;
           Language         = English;
           FileVersion      = 1.22.1.1;
           ProductVersion   = 1.22.1.1"
   emailtextfile.pl
=cut

our $awp = 'emailtextfile';
our $ver = '1.22.1.1';
our $cpy = 'Copyright � 1999-2007 adminware, llc';

use strict;
#use warnings;
use Getopt::Long;
use vars qw($awp $ver $cpy $log $help $man $version $quiet $test $filename $address $subject $server $delete);

# App-Specific Modules
use Net::SMTP;

# Global Sub Defs
sub version;
sub usage;
sub man;
sub _log($);
sub _err($);
sub startup;
sub puke($;$);

# App-Specific Sub Defs
sub sendMail;

# Global Option Defaults
our $test = 0;

# App-Specific Option Defaults
our $delete = 0;
our $filename = '';
our $server = 'smtp';
our $subject = "[Email TextFile] $filename";

our %optionMappings = ('log' => \$log, 'help' => \$help, 'man' => \$man, 'version' => \$version, 'quiet' => \$quiet, 'test' => \$test,
	'filename' => \$filename, 'address' => \$address, 'subject' => \$subject, 'server' => \$server, 'delete' => \$delete);
our @options = ("log=s", "help|?", "man", "version", "quiet!", "test!",
	"filename=s", "address=s", "subject:s", "server:s", "delete!");
GetOptions(\%optionMappings, @options) || usage;
version if $version;
usage if $help;
man if $man;

# Catch Missing/Invalid Parameter Failures
usage if (!(-e $filename) || !($address));

startup;

# App-Specific Subs
&sendMail;

puke(0);

# ----- Global Sub Defs

# Show Syntax & Usage
sub usage {
	print <<EOF;
\n$awp v$ver\n$cpy\n\n$awp {options}

  -filename      File to Send
  -address       Email Address(es) to Send to
  -subject       Email Subject                 ['[Email TextFile] <name>']
  -server        SMTP Server to Send Through   ['smtp']
  -delete        Delete After Sending: ON
  -nodelete      Delete After Sending: OFF     [on]

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

# Send Email
sub sendMail {
	my @addresses = split(',',$address);
	foreach my $email (@addresses) {
		my $smtp = new Net::SMTP($server, Hello => "$email");
		$smtp->mail($email);
		$smtp->to($email);
		$smtp->data();
		$smtp->datasend("To: $email\n");
		$smtp->datasend("From: $email\n");
		$smtp->datasend("Subject: $subject\n\n");
		open (Z, "< $filename"); my @z = <Z>; close(Z);
		$smtp->datasend( \@z );
		$smtp->dataend();
		$smtp->quit;
	}
	unlink ($filename) if ($delete);
}

1;
