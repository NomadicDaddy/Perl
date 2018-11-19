=for PDK_OPTS
   --exe displayNewest.exe
   --trim-implicit --shared none --force --dyndll --norunlib --verbose --freestanding --nologo --icon "x:/adminware/artwork/aw.ico"
   --info "CompanyName      = adminware, llc;
           FileDescription  = displayNewest - automatically display images as they are added to a folder;
           Copyright        = Copyright � 2009 adminware, llc;
           LegalCopyright   = Copyright � 2009 adminware, llc;
           LegalTrademarks  = adminware is a trademark of adminware, llc;
           SupportURL       = http://www.adminware.com/tools/;
           InternalName     = displayNewest;
           OriginalFilename = displayNewest;
           ProductName      = displayNewest;
           Language         = English;
           FileVersion      = 1.0.0.0;
           ProductVersion   = 1.0.0.0"
   displayNewest.pl
=cut

our $awp = 'displayNewest';
our $ver = '1.0.0.0';
our $cpy = 'Copyright � 2009 adminware, llc';

use strict;
#use warnings;
use Getopt::Long;
use vars qw($awp $ver $cpy $log $help $man $version $quiet $test $source);

# app-specific modules
require Win32::ChangeNotify;
use File::Util;
use Cwd;

# global sub defs
sub version;
sub usage;
sub man;
sub _log;
sub _err;
sub startup;
sub puke;

# app-specific sub defs
sub monitorDir;

# global option defaults
our $notify;
our $test = 0;

# app-specific option defaults
our $source = getcwd;

our %optionMappings = ('log' => \$log, 'help' => \$help, 'man' => \$man, 'version' => \$version, 'quiet' => \$quiet, 'test' => \$test,
	'source' => \$source);
our @options = ("log=s", "help|?", "man", "version", "quiet!", "test!",
	"source:s");
GetOptions(\%optionMappings, @options) || usage;
version if $version;
usage if $help;
man if $man;

# catch missing/invalid parameter failures
die "The source ($source) does not exist.\n" if (!(-e $source));

startup;

# app-specific subs
monitorDir;

puke(0);

# ----- global sub defs

# show syntax & usage
sub usage {
	print <<"EOF";
\n$awp v$ver\n$cpy\n\n$awp {options}

  -source        Source Directory to Monitor   [.]

  -test          Test Mode: ON                 [off]
  -notest        Test Mode: OFF

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

# display documentation
sub man { if (open(my $mf, '<', "$awp.txt")) { print $mf; close $mf; } else { _err "Documentation not found." } $quiet = 1; puke(1); }

# show version
sub version { print $ver; exit(0); }

# logging
sub _log { if ($log) { open(my $lf, '>>', $log) or die "ERROR:  Could not open $log: $!"; print $lf "@_"; close $lf } else { print STDERR "@_" } }
sub _err { print STDERR "ERROR:  @_" }

# startup
sub startup {
	print "\n$awp v$ver\n$cpy\n\n" unless $quiet;
	_log "--- TEST MODE ---\n\n" if $test;
}

# shutdown
sub puke {
	my $status = $_[0];
	my $message = $_[1];
	_log "\n--- TEST MODE ---\n" if $test;
	_err $message if $message;
	exit $status;
}

# ----- app-specific sub defs

sub monitorDir {

	$source =~ s/\//\\/g;
	print "MONITORING:  $source\n\n";

	our $item;
	our @like = ( );
	our @diff  = ( );
	our %count = ( );

	our $watch = File::Util->new();
	our @contents = $watch->list_dir($source, qw/ --files-only --no-fsdots --pattern=\.jpg$ /);

	$notify = Win32::ChangeNotify->new($source, 'false', 'ATTRIBUTES DIR_NAME FILE_NAME LAST_WRITE SECURITY SIZE');

	do {

		$notify->wait or puke(1, "$!\n");
		$notify->reset;

		my @files = $watch->list_dir($source, qw/ --files-only --no-fsdots --pattern=\.jpg$ /);

		@like = ( );
		@diff  = ( );
		%count = ( );

		foreach $item (@files, @contents) { $count{$item}++; }
		foreach $item (keys %count) {
			if ($count{$item} == 2) {
				push @like, $item;
			} else {
				push @diff, $item;
			}
		}

		@contents = @files;

		# something changed, do this...
		foreach $item (@diff) {
			$item =~ s/\//\\/g;
			if (-e $item) {
				_log "$item\n";

#				system("pskill -t xnview.exe");
#				system("\"$source\\xnview.exe\" -browser -full \"$source\\$item\" &");

#				system("pskill -t i_view32.exe");
				system("start /B \"$source\\i_view32.exe\" \"$source\\$item\" /one /fs /title=Cheese! /monitor=2 &");

			}
		}

	} until (1 == 2);

	# terminate watch
	$notify->close;

}
