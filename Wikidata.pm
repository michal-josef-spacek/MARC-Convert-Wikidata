package MARC::Convert::Wikidata;

use strict;
use warnings;

use Class::Utils qw(set_params);
use DateTime;
use Error::Pure qw(err);
use MARC::Convert::Wikidata::Transform;
use Unicode::UTF8 qw(decode_utf8);
use Wikibase::Datatype::Item;
use Wikibase::Datatype::Reference;
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

	# Lang callback.
	$self->{'callback_lang'} = undef;

	# People callback.
	$self->{'callback_people'} = undef;

	# Place of publication Wikidata lookup callback.
	$self->{'callback_place'} = undef;

	# Publisher Wikidata lookup callback.
	$self->{'callback_publisher'} = undef;

	# Retrieved date.
	$self->{'date_retrieved'} = undef;

	# MARC::Record object.
	$self->{'marc_record'} = undef;

	# Process parameters.
	set_params($self, @params);

	if (! defined $self->{'marc_record'}
		|| ! $self->{'marc_record'}->isa('MARC::Record')) {

		err "Parameter 'marc_record' must be a MARC::Record object.";
	}

	$self->{'_object'} = MARC::Convert::Wikidata::Transform->new(
		'marc_record' => $self->{'marc_record'},
	)->object;

	# TODO Check 'date_retrieved' parameter. Must be a ISO8601 format.
	if (! defined $self->{'date_retrieved'}) {
		$self->{'date_retrieved'} = '+'.DateTime->now->strftime('%Y-%m-%dT%H:%M:%S');
	}

	return $self;
}

sub object {
	my $self = shift;

	return $self->{'_object'};
}

sub wikidata_authors {
	my $self = shift;

	return $self->wikidata_people('authors', 'P50');
}

sub wikidata_ccnb {
	my $self = shift;

	if (! defined $self->{'_object'}->ccnb) {
		return;
	}

	return (
		Wikibase::Datatype::Statement->new(
			'references' => [$self->wikidata_reference],
			'snak' => Wikibase::Datatype::Snak->new(
				'datatype' => 'external-id',
				'datavalue' => Wikibase::Datatype::Value::String->new(
					'value' => $self->{'_object'}->ccnb,
				),
				'property' => 'P3184',
			),
		),
	);
}

sub wikidata_descriptions {
	my $self = shift;

	if (! defined $self->{'_object'}->full_name) {
		return ();
	}

	return (
		'descriptions' => [
			Wikibase::Datatype::Value::Monolingual->new(
				'language' => 'cs',
				'value' => $self->_description('cs'),
			),
			Wikibase::Datatype::Value::Monolingual->new(
				'language' => 'en',
				'value' => $self->_description('cs'),
			),
		],
	);
}

sub wikidata_edition_number {
	my $self = shift;

	if (! defined $self->{'_object'}->edition_number) {
		return;
	}

	return (
		Wikibase::Datatype::Statement->new(
			'references' => [$self->wikidata_reference],
			'snak' => Wikibase::Datatype::Snak->new(
				'datatype' => 'string',
				'datavalue' => Wikibase::Datatype::Value::String->new(
					'value' => $self->{'_object'}->edition_number,
				),
				'property' => 'P393',
			),
		),
	);
}

sub wikidata_editors {
	my $self = shift;

	return $self->wikidata_people('editors', 'P98');
}

sub wikidata_illustrators {
	my $self = shift;

	return $self->wikidata_people('illustrators', 'P110');
}

sub wikidata_isbn_10 {
	my $self = shift;

	if (! defined $self->{'_object'}->isbn_10) {
		return;
	}

	return (
		Wikibase::Datatype::Statement->new(
			'references' => [$self->wikidata_reference],
			'snak' => Wikibase::Datatype::Snak->new(
				'datatype' => 'external-id',
				'datavalue' => Wikibase::Datatype::Value::String->new(
					'value' => $self->{'_object'}->isbn_10,
				),
				'property' => 'P957',
			),
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
			'references' => [$self->wikidata_reference],
			'snak' => Wikibase::Datatype::Snak->new(
				'datatype' => 'external-id',
				'datavalue' => Wikibase::Datatype::Value::String->new(
					'value' => $self->{'_object'}->isbn_13,
				),
				'property' => 'P212',
			),
		),
	);
}

sub wikidata_labels {
	my $self = shift;

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

sub wikidata_language {
	my $self = shift;

	if (! defined $self->{'_object'}->language) {
		return;
	}

	my $lang_qid;
	if (! defined $self->{'callback_lang'}) {
		return;
	} else {
		$lang_qid = $self->{'callback_lang'}->($self->{'_object'});
	}

	if (! defined $lang_qid) {
		return;
	}

	return (
		Wikibase::Datatype::Statement->new(
			'references' => [$self->wikidata_reference],
			'snak' => Wikibase::Datatype::Snak->new(
				'datatype' => 'wikibase-item',
				'datavalue' => Wikibase::Datatype::Value::Quantity->new(
					'value' => $lang_qid,
				),
				'property' => 'P407',
			),
		),
	);
}

sub wikidata_krameriuses {
	my $self = shift;

	if (! defined $self->{'_object'}->krameriuses) {
		return;
	}

	my @krameriuses;
	foreach my $k (@{$self->{'_object'}->krameriuses}) {
		if ($k->kramerius_id eq 'mzk') {
			push @krameriuses, Wikibase::Datatype::Statement->new(
				'references' => [$self->wikidata_reference],
				'snak' => Wikibase::Datatype::Snak->new(
					'datatype' => 'external-id',
					'datavalue' => Wikibase::Datatype::Value::String->new(
						'value' => $k->object_id,
					),
					'property' => 'P8752',
				),
			),
		} else {
			push @krameriuses, Wikibase::Datatype::Statement->new(
				'references' => [$self->wikidata_reference],
				'snak' => Wikibase::Datatype::Snak->new(
					'datatype' => 'url',
					'datavalue' => Wikibase::Datatype::Value::String->new(
						'value' => $k->url,
					),
					'property' => 'P953',
				),
				# TODO Language of work or name: Czech
			),
		}
	}

	return @krameriuses;
}

sub wikidata_number_of_pages {
	my $self = shift;

	if (! defined $self->{'_object'}->number_of_pages) {
		return;
	}

	return (
		Wikibase::Datatype::Statement->new(
			'references' => [$self->wikidata_reference],
			'snak' => Wikibase::Datatype::Snak->new(
				'datatype' => 'quantity',
				'datavalue' => Wikibase::Datatype::Value::Quantity->new(
					'value' => $self->{'_object'}->number_of_pages,
				),
				'property' => 'P1104',
			),
		),
	);
}

sub wikidata_people {
	my ($self, $people_method, $people_property) = @_;

	if (! @{$self->{'_object'}->$people_method}) {
		return;
	}

	if (! defined $self->{'callback_people'}) {
		warn "No callback method for translation of people in '$people_method' method.";
		return;
	}

	my @people_qids;
	foreach my $people (@{$self->{'_object'}->$people_method}) {
		my $people_qid = $self->{'callback_people'}->($people);
		if (defined $people_qid) {
			push @people_qids, $people_qid;
		}
	}

	my @people;
	foreach my $people_qid (@people_qids) {
		push @people, Wikibase::Datatype::Statement->new(
			'references' => [$self->wikidata_reference],
			'snak' => Wikibase::Datatype::Snak->new(
				'datatype' => 'wikibase-item',
				'datavalue' => Wikibase::Datatype::Value::Item->new(
					'value' => $people_qid,
				),
				'property' => $people_property,
			),
		),
	}

	return @people;
}

sub wikidata_place_of_publication {
	my $self = shift;

	if (! defined $self->{'_object'}->place_of_publication) {
		return;
	}

	my $place_qid;
	if (! defined $self->{'callback_place'}) {
		return;
	} else {
		$place_qid = $self->{'callback_place'}->($self->{'_object'});
	}

	if (! defined $place_qid) {
		return;
	}

	return (
		Wikibase::Datatype::Statement->new(
			'references' => [$self->wikidata_reference],
			'snak' => Wikibase::Datatype::Snak->new(
				'datatype' => 'wikibase-item',
				'datavalue' => Wikibase::Datatype::Value::Item->new(
					'value' => $place_qid,
				),
				'property' => 'P291',
			),
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
			'references' => [$self->wikidata_reference],
			'snak' => Wikibase::Datatype::Snak->new(
				'datatype' => 'time',
				'datavalue' => Wikibase::Datatype::Value::Time->new(
					'value' => '+'.$self->{'_object'}->publication_date,
				),
				'property' => 'P577',
			),
		),
	);
}

sub wikidata_publisher {
	my $self = shift;

	if (! defined $self->{'_object'}->publisher) {
		return;
	}

	my $publisher_qid;
	if (! defined $self->{'callback_publisher'}) {
		return;
	} else {
		$publisher_qid = $self->{'callback_publisher'}->($self->{'_object'});
	}

	if (! defined $publisher_qid) {
		return;
	}

	return (
		Wikibase::Datatype::Statement->new(
			'references' => [$self->wikidata_reference],
			'snak' => Wikibase::Datatype::Snak->new(
				'datatype' => 'wikibase-item',
				'datavalue' => Wikibase::Datatype::Value::Item->new(
					'value' => $publisher_qid,
				),
				'property' => 'P123',
			),
		),
	);
}

sub wikidata_reference {
	my $self = shift;

	return (
		Wikibase::Datatype::Reference->new(
			'snaks' => [
				# Stated in NKČR AUT
				Wikibase::Datatype::Snak->new(
					'datatype' => 'wikibase-item',
					'datavalue' => Wikibase::Datatype::Value::Item->new(
						'value' => 'Q13550863',
					),
					'property' => 'P248',
				),

				# Czech National Bibliography book ID
				Wikibase::Datatype::Snak->new(
					'datatype' => 'external-id',
					'datavalue' => Wikibase::Datatype::Value::String->new(
						'value' => $self->{'_object'}->ccnb,
					),
					'property' => 'P3184',
				),

				# Retrieved.
				Wikibase::Datatype::Snak->new(
					'datatype' => 'time',
					'datavalue' => Wikibase::Datatype::Value::Time->new(
						'value' => $self->{'date_retrieved'},
					),
					'property' => 'P813',
				),
			],
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
			'references' => [$self->wikidata_reference],
			'snak' => Wikibase::Datatype::Snak->new(
				'datatype' => 'monolingualtext',
				'datavalue' => Wikibase::Datatype::Value::Monolingual->new(
					'language' => $self->_marc_lang_to_wd_lang,
					'value' => $self->{'_object'}->subtitle,
				),
				'property' => 'P1680',
			),
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
			'references' => [$self->wikidata_reference],
			'snak' => Wikibase::Datatype::Snak->new(
				'datatype' => 'monolingualtext',
				'datavalue' => Wikibase::Datatype::Value::Monolingual->new(
					'language' => $self->_marc_lang_to_wd_lang,
					'value' => $self->{'_object'}->title,
				),
				'property' => 'P1476',
			),
		),
	);
}

sub wikidata_translators {
	my $self = shift;

	return $self->wikidata_people('translators', 'P655');
}

sub wikidata {
	my $self = shift;

	my $wikidata = Wikibase::Datatype::Item->new(
		$self->wikidata_labels,
		$self->wikidata_descriptions,
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

			$self->wikidata_authors,
			$self->wikidata_ccnb,
			$self->wikidata_edition_number,
			$self->wikidata_editors,
			$self->wikidata_illustrators,
			$self->wikidata_isbn_10,
			$self->wikidata_isbn_13,
			$self->wikidata_krameriuses,
			$self->wikidata_language,
			$self->wikidata_number_of_pages,
			$self->wikidata_place_of_publication,
			$self->wikidata_publication_date,
			$self->wikidata_publisher,
			$self->wikidata_subtitle,
			$self->wikidata_title,
			$self->wikidata_translators,
		],
	);

	return $wikidata;
}

sub _description {
	my ($self, $lang) = @_;

	my $ret;
	if ($lang eq 'cs') {
		# XXX Czech
		$ret = decode_utf8('české knižní vydání');
		if (defined $self->{'_object'}->publication_date) {
			$ret .= ' z roku '.$self->{'_object'}->publication_date;
		}

	} elsif ($lang eq 'en') {
		if (defined $self->{'_object'}->publication_date) {
			$ret = $self->{'_object'}->publication_date.' ';
		}
		# XXX Czech
		$ret .= 'Czech book edition';
	}

	return $ret;
}

sub _marc_lang_to_wd_lang {
	my $self = shift;

	my $wd_lang;
	my $marc_lang = $self->object->language;
	# TODO Common way.
	if ($marc_lang eq 'cze') {
		$wd_lang = 'cs';
	}

	return $wd_lang;
}

1;

__END__
