=for PDK_OPTS
   --exe logcycle.exe
   --use awtools.dll
   --trim-implicit --shared private --force --dyndll --runlib "." --verbose --freestanding --nologo --icon "d:/adminware/artwork/aw.ico"
   --info "CompanyName      = adminware, llc;
           FileDescription  = logcycle - the quick logfile cycler;
           Copyright        = Copyright � 1999-2005 adminware, llc;
           LegalCopyright   = Copyright � 1999-2005 adminware, llc;
           LegalTrademarks  = adminware is a trademark of adminware, llc;
           SupportURL       = http://www.adminware.com/tools/;
           InternalName     = logcycle;
           OriginalFilename = logcycle;
           ProductName      = logcycle;
           Language         = English;
           FileVersion      = 1.13.1.1;
           ProductVersion   = 1.13.1.1"
   logcycle.pl
=cut

our $awp = 'logcycle';
our $ver = '1.13.1.1';
our $cpy = 'Copyright � 1999-2005 adminware, llc';

use strict;
#use warnings;
use Getopt::Long;
use vars qw($awp $ver $cpy $log $help $man $version $quiet $test $directory $exclude $include $recurse);

# App-Specific Modules
use Cwd;
use File::Basename qw(basename dirname);
use File::Find;
use POSIX qw(strftime);

# Global Sub Defs
sub version;
sub usage;
sub man;
sub _log($);
sub _err($);
sub startup;
sub puke($;$);

# App-Specific Sub Defs
sub dirWalk;
sub processFile;

# Global Option Defaults
our $test = 0;

# App-Specific Option Defaults
our $recurse = 1;
our $include = '*.log*';
our $dstamp = strftime("%Y%m%d%H%M%S", gmtime(time));
our $directory = getcwd;

our %optionMappings = ('log' => \$log, 'help' => \$help, 'man' => \$man, 'version' => \$version, 'quiet' => \$quiet, 'test' => \$test,
	'directory' => \$directory, 'exclude' => \$exclude, 'include' => \$include, 'recurse' => \$recurse);
our @options = ("log=s", "help|?", "man", "version", "quiet!", "test!",
	"directory:s", "exclude:s", "include:s", "recurse!");
GetOptions(\%optionMappings, @options) || usage;
version if $version;
usage if $help;
man if $man;

# Catch Missing/Invalid Parameter Failures
#usage if (!(-e $filename) || !($pattern));
chdir($directory) || die "Cannot chdir to $directory: $!";

# Convert Glob Wildcards to RegEx
$include =~ s/\./\\\./g;
$include =~ s/\*/\.\*/g;

startup;

# App-Specific Subs
find(\&dirWalk, $directory);

puke(0);

# ----- Global Sub Defs

# Show Syntax & Usage
sub usage {
	print <<EOF;
\n$awp v$ver\n$cpy\n\n$awp {options}

  -directory     Directory to Process          [.]
  -exclude       File(s) to Exclude            [none]
  -include       File(s) to Include Only       [all]
  -recurse       Directory Recursion: ON       [on]
  -norecurse     Directory Recursion: OFF

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

# Directory Walker
sub dirWalk {
	return if (!($recurse) && $directory ne $File::Find::dir);
	next unless $_ =~ /^$include$/;
	&processFile ("$File::Find::name");
}

# Do File Processing
sub processFile {
	my ($path) = dirname(@_);
	my ($file) = basename(@_);

	if ($file =~ /$exclude/i && $exclude ne '') {
		_log "-- EXCLUDE: $file\n";
		return;
	}

	$file =~ '.log';

	_log "Cycling @_ to\n        $path/$`\_$dstamp.log\n";
	unless ($test) {
		if (!(rename ("@_", "$path/$`\_$dstamp.log"))) { _log "\nERROR: Could not cycle @_.\n\n" }
	}
}

1;
