package WebService::TwitterBootstrap::Download::Custom::Zip;

use strict;
use warnings;
use File::Temp ();
use Archive::Zip ();
use Path::Class qw( dir );
use Moose;

# ABSTRACT: Zip file containing Twitter Bootstrap
# VERSION

=head1 DESCRIPTION

This class represents the zip file downloaded from the 
Twitter Bootstrap website.

=cut

has file => (
  is      => 'rw',
  isa     => 'File::Temp',
  lazy    => 1,
  default => sub { 
    # TODO: does this need to be binmoded for Win32?
    File::Temp->new(
      TEMPLATE => "bootstrapXXXXXX", 
      SUFFIX   => '.zip',
      DIR      => File::Spec->tmpdir,
    );
  }, 
);

has archive => (
  is      => 'rw',
  isa     => 'Archive::Zip',
  lazy    => 1,
  default => sub {
    Archive::Zip->new(shift->file->filename);
  },
);

=head1 ATTRIBUTES

=head2 $zip-E<gt>member_names

Returns a list reference containing the name of all the members inside
the zip file.

=cut

has member_names => (
  is      => 'ro',
  isa     => 'ArrayRef[Str]',
  lazy    => 1,
  default => sub {
    [grep !m{/$}, shift->archive->memberNames],
  },
);

=head1 METHODS

=head2 $zip-E<gt>member_content( $name )

Returns the content of the given members name.

=cut

sub member_content
{
  my($self, $name) = @_;
  my($content, $status) = $self->archive->contents($name);
  die "$status" unless $status == Archive::Zip::AZ_OK;
  return $content;
}

=head2 $zip-E<gt>extract_all( $dir )

Extract all members of the zip to the given directory.

=cut

sub extract_all
{
  my($self, $dir) = @_;
  foreach my $member_name (@{ $self->member_names })
  {
    my $member_file = dir($dir)->file($member_name);
    $member_file->dir->mkpath(0,0755);
    $member_file->spew($self->member_content($member_name));
  }
  $self;
}

sub spew
{
  my($self, $content) = @_;
  if(ref($content) eq 'Path::Class::File')
  {
    $self->archive(
      Archive::Zip->new($content->stringify),
    );
  }
  else
  {
    $self->file->print($content);
    $self->file->close;
  }
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

=head1 CAVEATS

This class uses L<Archive::Zip> internally, but that may
change in the future so only use the documented methods.

=cut
