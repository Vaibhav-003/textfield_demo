// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nominee_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$NomineeStore on _NomineeStore, Store {
  late final _$nomineesAtom = Atom(
    name: '_NomineeStore.nominees',
    context: context,
  );

  @override
  ObservableList<Nominee> get nominees {
    _$nomineesAtom.reportRead();
    return super.nominees;
  }

  @override
  set nominees(ObservableList<Nominee> value) {
    _$nomineesAtom.reportWrite(value, super.nominees, () {
      super.nominees = value;
    });
  }

  late final _$_NomineeStoreActionController = ActionController(
    name: '_NomineeStore',
    context: context,
  );

  @override
  void addNominee() {
    final _$actionInfo = _$_NomineeStoreActionController.startAction(
      name: '_NomineeStore.addNominee',
    );
    try {
      return super.addNominee();
    } finally {
      _$_NomineeStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void removeNominee(int index) {
    final _$actionInfo = _$_NomineeStoreActionController.startAction(
      name: '_NomineeStore.removeNominee',
    );
    try {
      return super.removeNominee(index);
    } finally {
      _$_NomineeStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateNominee(
    int index, {
    String? name,
    String? address,
    String? countryCode,
    String? mobileNumber,
  }) {
    final _$actionInfo = _$_NomineeStoreActionController.startAction(
      name: '_NomineeStore.updateNominee',
    );
    try {
      return super.updateNominee(
        index,
        name: name,
        address: address,
        countryCode: countryCode,
        mobileNumber: mobileNumber,
      );
    } finally {
      _$_NomineeStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
nominees: ${nominees}
    ''';
  }
}
