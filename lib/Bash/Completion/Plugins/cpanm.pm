package Bash::Completion::Plugins::cpanm;
# ABSTRACT: Bash completion for cpanm and cpanf
use strict;
use warnings;
use base 'Bash::Completion::Plugin';

use HTTP::Request::Common qw(POST);
use LWP::UserAgent;
use JSON;

use Bash::Completion::Utils qw( command_in_path );

sub should_activate {
    my @commands = ( 'cpanm', 'cpanf' );
    return [ grep { command_in_path($_) } @commands ];
}

sub generate_bash_setup { return [qw( default )] }

sub complete {
    my ( $class, $req ) = @_;
    my $ua = LWP::UserAgent->new;
    ( my $key = $req->word ) =~ s/::?/-/g;
    my $res = $ua->request(
                          POST 'http://api.metacpan.org/dist/_search',
                          Content => '{"query":{"prefix":{"_id":"' 
                            . $key
                            . '"}},"fields":["name"],"sort":["_id"],"size":100}'
    );
    eval {
        my $json = decode_json( $res->content );
        $req->candidates('') unless ( $json->{hits} );
        my @candidates;
        my $exact_match = 0;
        for ( @{ $json->{hits}->{hits} } ) {
            my $dist = $_->{fields}->{name};
            $exact_match = 1 if ( $key eq $dist );
            $key  =~ s/-.*?$/-/;
            $dist =~ s/^$key// if ( $key =~ /-/ );
            $dist =~ s/-/::/g;
            push( @candidates, $dist );
        }
        $req->candidates(@candidates)
          unless ( $exact_match && @candidates == 1 );
    };
}

1;

__END__

=head1 SYNOPSIS

  $ cpanm MooseX::      
  Display all 100 possibilities? (y or n)
  ABC                                  Error::Exception::Class
  APIRole                              Error::Trap
  AbstractFactory                      FSM
  Accessors::ReadWritePrivate          FileAttribute
  Aliases                              File_or_DB::Storage
  Alien                                FollowPBP
  AlwaysCoerce                         Getopt
  App::Cmd                             Getopt::Defanged
  ...

=head1 DESCRIPTION

L<Bash::Completion> profile for C<cpanm> and C<cpanf>.

Simply add this line to your C<.bashrc> or C<.bash_profile> file:

 source setup-bash-complete

or run it manually in a bash session.

=head1 METHODS

=head2 complete

Queries C<http://api.metacpan.org> for distributions that match the given name.
Limits the number of results to 100.
