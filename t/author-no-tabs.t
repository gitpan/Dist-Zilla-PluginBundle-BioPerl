
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.09

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Dist/Zilla/PluginBundle/BioPerl.pm',
    'lib/Pod/Weaver/PluginBundle/BioPerl.pm',
    't/00-compile.t',
    't/author-no-tabs.t',
    't/release-eol.t',
    't/release-mojibake.t',
    't/release-pod-coverage.t',
    't/release-pod-syntax.t'
);

notabs_ok($_) foreach @files;
done_testing;
