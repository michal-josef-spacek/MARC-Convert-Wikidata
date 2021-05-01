package MARC::Convert::Wikidata::Object;

use strict;
use warnings;

use Business::ISBN;
use Class::Utils qw(set_params);
use Error::Pure qw(err);
use Readonly;
use Roman;

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

	# Process people in 100, 700.
	$self->{'_people'} = {
		'authors' => [],
		'editors' => [],
		'illustrators' => [],
		'translators' => [],
	};
	$self->_process_people_100;
	$self->_process_people_700;

	return $self;
}

sub authors {
	my $self = shift;

	return @{$self->{'_people'}->{'authors'}};
}

sub ccnb {
	my $self = shift;

	return $self->_subfield('015', 'a');
}

sub edition_number {
	my $self = shift;

	my $edition_number = $self->_subfield('250', 'a');

	$edition_number =~ s/\s+$//g;
	$edition_number =~ s/\.\s+vyd\.$//g;
	if (isroman($edition_number)) {
		$edition_number = arabic($edition_number);
	}
	if ($edition_number !~ m/^\d$/ms) {
		$edition_number = undef;
	}

	return $edition_number;
}

sub editors {
	my $self = shift;

	return @{$self->{'_people'}->{'editors'}};
}

sub full_name {
	my $self = shift;

	my $full_name = $self->title;
	if ($self->subtitle) {
		$full_name .= ': '.$self->subtitle;
	}

	return $full_name;
}

sub illustrators {
	my $self = shift;

	return @{$self->{'_people'}->{'illustrators'}};
}

sub isbn {
	my $self = shift;

	return $self->_subfield('020', 'a');
}

sub isbn_10 {
	my $self = shift;

	if (! defined $self->isbn) {
		return;
	}

	my $isbn_o = Business::ISBN->new($self->isbn);

	if ($isbn_o->as_isbn10->as_string eq $self->isbn) {
		return $self->isbn;
	} else {
		return;
	}
}

sub isbn_13 {
	my $self = shift;

	if (! defined $self->isbn) {
		return;
	}

	my $isbn_o = Business::ISBN->new($self->isbn);

	if ($isbn_o->as_isbn13->as_string eq $self->isbn) {
		return $self->isbn;
	} else {
		return;
	}
}

sub number_of_pages {
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

sub place_of_publication {
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

sub publication_date {
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

sub publisher {
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

sub subtitle {
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

sub title {
	my $self = shift;

	my $title = $self->_subfield('245', 'a');

	# XXX Remove traling characters like 'Title :', 'Title /'.
	$title =~ s/\s+$//g;
	$title =~ s/\/$//g;
	$title =~ s/\:$//g;
	$title =~ s/\s+$//g;

	return $title;
}

sub translators {
	my $self = shift;

	return @{$self->{'_people'}->{'translators'}};
}

sub _process_people {
	my ($self, $field) = @_;

	my $type = $field->subfield('4');
	my $type_key = $self->_process_people_type($type);

	my $full_name = $field->subfield('a');
	# TODO Only if type 1. Fix for type 0 and 2.
	my ($surname, $name) = split m/,\s*/ms, $full_name;
	my $people_hr = {
		'surname' => $surname,
		'name' => $name,
	};

	my $nkcr_aut = $field->subfield('7');
	if ($nkcr_aut) {
		$people_hr->{'nkcr_aut'} = $nkcr_aut;
	}

	my $dates = $field->subfield('d');
	my $date_of_birth;
	my $date_of_death;
	if (defined $dates) {
		($date_of_birth, $date_of_death) = split m/-/ms, $dates;
		if (! $date_of_death) {
			$date_of_death = undef;
		}
	}
	if (defined $date_of_birth) {
		$people_hr->{'date_of_birth'} = $date_of_birth;
	}
	if (defined $date_of_death) {
		$people_hr->{'date_of_death'} = $date_of_death;
	}

	push @{$self->{'_people'}->{$type_key}}, $people_hr;

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
		err "People type doesn't exist.";
	}
}

sub _subfield {
	my ($self, $field, $subfield) = @_;

	my $field_value = $self->{'marc_record'}->field($field);
	if (! defined $field_value) {
		return;
	}

	return $field_value->subfield($subfield);
}

1;

__END__
