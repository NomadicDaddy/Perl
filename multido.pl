my $awpv	= 'adminware Multi-Do v1.0.219.1';
my $copyr	= 'Copyright � 2001 adminware, llc';
my $syntx	= "Syntax: $0 <command to run> <file extension>";

use strict;
use Cwd;

if ($ARGV[0] eq '') { die "$syntx\n\nCommand to run not specified.\n" }
if ($ARGV[1] eq '') { die "$syntx\n\nFile extension to process.\n" }

my $rcmd = shift;
my $fext = shift;
my $procdir = getcwd;

if (opendir (DIR, "$procdir")) {
	print "\nProcessing matched files in $procdir...\n";
	while(defined(my $file=readdir(DIR))) {
		if ($file =~ ".+\.$fext") {
			$file =~ ".+\.fext";
			print "\n  - $rcmd$file\n";
			`$rcmd$file > CON`;
		}
	}
	print "\nFinished!\n";
}
else { die "$syntx\n\nBad JuJu:  Could not open directory '$procdir'.\n" }
