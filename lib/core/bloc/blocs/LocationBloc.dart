//import 'package:flutter/material.dart';
//import 'package:flutter_bloc/flutter_bloc.dart';
//import 'package:gsot_timekeeping/core/bloc/events/LocationEvent.dart';
//import 'package:gsot_timekeeping/core/bloc/states/LocationState.dart';
//import 'package:geolocator/geolocator.dart' as geo;
//
//class LocationBloc extends Bloc<LocationEvent, LocationState> {
//  @override
//  LocationState get initialState => LocationInitialState();
//
//  @override
//  Stream<LocationState> mapEventToState(LocationEvent event) async* {
//    if (event is LoadLocationGetCurrentEvent) {
//      geo.Geolocator()
//        ..getCurrentPosition(
//          desiredAccuracy: geo.LocationAccuracy.best,
//        ).then((position) async* {
//          print('get location done: $position');
//          yield LocationGetCurrentState(currentPosition: position);
//        }).catchError((e) {
//          debugPrint(e);
//        });
//    }
//  }
//}
