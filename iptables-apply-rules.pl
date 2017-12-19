#/usr/bin/perl;

use v5.20;
use Try::Tiny;

# Enable whole file reading
$/ = undef;

use constant "RULES_FILE" => '/etc/iptables/rules.v4';

try {

	open my $rules_file_fh, '<', RULES_FILE;

	my $buffer = $rules_file_fh->getline;

	say $buffer;


} catch {
	die $_;
}