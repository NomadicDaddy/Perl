=for PDK_OPTS
   --exe copy2clip.exe
   --use awtools.dll
   --trim-implicit --shared private --force --dyndll --runlib "." --verbose --freestanding --nologo --icon "d:/adminware/artwork/aw.ico"
   --info "CompanyName      = adminware, llc;
           FileDescription  = copy2clip - copies files content to clipboard;
           Copyright        = Copyright � 1999-2005 adminware, llc;
           LegalCopyright   = Copyright � 1999-2005 adminware, llc;
           LegalTrademarks  = adminware is a trademark of adminware, llc;
           SupportURL       = http://www.adminware.com/tools/;
           InternalName     = copy2clip;
           OriginalFilename = copy2clip;
           ProductName      = copy2clip;
           Language         = English;
           FileVersion      = 1.1.1.1;
           ProductVersion   = 1.1.1.1"
   copy2clip.pl
=cut

our $awp = 'copy2clip';
our $ver = '1.1.1.1';
our $cpy = 'Copyright � 1999-2005 adminware, llc';

use strict;
#use warnings;
use Getopt::Long;
use vars qw($awp $ver $cpy $log $help $man $version $quiet $test $filename $pattern $new $exclude $count);

# App-Specific Modules
use Win32::Clipboard;

# Global Sub Defs
sub version;
sub usage;
sub man;
sub _log($);
sub _err($);
sub startup;
sub puke($;$);

# App-Specific Sub Defs
sub toClipboard($);

# Global Option Defaults
our $test = 0;

# App-Specific Option Defaults

our %optionMappings = ('log' => \$log, 'help' => \$help, 'man' => \$man, 'version' => \$version, 'quiet' => \$quiet, 'test' => \$test,
	'filename' => \$filename);
our @options = ("log=s", "help|?", "man", "version", "quiet!", "test!",
	"filename=s");
GetOptions(\%optionMappings, @options) || usage;
version if $version;
usage if $help;
man if $man;

# Catch Missing/Invalid Parameter Failures
usage if (! -e $filename);

startup;

# App-Specific Subs
toClipboard($filename);

puke(0);

# ----- Global Sub Defs

# Show Syntax & Usage
sub usage {
	print <<EOF;
\n$awp v$ver\n$cpy\n\n$awp {options}

  -filename      File to Copy to Clipboard

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

# Copy File to Clipboard
sub toClipboard($) {
	$filename = $_[0];

	open (Z,"$filename");
	my @z = <Z>;
	close(Z);

	my ($data, $z) = '';
	foreach $z (@z) {
		$data = "$data$z"
	}

	my $clip = Win32::Clipboard->new;
	$clip->Set($data) || die "Set: @{[Win32::FormatMessage(Win32::GetLastError())]}";

	print "The contents of $filename have been copied to your clipboard.\n\nUse ctrl-v to paste.\n" if (!$quiet);
	_log "Copied $filename to clipboard.\n" if ($log);
}

1;
