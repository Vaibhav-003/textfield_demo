// ignore_for_file: library_private_types_in_public_api

import 'package:mobx/mobx.dart';

part 'nominee_store.g.dart';

class Nominee {
  final String name;
  final String address;
  final String countryCode;
  final String mobileNumber;

  Nominee({
    this.name = '',
    this.address = '',
    this.countryCode = '+91',
    this.mobileNumber = '',
  });

  Nominee copyWith({
    String? name,
    String? address,
    String? countryCode,
    String? mobileNumber,
  }) {
    return Nominee(
      name: name ?? this.name,
      address: address ?? this.address,
      countryCode: countryCode ?? this.countryCode,
      mobileNumber: mobileNumber ?? this.mobileNumber,
    );
  }

  @override
  String toString() {
    return 'Nominee(name: $name, address: $address, countryCode: $countryCode, mobileNumber: $mobileNumber)';
  }
}

class NomineeStore = _NomineeStore with _$NomineeStore;

abstract class _NomineeStore with Store {
  @observable
  ObservableList<Nominee> nominees = ObservableList<Nominee>.of([
    Nominee(),
  ]);

  @action
  void addNominee() {
    if (nominees.length < 4) {
      nominees.add(Nominee());
    }
  }

  @action
  void removeNominee(int index) {
    if (nominees.length > 1) {
      nominees.removeAt(index);
    }
  }

  @action
  void updateNominee(
    int index, {
    String? name,
    String? address,
    String? countryCode,
    String? mobileNumber,
  }) {
    if (index >= 0 && index < nominees.length) {
      nominees[index] = nominees[index].copyWith(
        name: name,
        address: address,
        countryCode: countryCode,
        mobileNumber: mobileNumber,
      );
    }
  }
}
