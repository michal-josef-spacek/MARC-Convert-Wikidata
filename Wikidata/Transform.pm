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
use Readonly;
use Roman;
use URI;

Readonly::Hash our %PEOPLE_TYPE => {
	'aut' => 'authors',
	'com' => 'editors',
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
	if (defined $edition_number) {
		$edition_number =~ s/\s+$//g;
		$edition_number =~ s/\.\s+vyd\.$//g;
		if (isroman($edition_number)) {
			$edition_number = arabic($edition_number);
		}
		if ($edition_number !~ m/^\d$/ms) {
			$edition_number = undef;
		}
	}

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

sub _language {
	my $self = shift;

	# TODO In 008 is some other language.

	my $cataloging_lang = $self->_subfield('040', 'b');

	return $cataloging_lang;
}


sub _number_of_pages {
	my $self = shift;

	my $number_of_pages = $self->_subfield('300', 'a');

	# XXX Remove trailing characters.
	if (defined $number_of_pages) {
		$number_of_pages =~ s/\s+$//g;
		$number_of_pages =~ s/\s*:$//g;
		$number_of_pages =~ s/\s*;$//g;
		$number_of_pages =~ s/\s*s\.$//g;
		$number_of_pages =~ s/\s*stran$//g;
	}

	return $number_of_pages;
}

sub _place_of_publication {
	my $self = shift;

	my $place_of_publication = $self->_subfield('260', 'a');
	if (! defined $place_of_publication) {
		$place_of_publication = $self->_subfield('264', 'a');
	}

	# XXX Remove trailings characters.
	if (defined $place_of_publication) {
		$place_of_publication =~ s/\s+$//g;
		$place_of_publication =~ s/\s*:$//g;
	}

	return $place_of_publication;
}


sub _process_object {
	my $self = shift;

	$self->{'_object'} = MARC::Convert::Wikidata::Object->new(
		'authors' => $self->{'_people'}->{'authors'},
		'ccnb' => $self->_subfield('015', 'a'),
		'edition_number' => $self->_edition_number,
		'editors' => $self->{'_people'}->{'editors'},
		# XXX Why?
		defined $self->_isbn_10 ? ('isbn_10' => $self->_isbn_10) : (),
		defined $self->_isbn_13 ? ('isbn_13' => $self->_isbn_13) : (),
		'illustrators' => $self->{'_people'}->{'illustrators'},
		'krameriuses' => [$self->_krameriuses],
		'language' => $self->_language,
		'number_of_pages' => $self->_number_of_pages,
		'place_of_publication' => $self->_place_of_publication,
		'publication_date' => scalar $self->_publication_date,
		'publisher' => $self->_publisher,
		'subtitle' => $self->_subtitle,
		'title' => $self->_title,
		'translators' => $self->{'_people'}->{'translators'},
	);

	return;
}

sub _process_people {
	my ($self, $field) = @_;

	my $type = $field->subfield('4');
	my $type_key = $self->_process_people_type($type);

	my $full_name = $field->subfield('a');
	# TODO Only if type 1. Fix for type 0 and 2.
	my ($surname, $name) = split m/,\s*/ms, $full_name;

	my $nkcr_aut = $field->subfield('7');

	my $dates = $field->subfield('d');
	my $date_of_birth;
	my $date_of_death;
	if (defined $dates) {
		($date_of_birth, $date_of_death) = split m/-/ms, $dates;
		if (! $date_of_death) {
			$date_of_death = undef;
		}
	}

	push @{$self->{'_people'}->{$type_key}},
		MARC::Convert::Wikidata::Object::People->new(
			'date_of_birth' => $date_of_birth,
			'date_of_death' => $date_of_death,
			'name' => $name,
			'nkcr_aut' => $nkcr_aut,
			'surname' => $surname,
		);

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

	if (exists $PEOPLE_TYPE{$type}) {
		return $PEOPLE_TYPE{$type};
	} else {
		err "People type '$type' doesn't exist.";
	}
}

sub _publication_date {
	my $self = shift;

	my $publication_date = $self->_subfield('264', 'c');
	if (! $publication_date) {
		$publication_date = $self->_subfield('260', 'c');
	}

	# Supposition.
	my $supposition = 0;
	if ($publication_date =~ m/^\[(\d+)\]$/ms) {
		$publication_date = $1;
		$supposition = 1;
	}

	return wantarray ? ($publication_date, $supposition) : $publication_date;
}

sub _publisher {
	my $self = shift;

	my $publisher = $self->_subfield('260', 'b');
	if (! defined $publisher) {
		$publisher = $self->_subfield('264', 'b');
	}

	# XXX Remove trailing characters.
	if (defined $publisher) {
		$publisher =~ s/\s+$//g;
		$publisher =~ s/\s*,$//g;
	}

	return $publisher;
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

	# XXX Remove traling characters like 'Subtitle /'.
	if ($subtitle) {
		$subtitle =~ s/\s+$//g;
		$subtitle =~ s/\/$//g;
		$subtitle =~ s/\s+$//g;
	}

	return $subtitle;
}

sub _title {
	my $self = shift;

	my $title = $self->_subfield('245', 'a');

	# XXX Remove traling characters like 'Title :', 'Title /'.
	$title =~ s/\s+$//g;
	$title =~ s/\/$//g;
	$title =~ s/\:$//g;
	$title =~ s/\s+$//g;

	return $title;
}

1;

__END__
