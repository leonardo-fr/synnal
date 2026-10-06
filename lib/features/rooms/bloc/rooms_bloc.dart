import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:synnal/features/rooms/models/room.dart';
import 'package:synnal/features/rooms/repositories/rooms_repository.dart';

part 'rooms_event.dart';
part 'rooms_state.dart';

class RoomsBloc extends Bloc<RoomsEvent, RoomsState> {
  final RoomsRepository _roomsRepository;

  RoomsBloc(this._roomsRepository) : super(RoomsInicial()) {
    on<RoomsCarregadas>(_onRoomsCarregadas);
    on<RoomSelecionada>(_onRoomSelecionada);
  }

  FutureOr<void> _onRoomsCarregadas(
    RoomsCarregadas event,
    Emitter<RoomsState> emit,
  ) async {
    emit(
      RoomsCarregarEmProgresso.fromLastState(
        state,
        userId: event.userId,
        deviceId: event.deviceId,
        displayName: event.displayName,
      ),
    );

    try {
      final rooms = await _roomsRepository.listarSalas();

      emit(
        RoomsCarregarSucesso.fromLastState(
          state,
          rooms: rooms,
          userId: event.userId,
          deviceId: event.deviceId,
          displayName: event.displayName,
        ),
      );
    } catch (error, stackTrace) {
      addError(error, stackTrace);

      emit(RoomsCarregarFalha.fromLastState(state));
    }
  }

  void _onRoomSelecionada(RoomSelecionada event, Emitter<RoomsState> emit) {
    final roomExiste = state.rooms.any((room) => room.id == event.roomId);

    if (!roomExiste) {
      return;
    }

    emit(
      RoomSelecionarSucesso.fromLastState(state, selectedRoomId: event.roomId),
    );
  }
}
