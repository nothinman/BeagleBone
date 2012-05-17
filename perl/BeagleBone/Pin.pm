package BeagleBone::Pin;
use 5.14.1;
use warnings;
use Class::Accessor qw(antlers);
use Fcntl qw(:DEFAULT);
use autodie;

has 'desc' => (
    is => 'ro',
    isa => 'Str',
);

has 'mux' => (
    is => 'ro',
    isa => 'Str',
);

has 'gpio' => (
    is => 'ro',
    isa => 'Int',
);

has 'gpio_fh' => (
    is => 'rw',
);

sub set_mode {
    my ($self, $mode) = @_;
    sysopen(my $fh, "/sys/kernel/debug/omap_mux/" . $self->mux, O_WRONLY);
    syswrite($fh, "$mode", 1);
    close($fh);
}

sub gpio_open {
    my ($self, $direction) = @_;

    if (not -d "/sys/class/gpio/gpio" . $self->gpio) {
        sysopen(my $tmp, "/sys/class/gpio/export", O_WRONLY);
        my $str = sprintf('%d', $self->gpio);
        syswrite($tmp, $str, length($str));
        close($tmp);
    }
    if (not -d "/sys/class/gpio/gpio" . $self->gpio) {
        die "Could not export this pin (" . $self->name . ")\n";
    }
    sysopen(my $dir, "/sys/class/gpio/gpio" . $self->gpio . "/direction", O_WRONLY);
    syswrite($dir, $direction, length($direction));
    close($dir);

    sysopen(my $fh, "/sys/class/gpio/gpio" . $self->gpio . "/value",
        $direction eq 'out' ? O_WRONLY : O_RDONLY
    );
    $self->gpio_fh($fh);
    return $fh;
}

sub digitalWrite {
    my ($self, $value) = @_;
    $self->gpio_open('out') unless (defined $self->gpio_fh);
    syswrite($self->gpio_fh, "$value", 1);
}

sub digitalRead {
    my ($self) = @_;
    $self->gpio_open('in') unless (defined $self->gpio_fh);
    my $buf;
    sysread($self->gpio_fh, $buf, 1);
}

sub DESTROY {
    my $self = shift;
    if (defined $self->gpio_fh) {
        close($self->gpio_fh);
        $self->gpio_fh(undef);
    }
}

1;
