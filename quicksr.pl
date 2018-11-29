=for PDK_OPTS
   --exe quicksr.exe
   --use awtools.dll
   --trim-implicit --shared private --force --dyndll --runlib "." --verbose --freestanding --nologo --icon "d:/adminware/artwork/aw.ico"
   --info "CompanyName      = Phillip Beazley;
           FileDescription  = quicksr - the quick text file search and replacer;
           Copyright        = Copyright � 2006 Phillip Beazley;
           LegalCopyright   = Copyright � 2006 Phillip Beazley;
           SupportURL       = http://www.adminware.com/tools/;
           Comments         = ;
           InternalName     = quicksr;
           OriginalFilename = quicksr;
           ProductName      = quicksr;
           Language         = English;
           FileVersion      = 1.0.0.0;
           ProductVersion   = 1.0.0.0"
   quicksr.pl
=cut

our $awp = 'quicksr';
our $ver = '1.0.0.0';
our $cpy = 'Copyright � 2006 Phillip Beazley';

use strict;
use warnings;
use Getopt::Long;
use vars qw($awp $ver $cpy $log $help $man $version $quiet $test $filename $search $replace $newfilename $count);

# app-specific modules
use IO::File;

# global sub defs
sub version;
sub usage;
sub man;
sub _log(@);
sub _err(@);
sub startup;
sub puke($;@);

# app-specific sub defs
sub procFile;

# global option defaults
our $test = our $quiet = 0;
our $log = '';

# app-specific option defaults
our $filename = our $search = our $replace = our $newfilename = '';
our $count = our $counter = our $numlines = 0;

our %optionMappings = ('log' => \$log, 'help' => \$help, 'man' => \$man, 'version' => \$version, 'quiet' => \$quiet, 'test' => \$test,
	'filename' => \$filename, 'search' => \$search, 'replace' => \$replace, 'newfilename' => \$newfilename, 'count' => \$count);
our @options = ("log=s", "help|?", "man", "version", "quiet!", "test!",
	"filename:s", "search:s", "replace=s", "newfilename=s", "count");
GetOptions(\%optionMappings, @options) || usage;
version if $version;
usage if $help;
man if $man;

# catch missing/invalid parameter failures
usage if (!(-e $filename) || !($search));
if ($newfilename eq '') { $newfilename = $filename }

startup;

# app-specific subs
procFile;

puke(0);

# ----- global sub defs

# show syntax & usage
sub usage {
	print <<EOF;
\n$awp v$ver\n$cpy\n\n$awp {options}

  -filename      File to Process
  -search        Search Pattern
  -replace       Replace String
  -newfilename   New File to Output To         [overwrite existing]
  -count         Count Hits Only               [off]

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

# process file
sub procFile {
	my $counter = my $numlines = 0;
	my $newContent = '';
	my $oldFile = new IO::File "< $filename" || puke(1, "Can't open file: $filename");
	while (! $oldFile->eof) {
		my $line = $oldFile->getline;
		print '.';
		$numlines++;
		if ($line =~ $search) {
			$line =~ s/$search/$replace/g;
			$newContent = $newContent . $line;
			$counter++;
		} else {
			$newContent = $newContent . $line;
		}
	}
	$oldFile->close;

	if (!($count)) {
		my $newFile = new IO::File "> $newfilename" || puke(1, "Can't create file: $newfilename");
		if (defined $newFile) {
			print $newFile $newContent;
			$newFile->close;
			print "\n\nReplaced $counter occurrences of '$search' with '$replace' in $filename to $newfilename.\n";
		}
	} else {
		print "\n\nFound $counter occurrences of '$search' in $filename [$numlines lines total].\n";
	}
}

1;
