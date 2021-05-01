package MARC::Convert::Wikidata;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Error::Pure qw(err);
use MARC::Convert::Wikidata::Object;
use Wikibase::Datatype::Item;
use Wikibase::Datatype::Snak;
use Wikibase::Datatype::Statement;
use Wikibase::Datatype::Value::Item;
use Wikibase::Datatype::Value::Monolingual;
use Wikibase::Datatype::Value::Quantity;
use Wikibase::Datatype::Value::String;
use Wikibase::Datatype::Value::Time;

our $VERSION = 0.01;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# MARC::Record object.
	$self->{'marc_record'} = undef;

	# Process parameters.
	set_params($self, @params);

	if (! defined $self->{'marc_record'}
		|| ! $self->{'marc_record'}->isa('MARC::Record')) {

		err "Parameter 'marc_record' must be a MARC::Record object.";
	}

	$self->{'_object'} = MARC::Convert::Wikidata::Object->new(
		'marc_record' => $self->{'marc_record'},
	);

	return $self;
}

sub wikidata_ccnb {
	my $self = shift;

	if (! defined $self->{'_object'}->ccnb) {
		return;
	}

	return (
		Wikibase::Datatype::Statement->new(
			'snak' => Wikibase::Datatype::Snak->new(
				'datatype' => 'external-id',
				'datavalue' => Wikibase::Datatype::Value::String->new(
					'value' => $self->{'_object'}->ccnb,
				),
				'property' => 'P3184',
			),
			# TODO Reference.
		),
	);
}

sub wikidata_edition_number {
	my $self = shift;

	if (! defined $self->{'_object'}->edition_number) {
		return;
	}

	return (
		Wikibase::Datatype::Statement->new(
			'snak' => Wikibase::Datatype::Snak->new(
				'datatype' => 'string',
				'datavalue' => Wikibase::Datatype::Value::String->new(
					'value' => $self->{'_object'}->edition_number,
				),
				'property' => 'P393',
			),
			# TODO Reference.
		),
	);
}

sub wikidata_isbn_10 {
	my $self = shift;

	if (! defined $self->{'_object'}->isbn_10) {
		return;
	}

	return (
		Wikibase::Datatype::Statement->new(
			'snak' => Wikibase::Datatype::Snak->new(
				'datatype' => 'external-id',
				'datavalue' => Wikibase::Datatype::Value::String->new(
					'value' => $self->{'_object'}->isbn_10,
				),
				'property' => 'P957',
			),
			# TODO Reference.
		),
	);
}

sub wikidata_isbn_13 {
	my $self = shift;

	if (! defined $self->{'_object'}->isbn_13) {
		return;
	}

	return (
		Wikibase::Datatype::Statement->new(
			'snak' => Wikibase::Datatype::Snak->new(
				'datatype' => 'external-id',
				'datavalue' => Wikibase::Datatype::Value::String->new(
					'value' => $self->{'_object'}->isbn_13,
				),
				'property' => 'P212',
			),
			# TODO Reference.
		),
	);
}

sub wikidata_labels {
	my ($self, $lang) = @_;;

	if (! defined $self->{'_object'}->full_name) {
		return ();
	}

	return (
		'labels' => [
			Wikibase::Datatype::Value::Monolingual->new(
				'language' => 'cs',
				'value' => $self->{'_object'}->full_name,
			),
			Wikibase::Datatype::Value::Monolingual->new(
				'language' => 'en',
				'value' => $self->{'_object'}->full_name,
			),
		],
	);
}

sub wikidata_number_of_pages {
	my $self = shift;

	if (! defined $self->{'_object'}->number_of_pages) {
		return;
	}

	return (
		Wikibase::Datatype::Statement->new(
			'snak' => Wikibase::Datatype::Snak->new(
				'datatype' => 'quantity',
				'datavalue' => Wikibase::Datatype::Value::Quantity->new(
					'value' => $self->{'_object'}->number_of_pages,
				),
				'property' => 'P1104',
			),
			# TODO Reference.
		),
	);
}

sub wikidata_publication_date {
	my $self = shift;

	if (! defined $self->{'_object'}->publication_date) {
		return;
	}

	# TODO Second parameter of publication_date().
	return (
		Wikibase::Datatype::Statement->new(
			'snak' => Wikibase::Datatype::Snak->new(
				'datatype' => 'time',
				'datavalue' => Wikibase::Datatype::Value::Time->new(
					'value' => '+'.$self->{'_object'}->publication_date,
				),
				'property' => 'P577',
			),
			# TODO Reference.
		),
	);
}

sub wikidata_subtitle {
	my $self = shift;

	if (! defined $self->{'_object'}->subtitle) {
		return;
	}

	return (
		Wikibase::Datatype::Statement->new(
			'snak' => Wikibase::Datatype::Snak->new(
				'datatype' => 'monolingualtext',
				'datavalue' => Wikibase::Datatype::Value::Monolingual->new(
					'value' => $self->{'_object'}->subtitle,
					# TODO Language
				),
				'property' => 'P1680',
			),
			# TODO Reference.
		),
	);
}

sub wikidata_title {
	my $self = shift;

	if (! defined $self->{'_object'}->title) {
		return;
	}

	return (
		Wikibase::Datatype::Statement->new(
			'snak' => Wikibase::Datatype::Snak->new(
				'datatype' => 'monolingualtext',
				'datavalue' => Wikibase::Datatype::Value::Monolingual->new(
					'value' => $self->{'_object'}->title,
					# TODO Language
				),
				'property' => 'P1476',
			),
			# TODO Reference.
		),
	);
}

sub wikidata {
	my $self = shift;

	my $wikidata = Wikibase::Datatype::Item->new(
		$self->wikidata_labels,
		'statements' => [
			# instance of: version, edition, or translation
			Wikibase::Datatype::Statement->new(
				'snak' => Wikibase::Datatype::Snak->new(
					'datatype' => 'wikibase-item',
					'datavalue' => Wikibase::Datatype::Value::Item->new(
						'value' => 'Q3331189',
					),
					'property' => 'P31',
				),
			),

			$self->wikidata_ccnb,
			$self->wikidata_edition_number,
			$self->wikidata_isbn_10,
			$self->wikidata_isbn_13,
			$self->wikidata_number_of_pages,
			$self->wikidata_publication_date,
			$self->wikidata_subtitle,
			$self->wikidata_title,

			# language of work or name: ...
			# TODO

			# place of publication: ...
			# TODO

			# publisher: ...
			# TODO

			# author: ...
			# TODO

			# translator: ...
			# TODO

			# editor: ...
			# TODO
		],
	);

	return $wikidata;
}

1;

__END__
