import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:synnal/features/rooms/models/room.dart';
import 'package:synnal/features/rooms/models/rooms_snapshots.dart';
import 'package:synnal/features/rooms/repositories/rooms_repository.dart';

part 'rooms_event.dart';
part 'rooms_state.dart';

class RoomsBloc extends Bloc<RoomsEvent, RoomsState> {
  final RoomsRepository _roomsRepository;

  StreamSubscription<RoomsSnapshot>? _roomsSubscription;

  RoomsBloc(this._roomsRepository) : super(RoomsInicial()) {
    on<RoomsCarregadas>(_onRoomsCarregadas);
    on<RoomSelecionada>(_onRoomSelecionada);
    on<RoomCriada>(_onRoomCriada);
    on<RoomConviteAceito>(_onRoomConviteAceito);
    on<RoomApagada>(_onRoomApagada);
    on<RoomsLimpas>(_onRoomsLimpas);
    on<RoomsAtualizadas>(_onRoomsAtualizadas);
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
      final snapshot = await _roomsRepository.listarSalas();

      emit(
        RoomsCarregarSucesso.fromLastState(
          state,
          rooms: snapshot.rooms,
          invitedRooms: snapshot.invitedRooms,
          userId: event.userId,
          deviceId: event.deviceId,
          displayName: event.displayName,
        ),
      );

      await _iniciarMonitoramento();
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

  FutureOr<void> _onRoomCriada(
    RoomCriada event,
    Emitter<RoomsState> emit,
  ) async {
    emit(RoomCriarEmProgresso.fromLastState(state));

    try {
      final room = await _roomsRepository.criarSalaPrivada(
        name: event.name,
        invitedUserIds: event.invitedUserIds,
      );

      final rooms = [...state.rooms, room];

      emit(
        RoomCriarSucesso.fromLastState(
          state,
          rooms: rooms,
          selectedRoomId: room.id,
        ),
      );
    } catch (error, stackTrace) {
      addError(error, stackTrace);

      emit(RoomCriarFalha.fromLastState(state));
    }
  }

  Future<void> _onRoomConviteAceito(
    RoomConviteAceito event,
    Emitter<RoomsState> emit,
  ) async {
    emit(RoomConviteAceitarEmProgresso.fromLastState(state));

    try {
      final room = await _roomsRepository.aceitarConvite(event.roomId);

      emit(
        RoomConviteAceitarSucesso.fromLastState(
          state,
          rooms: [...state.rooms, room],
          invitedRooms: state.invitedRooms
              .where((item) => item.id != event.roomId)
              .toList(),
          selectedRoomId: room.id,
        ),
      );
    } catch (error, stackTrace) {
      addError(error, stackTrace);

      emit(RoomConviteAceitarFalha.fromLastState(state));
    }
  }

  Future<void> _onRoomApagada(
    RoomApagada event,
    Emitter<RoomsState> emit,
  ) async {
    emit(RoomApagarEmProgresso.fromLastState(state));

    try {
      await _roomsRepository.apagarSala(event.roomId);

      final rooms = state.rooms
          .where((room) => room.id != event.roomId)
          .toList();

      final invitedRooms = state.invitedRooms
          .where((room) => room.id != event.roomId)
          .toList();

      final apagouSelecionada = state.selectedRoomId == event.roomId;

      emit(
        RoomApagarSucesso.fromLastState(
          state,
          rooms: rooms,
          invitedRooms: invitedRooms,
          limparSelecao: apagouSelecionada,
        ),
      );
    } catch (error, stackTrace) {
      addError(error, stackTrace);

      emit(RoomApagarFalha.fromLastState(state));
    }
  }

  Future<void> _onRoomsLimpas(
    RoomsLimpas event,
    Emitter<RoomsState> emit,
  ) async {
    emit(RoomsLimparEmProgresso.fromLastState(state));

    try {
      await _roomsRepository.limparSalas();

      emit(
        RoomsLimparSucesso.fromLastState(
          state,
          rooms: const [],
          invitedRooms: const [],
          limparSelecao: true,
        ),
      );
    } catch (error, stackTrace) {
      addError(error, stackTrace);

      emit(RoomsLimparFalha.fromLastState(state));
    }
  }

  void _onRoomsAtualizadas(RoomsAtualizadas event, Emitter<RoomsState> emit) {
    final selectedRoomId = state.selectedRoomId;

    final selectedRoomExiste =
        selectedRoomId != null &&
        event.snapshot.rooms.any((room) => room.id == selectedRoomId);

    emit(
      RoomsCarregarSucesso.fromLastState(
        state,
        rooms: event.snapshot.rooms,
        invitedRooms: event.snapshot.invitedRooms,

        userId: state.userId,
        deviceId: state.deviceId,
        displayName: state.displayName,

        limparSelecao: selectedRoomId != null && !selectedRoomExiste,
      ),
    );
  }

  Future<void> _iniciarMonitoramento() async {
    await _roomsSubscription?.cancel();

    _roomsSubscription = _roomsRepository.observarSalas().listen(
      (snapshot) {
        add(RoomsAtualizadas(snapshot));
      },
      onError: (Object error, StackTrace stackTrace) {
        addError(error, stackTrace);
      },
    );
  }

  @override
  Future<void> close() {
    _roomsSubscription?.cancel();
    return super.close();
  }
}
