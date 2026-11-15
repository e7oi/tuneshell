import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/features/browse/album_key_text.dart';

void main() {
  /// @verifies BR-017
  group('BR-017 rule 1: normalised album key text', () {
    test('case, accents and runs of spaces do not count', () {
      expect(albumKeyText('  ALBUM   Á '), albumKeyText('album a'));
    });

    test('a combining accent equals the precomposed letter', () {
      expect(albumKeyText('Café'), albumKeyText('Café'));
      expect(albumKeyText('Café'), albumKeyText('Cafe'));
    });

    test('apostrophes of every shape are one', () {
      final plain = albumKeyText("L'album");
      expect(albumKeyText('L’album'), plain);
      expect(albumKeyText('L‘album'), plain);
      expect(albumKeyText('Lʼalbum'), plain);
      expect(albumKeyText('L`album'), plain);
    });

    test('quotes, dashes and ellipsis of every shape are one', () {
      expect(albumKeyText('“A”'), albumKeyText('"A"'));
      expect(albumKeyText('A–B'), albumKeyText('A-B'));
      expect(albumKeyText('A—B'), albumKeyText('A-B'));
      expect(albumKeyText('A…'), albumKeyText('A...'));
    });

    test('every kind of space is a plain space', () {
      final plain = albumKeyText('A B');
      expect(albumKeyText('A B'), plain);
      expect(albumKeyText('A B'), plain);
      expect(albumKeyText('A　B'), plain);
      expect(albumKeyText('A\t B'), plain);
    });

    test('invisible format characters are ignored', () {
      final plain = albumKeyText('AB');
      expect(albumKeyText('A​B'), plain);
      expect(albumKeyText('A­B'), plain);
      expect(albumKeyText('﻿AB'), plain);
      expect(albumKeyText('A‎B'), plain);
    });

    test('ligatures and letters outside the table are folded', () {
      expect(albumKeyText('Cœur'), albumKeyText('Coeur'));
      expect(albumKeyText('Straße'), albumKeyText('Strasse'));
      expect(albumKeyText('Øl'), albumKeyText('Ol'));
      expect(albumKeyText('Łódź'), albumKeyText('Lodz'));
    });

    test('titles that differ visibly stay different', () {
      expect(
        albumKeyText('Album A vol.1'),
        isNot(albumKeyText('Album A volume 1')),
      );
    });

    test('a symbol or digit leads like the sort key (BR-010, rule 7)', () {
      expect(albumKeyText('1984').compareTo(albumKeyText('Abba')), lessThan(0));
    });
  });
}
