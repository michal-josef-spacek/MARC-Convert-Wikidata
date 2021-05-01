package MARC::Convert::Wikidata;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Error::Pure qw(err);
use Wikibase::Datatype::Item;
use Wikibase::Datatype::Snak;
use Wikibase::Datatype::Statement;
use Wikibase::Datatype::Value::Item;
use Wikibase::Datatype::Value::Monolingual;
use Wikibase::Datatype::Value::Time;

our $VERSION = 0.01;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	$self->{'marc_record'} = undef;

	# Process parameters.
	set_params($self, @params);

	if (! defined $self->{'marc_record'}
		|| ! $self->{'marc_record'}->isa('MARC::Record')) {

		err "Parameter 'marc_record' must be a MARC::Record object.";
	}

	return $self;
}

sub full_name {
	my $self = shift;

	my $full_name = $self->title;
	if ($self->subtitle) {
		$full_name .= ': '.$self->subtitle;
	}

	return $full_name;
}

sub publication_date {
	my $self = shift;

	my $publication_date;
	my $field_264 = $self->{'marc_record'}->field('264');
	if ($field_264) {
		$publication_date = $field_264->subfield('c');
	}
	if (! $publication_date) {
		my $field_260 = $self->{'marc_record'}->field('260');
		if ($field_260) {
			$publication_date = $field_260->subfield('c');
		}
	}

	return $publication_date;
}

sub subtitle {
	my $self = shift;

	return $self->{'marc_record'}->field(245)->subfield('b');
}

sub title {
	my $self = shift;

	return $self->{'marc_record'}->field(245)->subfield('a');
}

sub wikidata {
	my $self = shift;

	my $wikidata = Wikibase::Datatype::Item->new(
		'labels' => [
			Wikibase::Datatype::Value::Monolingual->new(
				'language' => 'cs',
				'value' => $self->full_name,
			),
			Wikibase::Datatype::Value::Monolingual->new(
				'language' => 'en',
				'value' => $self->full_name,
			),
		],
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

			# title: ...
			Wikibase::Datatype::Statement->new(
				'snak' => Wikibase::Datatype::Snak->new(
					'datatype' => 'monolingualtext',
					'datavalue' => Wikibase::Datatype::Value::Monolingual->new(
						'value' => $self->title,
					),
					'property' => 'P1476',
				),
				# TODO Reference.
			),

			# subtitle: ...
			$self->subtitle ? (
				Wikibase::Datatype::Statement->new(
					'snak' => Wikibase::Datatype::Snak->new(
						'datatype' => 'monolingualtext',
						'datavalue' => Wikibase::Datatype::Value::Monolingual->new(
							'value' => $self->subtitle,
						),
						'property' => 'P1680',
					),
					# TODO Reference.
				),
			) : (),

			# publication name: ...
			Wikibase::Datatype::Statement->new(
				'snak' => Wikibase::Datatype::Snak->new(
					'datatype' => 'time',
					'datavalue' => Wikibase::Datatype::Value::Time->new(
						'value' => '+'.$self->publication_date,
					),
					'property' => 'P577',
				),
				# TODO Reference.
			),

			# number of pages: ...
			# TODO

			# language of work or name: ...
			# TODO

			# place of publication: ...
			# TODO

			# edition number: ...
			# TODO

			# publisher: ...
			# TODO

			# author: ...
			# TODO

			# translator: ...
			# TODO

			# editor: ...
			# TODO

			# isbn-10: ...
			# TODO

			# isbn-13: ...
			# TODO

			# ccnb: ...
			# TODO
		],
	);

	return $wikidata;
}

1;

__END__
