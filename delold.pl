=for PDK_OPTS
   --exe delold.exe
   --use awtools.dll
   --trim-implicit --shared private --force --dyndll --runlib "." --verbose --freestanding --nologo --icon "x:/adminware/artwork/aw.ico"
   --info "CompanyName      = adminware, llc;
           FileDescription  = delold - the old file remover;
           Copyright        = Copyright © 2001-2010 adminware, llc.  All rights reserved.;
           LegalCopyright   = Copyright © 2001-2010 adminware, llc.  All rights reserved.;
           LegalTrademarks  = adminware is a trademark of adminware, llc;
           SupportURL       = http://www.adminware.com/tools/;
           InternalName     = delold;
           OriginalFilename = delold;
           ProductName      = delold;
           Language         = English;
           FileVersion      = 1.27.1.1;
           ProductVersion   = 1.27.1.1"
   delold.pl
=cut

our $awp = 'delold';
our $ver = '1.27.1.1';
our $cpy = 'Copyright © 2001-2010 adminware, llc.  All rights reserved.';

use strict;
#use warnings;
use Getopt::Long;
use vars qw($awp $ver $cpy $log $help $man $version $quiet $test $directory $exclude $include $recurse $age);

# app-specific modules
use Cwd;
use File::Basename qw(basename dirname);
use File::Find;
use POSIX qw(ceil);

# global sub defs
sub version;
sub usage;
sub man;
sub _log(@);
sub _err(@);
sub startup;
sub puke($;@);

# app-specific sub defs
sub dirWalk;
sub processFile;

# global option defaults
our $test = 1;

# app-specific option defaults
our $recurse = 1;
our $include = '*.*';
our $exclude = '';
our $time = time();
our $directory = getcwd;
our $age = 0;

our %optionMappings = ('log' => \$log, 'help' => \$help, 'man' => \$man, 'version' => \$version, 'quiet' => \$quiet, 'test' => \$test,
	'directory' => \$directory, 'exclude' => \$exclude, 'include' => \$include, 'recurse' => \$recurse, 'age' => \$age);
our @options = ("log=s", "help|?", "man", "version", "quiet!", "test!",
	"directory:s", "exclude:s", "include:s", "recurse!", "age:i");
GetOptions(\%optionMappings, @options) || usage;
version if $version;
usage if $help;
man if $man;

# catch missing/invalid parameter failures
#usage if (!(-e $filename) || !($pattern));
chdir($directory) || die "Cannot chdir to $directory: $!";

# convert glob wildcards to regex
$include =~ s/\./\\\./g;
$include =~ s/\*/\.\*/g;
$exclude =~ s/\./\\\./g;
$exclude =~ s/\*/\.\*/g;

startup;

# app-specific subs
find({ wanted => \&dirWalk, preprocess => \&dirWalkPre }, $directory);

puke(0);

# ----- global sub defs

# show syntax & usage
sub usage {
	print <<EOF;
\n$awp v$ver\n$cpy\n\n$awp {options}

  -directory     Directory to Process          [.]
  -exclude       File(s) to Exclude            [none]
  -include       File(s) to Include Only       [all]
  -age           Age in Days to Process        [0]
  -recurse       Directory Recursion: ON       [on]
  -norecurse     Directory Recursion: OFF

  -test          Test Mode: ON                 [on]
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
sub man { if (open(MAN,"$awp.txt")) { print <MAN>; close(MAN); } else { _err "Documentation not found." } $quiet = 1; puke(1); }

# show version
sub version { print $ver; exit(0); }

# logging
sub _log(@) { if ($log) { open(LOGFILE, ">>$log") or die "ERROR:  Could not open $log: $!"; print LOGFILE "@_"; close(LOGFILE) } else { print STDERR "@_" } }
sub _err(@) { print STDERR "ERROR:  @_" }

# startup
sub startup {
	print "\n$awp v$ver\n$cpy\n\n" unless $quiet;
	_log "--- TEST MODE ---\n\n" if $test;
}

# shutdown
sub puke($;@) {
	my $status = $_[0];
	my $message = $_[1];
	_log "\n--- TEST MODE ---\n" if $test;
	_err $message if $message;
	exit $status;
}

# ----- app-specific sub defs

# directory walker
sub dirWalkPre { sort @_ }
sub dirWalk {
	return if (!($recurse) && $directory ne $File::Find::dir);
	next unless $_ =~ /^$include$/;
	&processFile ("$File::Find::name");
}

# do file processing
sub processFile {
	my ($fSize, $mTime) = (stat(@_))[7,9];

	$fSize = int($fSize/1024);
	return if $fSize eq 0;

	my $daysOld = int(((($time - $mTime) / 3600) / 24) + 0.5);
	return unless $daysOld > $age;

	my $fName = basename(@_);
	return if $fName =~ /^$exclude$/i;


	_log "@_ ($daysOld day(s) old, $fSize KB)\n" unless $quiet;
	unless ($test) {
		if (!(unlink(@_))) { _log "\nERROR: Could not delete @_.\n\n" }
	}
}

1;
