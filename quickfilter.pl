=for PDK_OPTS
   --exe quickfilter.exe
   --use awtools.dll
   --trim-implicit --shared private --force --dyndll --runlib "." --verbose --freestanding --nologo --icon "d:/adminware/artwork/aw.ico"
   --info "CompanyName      = adminware, llc;
           FileDescription  = quickfilter - the quick text file filter;
           Copyright        = Copyright � 1999-2005 adminware, llc;
           LegalCopyright   = Copyright � 1999-2005 adminware, llc;
           LegalTrademarks  = adminware is a trademark of adminware, llc;
           SupportURL       = http://www.adminware.com/tools/;
           InternalName     = quickfilter;
           OriginalFilename = quickfilter;
           ProductName      = quickfilter;
           Language         = English;
           FileVersion      = 1.31.1.1;
           ProductVersion   = 1.31.1.1"
   quickfilter.pl
=cut

our $awp = 'quickfilter';
our $ver = '1.31.1.1';
our $cpy = 'Copyright � 1999-2005 adminware, llc';

use strict;
#use warnings;
use Getopt::Long;
use vars qw($awp $ver $cpy $log $help $man $version $quiet $test $filename $pattern $newfilename $exclude $count);

# App-Specific Modules
use IO::File;

# Global Sub Defs
sub version;
sub usage;
sub man;
sub _log($);
sub _err($);
sub startup;
sub puke($;$);

# App-Specific Sub Defs
sub doFilter;

# Global Option Defaults
our $test = 0;

# App-Specific Option Defaults
our $newdata = '';
our $counter = our $numlines = 0;

our %optionMappings = ('log' => \$log, 'help' => \$help, 'man' => \$man, 'version' => \$version, 'quiet' => \$quiet, 'test' => \$test,
	'filename' => \$filename, 'pattern' => \$pattern, 'newfilename' => \$newfilename, 'exclude' => \$exclude, 'count' => \$count);
our @options = ("log=s", "help|?", "man", "version", "quiet!", "test!",
	"filename=s", "pattern=s", "newfilename=s", "exclude", "count");
GetOptions(\%optionMappings, @options) || usage;
version if $version;
usage if $help;
man if $man;

# Catch Missing/Invalid Parameter Failures
usage if (!(-e $filename) || !($pattern));
if ($newfilename eq '') { $newfilename = $filename }

startup;

# App-Specific Subs
&doFilter;

puke(0);

# ----- Global Sub Defs

# Show Syntax & Usage
sub usage {
	print <<EOF;
\n$awp v$ver\n$cpy\n\n$awp {options}

  -[f]ilename      File to Filter
  -[p]attern       Search Pattern
  -[ne]wfilename   New File to Output To         [overwrite existing]
  -[e]xclude       Exclude Pattern               [off]
  -[c]ount         Count Hits Only               [off]

  -[t]est          Test Mode: ON
  -[not]est        Test Mode: OFF                [on]

  -[noq]uiet       Output Verbosity: Verbose     [on]
  -[q]uiet         Output Verbosity: Terse
  -[l]og           Output to Specified Logfile   []

  -[h]elp | [?]    Show This Help Text
  -[m]an           Display Documentation
  -[v]ersion       Show Version
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

# Do Filtering
sub doFilter {
	my $oldFile = new IO::File "< $filename" || die "ERROR: Can't open file: $filename";
	while (! $oldFile->eof) {
		my $line = $oldFile->getline;
		print '.';
		$numlines++;
		if (($exclude && !($line =~ $pattern)) || (!($exclude) && $line =~ $pattern)) {
			$newdata = "$newdata$line";
			$counter++;
		}
	}
	$oldFile->close;

	if (!($count)) {
		my $newFile = new IO::File "> $newfilename" || die "ERROR: Can't create file: $newfilename";
		if (defined $newFile) {
			print $newFile "$newdata";
			$newFile->close;
		}
	}

	if ($exclude) { print "\n\n'$pattern' not found in $counter lines of $filename [$numlines lines total].\n\n" }
	else { print "\n\nFound $counter occurrences of '$pattern' in $filename [$numlines lines total].\n\n" }
}

1;
