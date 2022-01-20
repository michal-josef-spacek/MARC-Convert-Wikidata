package MARC::Convert::Wikidata::Transform;

use strict;
use warnings;

use Business::ISBN;
use Class::Utils qw(set_params);
use Data::Kramerius;
use Error::Pure qw(err);
use MARC::Convert::Wikidata::Object;
use MARC::Convert::Wikidata::Object::Kramerius;
use MARC::Convert::Wikidata::Object::People;
use MARC::Convert::Wikidata::Object::Publisher;
use MARC::Convert::Wikidata::Utils qw(clean_oclc clean_edition_number clean_number_of_pages
	clean_subtitle clean_title);
use Readonly;
use URI;
use Unicode::UTF8 qw(decode_utf8);

Readonly::Hash our %PEOPLE_TYPE => {
	'aui' => 'authors_of_introduction',
	'aut' => 'authors',
	'com' => 'compilers',
	'edt' => 'editors',
	'ill' => 'illustrators',
	'trl' => 'translators',
};

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

	$self->{'_kramerius'} = Data::Kramerius->new;

	# Process people in 100, 700.
	$self->{'_people'} = {
		'authors' => [],
		'authors_of_introduction' => [],
		'compilers' => [],
		'editors' => [],
		'illustrators' => [],
		'translators' => [],
	};
	$self->_process_people_100;
	$self->_process_people_700;

	$self->{'_object'} = undef;
	$self->_process_object;

	return $self;
}

sub object {
	my $self = shift;

	return $self->{'_object'};
}

sub _ccnb {
	my $self = shift;

	my $ccnb = $self->_subfield('015', 'a');
	if (! defined $ccnb) {
		$ccnb = $self->_subfield('015', 'z');
	}

	return $ccnb;
}

sub _construct_kramerius {
	my ($self, $kramerius_uri) = @_;

	# XXX krameriusndk.nkp.cz is virtual project domain.
	$kramerius_uri =~ s/krameriusndk\.nkp\.cz/kramerius.mzk.cz/ms;

	my $u = URI->new($kramerius_uri);
	my $authority = $u->authority;
	foreach my $k ($self->{'_kramerius'}->list) {
		if ($k->url =~ m/$authority\/$/ms) {
			my @path_seg = $u->path_segments;
			my $uuid = $path_seg[-1];
			$uuid =~ s/^uuid://ms;
			return MARC::Convert::Wikidata::Object::Kramerius->new(
				'kramerius_id' => $k->id,
				'object_id' => $uuid,
				'url' => $kramerius_uri,
			);
		}
	}

	return;
}

sub _edition_number {
	my $self = shift;

	my $edition_number = $self->_subfield('250', 'a');
	$edition_number = clean_edition_number($edition_number);

	return $edition_number;
}

sub _isbn {
	my $self = shift;

	return $self->_subfield('020', 'a');
}

sub _isbn_10 {
	my $self = shift;

	if (! defined $self->_isbn) {
		return;
	}

	my $isbn_o = Business::ISBN->new($self->_isbn);

	if ($isbn_o->as_isbn10->as_string eq $self->_isbn) {
		return $self->_isbn;
	} else {
		return;
	}
}

sub _isbn_13 {
	my $self = shift;

	if (! defined $self->_isbn) {
		return;
	}

	my $isbn_o = Business::ISBN->new($self->_isbn);

	if ($isbn_o->as_isbn13->as_string eq $self->_isbn) {
		return $self->_isbn;
	} else {
		return;
	}
}

sub _krameriuses {
	my $self = shift;

	return map {
		$self->_construct_kramerius($_);
	} $self->_subfield('856', 'u');
}

sub _languages {
	my $self = shift;

	my @lang = $self->_subfield('041', 'a');
	if (! @lang) {
		push @lang, $self->_subfield('040', 'b');
	}

	return @lang;
}


sub _number_of_pages {
	my $self = shift;

	my $number_of_pages = $self->_subfield('300', 'a');
	$number_of_pages = clean_number_of_pages($number_of_pages);

	return $number_of_pages;
}

sub _oclc {
	my $self = shift;

	my @oclc = $self->_subfield('035', 'a');
	foreach my $oclc (@oclc) {
		$oclc = clean_oclc($oclc);
	}
	if (@oclc > 1) {
		err 'Multiple OCLC control number.';
	}

	return $oclc[0];
}

sub _process_object {
	my $self = shift;

	$self->{'_object'} = MARC::Convert::Wikidata::Object->new(
		'authors' => $self->{'_people'}->{'authors'},
		'authors_of_introduction' => $self->{'_people'}->{'authors_of_introduction'},
		'ccnb' => $self->_ccnb,
		'compilers' => $self->{'_people'}->{'compilers'},
		'edition_number' => $self->_edition_number,
		'editors' => $self->{'_people'}->{'editors'},
		# XXX Why?
		defined $self->_isbn_10 ? ('isbn_10' => $self->_isbn_10) : (),
		defined $self->_isbn_13 ? ('isbn_13' => $self->_isbn_13) : (),
		'illustrators' => $self->{'_people'}->{'illustrators'},
		'krameriuses' => [$self->_krameriuses],
		'languages' => [$self->_languages],
		'number_of_pages' => $self->_number_of_pages,
		'oclc' => $self->_oclc,
		'publication_date' => scalar $self->_publication_date,
		'publishers' => [$self->_publishers],
		'subtitle' => $self->_subtitle,
		'title' => $self->_title,
		'translators' => $self->{'_people'}->{'translators'},
	);

	return;
}

sub _process_people {
	my ($self, $field) = @_;

	my @types = $field->subfield('4');
	my @type_keys;
	foreach my $type (@types) {
		my $type_key = $self->_process_people_type($type);
		if (defined $type_key) {
			push @type_keys, $type_key;
		}
	}
	if (! @type_keys) {
		return;
	}

	my $full_name = $field->subfield('a');
	# TODO Only if type 1. Fix for type 0 and 2.
	my ($surname, $name) = split m/,\s*/ms, $full_name;

	my $nkcr_aut = $field->subfield('7');

	my $dates = $field->subfield('d');
	my $date_of_birth;
	my $date_of_death;
	if (defined $dates) {
		($date_of_birth, $date_of_death) = split m/-/ms, $dates;
		# XXX common
		my $march = decode_utf8('březen');
		$date_of_birth =~ s/^(\d{4})\s*$march\s*(\d+)\.$/$1-03-$2/ms;
		my $bk = decode_utf8('př. Kr.');
		$date_of_birth =~ s/^(\d+)\s*$bk/-$1/ms;
		$date_of_death =~ s/^(\d+)\s*$bk/-$1/ms;
		if (! $date_of_death) {
			$date_of_death = undef;
		} else {
			$date_of_death =~ s/\s*\.$//ms;
		}
	}

	foreach my $type_key (@type_keys) {
		push @{$self->{'_people'}->{$type_key}},
			MARC::Convert::Wikidata::Object::People->new(
				'date_of_birth' => $date_of_birth,
				'date_of_death' => $date_of_death,
				'name' => $name,
				'nkcr_aut' => $nkcr_aut,
				'surname' => $surname,
			);
	}

	return;
}

sub _process_people_100 {
	my $self = shift;

	my @field_100 = $self->{'marc_record'}->field('100');
	foreach my $field (@field_100) {
		$self->_process_people($field);
	}

	return;
}

sub _process_people_700 {
	my $self = shift;

	my @field_700 = $self->{'marc_record'}->field('700');
	foreach my $field (@field_700) {
		$self->_process_people($field);
	}

	return;
}

sub _process_people_type {
	my ($self, $type) = @_;

	if (! defined $type || $type eq '') {
		warn "People type set to 'aut'.";
		$type = 'aut';
	}

	if ($type eq 'art' || $type eq 'pht') {
		return;
	}

	if (exists $PEOPLE_TYPE{$type}) {
		return $PEOPLE_TYPE{$type};
	} else {
		err "People type '$type' doesn't exist.";
	}
}

sub _process_publisher_field {
	my ($self, $field_num) = @_;

	my $field = $self->{'marc_record'}->field($field_num);
	if (! defined $field) {
		return ();
	}
	my @publisher_names = $field->subfield('b');
	my @publishers;
	for (my $i = 0; $i < @publisher_names; $i++) {
		my $publisher_name = $publisher_names[$i];
		$publisher_name =~ s/\s+$//g;
		$publisher_name =~ s/\s*,$//g;
		$publisher_name =~ s/\s*:$//g;
		$publisher_name =~ s/\s*;$//g;

		my @places = $field->subfield('a');
		my $place;
		if (defined $places[$i]) {
			$place = $places[$i];
		} else {
			$place = $places[0];
		}
		$place =~ s/\s+$//g;
		$place =~ s/\s*:$//g;
		$place =~ s/^V Praze$/Praha/ms;
		my $brno = decode_utf8('V Brně');
		$place =~ s/^$brno$/Brno/ms;
		# [Praha]
		$place =~ s/^\[(.*?)\]$/$1/ms;

		push @publishers, MARC::Convert::Wikidata::Object::Publisher->new(
			'name' => $publisher_name,
			'place' => $place,
		);
	}

	return @publishers;
}

sub _publication_date {
	my $self = shift;

	my $publication_date = $self->_subfield('264', 'c');
	if (! $publication_date) {
		$publication_date = $self->_subfield('260', 'c');
	}

	# Supposition.
	my $supposition = 0;
	if ($publication_date =~ m/^\[(\d+)\??\]$/ms) {
		$publication_date = $1;
		$supposition = 1;
	}

	return wantarray ? ($publication_date, $supposition) : $publication_date;
}

sub _publishers {
	my $self = shift;

	my @publishers = $self->_process_publisher_field('260');
	push @publishers, $self->_process_publisher_field('264');

	return @publishers;
}

sub _subfield {
	my ($self, $field, $subfield) = @_;

	my $field_value = $self->{'marc_record'}->field($field);
	if (! defined $field_value) {
		return;
	}

	return $field_value->subfield($subfield);
}

sub _subtitle {
	my $self = shift;

	my $subtitle = $self->_subfield('245', 'b');
	$subtitle = clean_subtitle($subtitle);

	return $subtitle;
}

sub _title {
	my $self = shift;

	my $title = $self->_subfield('245', 'a');
	$title = clean_title($title);

	return $title;
}

1;

__END__
