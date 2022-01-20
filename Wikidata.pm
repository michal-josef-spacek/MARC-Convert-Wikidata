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
	$self->{'callback_publisher_place'} = undef;

	# Publisher Wikidata lookup callback.
	$self->{'callback_publisher_name'} = undef;

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

	if (! defined $self->{'date_retrieved'}) {
		$self->{'date_retrieved'} = '+'.DateTime->now
			->truncate('to' => 'day')->iso8601().'Z';
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

sub wikidata_authors_of_introduction {
	my $self = shift;

	return $self->wikidata_people('authors_of_introduction', 'P2679');
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
				'value' => $self->_description('en'),
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

sub wikidata_compilers {
	my $self = shift;

	my $property_snaks_ar = [
		Wikibase::Datatype::Snak->new(
			'datatype' => 'wikibase-item',
			'datavalue' => Wikibase::Datatype::Value::Item->new(
				'value' => 'Q29514511',
			),
			'property' => 'P106',
		),
	];
	return $self->wikidata_people('compilers', 'P98', $property_snaks_ar);
}

sub wikidata_illustrators {
	my $self = shift;

	return $self->wikidata_people('illustrators', 'P110');
}

sub wikidata_isbn_10 {
	my $self = shift;

	if (! @{$self->{'_object'}->isbns}) {
		return;
	}

	my @ret;
	foreach my $isbn (@{$self->{'_object'}->isbns}) {
		if ($isbn->type != 10) {
			next;
		}
		push @ret, Wikibase::Datatype::Statement->new(
			'references' => [$self->wikidata_reference],
			'snak' => Wikibase::Datatype::Snak->new(
				'datatype' => 'external-id',
				'datavalue' => Wikibase::Datatype::Value::String->new(
					'value' => $isbn->isbn,
				),
				'property' => 'P957',
			),
		);
	}

	return @ret;
}

sub wikidata_isbn_13 {
	my $self = shift;

	if (! @{$self->{'_object'}->isbns}) {
		return;
	}

	my @ret;
	foreach my $isbn (@{$self->{'_object'}->isbns}) {
		if ($isbn->type != 13) {
			next;
		}
		push @ret, Wikibase::Datatype::Statement->new(
			'references' => [$self->wikidata_reference],
			'snak' => Wikibase::Datatype::Snak->new(
				'datatype' => 'external-id',
				'datavalue' => Wikibase::Datatype::Value::String->new(
					'value' => $isbn->isbn,
				),
				'property' => 'P212',
			),
		);
	}

	return @ret;
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

	if (! @{$self->{'_object'}->languages}) {
		return;
	}

	if (! defined $self->{'callback_lang'}) {
		warn "No callback method for translation of language.";
		return;
	}

	my @language_qids;
	foreach my $lang (@{$self->{'_object'}->languages}) {
		my $language_qid = $self->{'callback_lang'}->($lang);
		if (defined $language_qid) {
			push @language_qids, $language_qid;
		}
	}

	my @lang;
	foreach my $language_qid (@language_qids) {
		push @lang, Wikibase::Datatype::Statement->new(
			'references' => [$self->wikidata_reference],
			'snak' => Wikibase::Datatype::Snak->new(
				'datatype' => 'wikibase-item',
				'datavalue' => Wikibase::Datatype::Value::Item->new(
					'value' => $language_qid,
				),
				'property' => 'P407',
			),
		);
	}

	return @lang;
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

sub wikidata_oclc {
	my $self = shift;

	if (! defined $self->{'_object'}->oclc) {
		return;
	}

	return (
		Wikibase::Datatype::Statement->new(
			'references' => [$self->wikidata_reference],
			'snak' => Wikibase::Datatype::Snak->new(
				'datatype' => 'string',
				'datavalue' => Wikibase::Datatype::Value::String->new(
					'value' => $self->{'_object'}->oclc,
				),
				'property' => 'P243',
			),
		),
	);
}

sub wikidata_people {
	my ($self, $people_method, $people_property, $property_snaks_ar) = @_;

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
			defined $property_snaks_ar ? (
				'property_snaks' => $property_snaks_ar,
			) : (),
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

	if (! @{$self->{'_object'}->publishers}) {
		return;
	}

	my @places;
	if (! defined $self->{'callback_publisher_place'}) {
		return;
	} else {
		foreach my $publisher (@{$self->{'_object'}->publishers}) {
			my $place_qid = $self->{'callback_publisher_place'}->($publisher);
			my $publisher_qid = $self->{'callback_publisher_name'}->($publisher);
			if ($place_qid) {
				push @places, [$publisher_qid, $place_qid];
			}
		}
	}

	if (! @places) {
		return;
	}

	my $multiple = @places > 1 ? 1 : 0;
	return map {
		Wikibase::Datatype::Statement->new(
			'references' => [$self->wikidata_reference],
			'snak' => Wikibase::Datatype::Snak->new(
				'datatype' => 'wikibase-item',
				'datavalue' => Wikibase::Datatype::Value::Item->new(
					'value' => $_->[1],
				),
				'property' => 'P291',
			),
			# TODO property snak with publisher if multiples = 1;
		);
	} @places;
}

sub wikidata_publication_date {
	my $self = shift;

	if (! defined $self->{'_object'}->publication_date) {
		return;
	}

	# TODO Second parameter of publication_date().

	# XXX Publication date is year? Probably not.
	my $value = '+'.DateTime->new(
		'year' => $self->{'_object'}->publication_date,
	)->iso8601().'Z';
	return (
		Wikibase::Datatype::Statement->new(
			'references' => [$self->wikidata_reference],
			'snak' => Wikibase::Datatype::Snak->new(
				'datatype' => 'time',
				'datavalue' => Wikibase::Datatype::Value::Time->new(
					# Precision for year.
					'precision' => 9,
					'value' => $value,
				),
				'property' => 'P577',
			),
		),
	);
}

sub wikidata_publishers {
	my $self = shift;

	if (! @{$self->{'_object'}->publishers}) {
		return;
	}

	my @publisher_qids;
	if (! defined $self->{'callback_publisher_name'}) {
		return;
	} else {
		foreach my $publisher (@{$self->{'_object'}->publishers}) {
			my $publisher_qid = $self->{'callback_publisher_name'}->($publisher);
			if ($publisher_qid) {
				push @publisher_qids, [$publisher_qid, $publisher->name];
			}
		}
	}

	if (! @publisher_qids) {
		return;
	}

	my @publishers;
	foreach my $publisher_ar (@publisher_qids) {
		push @publishers, Wikibase::Datatype::Statement->new(
			'references' => [$self->wikidata_reference],
			'snak' => Wikibase::Datatype::Snak->new(
				'datatype' => 'wikibase-item',
				'datavalue' => Wikibase::Datatype::Value::Item->new(
					'value' => $publisher_ar->[0],
				),
				'property' => 'P123',
			),
			'property_snaks' => [
				Wikibase::Datatype::Snak->new(
					'datatype' => 'string',
					'datavalue' => Wikibase::Datatype::Value::String->new(
						'value' => $publisher_ar->[1],
					),
					'property' => 'P1810',
				),
			],
		);
	}

	return @publishers;
}

sub wikidata_reference {
	my $self = shift;

	return (
		Wikibase::Datatype::Reference->new(
			'snaks' => [
				# Stated in Czech National Bibliography
				Wikibase::Datatype::Snak->new(
					'datatype' => 'wikibase-item',
					'datavalue' => Wikibase::Datatype::Value::Item->new(
						'value' => 'Q86914821',
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
			$self->wikidata_authors_of_introduction,
			$self->wikidata_ccnb,
			$self->wikidata_compilers,
			$self->wikidata_edition_number,
			$self->wikidata_editors,
			$self->wikidata_illustrators,
			$self->wikidata_isbn_10,
			$self->wikidata_isbn_13,
			$self->wikidata_krameriuses,
			$self->wikidata_language,
			$self->wikidata_number_of_pages,
			$self->wikidata_oclc,
			$self->wikidata_place_of_publication,
			$self->wikidata_publication_date,
			$self->wikidata_publishers,
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
	my $marc_lang = $self->object->languages->[0];
	# TODO Common way. ISO 639-2 code for bibliography
	if ($marc_lang eq 'cze') {
		$wd_lang = 'cs';
	} elsif ($marc_lang eq 'eng') {
		$wd_lang = 'en';
	}

	return $wd_lang;
}

1;

__END__
