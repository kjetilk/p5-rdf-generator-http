use 5.010001;
use strict;
use warnings;

package RDF::Generator::HTTP;


our $AUTHORITY = 'cpan:KJETILK';
our $VERSION   = '0.001';

use Moo;
use Carp qw(carp);
use RDF::Trine qw(statement blank iri literal);
use URI::NamespaceMap;
use Types::Standard qw(InstanceOf ArrayRef Str);

has message => (is => 'ro', isa => InstanceOf['HTTP::Message'], required => 1);

has blacklist => (is => 'rw', isa => ArrayRef[Str]);

has whitelist => (is => 'rw', isa => ArrayRef[Str]);

has ns => (is => 'ro', isa => InstanceOf['URI::NamespaceMap'], lazy => 1, builder => '_build_namespacemap');

sub _build_namespacemap {
	my $self = shift;
	return URI::NamespaceMap->new({ rdf => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
											http => 'http://www.w3.org/2007/ont/http#',
											httph => 'http://www.w3.org/2007/ont/httph#' });
}


sub generate {
	my $self = shift;	
	my $model = shift || RDF::Trine::Model->temporary_model;
	my $reqsubj = blank();
	my $ressubj = blank();
	my $ns = $self->ns;
	if ($self->message->isa('HTTP::Request')) {
		$self->_request_statements($model, $self->message, $reqsubj);
		$self->message->headers->scan(sub {
				my ($field, $value) = @_;
				$model->add_statement(statement($reqsubj, iri($ns->httph->uri(_fix_headers($field))), literal($value)));
			 });
	} elsif ($self->message->isa('HTTP::Response')) {
		$model->add_statement(statement($ressubj, iri($ns->uri('rdf:type')), iri($ns->uri('http:ResponseMessage'))));
		$model->add_statement(statement($ressubj, iri($ns->uri('http:status')), literal($self->message->code)));
		$self->message->headers->scan(sub {
				  my ($field, $value) = @_;
				  $model->add_statement(statement($ressubj, iri($ns->httph->uri(_fix_headers($field))), literal($value)));
			   });
		if ($self->message->request) {
			$model->add_statement(statement($reqsubj, iri($ns->uri('http:hasResponse')), $ressubj));
			$self->_request_statements($model, $self->message->request, $reqsubj);
			$self->message->request->headers->scan(sub {
				my ($field, $value) = @_;
				$model->add_statement(statement($reqsubj, iri($ns->httph->uri(_fix_headers($field))), literal($value)));
			 });
		}
	} else {
		carp "Don't know what to do with message object of class " . ref($self->message);
	}
	return $model;
}

sub _request_statements {
	my ($self, $model, $r, $subj) = @_;
	my $ns = $self->ns;
	$model->add_statement(statement($subj, iri($ns->uri('rdf:type')), iri($ns->uri('http:RequestMessage'))));
	$model->add_statement(statement($subj, iri($ns->uri('http:method')), literal('GET')));
	$model->add_statement(statement($subj, iri($ns->uri('http:requestURI')), iri($r->uri)));
}

sub _fix_headers {
	my $field = shift;
	$field =~ tr/-/_/;
	$field = lc $field;
	return $field;
}
	  

1;
__END__

=pod

=encoding utf-8

=head1 NAME

RDF::Generator::HTTP - Generate RDF from a HTTP message

=head1 SYNOPSIS

=head1 DESCRIPTION

=head2 Constructor

=over

=item C<< new(%attributes) >>

Moose-style constructor function.

=back

=head2 Attributes

These attributes may be passed to the constructor.

=over

=item C<< message >>

A L<HTTP::Message> (or subclass thereof) object to generate RDF for. Required.

=back

=head1 BUGS

Please report any bugs to
L<https://github.com/kjetilk/p5-rdf-generator-http/issues>.

=head1 SEE ALSO

=head1 AUTHOR

Kjetil Kjernsmo E<lt>kjetilk@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Kjetil Kjernsmo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

