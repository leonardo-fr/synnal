part of 'rooms_bloc.dart';

abstract class RoomsState {
  final List<Room> rooms;
  final String? selectedRoomId;

  final String? userId;
  final String? deviceId;
  final String? displayName;

  const RoomsState(
    this.rooms,
    this.selectedRoomId,
    this.userId,
    this.deviceId,
    this.displayName,
  );

  RoomsState.vazio()
    : rooms = const [],
      selectedRoomId = null,
      userId = null,
      deviceId = null,
      displayName = null;

  RoomsState.fromLastState(
    RoomsState lastState, {
    List<Room>? rooms,
    String? selectedRoomId,
    String? userId,
    String? deviceId,
    String? displayName,
    bool limparSelecao = false,
  }) : rooms = rooms ?? lastState.rooms,
       selectedRoomId = limparSelecao
           ? null
           : selectedRoomId ?? lastState.selectedRoomId,
       userId = userId ?? lastState.userId,
       deviceId = deviceId ?? lastState.deviceId,
       displayName = displayName ?? lastState.displayName;

  Room? get selectedRoom {
    final id = selectedRoomId;

    if (id == null) {
      return null;
    }

    for (final room in rooms) {
      if (room.id == id) {
        return room;
      }
    }

    return null;
  }
}

class RoomsInicial extends RoomsState {
  RoomsInicial() : super.vazio();
}

class RoomsCarregarEmProgresso extends RoomsState {
  RoomsCarregarEmProgresso.fromLastState(
    super.lastState, {
    super.userId,
    super.deviceId,
    super.displayName,
  }) : super.fromLastState();
}

class RoomsCarregarSucesso extends RoomsState {
  RoomsCarregarSucesso.fromLastState(
    super.lastState, {
    required super.rooms,
    required super.userId,
    required super.deviceId,
    required super.displayName,
  }) : super.fromLastState();
}

class RoomsCarregarFalha extends RoomsState {
  RoomsCarregarFalha.fromLastState(super.lastState) : super.fromLastState();
}

class RoomSelecionarSucesso extends RoomsState {
  RoomSelecionarSucesso.fromLastState(
    super.lastState, {
    required super.selectedRoomId,
  }) : super.fromLastState();
}

class RoomCriarEmProgresso extends RoomsState {
  RoomCriarEmProgresso.fromLastState(super.lastState) : super.fromLastState();
}

class RoomCriarFalha extends RoomsState {
  RoomCriarFalha.fromLastState(super.lastState) : super.fromLastState();
}

class RoomCriarSucesso extends RoomsState {
  RoomCriarSucesso.fromLastState(
    super.lastState, {
    required super.rooms,
    required super.selectedRoomId,
  }) : super.fromLastState();
}
