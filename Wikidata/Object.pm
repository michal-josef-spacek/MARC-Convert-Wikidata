package MARC::Convert::Wikidata::Object;

use strict;
use warnings;

use Business::ISBN;
use Class::Utils qw(set_params);
use Error::Pure qw(err);

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

	return $self;
}

sub ccnb {
	my $self = shift;

	return $self->{'marc_record'}->field('015')->subfield('a');
}

sub full_name {
	my $self = shift;

	my $full_name = $self->title;
	if ($self->subtitle) {
		$full_name .= ': '.$self->subtitle;
	}

	return $full_name;
}

sub isbn {
	my $self = shift;

	my $field = $self->{'marc_record'}->field('020');
	if ($field) {
		return $field->subfield('a');
	} else {
		return;
	}
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

	# Supposition.
	my $supposition = 0;
	if ($publication_date =~ m/^\[(\d+)\]$/ms) {
		$publication_date = $1;
		$supposition = 1;
	}

	return wantarray ? ($publication_date, $supposition) : $publication_date;
}

sub subtitle {
	my $self = shift;

	my $subtitle = $self->{'marc_record'}->field(245)->subfield('b');

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

	my $title = $self->{'marc_record'}->field(245)->subfield('a');

	# XXX Remove traling characters like 'Title :', 'Title /'.
	$title =~ s/\s+$//g;
	$title =~ s/\/$//g;
	$title =~ s/\:$//g;
	$title =~ s/\s+$//g;

	return $title;
}

1;

__END__
