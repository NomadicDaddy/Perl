=for PDK_OPTS
   --exe logarc.exe
   --use awtools.dll
   --trim-implicit --shared private --force --dyndll --runlib "." --verbose --freestanding --nologo --icon "d:/adminware/artwork/aw.ico"
   --info "CompanyName      = adminware, llc;
           FileDescription  = logarc - the logfile aggregator;
           Copyright        = Copyright © 1999-2006 adminware, llc.  All rights reserved.;
           LegalCopyright   = Copyright © 1999-2006 adminware, llc.  All rights reserved.;
           LegalTrademarks  = adminware is a trademark of adminware, llc;
           SupportURL       = http://www.adminware.com/tools/;
           InternalName     = logarc;
           OriginalFilename = logarc;
           ProductName      = logarc;
           Language         = English;
           FileVersion      = 1.27.1.1;
           ProductVersion   = 1.27.1.1"
   logarc.pl
=cut

our $awp = 'logarc';
our $ver = '1.27.1.1';
our $cpy = 'Copyright © 1999-2006 adminware, llc.  All rights reserved.';

use strict;
#use warnings;
use Getopt::Long;
use vars qw($awp $ver $cpy $log $help $man $version $quiet $test $directory $exclude $include $recurse $zipcmd $target $move $notoday $cycle $delzero $subdirs $ignlog $delete);

# app-specific modules
use Cwd;
use File::Basename;
use File::Find;
use POSIX qw(strftime);
use Win32::FileOp;

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
sub doFile($$$);

# global option defaults
our $test = our $quiet = 0;
our $log = '';

# app-specific option defaults
our $move = our $cycle = our $delzero = our $subdirs = our $delete = 0;
our $ignlog = '';
our $recurse = our $notoday = 1;
our $include = '*.log*';
our $zipcmd = 'pkzip -add -move -fast';
our $directory = getcwd;
our $dstamp = strftime("%Y%m%d%H%M%S", gmtime(time));

our %optionMappings = ('log' => \$log, 'help' => \$help, 'man' => \$man, 'version' => \$version, 'quiet' => \$quiet, 'test' => \$test,
	'directory' => \$directory, 'exclude' => \$exclude, 'include' => \$include, 'recurse' => \$recurse, 'zipcmd' => \$zipcmd, 'target' => \$target, 'move' => \$move, 'notoday' => \$notoday, 'cycle' => \$cycle, 'delzero' => \$delzero, 'subdirs' => \$subdirs, 'ignlog' => \$ignlog, 'delete' => \$delete);
our @options = ("log=s", "help|?", "man", "version", "quiet!", "test!",
	"directory:s", "exclude:s", "include:s", "recurse!", "zipcmd:s", "target:s", "move!", "notoday!", "cycle!", "delzero!", "subdirs!", "ignlog:s", "delete!");
GetOptions(\%optionMappings, @options) || usage;
version if $version;
usage if $help;
man if $man;

# Normalize Slashes
$directory =~ s/(\/|\\\/)/\\/g;
$directory =~ s/\\+$//;
$directory = "$directory\\";
if (!($target)) {
	our $target = ".\\";
} else {
	our $target =~ s/(\/|\\\/)/\\/g;
	$target =~ s/\\+$//;
	$target = "$target\\";
	`md "$target"` unless (-d "$target");
}

# catch missing/invalid parameter failures
#usage if (!(-e $filename) || !($pattern));
chdir($directory) || die "Cannot chdir to $directory: $!";
puke(1,"Cannot move to same directory.") if ($directory eq $target && $move);

# Convert Glob Wildcards to RegEx
$include =~ s/\./\\\./g;
$include =~ s/\*/\.\*/g;

startup;

# app-specific subs
find(\&dirWalk, $directory);

puke(0);

# ----- global sub defs

# show syntax & usage
sub usage {
	print <<EOF;
\n$awp v$ver\n$cpy\n\n$awp {options}

  -directory     Source Directory              [.]
  -target        Target Directory              [.]
  -exclude       File(s) to Exclude            [none]
  -include       File(s) to Include Only       [all]
  -zipcmd        Zip Cmd/Opts                  [pkzip -add -move -fast]
  -recurse       Directory Recursion           [on]
  -move          Move Files Only               [off]
  -notoday       Don't Touch Today's Logs      [on]
  -delzero       Delete Zero Byte Logs         [off]
  -subdirs       Mirrored Subdirs              [off]

  -test          Test Mode                     [off]
  -quiet         Terse Output Verbosity        [off]
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

# Directory Walker
sub dirWalk {
	return if (!($recurse) && $directory ne $File::Find::dir);
	next unless $_ =~ /^$include$/i;

	(my $testDir = $File::Find::dir) =~ s/(\/|\\\/)/\\/g;
	(my $igntest = $directory) =~ s/\\/\\\\/g;
	$igntest =~ s/\$/\\\$/g;
	$testDir =~ "$igntest(.+)$ignlog";
	my $sub = $1;

	if ($subdirs && $ignlog ne '' && !($sub)) {
#		_log "-- EXCLUDE DIR: $testDir\n";
		next;
	}

	&processFile ("$File::Find::name");
}

# Do File Processing
sub processFile {
	my ($path) = dirname(@_);
	my ($file) = lc(basename(@_));

	$path =~ s/(\/|\\\/)/\\/g;
	$path =~ s/\\+$//;
	$path = "$path\\";

	if ($test) {
		print "PATH : $path\n";
		print "FILE : $file\n";
	}

	if ($file =~ /$exclude/i && $exclude ne '') {
		_log "-- EXCLUDE: $file\n";
		return;
	}

	if ($delzero && -z $file && -f $file) {
		_log "-- DELETED EMPTY: $file\n";
		unless ($test) {
			`del "$path$file"`;
		}
		return;
	}

	if ($delete) {
		_log "-- DELETED: $file\n";
		unless ($test) {
			`del "$path$file"`;
		}
		return;
	}

	if ($cycle) {
		my ($testStamp) = strftime("%Y%m%d", gmtime(time));
		if (!($file =~ "_$testStamp")) {
			$file =~ '.log';
			my ($cycled) = "$path$`_$dstamp.log";
			_log "    (cycle) - $path$file -> $cycled\n";
			unless ($test) {
				`move "$path$file" "$cycled"`;
			}
			$file = basename($cycled);
		} else {
			_log "    (cycle) - Skipping $file (already cycled)\n";
		}
	}

# save config to file
# matchToday, matchString, extractString, arcString
# "%Y%m%d", '^[\w,_-]+\d{14}.log', '^([\w,_-]+\d{6})\d{8}', "$1"		# virus_20031104050011.log		->	virus_200311.zip
# loop through, return on match

	############################################################################
	# EXAMPLE:	virus_20031104050011.log		->	virus_200311.zip		#
	############################################################################

	if ($file =~ '^[\w,_-]+\d{14}.(log|ctr)') {

		if ($notoday && $file =~ strftime("%Y%m%d", localtime(time()))) {
			_log "        - Skipping Today's: $file\n";
			return;
		}
		$file =~ '^([\w,_-]+\d{6})\d{8}';
		doFile(1, "$path$file", "$1");

	############################################################################
	# EXAMPLE:	SMTP20040104.log			->	SMTP200401.zip			#
	############################################################################
	
	} elsif ($file =~ '^[\w,_.-]+\d{8}.(log|ctr)') {

		if ($notoday && $file =~ strftime("%Y%m%d", localtime(time()))) {
			_log "        - Skipping Today's: $file\n";
			return;
		}
		$file =~ '^([\w,_.-]+\d{6})\d{2}';
		doFile(2, "$path$file", "$1");

	############################################################################
	# EXAMPLE:	onvix-20040104-1.log		->	onvix-200401.zip		#
	############################################################################

	} elsif ($file =~ '^[\w,_.-]+\d{8}-\d+.(log|ctr)') {

		if ($notoday && $file =~ strftime("%Y%m%d", localtime(time()))) {
			_log "        - Skipping Today's: $file\n";
			return;
		}
		$file =~ '^([\w,_.-]+\d{6})\d{2}-\d+';
		doFile(3, "$path$file", "$1");

	############################################################################
	# EXAMPLE:	10282004.log				->	200410.zip			#
	############################################################################

	} elsif ($file =~ '^\d{2}\d{2}\d{4}.(log|ctr)') {

		if ($notoday && $file =~ strftime("%m%d%Y", localtime(time()))) {
			_log "        - Skipping Today's: $file\n";
			return;
		}
		$file =~ '^(\d{2})\d{2}(\d{4})';
		doFile(4, "$path$file", "$2$1");

	############################################################################
	# EXAMPLE:	nc030318.log				->	nc0303.zip			#
	############################################################################

	} elsif ($file =~ '^[\w,_-]+\d{6}.(log|ctr)') {

		if ($notoday && $file =~ strftime("%y%m%d", localtime(time()))) {
			_log "        - Skipping Today's: $file\n";
			return;
		}
		$file =~ '^([\w_,-]+\d{4})\d{2}';
		doFile(5, "$path$file", "$1");

	############################################################################
	# EXAMPLE:	post.office-0124.log		->	post.office-01.zip		#
	############################################################################
	# This isn't good.

	} elsif ($file =~ '^[\w,_.-]+-\d{4}.(log|ctr)') {

		if ($notoday && $file =~ strftime("%m%d", localtime(time()))) {
			_log "        - Skipping Today's: $file\n";
			return;
		}
		$file =~ '^([\w,_.-]+-\d{2})\d{2}';
		doFile(6, "$path$file", "$1");

	############################################################################
	# EXAMPLE:	ftp-04Jan2004.log			->	ftp-2004Jan.zip		#
	############################################################################

	} elsif ($file =~ '^[\w,_-]+\d{2}\w{3}\d{4}.(log|ctr)') {

		if ($notoday && $file =~ strftime("%d%b%Y", localtime(time()))) {
			_log "        - Skipping Today's: $file\n";
			return;
		}
		$file =~ '^([\w_,-]+)\d{2}(\w{3})(\d{4})';
		doFile(7, "$path$file", "$1$3$2");

	############################################################################
	# EXAMPLE:	urlscan.011804.log			->	urlscan.0401.zip		#
	############################################################################

	} elsif ($file =~ '^[\w,_\.-]+\d{2}\d{2}\d{2}.(log|ctr)') {

		if ($notoday && $file =~ strftime("%m%d%y", localtime(time()))) {
			_log "        - Skipping Today's: $file\n";
			return;
		}
		$file =~ '^([\w_,\.-]+)(\d{2})\d{2}(\d{2})';
		doFile(8, "$path$file", "$1$3$2");

	############################################################################
	# EXAMPLE:	rm-access.log.20040207010914	->	rm-access.log.200401.zip	#
	############################################################################

	} elsif ($file =~ '^[\w,_\.-]+\d{6}\d{2}\d{6}') {

		if ($notoday && $file =~ strftime("%Y%m%d", localtime(time()))) {
			_log "        - Skipping Today's: $file\n";
			return;
		}
		$file =~ '^([\w_,\.-]+)(\d{6})\d{2}\d{6}';
		doFile(9, "$path$file", "$1$2");

	############################################################################
	# Move + Zip													#
	############################################################################

	} elsif ($file =~ '.zip' && $move) {

		doFile('a', "$path$file", '');

	############################################################################
	# NO REGEX MATCH												#
	############################################################################

	} else {
		_log "        - Not Processed: $file\n";
	}

}

# Zip or Move File
sub doFile($$$) {
	my ($type) = $_[0];
	my ($source) = $_[1];
	my ($target) = $target;

	if ($subdirs) {
		my $origin = dirname("$directory$type");
		$target = $target . substr(dirname($source), length($origin) + 1, length($source) - length($origin)) . "\\";
		$target =~ s/\\\\$/\\/;
		$target =~ s/$ignlog\\//i;
	}

	unless ($test) {
		if ($move) {
			_log "    ($type) - $source -> $target\n";
			`md "$target"` unless (-d "$target");
			`move "$source" "$target"`;
		} else {
			$target = "$target$_[2].zip";
			_log "    ($type) - $source -> $target\n";
			`$zipcmd "$target" "$source"`;
		}
	}
}

1;
