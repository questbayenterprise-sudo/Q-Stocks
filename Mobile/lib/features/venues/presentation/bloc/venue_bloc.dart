import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/venue.dart';
import '../../data/repositories/venue_repository.dart';

abstract class VenueEvent {}

class LoadVenues extends VenueEvent {
  final double? latitude;
  final double? longitude;
  final int? cityId;
  LoadVenues({this.latitude, this.longitude, this.cityId});
}

class AddVenue extends VenueEvent {
  final VenueEntity venue;
  AddVenue(this.venue);
}

class DeleteVenue extends VenueEvent {
  final String id;
  DeleteVenue(this.id);
}

// --- States ---
abstract class VenueState {}

class VenueInitial extends VenueState {}

class VenueLoading extends VenueState {}

class VenueSaving extends VenueState {}

class EditVenueRequested extends VenueEvent {
  final String id;
  EditVenueRequested(this.id);
}

class VenueLoaded extends VenueState {
  final List<VenueEntity> venues;
  final bool isSuccess;
  final String message;

  VenueLoaded(this.venues, {this.isSuccess = false, this.message = ""});
}

class VenueError extends VenueState {
  final String message;
  VenueError(this.message);
}

class VenueBloc extends Bloc<VenueEvent, VenueState> {
  final VenueRepository repository;

  VenueBloc(this.repository) : super(VenueInitial()) {
    on<DeleteVenue>((event, emit) async {
      try {
        await repository.deleteVenue(event.id);
        final venues = await repository.fetchVenues();
        emit(
          VenueLoaded(
            venues,
            isSuccess: true,
            message: "Venue deleted successfully!",
          ),
        );
      } catch (e) {
        emit(VenueError("Delete failed: ${e.toString()}"));
      }
    });
    on<LoadVenues>((event, emit) async {
      emit(VenueLoading());
      try {
        final venues = await repository.fetchVenues(
          latitude: event.latitude,
          longitude: event.longitude,
          cityId: event.cityId,
        );
        emit(VenueLoaded(venues));
      } catch (e) {
        emit(VenueError("Check server connection"));
      }
    });

    on<AddVenue>((event, emit) async {
      emit(VenueSaving()); // Triggers TurfLoader overlay
      try {
        await repository.saveVenueToServer(event.venue);

        final updatedVenues = await repository.fetchVenues();

        emit(VenueLoaded(updatedVenues, isSuccess: true));
      } catch (e) {
        emit(VenueError(e.toString()));
      }
    });
    on<EditVenueRequested>((event, emit) async {
      emit(VenueSaving());
      try {
        final venue = await repository.fetchVenueById(event.id);

        emit(VenueLoaded([venue], isSuccess: false));
      } catch (e) {
        emit(VenueError("Could not load venue details"));
      }
    });
  }
}
