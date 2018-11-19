=for PDK_OPTS
   --exe trimbak.exe
   --use awtools.dll
   --trim-implicit --shared private --force --dyndll --runlib "." --verbose --freestanding --nologo --icon "x:/adminware/artwork/aw.ico"
   --info "CompanyName      = adminware, llc;
           FileDescription  = trimbak - the backup file trimmer;
           Copyright        = Copyright � 2010 adminware, llc;
           LegalCopyright   = Copyright � 2010 adminware, llc;
           LegalTrademarks  = adminware is a trademark of adminware, llc;
           SupportURL       = http://www.adminware.com/tools/;
           InternalName     = trimbak;
           OriginalFilename = trimbak;
           ProductName      = trimbak;
           Language         = English;
           FileVersion      = 1.0.0.1;
           ProductVersion   = 1.0.0.1"
   trimbak.pl
=cut

our $awp = 'trimbak';
our $ver = '1.0.0.1';
our $cpy = 'Copyright � 2010 adminware, llc';

use strict;
#use warnings;
use Getopt::Long;
use vars qw($awp $ver $cpy $log $help $man $version $quiet $test $directory $exclude $include $recurse $age $w2k $wkd $showDels $showKeeps);

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
our $age = 7;
our $w2k = 5;
our $wkd = 'Sunday';
our $showDels = 0;
our $showKeeps = 0;

our %optionMappings = ('log' => \$log, 'help' => \$help, 'man' => \$man, 'version' => \$version, 'quiet' => \$quiet, 'test' => \$test,
	'directory' => \$directory, 'exclude' => \$exclude, 'include' => \$include, 'recurse' => \$recurse, 'age' => \$age, 'w2k' => \$w2k, 'wkd' => \$wkd, 'showDels' => \$showDels, 'showKeeps' => \$showKeeps);
our @options = ("log=s", "help|?", "man", "version", "quiet!", "test!",
	"directory:s", "exclude:s", "include:s", "recurse!", "age:i", "w2k:i", "wkd:s", "showDels!", "showKeeps!");
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

_log "Keeping $w2k weeks of $wkd files while ignoring anything less than $age days old.\n\n";
_log "---------------------------------------------------------------------------\n";
_log "      : AGE : DAY : BACKUP FILE                                 : SIZE (KB)\n";
_log "---------------------------------------------------------------------------\n\n";

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
  -age           Age in Days to Ignore         [7]
  -w2k           # of Weeks to Keep            [5]
  -wkd           Base on Which Weekday         [Sunday]
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
#	return unless $daysOld > $age;

	my $fName = basename(@_);
	return if $fName =~ /^$exclude$/i;

	my $wday = (localtime($mTime))[6];
	my $dow = ('Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday')[$wday];
	my $dispDow = uc(substr($dow, 0, 3));
	my $logStr = sprintf("%3d : %3s : %43s : %9s", $daysOld, $dispDow, $fName, $fSize);

	# delete if age is greater than weeks to keep x 7 days
	if ($daysOld > ($w2k * 7)) {
		_log "- AGE : $logStr\n" unless $quiet || $showKeeps eq 1;
		unless ($test) {
			if (!(unlink(@_))) { _log "\nERROR: Could not delete @_.\n\n" }
		}
	}

	# delete if age is greater than days specified to keep AND the file isn't a weekly file
	elsif ($daysOld > $age && $dow ne $wkd) {
		_log "- DOW : $logStr\n" unless $quiet || $showKeeps eq 1;
		unless ($test) {
			if (!(unlink(@_))) { _log "\nERROR: Could not delete @_.\n\n" }
		}
	}

	# keep if age less than days specified to keep
	elsif ($daysOld <= $age) {
		_log "K AGE : $logStr\n" unless $quiet || $showDels eq 1;
	}

	# keep if it's a weekly file
	elsif ($dow eq $wkd) {
		_log "K DOW : $logStr\n" unless $quiet || $showDels eq 1;
	}

	else {
		_log "----- : $logStr\n" unless $quiet;
	}

}

1;

# master sort by date, cycle through distinct days with files
# for each base filename in each day, sort by date asc
# for each base filename batch, keep last one - delete previous ones
# for only one file in base filename batch, keep it

# directives
# keep_first_per_[day|week|month|year]
# keep_last_per_[day|week|month|year]
# name_string
# type_string

# keep one of each type per name per day
# name_string: [^*.]_*.
# type_string: ^*._[*.]\.*.
# keep_last_per_day

# keep one of each name per day
# name_string: [^*.]_*.
# keep_last_per_day
