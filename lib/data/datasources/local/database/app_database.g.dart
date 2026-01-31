// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ChatRoomsTable extends ChatRooms
    with TableInfo<$ChatRoomsTable, ChatRoom> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatRoomsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('DIRECT'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastMessageMeta = const VerificationMeta(
    'lastMessage',
  );
  @override
  late final GeneratedColumn<String> lastMessage = GeneratedColumn<String>(
    'last_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastMessageTypeMeta = const VerificationMeta(
    'lastMessageType',
  );
  @override
  late final GeneratedColumn<String> lastMessageType = GeneratedColumn<String>(
    'last_message_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastMessageAtMeta = const VerificationMeta(
    'lastMessageAt',
  );
  @override
  late final GeneratedColumn<int> lastMessageAt = GeneratedColumn<int>(
    'last_message_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unreadCountMeta = const VerificationMeta(
    'unreadCount',
  );
  @override
  late final GeneratedColumn<int> unreadCount = GeneratedColumn<int>(
    'unread_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _otherUserIdMeta = const VerificationMeta(
    'otherUserId',
  );
  @override
  late final GeneratedColumn<int> otherUserId = GeneratedColumn<int>(
    'other_user_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _otherUserNicknameMeta = const VerificationMeta(
    'otherUserNickname',
  );
  @override
  late final GeneratedColumn<String> otherUserNickname =
      GeneratedColumn<String>(
        'other_user_nickname',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _otherUserAvatarUrlMeta =
      const VerificationMeta('otherUserAvatarUrl');
  @override
  late final GeneratedColumn<String> otherUserAvatarUrl =
      GeneratedColumn<String>(
        'other_user_avatar_url',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _isOtherUserLeftMeta = const VerificationMeta(
    'isOtherUserLeft',
  );
  @override
  late final GeneratedColumn<bool> isOtherUserLeft = GeneratedColumn<bool>(
    'is_other_user_left',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_other_user_left" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isOtherUserOnlineMeta = const VerificationMeta(
    'isOtherUserOnline',
  );
  @override
  late final GeneratedColumn<bool> isOtherUserOnline = GeneratedColumn<bool>(
    'is_other_user_online',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_other_user_online" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _otherUserLastActiveAtMeta =
      const VerificationMeta('otherUserLastActiveAt');
  @override
  late final GeneratedColumn<int> otherUserLastActiveAt = GeneratedColumn<int>(
    'other_user_last_active_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSyncAtMeta = const VerificationMeta(
    'lastSyncAt',
  );
  @override
  late final GeneratedColumn<int> lastSyncAt = GeneratedColumn<int>(
    'last_sync_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    type,
    createdAt,
    lastMessage,
    lastMessageType,
    lastMessageAt,
    unreadCount,
    otherUserId,
    otherUserNickname,
    otherUserAvatarUrl,
    isOtherUserLeft,
    isOtherUserOnline,
    otherUserLastActiveAt,
    lastSyncAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chat_rooms';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChatRoom> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_message')) {
      context.handle(
        _lastMessageMeta,
        lastMessage.isAcceptableOrUnknown(
          data['last_message']!,
          _lastMessageMeta,
        ),
      );
    }
    if (data.containsKey('last_message_type')) {
      context.handle(
        _lastMessageTypeMeta,
        lastMessageType.isAcceptableOrUnknown(
          data['last_message_type']!,
          _lastMessageTypeMeta,
        ),
      );
    }
    if (data.containsKey('last_message_at')) {
      context.handle(
        _lastMessageAtMeta,
        lastMessageAt.isAcceptableOrUnknown(
          data['last_message_at']!,
          _lastMessageAtMeta,
        ),
      );
    }
    if (data.containsKey('unread_count')) {
      context.handle(
        _unreadCountMeta,
        unreadCount.isAcceptableOrUnknown(
          data['unread_count']!,
          _unreadCountMeta,
        ),
      );
    }
    if (data.containsKey('other_user_id')) {
      context.handle(
        _otherUserIdMeta,
        otherUserId.isAcceptableOrUnknown(
          data['other_user_id']!,
          _otherUserIdMeta,
        ),
      );
    }
    if (data.containsKey('other_user_nickname')) {
      context.handle(
        _otherUserNicknameMeta,
        otherUserNickname.isAcceptableOrUnknown(
          data['other_user_nickname']!,
          _otherUserNicknameMeta,
        ),
      );
    }
    if (data.containsKey('other_user_avatar_url')) {
      context.handle(
        _otherUserAvatarUrlMeta,
        otherUserAvatarUrl.isAcceptableOrUnknown(
          data['other_user_avatar_url']!,
          _otherUserAvatarUrlMeta,
        ),
      );
    }
    if (data.containsKey('is_other_user_left')) {
      context.handle(
        _isOtherUserLeftMeta,
        isOtherUserLeft.isAcceptableOrUnknown(
          data['is_other_user_left']!,
          _isOtherUserLeftMeta,
        ),
      );
    }
    if (data.containsKey('is_other_user_online')) {
      context.handle(
        _isOtherUserOnlineMeta,
        isOtherUserOnline.isAcceptableOrUnknown(
          data['is_other_user_online']!,
          _isOtherUserOnlineMeta,
        ),
      );
    }
    if (data.containsKey('other_user_last_active_at')) {
      context.handle(
        _otherUserLastActiveAtMeta,
        otherUserLastActiveAt.isAcceptableOrUnknown(
          data['other_user_last_active_at']!,
          _otherUserLastActiveAtMeta,
        ),
      );
    }
    if (data.containsKey('last_sync_at')) {
      context.handle(
        _lastSyncAtMeta,
        lastSyncAt.isAcceptableOrUnknown(
          data['last_sync_at']!,
          _lastSyncAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChatRoom map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChatRoom(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      lastMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_message'],
      ),
      lastMessageType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_message_type'],
      ),
      lastMessageAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_message_at'],
      ),
      unreadCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unread_count'],
      )!,
      otherUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}other_user_id'],
      ),
      otherUserNickname: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}other_user_nickname'],
      ),
      otherUserAvatarUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}other_user_avatar_url'],
      ),
      isOtherUserLeft: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_other_user_left'],
      )!,
      isOtherUserOnline: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_other_user_online'],
      )!,
      otherUserLastActiveAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}other_user_last_active_at'],
      ),
      lastSyncAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_sync_at'],
      ),
    );
  }

  @override
  $ChatRoomsTable createAlias(String alias) {
    return $ChatRoomsTable(attachedDatabase, alias);
  }
}

class ChatRoom extends DataClass implements Insertable<ChatRoom> {
  final int id;
  final String? name;
  final String type;
  final int createdAt;
  final String? lastMessage;
  final String? lastMessageType;
  final int? lastMessageAt;
  final int unreadCount;
  final int? otherUserId;
  final String? otherUserNickname;
  final String? otherUserAvatarUrl;
  final bool isOtherUserLeft;
  final bool isOtherUserOnline;
  final int? otherUserLastActiveAt;
  final int? lastSyncAt;
  const ChatRoom({
    required this.id,
    this.name,
    required this.type,
    required this.createdAt,
    this.lastMessage,
    this.lastMessageType,
    this.lastMessageAt,
    required this.unreadCount,
    this.otherUserId,
    this.otherUserNickname,
    this.otherUserAvatarUrl,
    required this.isOtherUserLeft,
    required this.isOtherUserOnline,
    this.otherUserLastActiveAt,
    this.lastSyncAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    map['type'] = Variable<String>(type);
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || lastMessage != null) {
      map['last_message'] = Variable<String>(lastMessage);
    }
    if (!nullToAbsent || lastMessageType != null) {
      map['last_message_type'] = Variable<String>(lastMessageType);
    }
    if (!nullToAbsent || lastMessageAt != null) {
      map['last_message_at'] = Variable<int>(lastMessageAt);
    }
    map['unread_count'] = Variable<int>(unreadCount);
    if (!nullToAbsent || otherUserId != null) {
      map['other_user_id'] = Variable<int>(otherUserId);
    }
    if (!nullToAbsent || otherUserNickname != null) {
      map['other_user_nickname'] = Variable<String>(otherUserNickname);
    }
    if (!nullToAbsent || otherUserAvatarUrl != null) {
      map['other_user_avatar_url'] = Variable<String>(otherUserAvatarUrl);
    }
    map['is_other_user_left'] = Variable<bool>(isOtherUserLeft);
    map['is_other_user_online'] = Variable<bool>(isOtherUserOnline);
    if (!nullToAbsent || otherUserLastActiveAt != null) {
      map['other_user_last_active_at'] = Variable<int>(otherUserLastActiveAt);
    }
    if (!nullToAbsent || lastSyncAt != null) {
      map['last_sync_at'] = Variable<int>(lastSyncAt);
    }
    return map;
  }

  ChatRoomsCompanion toCompanion(bool nullToAbsent) {
    return ChatRoomsCompanion(
      id: Value(id),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      type: Value(type),
      createdAt: Value(createdAt),
      lastMessage: lastMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessage),
      lastMessageType: lastMessageType == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessageType),
      lastMessageAt: lastMessageAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessageAt),
      unreadCount: Value(unreadCount),
      otherUserId: otherUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(otherUserId),
      otherUserNickname: otherUserNickname == null && nullToAbsent
          ? const Value.absent()
          : Value(otherUserNickname),
      otherUserAvatarUrl: otherUserAvatarUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(otherUserAvatarUrl),
      isOtherUserLeft: Value(isOtherUserLeft),
      isOtherUserOnline: Value(isOtherUserOnline),
      otherUserLastActiveAt: otherUserLastActiveAt == null && nullToAbsent
          ? const Value.absent()
          : Value(otherUserLastActiveAt),
      lastSyncAt: lastSyncAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAt),
    );
  }

  factory ChatRoom.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChatRoom(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String?>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      lastMessage: serializer.fromJson<String?>(json['lastMessage']),
      lastMessageType: serializer.fromJson<String?>(json['lastMessageType']),
      lastMessageAt: serializer.fromJson<int?>(json['lastMessageAt']),
      unreadCount: serializer.fromJson<int>(json['unreadCount']),
      otherUserId: serializer.fromJson<int?>(json['otherUserId']),
      otherUserNickname: serializer.fromJson<String?>(
        json['otherUserNickname'],
      ),
      otherUserAvatarUrl: serializer.fromJson<String?>(
        json['otherUserAvatarUrl'],
      ),
      isOtherUserLeft: serializer.fromJson<bool>(json['isOtherUserLeft']),
      isOtherUserOnline: serializer.fromJson<bool>(json['isOtherUserOnline']),
      otherUserLastActiveAt: serializer.fromJson<int?>(
        json['otherUserLastActiveAt'],
      ),
      lastSyncAt: serializer.fromJson<int?>(json['lastSyncAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String?>(name),
      'type': serializer.toJson<String>(type),
      'createdAt': serializer.toJson<int>(createdAt),
      'lastMessage': serializer.toJson<String?>(lastMessage),
      'lastMessageType': serializer.toJson<String?>(lastMessageType),
      'lastMessageAt': serializer.toJson<int?>(lastMessageAt),
      'unreadCount': serializer.toJson<int>(unreadCount),
      'otherUserId': serializer.toJson<int?>(otherUserId),
      'otherUserNickname': serializer.toJson<String?>(otherUserNickname),
      'otherUserAvatarUrl': serializer.toJson<String?>(otherUserAvatarUrl),
      'isOtherUserLeft': serializer.toJson<bool>(isOtherUserLeft),
      'isOtherUserOnline': serializer.toJson<bool>(isOtherUserOnline),
      'otherUserLastActiveAt': serializer.toJson<int?>(otherUserLastActiveAt),
      'lastSyncAt': serializer.toJson<int?>(lastSyncAt),
    };
  }

  ChatRoom copyWith({
    int? id,
    Value<String?> name = const Value.absent(),
    String? type,
    int? createdAt,
    Value<String?> lastMessage = const Value.absent(),
    Value<String?> lastMessageType = const Value.absent(),
    Value<int?> lastMessageAt = const Value.absent(),
    int? unreadCount,
    Value<int?> otherUserId = const Value.absent(),
    Value<String?> otherUserNickname = const Value.absent(),
    Value<String?> otherUserAvatarUrl = const Value.absent(),
    bool? isOtherUserLeft,
    bool? isOtherUserOnline,
    Value<int?> otherUserLastActiveAt = const Value.absent(),
    Value<int?> lastSyncAt = const Value.absent(),
  }) => ChatRoom(
    id: id ?? this.id,
    name: name.present ? name.value : this.name,
    type: type ?? this.type,
    createdAt: createdAt ?? this.createdAt,
    lastMessage: lastMessage.present ? lastMessage.value : this.lastMessage,
    lastMessageType: lastMessageType.present
        ? lastMessageType.value
        : this.lastMessageType,
    lastMessageAt: lastMessageAt.present
        ? lastMessageAt.value
        : this.lastMessageAt,
    unreadCount: unreadCount ?? this.unreadCount,
    otherUserId: otherUserId.present ? otherUserId.value : this.otherUserId,
    otherUserNickname: otherUserNickname.present
        ? otherUserNickname.value
        : this.otherUserNickname,
    otherUserAvatarUrl: otherUserAvatarUrl.present
        ? otherUserAvatarUrl.value
        : this.otherUserAvatarUrl,
    isOtherUserLeft: isOtherUserLeft ?? this.isOtherUserLeft,
    isOtherUserOnline: isOtherUserOnline ?? this.isOtherUserOnline,
    otherUserLastActiveAt: otherUserLastActiveAt.present
        ? otherUserLastActiveAt.value
        : this.otherUserLastActiveAt,
    lastSyncAt: lastSyncAt.present ? lastSyncAt.value : this.lastSyncAt,
  );
  ChatRoom copyWithCompanion(ChatRoomsCompanion data) {
    return ChatRoom(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastMessage: data.lastMessage.present
          ? data.lastMessage.value
          : this.lastMessage,
      lastMessageType: data.lastMessageType.present
          ? data.lastMessageType.value
          : this.lastMessageType,
      lastMessageAt: data.lastMessageAt.present
          ? data.lastMessageAt.value
          : this.lastMessageAt,
      unreadCount: data.unreadCount.present
          ? data.unreadCount.value
          : this.unreadCount,
      otherUserId: data.otherUserId.present
          ? data.otherUserId.value
          : this.otherUserId,
      otherUserNickname: data.otherUserNickname.present
          ? data.otherUserNickname.value
          : this.otherUserNickname,
      otherUserAvatarUrl: data.otherUserAvatarUrl.present
          ? data.otherUserAvatarUrl.value
          : this.otherUserAvatarUrl,
      isOtherUserLeft: data.isOtherUserLeft.present
          ? data.isOtherUserLeft.value
          : this.isOtherUserLeft,
      isOtherUserOnline: data.isOtherUserOnline.present
          ? data.isOtherUserOnline.value
          : this.isOtherUserOnline,
      otherUserLastActiveAt: data.otherUserLastActiveAt.present
          ? data.otherUserLastActiveAt.value
          : this.otherUserLastActiveAt,
      lastSyncAt: data.lastSyncAt.present
          ? data.lastSyncAt.value
          : this.lastSyncAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChatRoom(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastMessage: $lastMessage, ')
          ..write('lastMessageType: $lastMessageType, ')
          ..write('lastMessageAt: $lastMessageAt, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('otherUserId: $otherUserId, ')
          ..write('otherUserNickname: $otherUserNickname, ')
          ..write('otherUserAvatarUrl: $otherUserAvatarUrl, ')
          ..write('isOtherUserLeft: $isOtherUserLeft, ')
          ..write('isOtherUserOnline: $isOtherUserOnline, ')
          ..write('otherUserLastActiveAt: $otherUserLastActiveAt, ')
          ..write('lastSyncAt: $lastSyncAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    type,
    createdAt,
    lastMessage,
    lastMessageType,
    lastMessageAt,
    unreadCount,
    otherUserId,
    otherUserNickname,
    otherUserAvatarUrl,
    isOtherUserLeft,
    isOtherUserOnline,
    otherUserLastActiveAt,
    lastSyncAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatRoom &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.createdAt == this.createdAt &&
          other.lastMessage == this.lastMessage &&
          other.lastMessageType == this.lastMessageType &&
          other.lastMessageAt == this.lastMessageAt &&
          other.unreadCount == this.unreadCount &&
          other.otherUserId == this.otherUserId &&
          other.otherUserNickname == this.otherUserNickname &&
          other.otherUserAvatarUrl == this.otherUserAvatarUrl &&
          other.isOtherUserLeft == this.isOtherUserLeft &&
          other.isOtherUserOnline == this.isOtherUserOnline &&
          other.otherUserLastActiveAt == this.otherUserLastActiveAt &&
          other.lastSyncAt == this.lastSyncAt);
}

class ChatRoomsCompanion extends UpdateCompanion<ChatRoom> {
  final Value<int> id;
  final Value<String?> name;
  final Value<String> type;
  final Value<int> createdAt;
  final Value<String?> lastMessage;
  final Value<String?> lastMessageType;
  final Value<int?> lastMessageAt;
  final Value<int> unreadCount;
  final Value<int?> otherUserId;
  final Value<String?> otherUserNickname;
  final Value<String?> otherUserAvatarUrl;
  final Value<bool> isOtherUserLeft;
  final Value<bool> isOtherUserOnline;
  final Value<int?> otherUserLastActiveAt;
  final Value<int?> lastSyncAt;
  const ChatRoomsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastMessage = const Value.absent(),
    this.lastMessageType = const Value.absent(),
    this.lastMessageAt = const Value.absent(),
    this.unreadCount = const Value.absent(),
    this.otherUserId = const Value.absent(),
    this.otherUserNickname = const Value.absent(),
    this.otherUserAvatarUrl = const Value.absent(),
    this.isOtherUserLeft = const Value.absent(),
    this.isOtherUserOnline = const Value.absent(),
    this.otherUserLastActiveAt = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
  });
  ChatRoomsCompanion.insert({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    required int createdAt,
    this.lastMessage = const Value.absent(),
    this.lastMessageType = const Value.absent(),
    this.lastMessageAt = const Value.absent(),
    this.unreadCount = const Value.absent(),
    this.otherUserId = const Value.absent(),
    this.otherUserNickname = const Value.absent(),
    this.otherUserAvatarUrl = const Value.absent(),
    this.isOtherUserLeft = const Value.absent(),
    this.isOtherUserOnline = const Value.absent(),
    this.otherUserLastActiveAt = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
  }) : createdAt = Value(createdAt);
  static Insertable<ChatRoom> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<int>? createdAt,
    Expression<String>? lastMessage,
    Expression<String>? lastMessageType,
    Expression<int>? lastMessageAt,
    Expression<int>? unreadCount,
    Expression<int>? otherUserId,
    Expression<String>? otherUserNickname,
    Expression<String>? otherUserAvatarUrl,
    Expression<bool>? isOtherUserLeft,
    Expression<bool>? isOtherUserOnline,
    Expression<int>? otherUserLastActiveAt,
    Expression<int>? lastSyncAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (createdAt != null) 'created_at': createdAt,
      if (lastMessage != null) 'last_message': lastMessage,
      if (lastMessageType != null) 'last_message_type': lastMessageType,
      if (lastMessageAt != null) 'last_message_at': lastMessageAt,
      if (unreadCount != null) 'unread_count': unreadCount,
      if (otherUserId != null) 'other_user_id': otherUserId,
      if (otherUserNickname != null) 'other_user_nickname': otherUserNickname,
      if (otherUserAvatarUrl != null)
        'other_user_avatar_url': otherUserAvatarUrl,
      if (isOtherUserLeft != null) 'is_other_user_left': isOtherUserLeft,
      if (isOtherUserOnline != null) 'is_other_user_online': isOtherUserOnline,
      if (otherUserLastActiveAt != null)
        'other_user_last_active_at': otherUserLastActiveAt,
      if (lastSyncAt != null) 'last_sync_at': lastSyncAt,
    });
  }

  ChatRoomsCompanion copyWith({
    Value<int>? id,
    Value<String?>? name,
    Value<String>? type,
    Value<int>? createdAt,
    Value<String?>? lastMessage,
    Value<String?>? lastMessageType,
    Value<int?>? lastMessageAt,
    Value<int>? unreadCount,
    Value<int?>? otherUserId,
    Value<String?>? otherUserNickname,
    Value<String?>? otherUserAvatarUrl,
    Value<bool>? isOtherUserLeft,
    Value<bool>? isOtherUserOnline,
    Value<int?>? otherUserLastActiveAt,
    Value<int?>? lastSyncAt,
  }) {
    return ChatRoomsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageType: lastMessageType ?? this.lastMessageType,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      otherUserId: otherUserId ?? this.otherUserId,
      otherUserNickname: otherUserNickname ?? this.otherUserNickname,
      otherUserAvatarUrl: otherUserAvatarUrl ?? this.otherUserAvatarUrl,
      isOtherUserLeft: isOtherUserLeft ?? this.isOtherUserLeft,
      isOtherUserOnline: isOtherUserOnline ?? this.isOtherUserOnline,
      otherUserLastActiveAt:
          otherUserLastActiveAt ?? this.otherUserLastActiveAt,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (lastMessage.present) {
      map['last_message'] = Variable<String>(lastMessage.value);
    }
    if (lastMessageType.present) {
      map['last_message_type'] = Variable<String>(lastMessageType.value);
    }
    if (lastMessageAt.present) {
      map['last_message_at'] = Variable<int>(lastMessageAt.value);
    }
    if (unreadCount.present) {
      map['unread_count'] = Variable<int>(unreadCount.value);
    }
    if (otherUserId.present) {
      map['other_user_id'] = Variable<int>(otherUserId.value);
    }
    if (otherUserNickname.present) {
      map['other_user_nickname'] = Variable<String>(otherUserNickname.value);
    }
    if (otherUserAvatarUrl.present) {
      map['other_user_avatar_url'] = Variable<String>(otherUserAvatarUrl.value);
    }
    if (isOtherUserLeft.present) {
      map['is_other_user_left'] = Variable<bool>(isOtherUserLeft.value);
    }
    if (isOtherUserOnline.present) {
      map['is_other_user_online'] = Variable<bool>(isOtherUserOnline.value);
    }
    if (otherUserLastActiveAt.present) {
      map['other_user_last_active_at'] = Variable<int>(
        otherUserLastActiveAt.value,
      );
    }
    if (lastSyncAt.present) {
      map['last_sync_at'] = Variable<int>(lastSyncAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChatRoomsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastMessage: $lastMessage, ')
          ..write('lastMessageType: $lastMessageType, ')
          ..write('lastMessageAt: $lastMessageAt, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('otherUserId: $otherUserId, ')
          ..write('otherUserNickname: $otherUserNickname, ')
          ..write('otherUserAvatarUrl: $otherUserAvatarUrl, ')
          ..write('isOtherUserLeft: $isOtherUserLeft, ')
          ..write('isOtherUserOnline: $isOtherUserOnline, ')
          ..write('otherUserLastActiveAt: $otherUserLastActiveAt, ')
          ..write('lastSyncAt: $lastSyncAt')
          ..write(')'))
        .toString();
  }
}

class $MessagesTable extends Messages with TableInfo<$MessagesTable, Message> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _chatRoomIdMeta = const VerificationMeta(
    'chatRoomId',
  );
  @override
  late final GeneratedColumn<int> chatRoomId = GeneratedColumn<int>(
    'chat_room_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _senderIdMeta = const VerificationMeta(
    'senderId',
  );
  @override
  late final GeneratedColumn<int> senderId = GeneratedColumn<int>(
    'sender_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _senderNicknameMeta = const VerificationMeta(
    'senderNickname',
  );
  @override
  late final GeneratedColumn<String> senderNickname = GeneratedColumn<String>(
    'sender_nickname',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _senderAvatarUrlMeta = const VerificationMeta(
    'senderAvatarUrl',
  );
  @override
  late final GeneratedColumn<String> senderAvatarUrl = GeneratedColumn<String>(
    'sender_avatar_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('TEXT'),
  );
  static const VerificationMeta _fileUrlMeta = const VerificationMeta(
    'fileUrl',
  );
  @override
  late final GeneratedColumn<String> fileUrl = GeneratedColumn<String>(
    'file_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fileSizeMeta = const VerificationMeta(
    'fileSize',
  );
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
    'file_size',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fileContentTypeMeta = const VerificationMeta(
    'fileContentType',
  );
  @override
  late final GeneratedColumn<String> fileContentType = GeneratedColumn<String>(
    'file_content_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _thumbnailUrlMeta = const VerificationMeta(
    'thumbnailUrl',
  );
  @override
  late final GeneratedColumn<String> thumbnailUrl = GeneratedColumn<String>(
    'thumbnail_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _replyToMessageIdMeta = const VerificationMeta(
    'replyToMessageId',
  );
  @override
  late final GeneratedColumn<int> replyToMessageId = GeneratedColumn<int>(
    'reply_to_message_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _forwardedFromMessageIdMeta =
      const VerificationMeta('forwardedFromMessageId');
  @override
  late final GeneratedColumn<int> forwardedFromMessageId = GeneratedColumn<int>(
    'forwarded_from_message_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unreadCountMeta = const VerificationMeta(
    'unreadCount',
  );
  @override
  late final GeneratedColumn<int> unreadCount = GeneratedColumn<int>(
    'unread_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('synced'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    chatRoomId,
    senderId,
    senderNickname,
    senderAvatarUrl,
    content,
    type,
    fileUrl,
    fileName,
    fileSize,
    fileContentType,
    thumbnailUrl,
    replyToMessageId,
    forwardedFromMessageId,
    isDeleted,
    createdAt,
    updatedAt,
    unreadCount,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<Message> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('chat_room_id')) {
      context.handle(
        _chatRoomIdMeta,
        chatRoomId.isAcceptableOrUnknown(
          data['chat_room_id']!,
          _chatRoomIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_chatRoomIdMeta);
    }
    if (data.containsKey('sender_id')) {
      context.handle(
        _senderIdMeta,
        senderId.isAcceptableOrUnknown(data['sender_id']!, _senderIdMeta),
      );
    } else if (isInserting) {
      context.missing(_senderIdMeta);
    }
    if (data.containsKey('sender_nickname')) {
      context.handle(
        _senderNicknameMeta,
        senderNickname.isAcceptableOrUnknown(
          data['sender_nickname']!,
          _senderNicknameMeta,
        ),
      );
    }
    if (data.containsKey('sender_avatar_url')) {
      context.handle(
        _senderAvatarUrlMeta,
        senderAvatarUrl.isAcceptableOrUnknown(
          data['sender_avatar_url']!,
          _senderAvatarUrlMeta,
        ),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('file_url')) {
      context.handle(
        _fileUrlMeta,
        fileUrl.isAcceptableOrUnknown(data['file_url']!, _fileUrlMeta),
      );
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    }
    if (data.containsKey('file_size')) {
      context.handle(
        _fileSizeMeta,
        fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta),
      );
    }
    if (data.containsKey('file_content_type')) {
      context.handle(
        _fileContentTypeMeta,
        fileContentType.isAcceptableOrUnknown(
          data['file_content_type']!,
          _fileContentTypeMeta,
        ),
      );
    }
    if (data.containsKey('thumbnail_url')) {
      context.handle(
        _thumbnailUrlMeta,
        thumbnailUrl.isAcceptableOrUnknown(
          data['thumbnail_url']!,
          _thumbnailUrlMeta,
        ),
      );
    }
    if (data.containsKey('reply_to_message_id')) {
      context.handle(
        _replyToMessageIdMeta,
        replyToMessageId.isAcceptableOrUnknown(
          data['reply_to_message_id']!,
          _replyToMessageIdMeta,
        ),
      );
    }
    if (data.containsKey('forwarded_from_message_id')) {
      context.handle(
        _forwardedFromMessageIdMeta,
        forwardedFromMessageId.isAcceptableOrUnknown(
          data['forwarded_from_message_id']!,
          _forwardedFromMessageIdMeta,
        ),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('unread_count')) {
      context.handle(
        _unreadCountMeta,
        unreadCount.isAcceptableOrUnknown(
          data['unread_count']!,
          _unreadCountMeta,
        ),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Message map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Message(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      chatRoomId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chat_room_id'],
      )!,
      senderId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sender_id'],
      )!,
      senderNickname: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender_nickname'],
      ),
      senderAvatarUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender_avatar_url'],
      ),
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      fileUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_url'],
      ),
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      ),
      fileSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size'],
      ),
      fileContentType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_content_type'],
      ),
      thumbnailUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_url'],
      ),
      replyToMessageId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reply_to_message_id'],
      ),
      forwardedFromMessageId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}forwarded_from_message_id'],
      ),
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      ),
      unreadCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unread_count'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $MessagesTable createAlias(String alias) {
    return $MessagesTable(attachedDatabase, alias);
  }
}

class Message extends DataClass implements Insertable<Message> {
  final int id;
  final int chatRoomId;
  final int senderId;
  final String? senderNickname;
  final String? senderAvatarUrl;
  final String content;
  final String type;
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  final String? fileContentType;
  final String? thumbnailUrl;
  final int? replyToMessageId;
  final int? forwardedFromMessageId;
  final bool isDeleted;
  final int createdAt;
  final int? updatedAt;
  final int unreadCount;
  final String syncStatus;
  const Message({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    this.senderNickname,
    this.senderAvatarUrl,
    required this.content,
    required this.type,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.fileContentType,
    this.thumbnailUrl,
    this.replyToMessageId,
    this.forwardedFromMessageId,
    required this.isDeleted,
    required this.createdAt,
    this.updatedAt,
    required this.unreadCount,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['chat_room_id'] = Variable<int>(chatRoomId);
    map['sender_id'] = Variable<int>(senderId);
    if (!nullToAbsent || senderNickname != null) {
      map['sender_nickname'] = Variable<String>(senderNickname);
    }
    if (!nullToAbsent || senderAvatarUrl != null) {
      map['sender_avatar_url'] = Variable<String>(senderAvatarUrl);
    }
    map['content'] = Variable<String>(content);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || fileUrl != null) {
      map['file_url'] = Variable<String>(fileUrl);
    }
    if (!nullToAbsent || fileName != null) {
      map['file_name'] = Variable<String>(fileName);
    }
    if (!nullToAbsent || fileSize != null) {
      map['file_size'] = Variable<int>(fileSize);
    }
    if (!nullToAbsent || fileContentType != null) {
      map['file_content_type'] = Variable<String>(fileContentType);
    }
    if (!nullToAbsent || thumbnailUrl != null) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl);
    }
    if (!nullToAbsent || replyToMessageId != null) {
      map['reply_to_message_id'] = Variable<int>(replyToMessageId);
    }
    if (!nullToAbsent || forwardedFromMessageId != null) {
      map['forwarded_from_message_id'] = Variable<int>(forwardedFromMessageId);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<int>(updatedAt);
    }
    map['unread_count'] = Variable<int>(unreadCount);
    map['sync_status'] = Variable<String>(syncStatus);
    return map;
  }

  MessagesCompanion toCompanion(bool nullToAbsent) {
    return MessagesCompanion(
      id: Value(id),
      chatRoomId: Value(chatRoomId),
      senderId: Value(senderId),
      senderNickname: senderNickname == null && nullToAbsent
          ? const Value.absent()
          : Value(senderNickname),
      senderAvatarUrl: senderAvatarUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(senderAvatarUrl),
      content: Value(content),
      type: Value(type),
      fileUrl: fileUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(fileUrl),
      fileName: fileName == null && nullToAbsent
          ? const Value.absent()
          : Value(fileName),
      fileSize: fileSize == null && nullToAbsent
          ? const Value.absent()
          : Value(fileSize),
      fileContentType: fileContentType == null && nullToAbsent
          ? const Value.absent()
          : Value(fileContentType),
      thumbnailUrl: thumbnailUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailUrl),
      replyToMessageId: replyToMessageId == null && nullToAbsent
          ? const Value.absent()
          : Value(replyToMessageId),
      forwardedFromMessageId: forwardedFromMessageId == null && nullToAbsent
          ? const Value.absent()
          : Value(forwardedFromMessageId),
      isDeleted: Value(isDeleted),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      unreadCount: Value(unreadCount),
      syncStatus: Value(syncStatus),
    );
  }

  factory Message.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Message(
      id: serializer.fromJson<int>(json['id']),
      chatRoomId: serializer.fromJson<int>(json['chatRoomId']),
      senderId: serializer.fromJson<int>(json['senderId']),
      senderNickname: serializer.fromJson<String?>(json['senderNickname']),
      senderAvatarUrl: serializer.fromJson<String?>(json['senderAvatarUrl']),
      content: serializer.fromJson<String>(json['content']),
      type: serializer.fromJson<String>(json['type']),
      fileUrl: serializer.fromJson<String?>(json['fileUrl']),
      fileName: serializer.fromJson<String?>(json['fileName']),
      fileSize: serializer.fromJson<int?>(json['fileSize']),
      fileContentType: serializer.fromJson<String?>(json['fileContentType']),
      thumbnailUrl: serializer.fromJson<String?>(json['thumbnailUrl']),
      replyToMessageId: serializer.fromJson<int?>(json['replyToMessageId']),
      forwardedFromMessageId: serializer.fromJson<int?>(
        json['forwardedFromMessageId'],
      ),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int?>(json['updatedAt']),
      unreadCount: serializer.fromJson<int>(json['unreadCount']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'chatRoomId': serializer.toJson<int>(chatRoomId),
      'senderId': serializer.toJson<int>(senderId),
      'senderNickname': serializer.toJson<String?>(senderNickname),
      'senderAvatarUrl': serializer.toJson<String?>(senderAvatarUrl),
      'content': serializer.toJson<String>(content),
      'type': serializer.toJson<String>(type),
      'fileUrl': serializer.toJson<String?>(fileUrl),
      'fileName': serializer.toJson<String?>(fileName),
      'fileSize': serializer.toJson<int?>(fileSize),
      'fileContentType': serializer.toJson<String?>(fileContentType),
      'thumbnailUrl': serializer.toJson<String?>(thumbnailUrl),
      'replyToMessageId': serializer.toJson<int?>(replyToMessageId),
      'forwardedFromMessageId': serializer.toJson<int?>(forwardedFromMessageId),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int?>(updatedAt),
      'unreadCount': serializer.toJson<int>(unreadCount),
      'syncStatus': serializer.toJson<String>(syncStatus),
    };
  }

  Message copyWith({
    int? id,
    int? chatRoomId,
    int? senderId,
    Value<String?> senderNickname = const Value.absent(),
    Value<String?> senderAvatarUrl = const Value.absent(),
    String? content,
    String? type,
    Value<String?> fileUrl = const Value.absent(),
    Value<String?> fileName = const Value.absent(),
    Value<int?> fileSize = const Value.absent(),
    Value<String?> fileContentType = const Value.absent(),
    Value<String?> thumbnailUrl = const Value.absent(),
    Value<int?> replyToMessageId = const Value.absent(),
    Value<int?> forwardedFromMessageId = const Value.absent(),
    bool? isDeleted,
    int? createdAt,
    Value<int?> updatedAt = const Value.absent(),
    int? unreadCount,
    String? syncStatus,
  }) => Message(
    id: id ?? this.id,
    chatRoomId: chatRoomId ?? this.chatRoomId,
    senderId: senderId ?? this.senderId,
    senderNickname: senderNickname.present
        ? senderNickname.value
        : this.senderNickname,
    senderAvatarUrl: senderAvatarUrl.present
        ? senderAvatarUrl.value
        : this.senderAvatarUrl,
    content: content ?? this.content,
    type: type ?? this.type,
    fileUrl: fileUrl.present ? fileUrl.value : this.fileUrl,
    fileName: fileName.present ? fileName.value : this.fileName,
    fileSize: fileSize.present ? fileSize.value : this.fileSize,
    fileContentType: fileContentType.present
        ? fileContentType.value
        : this.fileContentType,
    thumbnailUrl: thumbnailUrl.present ? thumbnailUrl.value : this.thumbnailUrl,
    replyToMessageId: replyToMessageId.present
        ? replyToMessageId.value
        : this.replyToMessageId,
    forwardedFromMessageId: forwardedFromMessageId.present
        ? forwardedFromMessageId.value
        : this.forwardedFromMessageId,
    isDeleted: isDeleted ?? this.isDeleted,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    unreadCount: unreadCount ?? this.unreadCount,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  Message copyWithCompanion(MessagesCompanion data) {
    return Message(
      id: data.id.present ? data.id.value : this.id,
      chatRoomId: data.chatRoomId.present
          ? data.chatRoomId.value
          : this.chatRoomId,
      senderId: data.senderId.present ? data.senderId.value : this.senderId,
      senderNickname: data.senderNickname.present
          ? data.senderNickname.value
          : this.senderNickname,
      senderAvatarUrl: data.senderAvatarUrl.present
          ? data.senderAvatarUrl.value
          : this.senderAvatarUrl,
      content: data.content.present ? data.content.value : this.content,
      type: data.type.present ? data.type.value : this.type,
      fileUrl: data.fileUrl.present ? data.fileUrl.value : this.fileUrl,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      fileContentType: data.fileContentType.present
          ? data.fileContentType.value
          : this.fileContentType,
      thumbnailUrl: data.thumbnailUrl.present
          ? data.thumbnailUrl.value
          : this.thumbnailUrl,
      replyToMessageId: data.replyToMessageId.present
          ? data.replyToMessageId.value
          : this.replyToMessageId,
      forwardedFromMessageId: data.forwardedFromMessageId.present
          ? data.forwardedFromMessageId.value
          : this.forwardedFromMessageId,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      unreadCount: data.unreadCount.present
          ? data.unreadCount.value
          : this.unreadCount,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Message(')
          ..write('id: $id, ')
          ..write('chatRoomId: $chatRoomId, ')
          ..write('senderId: $senderId, ')
          ..write('senderNickname: $senderNickname, ')
          ..write('senderAvatarUrl: $senderAvatarUrl, ')
          ..write('content: $content, ')
          ..write('type: $type, ')
          ..write('fileUrl: $fileUrl, ')
          ..write('fileName: $fileName, ')
          ..write('fileSize: $fileSize, ')
          ..write('fileContentType: $fileContentType, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('replyToMessageId: $replyToMessageId, ')
          ..write('forwardedFromMessageId: $forwardedFromMessageId, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    chatRoomId,
    senderId,
    senderNickname,
    senderAvatarUrl,
    content,
    type,
    fileUrl,
    fileName,
    fileSize,
    fileContentType,
    thumbnailUrl,
    replyToMessageId,
    forwardedFromMessageId,
    isDeleted,
    createdAt,
    updatedAt,
    unreadCount,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Message &&
          other.id == this.id &&
          other.chatRoomId == this.chatRoomId &&
          other.senderId == this.senderId &&
          other.senderNickname == this.senderNickname &&
          other.senderAvatarUrl == this.senderAvatarUrl &&
          other.content == this.content &&
          other.type == this.type &&
          other.fileUrl == this.fileUrl &&
          other.fileName == this.fileName &&
          other.fileSize == this.fileSize &&
          other.fileContentType == this.fileContentType &&
          other.thumbnailUrl == this.thumbnailUrl &&
          other.replyToMessageId == this.replyToMessageId &&
          other.forwardedFromMessageId == this.forwardedFromMessageId &&
          other.isDeleted == this.isDeleted &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.unreadCount == this.unreadCount &&
          other.syncStatus == this.syncStatus);
}

class MessagesCompanion extends UpdateCompanion<Message> {
  final Value<int> id;
  final Value<int> chatRoomId;
  final Value<int> senderId;
  final Value<String?> senderNickname;
  final Value<String?> senderAvatarUrl;
  final Value<String> content;
  final Value<String> type;
  final Value<String?> fileUrl;
  final Value<String?> fileName;
  final Value<int?> fileSize;
  final Value<String?> fileContentType;
  final Value<String?> thumbnailUrl;
  final Value<int?> replyToMessageId;
  final Value<int?> forwardedFromMessageId;
  final Value<bool> isDeleted;
  final Value<int> createdAt;
  final Value<int?> updatedAt;
  final Value<int> unreadCount;
  final Value<String> syncStatus;
  const MessagesCompanion({
    this.id = const Value.absent(),
    this.chatRoomId = const Value.absent(),
    this.senderId = const Value.absent(),
    this.senderNickname = const Value.absent(),
    this.senderAvatarUrl = const Value.absent(),
    this.content = const Value.absent(),
    this.type = const Value.absent(),
    this.fileUrl = const Value.absent(),
    this.fileName = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.fileContentType = const Value.absent(),
    this.thumbnailUrl = const Value.absent(),
    this.replyToMessageId = const Value.absent(),
    this.forwardedFromMessageId = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.unreadCount = const Value.absent(),
    this.syncStatus = const Value.absent(),
  });
  MessagesCompanion.insert({
    this.id = const Value.absent(),
    required int chatRoomId,
    required int senderId,
    this.senderNickname = const Value.absent(),
    this.senderAvatarUrl = const Value.absent(),
    required String content,
    this.type = const Value.absent(),
    this.fileUrl = const Value.absent(),
    this.fileName = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.fileContentType = const Value.absent(),
    this.thumbnailUrl = const Value.absent(),
    this.replyToMessageId = const Value.absent(),
    this.forwardedFromMessageId = const Value.absent(),
    this.isDeleted = const Value.absent(),
    required int createdAt,
    this.updatedAt = const Value.absent(),
    this.unreadCount = const Value.absent(),
    this.syncStatus = const Value.absent(),
  }) : chatRoomId = Value(chatRoomId),
       senderId = Value(senderId),
       content = Value(content),
       createdAt = Value(createdAt);
  static Insertable<Message> custom({
    Expression<int>? id,
    Expression<int>? chatRoomId,
    Expression<int>? senderId,
    Expression<String>? senderNickname,
    Expression<String>? senderAvatarUrl,
    Expression<String>? content,
    Expression<String>? type,
    Expression<String>? fileUrl,
    Expression<String>? fileName,
    Expression<int>? fileSize,
    Expression<String>? fileContentType,
    Expression<String>? thumbnailUrl,
    Expression<int>? replyToMessageId,
    Expression<int>? forwardedFromMessageId,
    Expression<bool>? isDeleted,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? unreadCount,
    Expression<String>? syncStatus,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (chatRoomId != null) 'chat_room_id': chatRoomId,
      if (senderId != null) 'sender_id': senderId,
      if (senderNickname != null) 'sender_nickname': senderNickname,
      if (senderAvatarUrl != null) 'sender_avatar_url': senderAvatarUrl,
      if (content != null) 'content': content,
      if (type != null) 'type': type,
      if (fileUrl != null) 'file_url': fileUrl,
      if (fileName != null) 'file_name': fileName,
      if (fileSize != null) 'file_size': fileSize,
      if (fileContentType != null) 'file_content_type': fileContentType,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      if (replyToMessageId != null) 'reply_to_message_id': replyToMessageId,
      if (forwardedFromMessageId != null)
        'forwarded_from_message_id': forwardedFromMessageId,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (unreadCount != null) 'unread_count': unreadCount,
      if (syncStatus != null) 'sync_status': syncStatus,
    });
  }

  MessagesCompanion copyWith({
    Value<int>? id,
    Value<int>? chatRoomId,
    Value<int>? senderId,
    Value<String?>? senderNickname,
    Value<String?>? senderAvatarUrl,
    Value<String>? content,
    Value<String>? type,
    Value<String?>? fileUrl,
    Value<String?>? fileName,
    Value<int?>? fileSize,
    Value<String?>? fileContentType,
    Value<String?>? thumbnailUrl,
    Value<int?>? replyToMessageId,
    Value<int?>? forwardedFromMessageId,
    Value<bool>? isDeleted,
    Value<int>? createdAt,
    Value<int?>? updatedAt,
    Value<int>? unreadCount,
    Value<String>? syncStatus,
  }) {
    return MessagesCompanion(
      id: id ?? this.id,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      senderId: senderId ?? this.senderId,
      senderNickname: senderNickname ?? this.senderNickname,
      senderAvatarUrl: senderAvatarUrl ?? this.senderAvatarUrl,
      content: content ?? this.content,
      type: type ?? this.type,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      fileContentType: fileContentType ?? this.fileContentType,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      forwardedFromMessageId:
          forwardedFromMessageId ?? this.forwardedFromMessageId,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      unreadCount: unreadCount ?? this.unreadCount,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (chatRoomId.present) {
      map['chat_room_id'] = Variable<int>(chatRoomId.value);
    }
    if (senderId.present) {
      map['sender_id'] = Variable<int>(senderId.value);
    }
    if (senderNickname.present) {
      map['sender_nickname'] = Variable<String>(senderNickname.value);
    }
    if (senderAvatarUrl.present) {
      map['sender_avatar_url'] = Variable<String>(senderAvatarUrl.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (fileUrl.present) {
      map['file_url'] = Variable<String>(fileUrl.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (fileContentType.present) {
      map['file_content_type'] = Variable<String>(fileContentType.value);
    }
    if (thumbnailUrl.present) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl.value);
    }
    if (replyToMessageId.present) {
      map['reply_to_message_id'] = Variable<int>(replyToMessageId.value);
    }
    if (forwardedFromMessageId.present) {
      map['forwarded_from_message_id'] = Variable<int>(
        forwardedFromMessageId.value,
      );
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (unreadCount.present) {
      map['unread_count'] = Variable<int>(unreadCount.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesCompanion(')
          ..write('id: $id, ')
          ..write('chatRoomId: $chatRoomId, ')
          ..write('senderId: $senderId, ')
          ..write('senderNickname: $senderNickname, ')
          ..write('senderAvatarUrl: $senderAvatarUrl, ')
          ..write('content: $content, ')
          ..write('type: $type, ')
          ..write('fileUrl: $fileUrl, ')
          ..write('fileName: $fileName, ')
          ..write('fileSize: $fileSize, ')
          ..write('fileContentType: $fileContentType, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('replyToMessageId: $replyToMessageId, ')
          ..write('forwardedFromMessageId: $forwardedFromMessageId, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }
}

class $MessageReactionsTable extends MessageReactions
    with TableInfo<$MessageReactionsTable, MessageReaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessageReactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _messageIdMeta = const VerificationMeta(
    'messageId',
  );
  @override
  late final GeneratedColumn<int> messageId = GeneratedColumn<int>(
    'message_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userNicknameMeta = const VerificationMeta(
    'userNickname',
  );
  @override
  late final GeneratedColumn<String> userNickname = GeneratedColumn<String>(
    'user_nickname',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emojiMeta = const VerificationMeta('emoji');
  @override
  late final GeneratedColumn<String> emoji = GeneratedColumn<String>(
    'emoji',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    messageId,
    userId,
    userNickname,
    emoji,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'message_reactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<MessageReaction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('message_id')) {
      context.handle(
        _messageIdMeta,
        messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('user_nickname')) {
      context.handle(
        _userNicknameMeta,
        userNickname.isAcceptableOrUnknown(
          data['user_nickname']!,
          _userNicknameMeta,
        ),
      );
    }
    if (data.containsKey('emoji')) {
      context.handle(
        _emojiMeta,
        emoji.isAcceptableOrUnknown(data['emoji']!, _emojiMeta),
      );
    } else if (isInserting) {
      context.missing(_emojiMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MessageReaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MessageReaction(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      messageId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}message_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      )!,
      userNickname: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_nickname'],
      ),
      emoji: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}emoji'],
      )!,
    );
  }

  @override
  $MessageReactionsTable createAlias(String alias) {
    return $MessageReactionsTable(attachedDatabase, alias);
  }
}

class MessageReaction extends DataClass implements Insertable<MessageReaction> {
  final int id;
  final int messageId;
  final int userId;
  final String? userNickname;
  final String emoji;
  const MessageReaction({
    required this.id,
    required this.messageId,
    required this.userId,
    this.userNickname,
    required this.emoji,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['message_id'] = Variable<int>(messageId);
    map['user_id'] = Variable<int>(userId);
    if (!nullToAbsent || userNickname != null) {
      map['user_nickname'] = Variable<String>(userNickname);
    }
    map['emoji'] = Variable<String>(emoji);
    return map;
  }

  MessageReactionsCompanion toCompanion(bool nullToAbsent) {
    return MessageReactionsCompanion(
      id: Value(id),
      messageId: Value(messageId),
      userId: Value(userId),
      userNickname: userNickname == null && nullToAbsent
          ? const Value.absent()
          : Value(userNickname),
      emoji: Value(emoji),
    );
  }

  factory MessageReaction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MessageReaction(
      id: serializer.fromJson<int>(json['id']),
      messageId: serializer.fromJson<int>(json['messageId']),
      userId: serializer.fromJson<int>(json['userId']),
      userNickname: serializer.fromJson<String?>(json['userNickname']),
      emoji: serializer.fromJson<String>(json['emoji']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'messageId': serializer.toJson<int>(messageId),
      'userId': serializer.toJson<int>(userId),
      'userNickname': serializer.toJson<String?>(userNickname),
      'emoji': serializer.toJson<String>(emoji),
    };
  }

  MessageReaction copyWith({
    int? id,
    int? messageId,
    int? userId,
    Value<String?> userNickname = const Value.absent(),
    String? emoji,
  }) => MessageReaction(
    id: id ?? this.id,
    messageId: messageId ?? this.messageId,
    userId: userId ?? this.userId,
    userNickname: userNickname.present ? userNickname.value : this.userNickname,
    emoji: emoji ?? this.emoji,
  );
  MessageReaction copyWithCompanion(MessageReactionsCompanion data) {
    return MessageReaction(
      id: data.id.present ? data.id.value : this.id,
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      userId: data.userId.present ? data.userId.value : this.userId,
      userNickname: data.userNickname.present
          ? data.userNickname.value
          : this.userNickname,
      emoji: data.emoji.present ? data.emoji.value : this.emoji,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MessageReaction(')
          ..write('id: $id, ')
          ..write('messageId: $messageId, ')
          ..write('userId: $userId, ')
          ..write('userNickname: $userNickname, ')
          ..write('emoji: $emoji')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, messageId, userId, userNickname, emoji);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MessageReaction &&
          other.id == this.id &&
          other.messageId == this.messageId &&
          other.userId == this.userId &&
          other.userNickname == this.userNickname &&
          other.emoji == this.emoji);
}

class MessageReactionsCompanion extends UpdateCompanion<MessageReaction> {
  final Value<int> id;
  final Value<int> messageId;
  final Value<int> userId;
  final Value<String?> userNickname;
  final Value<String> emoji;
  const MessageReactionsCompanion({
    this.id = const Value.absent(),
    this.messageId = const Value.absent(),
    this.userId = const Value.absent(),
    this.userNickname = const Value.absent(),
    this.emoji = const Value.absent(),
  });
  MessageReactionsCompanion.insert({
    this.id = const Value.absent(),
    required int messageId,
    required int userId,
    this.userNickname = const Value.absent(),
    required String emoji,
  }) : messageId = Value(messageId),
       userId = Value(userId),
       emoji = Value(emoji);
  static Insertable<MessageReaction> custom({
    Expression<int>? id,
    Expression<int>? messageId,
    Expression<int>? userId,
    Expression<String>? userNickname,
    Expression<String>? emoji,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (messageId != null) 'message_id': messageId,
      if (userId != null) 'user_id': userId,
      if (userNickname != null) 'user_nickname': userNickname,
      if (emoji != null) 'emoji': emoji,
    });
  }

  MessageReactionsCompanion copyWith({
    Value<int>? id,
    Value<int>? messageId,
    Value<int>? userId,
    Value<String?>? userNickname,
    Value<String>? emoji,
  }) {
    return MessageReactionsCompanion(
      id: id ?? this.id,
      messageId: messageId ?? this.messageId,
      userId: userId ?? this.userId,
      userNickname: userNickname ?? this.userNickname,
      emoji: emoji ?? this.emoji,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (messageId.present) {
      map['message_id'] = Variable<int>(messageId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (userNickname.present) {
      map['user_nickname'] = Variable<String>(userNickname.value);
    }
    if (emoji.present) {
      map['emoji'] = Variable<String>(emoji.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessageReactionsCompanion(')
          ..write('id: $id, ')
          ..write('messageId: $messageId, ')
          ..write('userId: $userId, ')
          ..write('userNickname: $userNickname, ')
          ..write('emoji: $emoji')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ChatRoomsTable chatRooms = $ChatRoomsTable(this);
  late final $MessagesTable messages = $MessagesTable(this);
  late final $MessageReactionsTable messageReactions = $MessageReactionsTable(
    this,
  );
  late final MessageDao messageDao = MessageDao(this as AppDatabase);
  late final ChatRoomDao chatRoomDao = ChatRoomDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    chatRooms,
    messages,
    messageReactions,
  ];
}

typedef $$ChatRoomsTableCreateCompanionBuilder =
    ChatRoomsCompanion Function({
      Value<int> id,
      Value<String?> name,
      Value<String> type,
      required int createdAt,
      Value<String?> lastMessage,
      Value<String?> lastMessageType,
      Value<int?> lastMessageAt,
      Value<int> unreadCount,
      Value<int?> otherUserId,
      Value<String?> otherUserNickname,
      Value<String?> otherUserAvatarUrl,
      Value<bool> isOtherUserLeft,
      Value<bool> isOtherUserOnline,
      Value<int?> otherUserLastActiveAt,
      Value<int?> lastSyncAt,
    });
typedef $$ChatRoomsTableUpdateCompanionBuilder =
    ChatRoomsCompanion Function({
      Value<int> id,
      Value<String?> name,
      Value<String> type,
      Value<int> createdAt,
      Value<String?> lastMessage,
      Value<String?> lastMessageType,
      Value<int?> lastMessageAt,
      Value<int> unreadCount,
      Value<int?> otherUserId,
      Value<String?> otherUserNickname,
      Value<String?> otherUserAvatarUrl,
      Value<bool> isOtherUserLeft,
      Value<bool> isOtherUserOnline,
      Value<int?> otherUserLastActiveAt,
      Value<int?> lastSyncAt,
    });

class $$ChatRoomsTableFilterComposer
    extends Composer<_$AppDatabase, $ChatRoomsTable> {
  $$ChatRoomsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastMessage => $composableBuilder(
    column: $table.lastMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastMessageType => $composableBuilder(
    column: $table.lastMessageType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastMessageAt => $composableBuilder(
    column: $table.lastMessageAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get otherUserId => $composableBuilder(
    column: $table.otherUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get otherUserNickname => $composableBuilder(
    column: $table.otherUserNickname,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get otherUserAvatarUrl => $composableBuilder(
    column: $table.otherUserAvatarUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isOtherUserLeft => $composableBuilder(
    column: $table.isOtherUserLeft,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isOtherUserOnline => $composableBuilder(
    column: $table.isOtherUserOnline,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get otherUserLastActiveAt => $composableBuilder(
    column: $table.otherUserLastActiveAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ChatRoomsTableOrderingComposer
    extends Composer<_$AppDatabase, $ChatRoomsTable> {
  $$ChatRoomsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastMessage => $composableBuilder(
    column: $table.lastMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastMessageType => $composableBuilder(
    column: $table.lastMessageType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastMessageAt => $composableBuilder(
    column: $table.lastMessageAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get otherUserId => $composableBuilder(
    column: $table.otherUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get otherUserNickname => $composableBuilder(
    column: $table.otherUserNickname,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get otherUserAvatarUrl => $composableBuilder(
    column: $table.otherUserAvatarUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isOtherUserLeft => $composableBuilder(
    column: $table.isOtherUserLeft,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isOtherUserOnline => $composableBuilder(
    column: $table.isOtherUserOnline,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get otherUserLastActiveAt => $composableBuilder(
    column: $table.otherUserLastActiveAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChatRoomsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChatRoomsTable> {
  $$ChatRoomsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get lastMessage => $composableBuilder(
    column: $table.lastMessage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastMessageType => $composableBuilder(
    column: $table.lastMessageType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastMessageAt => $composableBuilder(
    column: $table.lastMessageAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get otherUserId => $composableBuilder(
    column: $table.otherUserId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get otherUserNickname => $composableBuilder(
    column: $table.otherUserNickname,
    builder: (column) => column,
  );

  GeneratedColumn<String> get otherUserAvatarUrl => $composableBuilder(
    column: $table.otherUserAvatarUrl,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isOtherUserLeft => $composableBuilder(
    column: $table.isOtherUserLeft,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isOtherUserOnline => $composableBuilder(
    column: $table.isOtherUserOnline,
    builder: (column) => column,
  );

  GeneratedColumn<int> get otherUserLastActiveAt => $composableBuilder(
    column: $table.otherUserLastActiveAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => column,
  );
}

class $$ChatRoomsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChatRoomsTable,
          ChatRoom,
          $$ChatRoomsTableFilterComposer,
          $$ChatRoomsTableOrderingComposer,
          $$ChatRoomsTableAnnotationComposer,
          $$ChatRoomsTableCreateCompanionBuilder,
          $$ChatRoomsTableUpdateCompanionBuilder,
          (ChatRoom, BaseReferences<_$AppDatabase, $ChatRoomsTable, ChatRoom>),
          ChatRoom,
          PrefetchHooks Function()
        > {
  $$ChatRoomsTableTableManager(_$AppDatabase db, $ChatRoomsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChatRoomsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChatRoomsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChatRoomsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<String?> lastMessage = const Value.absent(),
                Value<String?> lastMessageType = const Value.absent(),
                Value<int?> lastMessageAt = const Value.absent(),
                Value<int> unreadCount = const Value.absent(),
                Value<int?> otherUserId = const Value.absent(),
                Value<String?> otherUserNickname = const Value.absent(),
                Value<String?> otherUserAvatarUrl = const Value.absent(),
                Value<bool> isOtherUserLeft = const Value.absent(),
                Value<bool> isOtherUserOnline = const Value.absent(),
                Value<int?> otherUserLastActiveAt = const Value.absent(),
                Value<int?> lastSyncAt = const Value.absent(),
              }) => ChatRoomsCompanion(
                id: id,
                name: name,
                type: type,
                createdAt: createdAt,
                lastMessage: lastMessage,
                lastMessageType: lastMessageType,
                lastMessageAt: lastMessageAt,
                unreadCount: unreadCount,
                otherUserId: otherUserId,
                otherUserNickname: otherUserNickname,
                otherUserAvatarUrl: otherUserAvatarUrl,
                isOtherUserLeft: isOtherUserLeft,
                isOtherUserOnline: isOtherUserOnline,
                otherUserLastActiveAt: otherUserLastActiveAt,
                lastSyncAt: lastSyncAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String> type = const Value.absent(),
                required int createdAt,
                Value<String?> lastMessage = const Value.absent(),
                Value<String?> lastMessageType = const Value.absent(),
                Value<int?> lastMessageAt = const Value.absent(),
                Value<int> unreadCount = const Value.absent(),
                Value<int?> otherUserId = const Value.absent(),
                Value<String?> otherUserNickname = const Value.absent(),
                Value<String?> otherUserAvatarUrl = const Value.absent(),
                Value<bool> isOtherUserLeft = const Value.absent(),
                Value<bool> isOtherUserOnline = const Value.absent(),
                Value<int?> otherUserLastActiveAt = const Value.absent(),
                Value<int?> lastSyncAt = const Value.absent(),
              }) => ChatRoomsCompanion.insert(
                id: id,
                name: name,
                type: type,
                createdAt: createdAt,
                lastMessage: lastMessage,
                lastMessageType: lastMessageType,
                lastMessageAt: lastMessageAt,
                unreadCount: unreadCount,
                otherUserId: otherUserId,
                otherUserNickname: otherUserNickname,
                otherUserAvatarUrl: otherUserAvatarUrl,
                isOtherUserLeft: isOtherUserLeft,
                isOtherUserOnline: isOtherUserOnline,
                otherUserLastActiveAt: otherUserLastActiveAt,
                lastSyncAt: lastSyncAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ChatRoomsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChatRoomsTable,
      ChatRoom,
      $$ChatRoomsTableFilterComposer,
      $$ChatRoomsTableOrderingComposer,
      $$ChatRoomsTableAnnotationComposer,
      $$ChatRoomsTableCreateCompanionBuilder,
      $$ChatRoomsTableUpdateCompanionBuilder,
      (ChatRoom, BaseReferences<_$AppDatabase, $ChatRoomsTable, ChatRoom>),
      ChatRoom,
      PrefetchHooks Function()
    >;
typedef $$MessagesTableCreateCompanionBuilder =
    MessagesCompanion Function({
      Value<int> id,
      required int chatRoomId,
      required int senderId,
      Value<String?> senderNickname,
      Value<String?> senderAvatarUrl,
      required String content,
      Value<String> type,
      Value<String?> fileUrl,
      Value<String?> fileName,
      Value<int?> fileSize,
      Value<String?> fileContentType,
      Value<String?> thumbnailUrl,
      Value<int?> replyToMessageId,
      Value<int?> forwardedFromMessageId,
      Value<bool> isDeleted,
      required int createdAt,
      Value<int?> updatedAt,
      Value<int> unreadCount,
      Value<String> syncStatus,
    });
typedef $$MessagesTableUpdateCompanionBuilder =
    MessagesCompanion Function({
      Value<int> id,
      Value<int> chatRoomId,
      Value<int> senderId,
      Value<String?> senderNickname,
      Value<String?> senderAvatarUrl,
      Value<String> content,
      Value<String> type,
      Value<String?> fileUrl,
      Value<String?> fileName,
      Value<int?> fileSize,
      Value<String?> fileContentType,
      Value<String?> thumbnailUrl,
      Value<int?> replyToMessageId,
      Value<int?> forwardedFromMessageId,
      Value<bool> isDeleted,
      Value<int> createdAt,
      Value<int?> updatedAt,
      Value<int> unreadCount,
      Value<String> syncStatus,
    });

class $$MessagesTableFilterComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chatRoomId => $composableBuilder(
    column: $table.chatRoomId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get senderId => $composableBuilder(
    column: $table.senderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get senderNickname => $composableBuilder(
    column: $table.senderNickname,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get senderAvatarUrl => $composableBuilder(
    column: $table.senderAvatarUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileUrl => $composableBuilder(
    column: $table.fileUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileContentType => $composableBuilder(
    column: $table.fileContentType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get replyToMessageId => $composableBuilder(
    column: $table.replyToMessageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get forwardedFromMessageId => $composableBuilder(
    column: $table.forwardedFromMessageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chatRoomId => $composableBuilder(
    column: $table.chatRoomId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get senderId => $composableBuilder(
    column: $table.senderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get senderNickname => $composableBuilder(
    column: $table.senderNickname,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get senderAvatarUrl => $composableBuilder(
    column: $table.senderAvatarUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileUrl => $composableBuilder(
    column: $table.fileUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileContentType => $composableBuilder(
    column: $table.fileContentType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get replyToMessageId => $composableBuilder(
    column: $table.replyToMessageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get forwardedFromMessageId => $composableBuilder(
    column: $table.forwardedFromMessageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get chatRoomId => $composableBuilder(
    column: $table.chatRoomId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get senderId =>
      $composableBuilder(column: $table.senderId, builder: (column) => column);

  GeneratedColumn<String> get senderNickname => $composableBuilder(
    column: $table.senderNickname,
    builder: (column) => column,
  );

  GeneratedColumn<String> get senderAvatarUrl => $composableBuilder(
    column: $table.senderAvatarUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get fileUrl =>
      $composableBuilder(column: $table.fileUrl, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<String> get fileContentType => $composableBuilder(
    column: $table.fileContentType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => column,
  );

  GeneratedColumn<int> get replyToMessageId => $composableBuilder(
    column: $table.replyToMessageId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get forwardedFromMessageId => $composableBuilder(
    column: $table.forwardedFromMessageId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );
}

class $$MessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MessagesTable,
          Message,
          $$MessagesTableFilterComposer,
          $$MessagesTableOrderingComposer,
          $$MessagesTableAnnotationComposer,
          $$MessagesTableCreateCompanionBuilder,
          $$MessagesTableUpdateCompanionBuilder,
          (Message, BaseReferences<_$AppDatabase, $MessagesTable, Message>),
          Message,
          PrefetchHooks Function()
        > {
  $$MessagesTableTableManager(_$AppDatabase db, $MessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> chatRoomId = const Value.absent(),
                Value<int> senderId = const Value.absent(),
                Value<String?> senderNickname = const Value.absent(),
                Value<String?> senderAvatarUrl = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> fileUrl = const Value.absent(),
                Value<String?> fileName = const Value.absent(),
                Value<int?> fileSize = const Value.absent(),
                Value<String?> fileContentType = const Value.absent(),
                Value<String?> thumbnailUrl = const Value.absent(),
                Value<int?> replyToMessageId = const Value.absent(),
                Value<int?> forwardedFromMessageId = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int> unreadCount = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
              }) => MessagesCompanion(
                id: id,
                chatRoomId: chatRoomId,
                senderId: senderId,
                senderNickname: senderNickname,
                senderAvatarUrl: senderAvatarUrl,
                content: content,
                type: type,
                fileUrl: fileUrl,
                fileName: fileName,
                fileSize: fileSize,
                fileContentType: fileContentType,
                thumbnailUrl: thumbnailUrl,
                replyToMessageId: replyToMessageId,
                forwardedFromMessageId: forwardedFromMessageId,
                isDeleted: isDeleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
                unreadCount: unreadCount,
                syncStatus: syncStatus,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int chatRoomId,
                required int senderId,
                Value<String?> senderNickname = const Value.absent(),
                Value<String?> senderAvatarUrl = const Value.absent(),
                required String content,
                Value<String> type = const Value.absent(),
                Value<String?> fileUrl = const Value.absent(),
                Value<String?> fileName = const Value.absent(),
                Value<int?> fileSize = const Value.absent(),
                Value<String?> fileContentType = const Value.absent(),
                Value<String?> thumbnailUrl = const Value.absent(),
                Value<int?> replyToMessageId = const Value.absent(),
                Value<int?> forwardedFromMessageId = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                required int createdAt,
                Value<int?> updatedAt = const Value.absent(),
                Value<int> unreadCount = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
              }) => MessagesCompanion.insert(
                id: id,
                chatRoomId: chatRoomId,
                senderId: senderId,
                senderNickname: senderNickname,
                senderAvatarUrl: senderAvatarUrl,
                content: content,
                type: type,
                fileUrl: fileUrl,
                fileName: fileName,
                fileSize: fileSize,
                fileContentType: fileContentType,
                thumbnailUrl: thumbnailUrl,
                replyToMessageId: replyToMessageId,
                forwardedFromMessageId: forwardedFromMessageId,
                isDeleted: isDeleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
                unreadCount: unreadCount,
                syncStatus: syncStatus,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MessagesTable,
      Message,
      $$MessagesTableFilterComposer,
      $$MessagesTableOrderingComposer,
      $$MessagesTableAnnotationComposer,
      $$MessagesTableCreateCompanionBuilder,
      $$MessagesTableUpdateCompanionBuilder,
      (Message, BaseReferences<_$AppDatabase, $MessagesTable, Message>),
      Message,
      PrefetchHooks Function()
    >;
typedef $$MessageReactionsTableCreateCompanionBuilder =
    MessageReactionsCompanion Function({
      Value<int> id,
      required int messageId,
      required int userId,
      Value<String?> userNickname,
      required String emoji,
    });
typedef $$MessageReactionsTableUpdateCompanionBuilder =
    MessageReactionsCompanion Function({
      Value<int> id,
      Value<int> messageId,
      Value<int> userId,
      Value<String?> userNickname,
      Value<String> emoji,
    });

class $$MessageReactionsTableFilterComposer
    extends Composer<_$AppDatabase, $MessageReactionsTable> {
  $$MessageReactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userNickname => $composableBuilder(
    column: $table.userNickname,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MessageReactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $MessageReactionsTable> {
  $$MessageReactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userNickname => $composableBuilder(
    column: $table.userNickname,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MessageReactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MessageReactionsTable> {
  $$MessageReactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get userNickname => $composableBuilder(
    column: $table.userNickname,
    builder: (column) => column,
  );

  GeneratedColumn<String> get emoji =>
      $composableBuilder(column: $table.emoji, builder: (column) => column);
}

class $$MessageReactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MessageReactionsTable,
          MessageReaction,
          $$MessageReactionsTableFilterComposer,
          $$MessageReactionsTableOrderingComposer,
          $$MessageReactionsTableAnnotationComposer,
          $$MessageReactionsTableCreateCompanionBuilder,
          $$MessageReactionsTableUpdateCompanionBuilder,
          (
            MessageReaction,
            BaseReferences<
              _$AppDatabase,
              $MessageReactionsTable,
              MessageReaction
            >,
          ),
          MessageReaction,
          PrefetchHooks Function()
        > {
  $$MessageReactionsTableTableManager(
    _$AppDatabase db,
    $MessageReactionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessageReactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessageReactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessageReactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> messageId = const Value.absent(),
                Value<int> userId = const Value.absent(),
                Value<String?> userNickname = const Value.absent(),
                Value<String> emoji = const Value.absent(),
              }) => MessageReactionsCompanion(
                id: id,
                messageId: messageId,
                userId: userId,
                userNickname: userNickname,
                emoji: emoji,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int messageId,
                required int userId,
                Value<String?> userNickname = const Value.absent(),
                required String emoji,
              }) => MessageReactionsCompanion.insert(
                id: id,
                messageId: messageId,
                userId: userId,
                userNickname: userNickname,
                emoji: emoji,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MessageReactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MessageReactionsTable,
      MessageReaction,
      $$MessageReactionsTableFilterComposer,
      $$MessageReactionsTableOrderingComposer,
      $$MessageReactionsTableAnnotationComposer,
      $$MessageReactionsTableCreateCompanionBuilder,
      $$MessageReactionsTableUpdateCompanionBuilder,
      (
        MessageReaction,
        BaseReferences<_$AppDatabase, $MessageReactionsTable, MessageReaction>,
      ),
      MessageReaction,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ChatRoomsTableTableManager get chatRooms =>
      $$ChatRoomsTableTableManager(_db, _db.chatRooms);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db, _db.messages);
  $$MessageReactionsTableTableManager get messageReactions =>
      $$MessageReactionsTableTableManager(_db, _db.messageReactions);
}
