=for PDK_OPTS
   --exe zipmonths.exe
   --use awtools.dll
   --trim-implicit --shared private --force --dyndll --runlib "." --verbose --freestanding --nologo --icon "d:/adminware/artwork/aw.ico"
   --info "CompanyName      = Phillip Beazley.;
           FileDescription  = zipmonths - the logfile aggregator;
           Copyright        = Copyright � 1999-2005 Phillip Beazley;
           LegalCopyright   = Copyright � 1999-2005 Phillip Beazley;
           SupportURL       = http://www.adminware.com/tools/;
           InternalName     = zipmonths;
           OriginalFilename = zipmonths;
           ProductName      = zipmonths;
           Language         = English;
           FileVersion      = 1.17.1.1;
           ProductVersion   = 1.17.1.1"
   zipmonths.pl
=cut

our $awp = 'zipmonths';
our $ver = '1.17.1.1';
our $cpy = 'Copyright � 1999-2005 Phillip Beazley';

use strict;
#use warnings;
use Getopt::Long;
use vars qw($awp $ver $cpy $log $help $man $version $quiet $test $directory $exclude $include $recurse $zipcmd);

# App-Specific Modules
use Cwd;
use File::Basename;
use File::Find;

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
our $zipcmd = 'pkzip -add -move -max';
our $directory = getcwd;

our %optionMappings = ('log' => \$log, 'help' => \$help, 'man' => \$man, 'version' => \$version, 'quiet' => \$quiet, 'test' => \$test,
	'directory' => \$directory, 'exclude' => \$exclude, 'include' => \$include, 'recurse' => \$recurse, 'zipcmd' => \$zipcmd);
our @options = ("log=s", "help|?", "man", "version", "quiet!", "test!",
	"directory:s", "exclude:s", "include:s", "recurse!", "zipcmd:s");
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
  -zipcmd        Zip Cmd/Opts                  [pkzip -add -move -max]
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
sub man { if (open (MAN,"$awp.txt")) { print <MAN>; close(MAN); } else { _err "Documentation not found." } $quiet = 1; puke(1); }

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
	my ($status) = $_[0];
	my ($message) = $_[1];
	_log "\n--- TEST MODE ---\n" if $test;
	_err $message if $message;
	exit $status;
}

# ----- App-Specific Sub Defs

# Directory Walker
sub dirWalk {
	return if (!($recurse) && $directory ne $File::Find::dir);
	next unless lc($_) =~ /^$include$/;
	&processFile ("$File::Find::name");
}

# Do File Processing
sub processFile {
	my ($path) = dirname(@_);
	my ($file) = lc(basename(@_));

	if ($test) {
		print "PATH : $path\n";
		print "FILE : $file\n";
	}

	if ($file =~ /$exclude/i && $exclude ne '') {
		_log "-- EXCLUDE: $file\n";
		return;
	}

	#######################################################################
	# EXAMPLE:	virus_20031104050011.log	->	virus_200311.zip		#
	#######################################################################

	if      ($file =~ '^[\w,_-]+\d{14}.log') {

		$file =~ '^([\w,_-]+\d{6})\d{8}';
		_log "    (1) - $file -> $1.zip\n";
		`$zipcmd $1.zip $file` if (!($test));

	############################################################################
	# EXAMPLE:	SMTP20040104.log			->	SMTP200401.zip			#
	############################################################################

	} elsif ($file =~ '^[\w,_.-]+\d{8}.log') {

		$file =~ '^([\w,_.-]+\d{6})\d{2}';
		_log "    (2) - $file -> $1.zip\n";
		`$zipcmd $1.zip $file` if (!($test));

	############################################################################
	# EXAMPLE:	onvix-20040104-1.log		->	onvix-200401.zip		#
	############################################################################

	} elsif ($file =~ '^[\w,_.-]+\d{8}-\d+.log') {

		$file =~ '^([\w,_.-]+\d{6})\d{2}-\d+';
		_log "    (3) - $file -> $1.zip\n";
		`$zipcmd $1.zip $file` if (!($test));

	############################################################################
	# EXAMPLE:	10282004.log				->	200410.zip			#
	############################################################################

	} elsif ($file =~ '^\d{2}\d{2}\d{4}.log') {

		$file =~ '^(\d{2})\d{2}(\d{4})';
		_log "    (4) - $file -> $2$1.zip\n";
		`$zipcmd $2$1.zip $file` if (!($test));

	############################################################################
	# EXAMPLE:	nc030318.log				->	nc0303.zip			#
	############################################################################

	} elsif ($file =~ '^[\w,_-]+\d{6}.log') {

		$file =~ '^([\w_,-]+\d{4})\d{2}';
		_log "    (5) - $file -> $1.zip\n";
		`$zipcmd $1.zip $file` if (!($test));

	############################################################################
	# EXAMPLE:	post.office-0124.log		->	post.office-01.zip		#
	############################################################################

	# This isn't good.

	} elsif ($file =~ '^[\w,_.-]+-\d{4}.log') {

		$file =~ '^([\w,_.-]+-\d{2})\d{2}';
		_log "    (6) - $file -> $1.zip\n";
		`$zipcmd $1.zip $file` if (!($test));

	############################################################################
	# EXAMPLE:	ftp-04Jan2004.log			->	ftp-2004Jan.zip		#
	############################################################################

	} elsif ($file =~ '^[\w,_-]+\d{2}\w{3}\d{4}.log') {

		$file =~ '^([\w_,-]+)\d{2}(\w{3})(\d{4})';
		_log "    (7) - $file -> $1$3$2.zip\n";
		`$zipcmd $1$3$2.zip $file` if (!($test));

	############################################################################
	# EXAMPLE:	urlscan.011804.log			->	urlscan.0401.zip		#
	############################################################################

	} elsif ($file =~ '^[\w,_\.-]+\d{2}\d{2}\d{2}.log') {

		$file =~ '^([\w_,\.-]+)(\d{2})\d{2}(\d{2})';
		_log "    (8) - $file -> $1$3$2.zip\n";
		`$zipcmd $1$3$2.zip $file` if (!($test));

	############################################################################
	# EXAMPLE:	rm-access.log.20040207010914	->	rm-access.log.200401.zip	#
	############################################################################

	} elsif ($file =~ '^[\w,_\.-]+\d{6}\d{2}\d{6}') {

		$file =~ '^([\w_,\.-]+)(\d{6})\d{2}\d{6}';
		_log "    (9) - $file -> $1$2.zip\n";
		`$zipcmd $1$2.zip $file` if (!($test));

	############################################################################
	# NO REGEX MATCH												#
	############################################################################

	} else {
		_log "        - Not Processed: $file\n";
	}

}

1;
