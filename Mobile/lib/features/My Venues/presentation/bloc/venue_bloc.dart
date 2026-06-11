import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/venue.dart';
import '../../data/repositories/venue_repository.dart';

// --- Events ---
abstract class MyVenueEvent {}

class LoadMyVenues extends MyVenueEvent {}

class AddMyVenue extends MyVenueEvent {
  final MyVenueEntity venue;
  AddMyVenue(this.venue);
}

class DeleteMyVenue extends MyVenueEvent {
  final String id;
  DeleteMyVenue(this.id);
}

class EditMyVenueRequested extends MyVenueEvent {
  final String id;
  EditMyVenueRequested(this.id);
}

// --- States ---
abstract class MyVenueState {}

class MyVenueInitial extends MyVenueState {}

class MyVenueLoading extends MyVenueState {}

class MyVenueSaving extends MyVenueState {}

class MyVenueLoaded extends MyVenueState {
  final List<MyVenueEntity> venues;
  final bool isSuccess;
  final String message;

  MyVenueLoaded(this.venues, {this.isSuccess = false, this.message = ""});
}

class MyVenueError extends MyVenueState {
  final String message;
  MyVenueError(this.message);
}

class MyVenueBloc extends Bloc<MyVenueEvent, MyVenueState> {
  final MyVenueRepository repository;

  MyVenueBloc(this.repository) : super(MyVenueInitial()) {
    on<DeleteMyVenue>((event, emit) async {
      try {
        await repository.deleteVenue(event.id);
        final venues = await repository.fetchVenues();
        emit(MyVenueLoaded(
          venues,
          isSuccess: true,
          message: "Venue deleted successfully!",
        ));
      } catch (e) {
        emit(MyVenueError("Delete failed: ${e.toString()}"));
      }
    });

    on<LoadMyVenues>((event, emit) async {
      emit(MyVenueLoading());
      try {
        final venues = await repository.fetchVenues();
        emit(MyVenueLoaded(venues));
      } catch (e) {
        emit(MyVenueError("Check server connection"));
      }
    });

    on<AddMyVenue>((event, emit) async {
      emit(MyVenueSaving());
      try {
        await repository.saveVenueToServer(event.venue);
        final updatedVenues = await repository.fetchVenues();
        emit(MyVenueLoaded(updatedVenues, isSuccess: true));
      } catch (e) {
        emit(MyVenueError(e.toString()));
      }
    });

    on<EditMyVenueRequested>((event, emit) async {
      emit(MyVenueSaving());
      try {
        final venue = await repository.fetchVenueById(event.id);
        emit(MyVenueLoaded([venue], isSuccess: false));
      } catch (e) {
        emit(MyVenueError("Could not load venue details"));
      }
    });
  }
}
