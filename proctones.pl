=for PDK_OPTS
   --exe proctones.exe
   --trim-implicit --shared none --force --dyndll --norunlib --verbose --freestanding --nologo --icon "d:/adminware/artwork/aw.ico"
   --info "CompanyName      = adminware, llc;
           FileDescription  = proctones - custom ringtone prep for iPhone;
           Copyright        = Copyright © 2009 adminware, llc.  All rights reserved.;
           LegalCopyright   = Copyright © 2009 adminware, llc.  All rights reserved.;
           LegalTrademarks  = adminware is a trademark of adminware, llc;
           SupportURL       = http://www.adminware.com/tools/;
           InternalName     = proctones;
           OriginalFilename = proctones;
           ProductName      = proctones;
           Language         = English;
           FileVersion      = 1.0.0.1;
           ProductVersion   = 1.0.0.1"
   proctones.pl
=cut

our $awp = 'proctones';
our $ver = '1.0.0.1';
our $cpy = 'Copyright © 2009 adminware, llc.  All rights reserved.';

use strict;
#use warnings;
use Getopt::Long;
use vars qw($awp $ver $cpy $log $help $man $version $quiet $test $include $directory $toneList $count);

# app-specific modules
use Cwd;
use File::Find;
use File::Basename;
use MP4::Info;

# global sub defs
sub version;
sub usage;
sub man;
sub _log(@);
sub _err(@);
sub startup;
sub puke($;@);

# app-specific sub defs
sub procTones;
sub makeplist;

# global option defaults
our $test = 0;

# app-specific option defaults
our $include = '*.(m4a|m4r)';
our $directory = getcwd;
our $toneList = '';
our $count = 0;

our %optionMappings = ('log' => \$log, 'help' => \$help, 'man' => \$man, 'version' => \$version, 'quiet' => \$quiet, 'test' => \$test,
	'directory' => \$directory);
our @options = ("log=s", "help|?", "man", "version", "quiet!", "test!",
	"directory:s");
GetOptions(\%optionMappings, @options) || usage;
version if $version;
usage if $help;
man if $man;

# catch missing/invalid parameter failures
#usage if (!(-e $filename) || !($pattern));
chdir($directory) || die "Cannot chdir to $directory: $!";

# Convert Glob Wildcards to RegEx
$include =~ s/\./\\\./g;
$include =~ s/\*/\.\*/g;

startup;

# app-specific subs
find(\&procTones, $directory);
&makeplist;

puke(0);

# ----- global sub defs

# show syntax & usage
sub usage {
	print <<EOF;
\n$awp v$ver\n$cpy\n\n$awp {options}

  -directory     Directory to Process          [.]

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

# Process Ringtones
sub procTones {
	return if ($directory ne $File::Find::dir);
	next unless $_ =~ /^$include$/;
	$count++;

	my $info = get_mp4info($_);

	s/&/&#38;/g;
	my ($name, $path, $suffix) = fileparse($_, '\.[^\.]*');
	my $guid = sprintf("%X", $count);
	my $time = 30;

	$name = $info->{NAM} unless $info->{NAM} == '';
	$time = $info->{SECS} unless $info->{SECS} == 0;

	print ":: $name\n" unless $quiet;

	$name =~ s/&/&#38;/g;
	$info->{ART} =~ s/&/&#38;/g;
	$info->{ALB} =~ s/&/&#38;/g;

	$toneList = $toneList . "		<key>$_</key>
		<dict>
			<key>GUID</key><string>$guid</string>
			<key>Name</key><string>$name</string>
";
	if ($info->{ART} ne '') {
		$toneList = $toneList . "			<key>Artist</key><string>$info->{ART}</string>
";
	}
	if ($info->{ALB} ne '') {
		$toneList = $toneList . "			<key>Album</key><string>$info->{ALB}</string>
";
	}
	$toneList = $toneList . "			<key>Total Time</key><integer>$time</integer>
		</dict>
";

}

# Create Custom Ringtones plist
sub makeplist {

	my $plist = '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Ringtones</key>
	<dict>
' . $toneList . '	</dict>
</dict>
</plist>
';

	if (!$test) {
		open(PLIST, ">$directory/Ringtones.plist") or die "ERROR:  Could not open $directory/Ringtones.plist: $!";
		print PLIST $plist;
		close(PLIST);
		print "\nRingtones.plist created successfully.\n";
	} else {
		print "\nTest successful.  No Ringtones.plist file created at this time.\n";
	}

}

1;
