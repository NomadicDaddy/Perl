=for PDK_OPTS
   --exe servusql.exe
   --trim-implicit --shared private --force --dyndll --runlib "." --verbose --freestanding --nologo --icon "d:/adminware/artwork/aw.ico"
   --info "CompanyName      = Phillip Beazley;
           FileDescription  = servusql - the Serv-U Ini-to-SQL Converter;
           Copyright        = Copyright � 2003-2005 Phillip Beazley;
           LegalCopyright   = Copyright � 2003-2005 Phillip Beazley;
           SupportURL       = http://www.adminware.com/tools/;
           InternalName     = servusql;
           OriginalFilename = servusql;
           ProductName      = servusql;
           Language         = English;
           FileVersion      = 1.1.62.1;
           ProductVersion   = 1.1.62.1"
   servusql.pl
=cut

our $awp = 'servusql';
our $ver = '1.1.62.1';
our $cpy = 'Copyright � 2003-2005 Phillip Beazley';

use strict;
#use warnings;
use Getopt::Long;
use vars qw($awp $ver $cpy $log $help $man $version $quiet $test $inputFile $outputFile $mySQL $truncate);

# App-Specific Modules
use Config::IniFiles;

# Global Sub Defs
sub version;
sub usage;
sub man;
sub _log($);
sub _err($);
sub startup;
sub puke($;$);

# App-Specific Sub Defs
sub genOutput;

# Global Option Defaults
our $test = 0;

# App-Specific Option Defaults
our $mySQL = our $truncate = 0;

our %optionMappings = ('log' => \$log, 'help' => \$help, 'man' => \$man, 'version' => \$version, 'quiet' => \$quiet, 'test' => \$test,
	'inputFile' => \$inputFile, 'outputFile' => \$outputFile, 'mySQL' => \$mySQL, 'truncate' => \$truncate);
our @options = ("log=s", "help|?", "man", "version", "quiet!", "test!",
	"inputFile:s", "outputFile:s", "mySQL!", "truncate!");
GetOptions(\%optionMappings, @options) || usage;
version if $version;
usage if $help;
man if $man;

# Catch Missing/Invalid Parameter Failures
usage if (!(-e $inputFile));
if (!($outputFile)) { $outputFile = "$inputFile.sql" }

startup;

# App-Specific Subs
&genOutput;

puke(0);

# ----- Global Sub Defs

# Show Syntax & Usage
sub usage {
	print <<EOF;
\n$awp v$ver\n$cpy\n\n$awp {options}

  -inputFile     Path/Filename of Serv-U Ini
  -outputFile    Path/Filename of Output File
  -mysql         Generate mySQL Format         [off]
  -truncate      Truncate Existing Data First  [off]

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

# Generate SQL
sub genOutput {

	open(SQL, ">$outputFile") or die "ERROR: Could not open $outputFile: $!";

	if ($truncate) {
		print SQL "truncate table ftp_users ;\n";
		print SQL "truncate table ftp_userAccess ;\n";
		print SQL "truncate table ftp_userIPs ;\n";
		print SQL "truncate table ftp_groups ;\n";
		print SQL "truncate table ftp_groupIPs ;\n";
		print SQL "truncate table ftp_groupAccess ;\n";
		print SQL "go";
	}

	my @cfg = new Config::IniFiles( -file => "$inputFile" );

	#	my @domains = $cfg->Parameters('DOMAINS');
	#	foreach my $domain (@domains) {
	#		my $value = $cfg->val('DOMAINS', $domain);
	#	     (my $domain_ip, my $domain_y, my $domain_port, my $domain_name, my $domain_id, my $domain_z) = split(/\|/, $value);
	#		print SQL "update ftp_users set ip_address='$domain_ip' where ip_address='$domain_id' ;\n";
	#		print SQL "update ftp_userPath set ip_address='$domain_ip' where ip_address='$domain_id' ;\n";
	#	}

	foreach my $cfg (@cfg) {
		my @sections = $cfg->Sections();

		foreach my $user (@sections) {
			if ($user =~ 'USER=') {
			     (my $u_UserName, my $domain) = split(/\|/, $');
				my @userInfo = $cfg->Parameters($user);

				my $u_Password = $cfg->val($user, 'Password');
				my $u_HomeDir = $cfg->val($user, 'HomeDir');
				my $u_Disabled = $cfg->val($user, 'Enable');
				if ($u_Disabled eq 1 || $u_Disabled eq '') { $u_Disabled = '0' } else { $u_Disabled = '1' }
				my $u_RelPaths = $cfg->val($user, 'RelPaths'); if ($u_RelPaths eq '') { $u_RelPaths = '1' }
				my $u_MaxUsersLoginPerIP = $cfg->val($user, 'MaxUsersLoginPerIP'); if ($u_MaxUsersLoginPerIP eq '') { $u_MaxUsersLoginPerIP = '-1' }
				my $u_SpeedLimitUp = $cfg->val($user, 'SpeedLimitUp'); if ($u_SpeedLimitUp eq '') { $u_SpeedLimitUp = '-1' }
				my $u_SpeedLimitDown = $cfg->val($user, 'SpeedLimitDown'); if ($u_SpeedLimitDown eq '') { $u_SpeedLimitDown = '-1' }
				my $u_TimeOut = $cfg->val($user, 'TimeOut'); if ($u_TimeOut eq '') { $u_TimeOut = '600' }
				my $u_SessionTimeOut = $cfg->val($user, 'SessionTimeOut'); if ($u_SessionTimeOut eq '') { $u_SessionTimeOut = '-1' }
				my $u_DiskQuota = $cfg->val($user, 'DiskQuota');
			     (my $u_QuotaEnable, my $u_QuotaMax, my $u_QuotaCurrent) = split(/\|/, $u_DiskQuota);
					if ($u_QuotaEnable eq '') { $u_QuotaEnable = '0' } else { $u_QuotaEnable = '1' }
					if ($u_QuotaMax eq '') { $u_QuotaMax = '0' }
					if ($u_QuotaCurrent eq '') { $u_QuotaCurrent = '0' }

				my $u_Maintenance = $cfg->val($user, 'Maintenance');
					if ($u_Maintenance eq '') { $u_Maintenance = '0' }
					if ($u_Maintenance eq 'System') { $u_Maintenance = '1' }
					if ($u_Maintenance eq 'Group') { $u_Maintenance = '2' }
					if ($u_Maintenance eq 'Domain') { $u_Maintenance = '3' }
					if ($u_Maintenance eq 'Read-only') { $u_Maintenance = '4' }
					if ($u_Maintenance eq 'ReadOnly') { $u_Maintenance = '4' }

				my $u_Group = $cfg->val($user, 'Group');
				my $u_Expire = $cfg->val($user, 'Expire'); if ($u_Expire eq '') { $u_Expire = '1980-01-01' }
				my $u_HideHidden = $cfg->val($user, 'HideHidden'); if ($u_HideHidden eq '') { $u_HideHidden = '1' }
				my $u_AlwaysAllowLogin = $cfg->val($user, 'AlwaysAllowLogin'); if ($u_AlwaysAllowLogin eq '') { $u_AlwaysAllowLogin = '0' }
				my $u_ChangePassword = $cfg->val($user, 'ChangePassword'); if ($u_ChangePassword eq '') { $u_ChangePassword = '1' }
				my $u_MaxNrUsers = $cfg->val($user, 'MaxNrUsers'); if ($u_MaxNrUsers eq '') { $u_MaxNrUsers = '-1' }
				my $u_PasswordType = $cfg->val($user, 'PasswordType');
				my $u_LoginMesFile = $cfg->val($user, 'LoginMesFile');

				my $u_Ratios = $cfg->val($user, 'Ratios');
				(my $u_RatioType, my $u_RatioUp, my $u_RatioDown, my $u_RatioCredit) = split(/\|/, $u_Ratios);
					if ($u_RatioUp eq '') { $u_RatioUp = '0' }
					if ($u_RatioDown eq '') { $u_RatioDown = '0' }
					if ($u_RatioCredit eq '') { $u_RatioCredit = '0' }

				# Notes
				my $seq = 1;
				my $u_Notes = '';
				foreach my $userParameter (@userInfo) {
					if ($userParameter =~ "^Note") {
						my $value = $cfg->val($user, $userParameter);
						$u_Notes = $u_Notes . $value . "|";
						$seq++;
					}
				}
				chop($u_Notes);

				# Directory Permissions
				$seq = 1;
				my $u_accessRule = '';
				my $u_accessRules = '';
				foreach my $userParameter (@userInfo) {
					if ($userParameter =~ "^Access") {
						my $value = $cfg->val($user, $userParameter);
						if (!($mySQL)) {
							if ($seq eq 1) {
								$u_accessRule = $value;
							} else {
								$u_accessRules = $u_accessRules . "insert into ftp_userAccess (indexNo, ftpUserName, accessRule) values ($seq, '$u_UserName', '$value') ;\n";
							}
						} else {
							$value =~ s/\\/\\\\/g;
							$u_accessRules = $u_accessRules . "insert into userdiraccess (Name, Access) values ('$u_UserName', '$value') ;\n";
						}
						$seq++;
					}
				}

				# FTP Users
				if (!($mySQL)) {
					print SQL "insert into ftp_users (ftpUserName, ftpPassword, disabled, dirHomeLock, timeOutIdle, quotaEnable, quotaMax, quotaCurrent, dirHome, accessRule, groups, timeOutsession, speedLimitUp, speedLimitDown, maxUsersLoginPerIP, privilege, expiration, hideHidden, alwaysAllowLogin, changePassword, maxUsersConcurrent, ftpPasswordType, loginMsgFile, ratioType, ratioUp, ratioDown, ratioCredit, notes) values ('$u_UserName', '$u_Password', $u_Disabled, $u_RelPaths, $u_TimeOut, $u_QuotaEnable, $u_QuotaMax, $u_QuotaCurrent, '$u_HomeDir', '$u_accessRule', '$u_Group', $u_SessionTimeOut, $u_SpeedLimitUp, $u_SpeedLimitDown, $u_MaxUsersLoginPerIP, $u_Maintenance, '$u_Expire', $u_HideHidden, $u_AlwaysAllowLogin, $u_ChangePassword, $u_MaxNrUsers, '$u_PasswordType', '$u_LoginMesFile', '$u_RatioType', $u_RatioUp, $u_RatioDown, $u_RatioCredit, '$u_Notes') ;\n";
				} else {
					$u_HomeDir =~ s/\\/\\\\/g;
					print SQL "insert into useraccounts (Name, Password, Disable, RelPaths, IdleTimeOut, QuotaEnable, QuotaMax, QuotaCurrent, HomeDir, Groups, SessionTimeOut, MaxSpeedUp, MaxSpeedDown, MaxIP, Privilege, Expiration, HideHidden, AlwaysLogin, ChangePass, MaxUsers, PassType, LogMesFile, RatioType, RatioUp, RatioDown, RatioCredit, Notes) values ('$u_UserName', '$u_Password', $u_Disabled, $u_RelPaths, $u_TimeOut, $u_QuotaEnable, $u_QuotaMax, $u_QuotaCurrent, '$u_HomeDir', '$u_Group', $u_SessionTimeOut, $u_SpeedLimitUp, $u_SpeedLimitDown, $u_MaxUsersLoginPerIP, $u_Maintenance, '$u_Expire', $u_HideHidden, $u_AlwaysAllowLogin, $u_ChangePassword, $u_MaxNrUsers, '$u_PasswordType', '$u_LoginMesFile', '$u_RatioType', $u_RatioUp, $u_RatioDown, $u_RatioCredit, '$u_Notes') ;\n";
				}
				print SQL $u_accessRules;

				# IP Address Permissions
				$seq = 1;
				foreach my $userParameter (@userInfo) {
					if ($userParameter =~ "^IPAccess") {
						my $value = $cfg->val($user, $userParameter);
						if (!($mySQL)) {
							print SQL "insert into ftp_userIPs (indexNo, ftpUserName, accessRule) values ($seq, '$u_UserName', '$value') ;\n";
						} else {
							print SQL "insert into useripaccess (Name, Access) values ('$u_UserName', '$value') ;\n";
						}
						$seq++;
					}
				}

			}
			print SQL "\n";
		}
		print SQL "\n";

	}

	close(SQL);

}

1;
