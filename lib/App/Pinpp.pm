package App::Pinpp;
use v5.010;
use strict;
use warnings;
use autodie;
use File::Spec;
use File::Slurp qw(slurp);
use Getopt::Std;
use File::Temp qw(tempfile); 

# ABSTRACT: Container for the pinpp command

# VERSION: Generated by DZP::OurPkg:Version

sub run {

    # Our first arg will be our class. We're going to ignore that for now.
    shift;

    # Load our arguments into ARGV, so we can use getopts.
    local @ARGV = @_;

    my %opts = (
        o => '',          # Output to PDF
        i => 'topics'     # Includes directory
    );

    getopts("o:i:",\%opts);

    my ($file) = @ARGV;

    $file or die "Usage: $0 file.pinpp";

    # Okay code, you have just one job:
    # @include <foo.pin> -> includes $INCLUDE_DIR/foo.pin
    # NB: Everything after the @include on a line will be removed.

    my $content = slurp($file);

    # Remove // comments

    $content =~ s{^//[^\n]*\n}{}gsm;

    # Process includes

    $content =~ s{^\@include\s+<([^>]+)>[^\n]*\n}{include($opts{i},$1)}gmse;

    # Remove blank slides

    $content =~ s{^--\n--}{--}gsm;

    if (my $outputfile = $opts{o}) {

        # Iff we're producing a PDF, then remove speaker comments
        $content =~ s{^#[^\n]*\n}{}gsm;

        my ($tmp_fh, $tmp_filename) = tempfile( DIR => '.' );

        say {$tmp_fh} $content;
        close($tmp_fh);

        system("pinpoint", "--output=$opts{o}", $tmp_filename);
    }
    else {
        # Otherwise just display our text
        say $content;
    }
}

=func include($dir, $include)

Looks inside C<$dir> for the file specified in C<$include> and
returns its contents, along with a C<--> at the end to prevent
slides running into each other between topics.

=cut

sub include {
    my ($dir, $include) = @_;
    return slurp(File::Spec->catdir($dir, $include))."--\n";
}

1;
