package DDGC::User::Page;

use Moose;
use DDGC::User::Page::Field;
use URI;

# default type = text

my @attributes = (
	headline => 'Userpage headline, instead of username' => {},
	about => 'About you' => { type => 'textarea' },
	whyddg => 'Why you use DuckDuckGo?' => { type => 'textarea' },
	email => 'Your public email' => { type => 'email' },
	web => 'Your website' => { type => 'url' },
	twitter => 'Your twitter username' => {
		view => 'twitter',
		edit => 'twitter',
		validators => [sub {
			m/^\w{1,15}$/ ? () : ("Invalid twitter username")
		}],
	},
	facebook => 'Your facebook profile url' => {
		view => 'facebook',
		edit => 'facebook',
		validators => [sub {
			m/^[\w\/]+$/ ? () : ("Invalid url")
		}],
	},
);

has data => (
	is => 'ro',
	isa => 'HashRef',
	lazy => 1,
	default => sub {{}},
);

has user => (
	is => 'ro',
	isa => 'DDGC::User',
	predicate => 'has_user',
);

has attribute_fields => (
	is => 'ro',
	isa => 'HashRef[DDGC::User::Page::Field]',
	lazy_build => 1,
);

sub field {
	my ( $self, $name ) = @_;
	return $self->attribute_fields->{$name};
}

sub _build_attribute_fields {
	my ( $self ) = @_;
	my %fields;
	my @attrs = @attributes;
	while (@attrs) {
		my $name = shift @attrs;
		my $desc = shift @attrs;
		my %extra = %{shift @attrs};
		my $value = defined $self->data->{$name}
			? $self->data->{$name}
			: '';
		$fields{$name} = DDGC::User::Page::Field->new(
			page => $self,
			name => $name,
			description => $desc,
			value => $value,
			%extra,
		);
	}
	return \%fields;
}

sub update_data {
	my ( $self, $data ) = @_;
	my $error_count;
	for (keys %{$data}) {
		my $key = $_;
		my $value = $data->{$_};
		my $field = $self->field($_);
		if ($field) {
			$field->value($value);
			if ($field->error_count) {
				$error_count += $field->error_count;
			} else {
				$self->data->{$key} = $value;
			}
		}
	}
	return $error_count;
}

sub new_from_user {
	my ( $class, $user ) = @_;
	my $data = defined $user->data->{userpage}
		? $user->data->{userpage}
		: {};
	return $class->new(
		data => $data,
		user => $user,
	);
}

sub update {
	my ( $self ) = @_;
	die __PACKAGE__." need a user to save" unless $self->has_user;
	my $data = $self->user->data;
	$data->{userpage} = $self->data;
	$self->user->data($data);
	$self->user->update;
}

1;