package Dist::Zilla::PluginBundle::BioPerl;
BEGIN {
  $Dist::Zilla::PluginBundle::BioPerl::AUTHORITY = 'cpan:BIOPERLML';
}
$Dist::Zilla::PluginBundle::BioPerl::VERSION = '0.23';
use utf8;

# ABSTRACT: Build your distributions like Bioperl does
# AUTHOR:   Florian Ragwitz <rafl@debian.org>
# AUTHOR:   Sheena Scroggins
# AUTHOR:   Carnë Draug <carandraug+dev@gmail.com
# AUTHOR:   Chris Fields <cjfields1@gmail.com
# OWNER:    2010 Florian Ragwitz
# OWNER:    2011 Sheena Scroggins
# OWNER:    2013 Carnë Draug
# LICENSE:  Perl_5

use Moose 1.00;
use MooseX::AttributeShortcuts;
use MooseX::Types::URI qw(Uri);
use MooseX::Types::Email qw(EmailAddress);
use MooseX::Types::Moose qw(ArrayRef Bool Str);
use namespace::autoclean;
with qw/Dist::Zilla::Role::PluginBundle::Easy Dist::Zilla::Role::PluginBundle::PluginRemover Dist::Zilla::Role::PluginBundle::Config::Slicer/;



sub get_value {
    my ($self, $accessor) = @_;
    my %defaults = (
        'homepage'            => 'https://metacpan.org/release/%{dist}',
        'repository.github'   => 'user:bioperl',
        'bugtracker.web'      => 'https://github.com/bioperl/%{dist}',
        'bugtracker.mailto'   => 'bioperl-l@bioperl.org',
        'authority'           => 'cpan:BIOPERLML',
        'trailing_whitespace' => 1,
        'allow_dirty'         => ['Changes', 'dist.ini'],
    );
    return $self->payload->{$accessor} || $defaults{$accessor};
}

has homepage => (
    is      => 'lazy',
    isa     => Str,
    default => sub { shift->get_value('homepage') }
);

has repository_github => (
    is      => 'lazy',
    isa     => Str,
    default => sub { shift->get_value('repository.github') }
);

has bugtracker_web => (
    is      => 'lazy',
    isa     => Uri,
    coerce  => 1,
    default => sub { shift->get_value('bugtracker.web') }
);

has bugtracker_mailto => (
    is      => 'lazy',
    isa     => EmailAddress,
    default => sub { shift->get_value('bugtracker.mailto') }
);

has authority => (
    is      => 'lazy',
    isa     => Str,
    default => sub { shift->get_value('authority') }
);

has trailing_whitespace => (
    is      => 'lazy',
    isa     => Bool,
    default => sub { shift->get_value('trailing_whitespace') }
);


sub mvp_multivalue_args { qw( allow_dirty ) }
has allow_dirty => (
    is      => 'lazy',
    isa     => ArrayRef,
    default => sub { shift->get_value('allow_dirty') }
);


sub configure {
    my $self = shift;

    $self->add_bundle('@Filter' => {
        '-bundle' => '@Basic',
        '-remove' => ['Readme'],
    });

    $self->add_plugins(qw(
        MetaConfig
        MetaJSON
        PkgVersion
        PodSyntaxTests
        Test::NoTabs
        NextRelease
        Test::Compile
        PodCoverageTests
        MojibakeTests
        AutoPrereqs
        RunExtraTests
    ));

    my @allow_dirty;
    foreach (@{$self->allow_dirty}) {
        push (@allow_dirty, 'allow_dirty', $_);
    }

    $self->add_plugins(
        [AutoMetaResources => [
            'repository.github' => $self->repository_github,
            'homepage'          => $self->homepage,
        ]],
        ## AutoMetaResources does not let us configure the bugtracker
        [MetaResources => [
            'bugtracker.web'    => $self->bugtracker_web,
            'bugtracker.mailto' => $self->bugtracker_mailto,
        ]],
        [Authority => {
            authority   => $self->authority,
            do_metadata => 1,
        }],
        [EOLTests => {
            trailing_whitespace => $self->trailing_whitespace,
        }],
        [PodWeaver => {
            config_plugin => '@BioPerl',
        }],
        ['Git::Check' => [
            @allow_dirty,
        ]],
        ['Git::Commit' => [
            @allow_dirty,
        ]],
        ['Git::Tag' => [
            tag_format  => '%N-v%v',
            tag_message => '%N-v%v',
        ]],
    );

}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding utf-8

=head1 NAME

Dist::Zilla::PluginBundle::BioPerl - Build your distributions like Bioperl does

=head1 VERSION

version 0.23

=head1 SYNOPSIS

  # dist.ini
  name = Dist-Zilla-Plugin-BioPerl
  ...

  [@BioPerl]

=head1 DESCRIPTION

This is the L<Dist::Zilla> configuration for the BioPerl project. It is roughly
equivalent to:

  [@Filter]
  -bundle = @Basic      ; the basic to maintain and release CPAN distros
  -remove = Readme      ; avoid conflict since we already have a README file

  [MetaConfig]          ; summarize Dist::Zilla configuration on distribution
  [MetaJSON]            ; produce a META.json
  [PkgVersion]          ; add a $version to the modules
  [PodSyntaxTests]      ; create a release test for Pod syntax
  [Test::NoTabs]        ; create a release tests making sure hard tabs aren't used
  [Test::Compile]       ; test syntax of all modules
  [PodCoverageTests]    ; create release test for Pod coverage
  [MojibakeTests]       ; create release test for correct encoding
  [AutoPrereqs]         ; automatically find the dependencies
  [RunExtraTests]       ; run tests /xt directory, normally only needed for release

  [AutoMetaResources]   ; automatically fill resources fields on metadata
  repository.github     = user:bioperl
  homepage              = https://metacpan.org/release/${dist}

  [MetaResources]       ; fill resources fields on metadata
  bugtracker.web        = https://github.com/bioperl/${dist}
  bugtracker.mailto     = bioperl-l@bioperl.org

  [Authority]           ; put the $AUTHORITY line in the modules and metadata
  authority             = cpan:BIOPERLML
  do_metadata           = 1

  [EOLTests]            ; create release tests for correct line endings
  trailing_whitespace   = 1

  [PodWeaver]
  config_plugin = @BioPerl

  [NextRelease]         ; update release number on Changes file
  [Git::Check]          ; check working path for any uncommitted stuff
  allow_dirty = Changes
  allow_dirty = dist.ini
  [Git::Commit]         ; commit the dzil-generated stuff
  allow_dirty = Changes
  allow_dirty = dist.ini
  [Git::Tag]            ; tag our new release
  tag_format  = %N-v%v
  tag_message = %N-v%v

In addition, this also has two roles, L<Dist::Zilla::PluginBundle::PluginRemover> and
Dist::Zilla::PluginBundle::Config::Slice, so one could do something like this for
problematic distributions:

  [@BioPerl]
  -remove = MojibakeTests
  -remove = PodSyntaxTests

=head1 CONFIGURATION

Use the L<Dist::Zilla::PluginBundle::Filter> to filter any undesired plugin
that is part of the default set. This also allows to change those plugins
default values. However, the BioPerl bundle already recognizes some of the
plugins options and will pass it to the corresponding plugin. If any is missing,
please consider patching this bundle.

In some cases, this bundle will also perform some sanity checks before passing
the value to the original plugin.

=over 4

=item *

homepage

Same option used by the L<Dist::Zilla::Plugin::AutoMetaResources>

=item *

repository.github

Same option used by the L<Dist::Zilla::Plugin::AutoMetaResources>

=item *

bugtracker.web

Same option used by the L<Dist::Zilla::Plugin::MetaResources>

=item *

bugtracker.mailto

Same option used by the L<Dist::Zilla::Plugin::MetaResources>

=item *

authority

Same option used by the L<Dist::Zilla::Plugin::Authority>

=item *

trailing_whitespace

Same option used by the L<Dist::Zilla::Plugin::EOLTests>

=item *

allow_dirty

Same option used by the L<Dist::Zilla::Plugin::Git::Commit> and
L<Dist::Zilla::Plugin::Git::Check>

=back

=for Pod::Coverage get_value

=for Pod::Coverage mvp_multivalue_args

=for Pod::Coverage configure

=head1 FEEDBACK

=head2 Mailing lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to
the Bioperl mailing list.  Your participation is much appreciated.

  bioperl-l@bioperl.org                  - General discussion
  http://bioperl.org/wiki/Mailing_lists  - About the mailing lists

=head2 Support

Please direct usage questions or support issues to the mailing list:
I<bioperl-l@bioperl.org>

rather than to the module maintainer directly. Many experienced and
reponsive experts will be able look at the problem and quickly
address it. Please include a thorough description of the problem
with code and data examples if at all possible.

=head2 Reporting bugs

Report bugs to the Bioperl bug tracking system to help us keep track
of the bugs and their resolution. Bug reports can be submitted via the
web:

  https://github.com/bioperl/dist-zilla-pluginbundle-bioperl/issues

=head1 AUTHORS

Florian Ragwitz <rafl@debian.org>

Sheena Scroggins

CarnÃ« Draug <carandraug+dev@gmail.com

Chris Fields <cjfields1@gmail.com

=head1 COPYRIGHT

This software is copyright (c) 2010 by Florian Ragwitz, 2011 by Sheena Scroggins, and 2013 by CarnÃ« Draug.

This software is available under the same terms as the perl 5 programming language system itself.

=cut
