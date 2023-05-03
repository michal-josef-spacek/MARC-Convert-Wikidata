package MARC::Convert::Wikidata;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Error::Pure qw(err);
use MARC::Convert::Wikidata::Item::BookEdition;
use MARC::Convert::Wikidata::Transform;

our $VERSION = 0.01;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Cover callback.
	$self->{'callback_cover'} = undef;

	# Lang callback.
	$self->{'callback_lang'} = undef;

	# People callback.
	$self->{'callback_people'} = undef;

	# Place of publication Wikidata lookup callback.
	$self->{'callback_publisher_place'} = undef;

	# Publisher Wikidata lookup callback.
	$self->{'callback_publisher_name'} = undef;

	# Book series Wikidata lookup callback.
	$self->{'callback_series'} = undef;

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

	$self->{'_transform_object'} = MARC::Convert::Wikidata::Transform->new(
		'marc_record' => $self->{'marc_record'},
	)->object;

	return $self;
}

sub object {
	my $self = shift;

	return $self->{'_transform_object'};
}

sub type {
	my $self = shift;

	my $leader = $self->{'marc_record'}->leader;
	# XXX Use MARC::Leader if exist.
	my $leader_hr = $self->_leader($leader);

	if ($leader_hr->{'type_of_record'} eq 'a' && $leader_hr->{'bibliographic_level'} eq 'm') {
		return 'monograph';
	} else {
		err "Unsupported item with leader '$leader'.";
	}
}

sub wikidata {
	my $self = shift;

	my $wikidata;
	if ($self->type eq 'monograph') {
		$wikidata = MARC::Convert::Wikidata::Item::BookEdition->new(
			'callback_cover' => $self->{'callback_cover'},
			'callback_lang' => $self->{'callback_lang'},,
			'callback_publisher_place' => $self->{'callback_publisher_place'},,
			'callback_people' => $self->{'callback_people'},
			'callback_publisher_name' => $self->{'callback_publisher_name'},
			'callback_series' => $self->{'callback_series'},
			'marc_record' => $self->{'marc_record'},
			'transform_object' => $self->{'_transform_object'},
		)->wikidata;

	# TODO Implement series.
	# TODO Implement audiobook.
	} else {
		err "Unsupported MARC type.";
	}

	return $wikidata;
}

sub _leader {
	my ($self, $leader) = @_;

	# Example '03691nam a2200685 aa4500'
	my $length = substr $leader, 0, 5;
	my $record_status = substr $leader, 5, 1;
	my $type_of_record = substr $leader, 6, 1;
	my $bibliographic_level = substr $leader, 7, 1;

	return {
		'length' => $length,
		'record_status' => $record_status,
		'type_of_record' => $type_of_record,
		'bibliographic_level' => $bibliographic_level,
	}
}

1;

__END__
