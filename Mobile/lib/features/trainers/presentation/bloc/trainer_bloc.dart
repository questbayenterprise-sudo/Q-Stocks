import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/trainer.dart';

abstract class TrainerEvent {}

class LoadTrainers extends TrainerEvent {}

abstract class TrainerState {}

class TrainerLoading extends TrainerState {}

class TrainerLoaded extends TrainerState {
  final List<TrainerEntity> trainers;
  TrainerLoaded(this.trainers);
}

class TrainerBloc extends Bloc<TrainerEvent, TrainerState> {
  TrainerBloc() : super(TrainerLoading()) {
    on<LoadTrainers>((event, emit) async {
      emit(TrainerLoading());
      await Future.delayed(const Duration(milliseconds: 500));
      emit(
        TrainerLoaded([
          TrainerEntity(
            id: '1',
            name: 'Gayathri Gopinath',
            imageUrl:
                'https://via.placeholder.com/300', // Replace with actual image
            location: 'Thanjavur, Thanjav...',
            targetGroups: ['Adults', 'Kids'],
          ),
        ]),
      );
    });
  }
}
