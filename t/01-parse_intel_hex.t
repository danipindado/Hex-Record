use strict;
use warnings;
use Test::More;
BEGIN { plan tests => 6 }
use Test::Warn;
use lib '/home/ben/workspace/perl5/Hex-Record/lib';
use Hex::Record;

my @tests = (
    {
        case      => 'simple intel hex (in order)',
        intel_hex =>
              ":0A00000000010203040506070809C9\n"
            . ":0A000A00101112131415161718191F\n"
            . ":0A0014002021222324252627282975\n"
            . "::00000001FF\n",
        parts_exp => [
            {
                start => 0x0,
                bytes => [
                    qw(00 01 02 03 04 05 06 07 08 09
                       10 11 12 13 14 15 16 17 18 19
                       20 21 22 23 24 25 26 27 28 29),
                ],
            },
        ],
    },
    {
        case      => 'simple intel hex (not in order)',
        intel_hex =>
              ":0A000A00101112131415161718191F\n"
            . ":0A0014002021222324252627282975\n"
            . ":0A00000000010203040506070809C9\n",
        parts_exp => [
            {
                start => 0x0,
                bytes => [
                    qw(00 01 02 03 04 05 06 07 08 09
                       10 11 12 13 14 15 16 17 18 19
                       20 21 22 23 24 25 26 27 28 29),
                ],
            },
        ],
    },
    {
        case      => 'colliding parts',
        intel_hex =>
              ":0A00000000010203040506070809C9\n"
            . ":0A0009001011121314151617181920\n"
            . ":0A0014002021222324252627282975\n"
            . ":00000001FF\n",
        parts_exp => [
            {
                start  => 0x0,
                bytes => [
                    qw(00 01 02 03 04 05 06 07 08 10
                       11 12 13 14 15 16 17 18 19),
                ],
            },
            {
                start => 0x14,
                bytes =>[
                    qw(20 21 22 23 24 25 26 27 28 29),
                ],
            },
        ],
    },
    {
        case      => 'multiple colliding parts',
        intel_hex =>
              ":0A00000000010203040506070809C9\n"
            . ":0A0003001011121314151617181926\n"
            . ":0A0005002021222324252627282984\n"
            . ":00000001FF\n",
        parts_exp => [
            {
                start => 0x0,
                bytes => [
                    qw(00 01 02 10 11 20 21 22 23 24
                       25 26 27 28 29),
                ],
            },
        ]
    },
    {
        case      => 'extended linear addresses',
        intel_hex =>
            ":020000040000FA\n"
            . ":0A00000000112233445566778899F9\n"
            . ":0A000A0099887766554433221100EF\n"
            . ":02000004FFFFFC\n"
            . ":0A00010000112233445566778899F8\n"
            . ":0A000B0099887766554433221100EE\n"
            . ":020000040001F9\n"
            . ":0AFF000000112233445566778899FA\n"
            . ":0AFF0A0099887766554433221100F0",
        parts_exp => [
            {
                start => 0x0,
                bytes => [
                    qw(00 11 22 33 44 55 66 77 88 99
                       99 88 77 66 55 44 33 22 11 00),
                ],
            },
            {
                start => 0x0001FF00,
                bytes => [
                    qw(00 11 22 33 44 55 66 77 88 99
                       99 88 77 66 55 44 33 22 11 00),
                ],
            },
            {
                start => 0xFFFF0001,
                bytes => [
                    qw(00 11 22 33 44 55 66 77 88 99
                       99 88 77 66 55 44 33 22 11 00),
                ],
            },
        ],
    },
    {
        case      => 'extended segment addresses',
        intel_hex =>
              ":020000020000FC\n"
            . ":0A00000000112233445566778899F9\n"
            . ":0A000A0099887766554433221100EF\n"
            . ":02000002FFFFFE\n"
            . ":0A00010000112233445566778899F8\n"
            . ":0A000B0099887766554433221100EE\n"
            . ":020000020001FB\n"
            . ":0AFF000000112233445566778899FA\n"
            . ":0AFF0A0099887766554433221100F0\n",
        parts_exp => [
            {
                start => 0x0,
                bytes => [
                    qw(00 11 22 33 44 55 66 77 88 99
                       99 88 77 66 55 44 33 22 11 00),
                ],
            },
            {
                start => 0xFF10,
                bytes => [
                    qw(00 11 22 33 44 55 66 77 88 99
                       99 88 77 66 55 44 33 22 11 00),
                ],
            },
            {
                start => 0xFFFF1,
                bytes => [
                    qw(00 11 22 33 44 55 66 77 88 99
                       99 88 77 66 55 44 33 22 11 00),
                ],
            },
        ],
    },
);

for my $test (@tests) {
    my $hex_record = Hex::Record->new;
    $hex_record->import_intel_hex($test->{intel_hex});
    is_deeply($hex_record->{parts}, $test->{parts_exp}, $test->{case});
}
