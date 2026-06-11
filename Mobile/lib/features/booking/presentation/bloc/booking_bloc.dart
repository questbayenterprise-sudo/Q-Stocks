import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/booking_info.dart';
import '../../domain/repositories/i_booking_repository.dart';

abstract class BookingEvent {}

class SubmitBookingForm extends BookingEvent {
  final BookingInfo info;
  SubmitBookingForm(this.info);
}

abstract class BookingState {}

class BookingInitial extends BookingState {}

class BookingLoading extends BookingState {}

class BookingSuccess extends BookingState {}

class BookingError extends BookingState {
  final String message;
  BookingError(this.message);
}

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final IBookingRepository repository;

  BookingBloc(this.repository) : super(BookingInitial()) {
    on<SubmitBookingForm>((event, emit) async {
      emit(BookingLoading());
      try {
        // await repository.submitBooking(event.info);
        emit(BookingSuccess());
      } catch (e) {
        emit(BookingError(e.toString()));
      }
    });
  }
}
