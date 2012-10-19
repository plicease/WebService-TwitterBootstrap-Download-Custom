use strict;
use warnings;
use Test::More tests => 11;
use WebService::TwitterBootstrap::Download::Custom::Zip;
use FindBin ();
use Path::Class qw( file );
use Test::Differences;

my $zip = eval { WebService::TwitterBootstrap::Download::Custom::Zip->new };
diag $@ if $@;

isa_ok $zip, 'WebService::TwitterBootstrap::Download::Custom::Zip';

ok $zip->file, "zip.file = " . eval  { $zip->file->filename };
ok -w $zip->file, "empty zip is writable";
ok -z $zip->file, "empty zip is empty";

eval { 
  $zip->spew(scalar file( $FindBin::Bin, 'data', 'example.zip')->slurp);
};
is $@, '', "writing to zip did not crash";

isa_ok $zip->archive, 'Archive::Zip';
is $zip->archive->memberNamed('bogus.txt'), undef, "no member named bogus.txt";
isa_ok $zip->archive->memberNamed('js/bootstrap.min.js'), 'Archive::Zip::ZipFileMember', "has member js/bootstrap.min.js";

eq_or_diff 
  eval { [sort @{ $zip->member_names } ] }, 
  [sort qw( img/glyphicons-halflings-white.png img/glyphicons-halflings.png js/bootstrap.min.js js/bootstrap.js css/bootstrap.css css/bootstrap.min.css)],
  'zip.member_names';
diag $@ if $@;

is eval { $zip->member_content('js/bootstrap.js') }, "some content\n", 'zip.member(js/bootstrap.js)';
diag $@ if $@;

my $save_filename = $zip->file->filename;
#diag `unzip -v $save_filename`;
undef $zip;
ok !-e $save_filename, "zip removed when object falls out of scope";
