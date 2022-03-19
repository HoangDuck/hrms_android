// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:location/location.dart';
//
// enum LocationEvent {
//   getCurrentPosition,
// }
//
// class LocationBloc extends Bloc<LocationEvent, Position> {
//
//   Location location = new Location();
//
//   @override
//   Position get initialState => Position();
//
//   @override
//   Stream<Position> mapEventToState(LocationEvent event) async* {
//     switch (event) {
//       case LocationEvent.getCurrentPosition:
//         LocationData currentPosition = await location.getLocation();
//         yield Position(latitude: currentPosition.latitude, longitude: currentPosition.longitude);
//         break;
//     }
//   }
// }
