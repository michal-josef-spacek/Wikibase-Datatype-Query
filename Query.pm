package Wikibase::Datatype::Query;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Error::Pure qw(err);
use Scalar::Util qw(blessed);

our $VERSION = 0.04;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Mode for deprecated values.
	$self->{'deprecated'} = 0;

	# Process parameters.
	set_params($self, @params);

	return $self;
}

sub query {
	my ($self, $datatype, $query_string) = @_;

	if (! defined $datatype || ! blessed($datatype)) {
		return;
	}

	if ($datatype->isa('Wikibase::Datatype::Item')) {
		return $self->query_item($datatype, $query_string);
	} elsif ($datatype->isa('Wikibase::Datatype::Mediainfo')) {
		# XXX Provisional
		return $self->query_item($datatype, $query_string);
	} elsif ($datatype->isa('Wikibase::Datatype::Lexeme')) {
		return $self->query_lexeme($datatype, $query_string);
	} else {
		err "Datatype doesn't supported.",
			'Ref', (ref $datatype),
		;
	}

	return;
}

sub query_item {
	my ($self, $item, $query_string) = @_;

	if (! defined $item) {
		err "Item is required.";
	}
	if (! blessed($item) || (! $item->isa('Wikibase::Datatype::Item')
		&& ! $item->isa('Wikibase::Datatype::Mediainfo'))) {

		err "Item must be a 'Wikibase::Datatype::Item' or 'Wikibase::Datatype::Mediainfo' object.";
	}

	# Property.
	if ($query_string =~ m/^P\d+$/ms) {
		return $self->_query_property($item, $query_string);

	# Alias.
	} elsif ($query_string =~ m/^alias:?([\w\-]+)?$/ms) {
		return $self->_query_text($item, $1, 'aliases');

	# Label.
	} elsif ($query_string =~ m/^label:?([\w\-]+)?$/ms) {
		return $self->_query_text($item, $1, 'labels');

	# Description.
	} elsif ($query_string =~ m/^description:?([\w\-]+)?$/ms) {
		return $self->_query_text($item, $1, 'descriptions');
	} else {
		err "Unsupported query string '$query_string'.";
	}

	return;
}

sub query_lexeme {
	my ($self, $lexeme, $query_string) = @_;

	if (! defined $lexeme) {
		err "Lexeme is required.";
	}
	if (! blessed($lexeme) || ! $lexeme->isa('Wikibase::Datatype::Lexeme')) {
		err "Item must be a 'Wikibase::Datatype::Lexeme' object.";
	}

	# Property.
	if ($query_string =~ m/^P\d+$/ms) {
		return $self->_query_property($lexeme, $query_string);

	# Sense property.
	} elsif ($query_string =~ m/^sense_(P\d+)$/ms) {
		return $self->_query_sense($lexeme, $1);

	# Form property.
	} elsif ($query_string =~ m/^form_(P\d+)$/ms) {
		return $self->_query_form($lexeme, $1);
	
	} else {
		err "Unsupported query string '$query_string'.";
	}

	return;
}

sub _query_form {
	my ($self, $lexeme, $query_string) = @_;

	my @values;
	foreach my $form (@{$lexeme->forms}) {
		push @values, $self->_query_property($form, $query_string);
	}

	return wantarray ? @values : $values[0];
}


sub _query_property {
	my ($self, $item, $property) = @_;

	# XXX In multiple languages?

	my @values;
	foreach my $statement (@{$item->statements}) {

		# Skip deprecated if 'deprecated' parameters is on 0.
		if (! $self->{'deprecated'} && $statement->rank eq 'deprecated') {
			next;
		}

		my $snak = $statement->snak;
		if ($snak->snaktype ne 'value' || $snak->property ne $property) {
			next;
		}
		my $datavalue = $snak->datavalue;
		my $value = $datavalue->value;
		if (defined $value) {
			push @values, $value;
		}
	}

	return wantarray ? @values : $values[0];
}

sub _query_sense {
	my ($self, $lexeme, $query_string) = @_;

	my @values;
	foreach my $sense (@{$lexeme->senses}) {
		push @values, $self->_query_property($sense, $query_string);
	}

	return wantarray ? @values : $values[0];
}

sub _query_text {
	my ($self, $item, $lang, $method) = @_;

	my @values;
	foreach my $text (@{$item->$method}) {
		if (defined $text->value) {
			if (defined $lang) {
				if ($text->language eq $lang) {
					push @values, $text->value;
				}
			} else {
				push @values, $text->value;
			}
		}
	}

	return wantarray ? @values : $values[0];
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Wikibase::Datatype::Query - Query class on Wikibase item.

=head1 SYNOPSIS

 use Wikibase::Datatype::Query;

 my $obj = Wikibase::Datatype::Query->new;
 my $res = $obj->query($obj, $property);
 my $res = $obj->query_item($item_obj, $property);
 my $res = $obj->query_lexeme($lexeme_obj, $query_string);
 my @res = $obj->query_lexeme($lexeme_obj, $query_string);

=head1 METHODS

=head2 C<new>

 my $obj = Wikibase::Datatype::Query->new;

Constructor.

=over

=item * C<deprecated>

Flag which controls query of deprecated values.
Zero (0) means no deprecated values in result.

Default value is 0.

=back

Returns instance of object.

=head2 C<query>

 my $res = $obj->query($obj, $property);

Query L<Wikibase::Datatype> object for value.

Returns value or undef.

=head2 C<query_item>

 my $res = $obj->query($item_obj, $property);

Query L<Wikibase::Datatype::Item> item for value.

Returns value or undef.

=head2 C<query_lexeme>

 my $res = $obj->query_lexeme($lexeme_obj, $query_string);
 my @res = $obj->query_lexeme($lexeme_obj, $query_string);

Query L<Wikibase::Datatype::Lexeme> item for value.

Returns value or undef in scalar context.
Returns list of values in array context.

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

 query():
         Parameter 'item' is required.
         Parameter 'item' must be a 'Wikibase::Datatype::Item' object.

 query_item():
         Parameter 'item' is required.
         Parameter 'item' must be a 'Wikibase::Datatype::Item' object.

 query_lexeme():
         Item must be a 'Wikibase::Datatype::Lexeme' object.
         Lexeme is required.
         Unsupported query string '%s'.

=head1 EXAMPLE1

=for comment filename=query_item.pl

 use strict;
 use warnings;

 use Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog;
 use Wikibase::Datatype::Query;

 my $obj = Wikibase::Datatype::Query->new;

 my $item = Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog->new;

 my $ret = $obj->query_item($item, 'P31');

 print "Query for P31 property on Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog:\n";
 print $ret."\n";

 # Output like:
 # Query for P31 property on Test::Shared::Fixture::Wikibase::Datatype::Item::Wikidata::Dog:
 # Q55983715

=head1 EXAMPLE2

=for comment filename=query_lexeme.pl

 use strict;
 use warnings;

 use Test::Shared::Fixture::Wikibase::Datatype::Lexeme::Wikidata::DogCzechNoun;
 use Wikibase::Datatype::Query;

 my $obj = Wikibase::Datatype::Query->new;

 my $item = Test::Shared::Fixture::Wikibase::Datatype::Lexeme::Wikidata::DogCzechNoun->new;

 my $ret = $obj->query_lexeme($item, 'P5185');

 print "Query for P5185 property on Test::Shared::Fixture::Wikibase::Datatype::Lexeme::Wikidata::DogCzechNoun:\n";
 print $ret."\n";

 # Output like:
 # Query for P5185 property on Test::Shared::Fixture::Wikibase::Datatype::Lexeme::Wikidata::DogCzechNoun:
 # Q499327

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>,
L<Scalar::Util>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype>

Wikibase datatypes.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Wikibase-Datatype-Query>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2022-2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.04

=cut
