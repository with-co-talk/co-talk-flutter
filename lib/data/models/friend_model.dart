import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/friend.dart';
import 'user_model.dart';

part 'friend_model.g.dart';

@JsonSerializable()
class FriendModel {
  final int id;
  final UserModel user;
  final DateTime createdAt;
  final bool isHidden;

  const FriendModel({
    required this.id,
    required this.user,
    required this.createdAt,
    this.isHidden = false,
  });

  factory FriendModel.fromJson(Map<String, dynamic> json) =>
      _$FriendModelFromJson(json);

  Map<String, dynamic> toJson() => _$FriendModelToJson(this);

  Friend toEntity() {
    return Friend(
      id: id,
      user: user.toEntity(),
      createdAt: createdAt,
      isHidden: isHidden,
    );
  }
}

@JsonSerializable()
class FriendRequestModel {
  final int id;
  final UserModel requester;
  final UserModel receiver;
  final String? status;
  final DateTime createdAt;

  const FriendRequestModel({
    required this.id,
    required this.requester,
    required this.receiver,
    this.status,
    required this.createdAt,
  });

  factory FriendRequestModel.fromJson(Map<String, dynamic> json) =>
      _$FriendRequestModelFromJson(json);

  Map<String, dynamic> toJson() => _$FriendRequestModelToJson(this);

  FriendRequest toEntity() {
    return FriendRequest(
      id: id,
      requester: requester.toEntity(),
      receiver: receiver.toEntity(),
      status: _parseStatus(status),
      createdAt: createdAt,
    );
  }

  static FriendRequestStatus _parseStatus(String? value) {
    switch (value?.toUpperCase()) {
      case 'ACCEPTED':
        return FriendRequestStatus.accepted;
      case 'REJECTED':
        return FriendRequestStatus.rejected;
      default:
        return FriendRequestStatus.pending;
    }
  }
}

@JsonSerializable()
class SendFriendRequestRequest {
  final int requesterId;
  final int receiverId;

  const SendFriendRequestRequest({
    required this.requesterId,
    required this.receiverId,
  });

  factory SendFriendRequestRequest.fromJson(Map<String, dynamic> json) =>
      _$SendFriendRequestRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SendFriendRequestRequestToJson(this);
}

@JsonSerializable()
class FriendListResponse {
  final List<FriendModel> friends;

  const FriendListResponse({required this.friends});

  factory FriendListResponse.fromJson(Map<String, dynamic> json) =>
      _$FriendListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FriendListResponseToJson(this);
}
