// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $HabitsTable extends Habits with TableInfo<$HabitsTable, HabitRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HabitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<HabitFrequencyType, String>
  frequencyType = GeneratedColumn<String>(
    'frequency_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<HabitFrequencyType>($HabitsTable.$converterfrequencyType);
  @override
  late final GeneratedColumnWithTypeConverter<List<int>?, String>
  targetDaysOfWeek = GeneratedColumn<String>(
    'target_days_of_week',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<List<int>?>($HabitsTable.$convertertargetDaysOfWeekn);
  static const VerificationMeta _targetCountPerWeekMeta =
      const VerificationMeta('targetCountPerWeek');
  @override
  late final GeneratedColumn<int> targetCountPerWeek = GeneratedColumn<int>(
    'target_count_per_week',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _intervalHoursMeta = const VerificationMeta(
    'intervalHours',
  );
  @override
  late final GeneratedColumn<int> intervalHours = GeneratedColumn<int>(
    'interval_hours',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timesPerDayMeta = const VerificationMeta(
    'timesPerDay',
  );
  @override
  late final GeneratedColumn<int> timesPerDay = GeneratedColumn<int>(
    'times_per_day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TimeWindow?, String> timeWindow =
      GeneratedColumn<String>(
        'time_window',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<TimeWindow?>($HabitsTable.$convertertimeWindown);
  @override
  late final GeneratedColumnWithTypeConverter<HabitTargetType, String>
  targetType = GeneratedColumn<String>(
    'target_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<HabitTargetType>($HabitsTable.$convertertargetType);
  static const VerificationMeta _targetValueMeta = const VerificationMeta(
    'targetValue',
  );
  @override
  late final GeneratedColumn<double> targetValue = GeneratedColumn<double>(
    'target_value',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _miniTargetValueMeta = const VerificationMeta(
    'miniTargetValue',
  );
  @override
  late final GeneratedColumn<double> miniTargetValue = GeneratedColumn<double>(
    'mini_target_value',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _eliteTargetValueMeta = const VerificationMeta(
    'eliteTargetValue',
  );
  @override
  late final GeneratedColumn<double> eliteTargetValue = GeneratedColumn<double>(
    'elite_target_value',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pinnedMeta = const VerificationMeta('pinned');
  @override
  late final GeneratedColumn<bool> pinned = GeneratedColumn<bool>(
    'pinned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pinned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String>
  reminderTimes = GeneratedColumn<String>(
    'reminder_times',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  ).withConverter<List<String>>($HabitsTable.$converterreminderTimes);
  static const VerificationMeta _motivationNotesMeta = const VerificationMeta(
    'motivationNotes',
  );
  @override
  late final GeneratedColumn<String> motivationNotes = GeneratedColumn<String>(
    'motivation_notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _promptReflectionMeta = const VerificationMeta(
    'promptReflection',
  );
  @override
  late final GeneratedColumn<bool> promptReflection = GeneratedColumn<bool>(
    'prompt_reflection',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("prompt_reflection" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<HealthMetricType?, String>
  healthMetric = GeneratedColumn<String>(
    'health_metric',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<HealthMetricType?>($HabitsTable.$converterhealthMetric);
  static const VerificationMeta _healthSyncEnabledMeta = const VerificationMeta(
    'healthSyncEnabled',
  );
  @override
  late final GeneratedColumn<bool> healthSyncEnabled = GeneratedColumn<bool>(
    'health_sync_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("health_sync_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    description,
    color,
    icon,
    categoryId,
    frequencyType,
    targetDaysOfWeek,
    targetCountPerWeek,
    intervalHours,
    timesPerDay,
    timeWindow,
    targetType,
    targetValue,
    miniTargetValue,
    eliteTargetValue,
    unit,
    pinned,
    reminderTimes,
    motivationNotes,
    archived,
    promptReflection,
    healthMetric,
    healthSyncEnabled,
    isDeleted,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'habits';
  @override
  VerificationContext validateIntegrity(
    Insertable<HabitRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    } else if (isInserting) {
      context.missing(_colorMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('target_count_per_week')) {
      context.handle(
        _targetCountPerWeekMeta,
        targetCountPerWeek.isAcceptableOrUnknown(
          data['target_count_per_week']!,
          _targetCountPerWeekMeta,
        ),
      );
    }
    if (data.containsKey('interval_hours')) {
      context.handle(
        _intervalHoursMeta,
        intervalHours.isAcceptableOrUnknown(
          data['interval_hours']!,
          _intervalHoursMeta,
        ),
      );
    }
    if (data.containsKey('times_per_day')) {
      context.handle(
        _timesPerDayMeta,
        timesPerDay.isAcceptableOrUnknown(
          data['times_per_day']!,
          _timesPerDayMeta,
        ),
      );
    }
    if (data.containsKey('target_value')) {
      context.handle(
        _targetValueMeta,
        targetValue.isAcceptableOrUnknown(
          data['target_value']!,
          _targetValueMeta,
        ),
      );
    }
    if (data.containsKey('mini_target_value')) {
      context.handle(
        _miniTargetValueMeta,
        miniTargetValue.isAcceptableOrUnknown(
          data['mini_target_value']!,
          _miniTargetValueMeta,
        ),
      );
    }
    if (data.containsKey('elite_target_value')) {
      context.handle(
        _eliteTargetValueMeta,
        eliteTargetValue.isAcceptableOrUnknown(
          data['elite_target_value']!,
          _eliteTargetValueMeta,
        ),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('pinned')) {
      context.handle(
        _pinnedMeta,
        pinned.isAcceptableOrUnknown(data['pinned']!, _pinnedMeta),
      );
    }
    if (data.containsKey('motivation_notes')) {
      context.handle(
        _motivationNotesMeta,
        motivationNotes.isAcceptableOrUnknown(
          data['motivation_notes']!,
          _motivationNotesMeta,
        ),
      );
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    if (data.containsKey('prompt_reflection')) {
      context.handle(
        _promptReflectionMeta,
        promptReflection.isAcceptableOrUnknown(
          data['prompt_reflection']!,
          _promptReflectionMeta,
        ),
      );
    }
    if (data.containsKey('health_sync_enabled')) {
      context.handle(
        _healthSyncEnabledMeta,
        healthSyncEnabled.isAcceptableOrUnknown(
          data['health_sync_enabled']!,
          _healthSyncEnabledMeta,
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
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HabitRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HabitRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      frequencyType: $HabitsTable.$converterfrequencyType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}frequency_type'],
        )!,
      ),
      targetDaysOfWeek: $HabitsTable.$convertertargetDaysOfWeekn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}target_days_of_week'],
        ),
      ),
      targetCountPerWeek: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_count_per_week'],
      ),
      intervalHours: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_hours'],
      ),
      timesPerDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}times_per_day'],
      ),
      timeWindow: $HabitsTable.$convertertimeWindown.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}time_window'],
        ),
      ),
      targetType: $HabitsTable.$convertertargetType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}target_type'],
        )!,
      ),
      targetValue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}target_value'],
      ),
      miniTargetValue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}mini_target_value'],
      ),
      eliteTargetValue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}elite_target_value'],
      ),
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      ),
      pinned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pinned'],
      )!,
      reminderTimes: $HabitsTable.$converterreminderTimes.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}reminder_times'],
        )!,
      ),
      motivationNotes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}motivation_notes'],
      ),
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
      promptReflection: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}prompt_reflection'],
      )!,
      healthMetric: $HabitsTable.$converterhealthMetric.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}health_metric'],
        ),
      ),
      healthSyncEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}health_sync_enabled'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $HabitsTable createAlias(String alias) {
    return $HabitsTable(attachedDatabase, alias);
  }

  static TypeConverter<HabitFrequencyType, String> $converterfrequencyType =
      const HabitFrequencyTypeConverter();
  static TypeConverter<List<int>, String> $convertertargetDaysOfWeek =
      const IntListConverter();
  static TypeConverter<List<int>?, String?> $convertertargetDaysOfWeekn =
      NullAwareTypeConverter.wrap($convertertargetDaysOfWeek);
  static TypeConverter<TimeWindow, String> $convertertimeWindow =
      const TimeWindowConverter();
  static TypeConverter<TimeWindow?, String?> $convertertimeWindown =
      NullAwareTypeConverter.wrap($convertertimeWindow);
  static TypeConverter<HabitTargetType, String> $convertertargetType =
      const HabitTargetTypeConverter();
  static TypeConverter<List<String>, String> $converterreminderTimes =
      const StringListConverter();
  static TypeConverter<HealthMetricType?, String?> $converterhealthMetric =
      const HealthMetricTypeConverter();
}

class HabitRow extends DataClass implements Insertable<HabitRow> {
  final String id;
  final String title;
  final String? description;
  final String color;
  final String? icon;
  final String? categoryId;
  final HabitFrequencyType frequencyType;
  final List<int>? targetDaysOfWeek;
  final int? targetCountPerWeek;
  final int? intervalHours;
  final int? timesPerDay;
  final TimeWindow? timeWindow;
  final HabitTargetType targetType;
  final double? targetValue;
  final double? miniTargetValue;
  final double? eliteTargetValue;
  final String? unit;
  final bool pinned;
  final List<String> reminderTimes;
  final String? motivationNotes;
  final bool archived;
  final bool promptReflection;
  final HealthMetricType? healthMetric;
  final bool healthSyncEnabled;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  const HabitRow({
    required this.id,
    required this.title,
    this.description,
    required this.color,
    this.icon,
    this.categoryId,
    required this.frequencyType,
    this.targetDaysOfWeek,
    this.targetCountPerWeek,
    this.intervalHours,
    this.timesPerDay,
    this.timeWindow,
    required this.targetType,
    this.targetValue,
    this.miniTargetValue,
    this.eliteTargetValue,
    this.unit,
    required this.pinned,
    required this.reminderTimes,
    this.motivationNotes,
    required this.archived,
    required this.promptReflection,
    this.healthMetric,
    required this.healthSyncEnabled,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['color'] = Variable<String>(color);
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    {
      map['frequency_type'] = Variable<String>(
        $HabitsTable.$converterfrequencyType.toSql(frequencyType),
      );
    }
    if (!nullToAbsent || targetDaysOfWeek != null) {
      map['target_days_of_week'] = Variable<String>(
        $HabitsTable.$convertertargetDaysOfWeekn.toSql(targetDaysOfWeek),
      );
    }
    if (!nullToAbsent || targetCountPerWeek != null) {
      map['target_count_per_week'] = Variable<int>(targetCountPerWeek);
    }
    if (!nullToAbsent || intervalHours != null) {
      map['interval_hours'] = Variable<int>(intervalHours);
    }
    if (!nullToAbsent || timesPerDay != null) {
      map['times_per_day'] = Variable<int>(timesPerDay);
    }
    if (!nullToAbsent || timeWindow != null) {
      map['time_window'] = Variable<String>(
        $HabitsTable.$convertertimeWindown.toSql(timeWindow),
      );
    }
    {
      map['target_type'] = Variable<String>(
        $HabitsTable.$convertertargetType.toSql(targetType),
      );
    }
    if (!nullToAbsent || targetValue != null) {
      map['target_value'] = Variable<double>(targetValue);
    }
    if (!nullToAbsent || miniTargetValue != null) {
      map['mini_target_value'] = Variable<double>(miniTargetValue);
    }
    if (!nullToAbsent || eliteTargetValue != null) {
      map['elite_target_value'] = Variable<double>(eliteTargetValue);
    }
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    map['pinned'] = Variable<bool>(pinned);
    {
      map['reminder_times'] = Variable<String>(
        $HabitsTable.$converterreminderTimes.toSql(reminderTimes),
      );
    }
    if (!nullToAbsent || motivationNotes != null) {
      map['motivation_notes'] = Variable<String>(motivationNotes);
    }
    map['archived'] = Variable<bool>(archived);
    map['prompt_reflection'] = Variable<bool>(promptReflection);
    if (!nullToAbsent || healthMetric != null) {
      map['health_metric'] = Variable<String>(
        $HabitsTable.$converterhealthMetric.toSql(healthMetric),
      );
    }
    map['health_sync_enabled'] = Variable<bool>(healthSyncEnabled);
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  HabitsCompanion toCompanion(bool nullToAbsent) {
    return HabitsCompanion(
      id: Value(id),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      color: Value(color),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      frequencyType: Value(frequencyType),
      targetDaysOfWeek: targetDaysOfWeek == null && nullToAbsent
          ? const Value.absent()
          : Value(targetDaysOfWeek),
      targetCountPerWeek: targetCountPerWeek == null && nullToAbsent
          ? const Value.absent()
          : Value(targetCountPerWeek),
      intervalHours: intervalHours == null && nullToAbsent
          ? const Value.absent()
          : Value(intervalHours),
      timesPerDay: timesPerDay == null && nullToAbsent
          ? const Value.absent()
          : Value(timesPerDay),
      timeWindow: timeWindow == null && nullToAbsent
          ? const Value.absent()
          : Value(timeWindow),
      targetType: Value(targetType),
      targetValue: targetValue == null && nullToAbsent
          ? const Value.absent()
          : Value(targetValue),
      miniTargetValue: miniTargetValue == null && nullToAbsent
          ? const Value.absent()
          : Value(miniTargetValue),
      eliteTargetValue: eliteTargetValue == null && nullToAbsent
          ? const Value.absent()
          : Value(eliteTargetValue),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      pinned: Value(pinned),
      reminderTimes: Value(reminderTimes),
      motivationNotes: motivationNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(motivationNotes),
      archived: Value(archived),
      promptReflection: Value(promptReflection),
      healthMetric: healthMetric == null && nullToAbsent
          ? const Value.absent()
          : Value(healthMetric),
      healthSyncEnabled: Value(healthSyncEnabled),
      isDeleted: Value(isDeleted),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory HabitRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HabitRow(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      color: serializer.fromJson<String>(json['color']),
      icon: serializer.fromJson<String?>(json['icon']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      frequencyType: serializer.fromJson<HabitFrequencyType>(
        json['frequencyType'],
      ),
      targetDaysOfWeek: serializer.fromJson<List<int>?>(
        json['targetDaysOfWeek'],
      ),
      targetCountPerWeek: serializer.fromJson<int?>(json['targetCountPerWeek']),
      intervalHours: serializer.fromJson<int?>(json['intervalHours']),
      timesPerDay: serializer.fromJson<int?>(json['timesPerDay']),
      timeWindow: serializer.fromJson<TimeWindow?>(json['timeWindow']),
      targetType: serializer.fromJson<HabitTargetType>(json['targetType']),
      targetValue: serializer.fromJson<double?>(json['targetValue']),
      miniTargetValue: serializer.fromJson<double?>(json['miniTargetValue']),
      eliteTargetValue: serializer.fromJson<double?>(json['eliteTargetValue']),
      unit: serializer.fromJson<String?>(json['unit']),
      pinned: serializer.fromJson<bool>(json['pinned']),
      reminderTimes: serializer.fromJson<List<String>>(json['reminderTimes']),
      motivationNotes: serializer.fromJson<String?>(json['motivationNotes']),
      archived: serializer.fromJson<bool>(json['archived']),
      promptReflection: serializer.fromJson<bool>(json['promptReflection']),
      healthMetric: serializer.fromJson<HealthMetricType?>(
        json['healthMetric'],
      ),
      healthSyncEnabled: serializer.fromJson<bool>(json['healthSyncEnabled']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'color': serializer.toJson<String>(color),
      'icon': serializer.toJson<String?>(icon),
      'categoryId': serializer.toJson<String?>(categoryId),
      'frequencyType': serializer.toJson<HabitFrequencyType>(frequencyType),
      'targetDaysOfWeek': serializer.toJson<List<int>?>(targetDaysOfWeek),
      'targetCountPerWeek': serializer.toJson<int?>(targetCountPerWeek),
      'intervalHours': serializer.toJson<int?>(intervalHours),
      'timesPerDay': serializer.toJson<int?>(timesPerDay),
      'timeWindow': serializer.toJson<TimeWindow?>(timeWindow),
      'targetType': serializer.toJson<HabitTargetType>(targetType),
      'targetValue': serializer.toJson<double?>(targetValue),
      'miniTargetValue': serializer.toJson<double?>(miniTargetValue),
      'eliteTargetValue': serializer.toJson<double?>(eliteTargetValue),
      'unit': serializer.toJson<String?>(unit),
      'pinned': serializer.toJson<bool>(pinned),
      'reminderTimes': serializer.toJson<List<String>>(reminderTimes),
      'motivationNotes': serializer.toJson<String?>(motivationNotes),
      'archived': serializer.toJson<bool>(archived),
      'promptReflection': serializer.toJson<bool>(promptReflection),
      'healthMetric': serializer.toJson<HealthMetricType?>(healthMetric),
      'healthSyncEnabled': serializer.toJson<bool>(healthSyncEnabled),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  HabitRow copyWith({
    String? id,
    String? title,
    Value<String?> description = const Value.absent(),
    String? color,
    Value<String?> icon = const Value.absent(),
    Value<String?> categoryId = const Value.absent(),
    HabitFrequencyType? frequencyType,
    Value<List<int>?> targetDaysOfWeek = const Value.absent(),
    Value<int?> targetCountPerWeek = const Value.absent(),
    Value<int?> intervalHours = const Value.absent(),
    Value<int?> timesPerDay = const Value.absent(),
    Value<TimeWindow?> timeWindow = const Value.absent(),
    HabitTargetType? targetType,
    Value<double?> targetValue = const Value.absent(),
    Value<double?> miniTargetValue = const Value.absent(),
    Value<double?> eliteTargetValue = const Value.absent(),
    Value<String?> unit = const Value.absent(),
    bool? pinned,
    List<String>? reminderTimes,
    Value<String?> motivationNotes = const Value.absent(),
    bool? archived,
    bool? promptReflection,
    Value<HealthMetricType?> healthMetric = const Value.absent(),
    bool? healthSyncEnabled,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => HabitRow(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    color: color ?? this.color,
    icon: icon.present ? icon.value : this.icon,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    frequencyType: frequencyType ?? this.frequencyType,
    targetDaysOfWeek: targetDaysOfWeek.present
        ? targetDaysOfWeek.value
        : this.targetDaysOfWeek,
    targetCountPerWeek: targetCountPerWeek.present
        ? targetCountPerWeek.value
        : this.targetCountPerWeek,
    intervalHours: intervalHours.present
        ? intervalHours.value
        : this.intervalHours,
    timesPerDay: timesPerDay.present ? timesPerDay.value : this.timesPerDay,
    timeWindow: timeWindow.present ? timeWindow.value : this.timeWindow,
    targetType: targetType ?? this.targetType,
    targetValue: targetValue.present ? targetValue.value : this.targetValue,
    miniTargetValue: miniTargetValue.present
        ? miniTargetValue.value
        : this.miniTargetValue,
    eliteTargetValue: eliteTargetValue.present
        ? eliteTargetValue.value
        : this.eliteTargetValue,
    unit: unit.present ? unit.value : this.unit,
    pinned: pinned ?? this.pinned,
    reminderTimes: reminderTimes ?? this.reminderTimes,
    motivationNotes: motivationNotes.present
        ? motivationNotes.value
        : this.motivationNotes,
    archived: archived ?? this.archived,
    promptReflection: promptReflection ?? this.promptReflection,
    healthMetric: healthMetric.present ? healthMetric.value : this.healthMetric,
    healthSyncEnabled: healthSyncEnabled ?? this.healthSyncEnabled,
    isDeleted: isDeleted ?? this.isDeleted,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  HabitRow copyWithCompanion(HabitsCompanion data) {
    return HabitRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      color: data.color.present ? data.color.value : this.color,
      icon: data.icon.present ? data.icon.value : this.icon,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      frequencyType: data.frequencyType.present
          ? data.frequencyType.value
          : this.frequencyType,
      targetDaysOfWeek: data.targetDaysOfWeek.present
          ? data.targetDaysOfWeek.value
          : this.targetDaysOfWeek,
      targetCountPerWeek: data.targetCountPerWeek.present
          ? data.targetCountPerWeek.value
          : this.targetCountPerWeek,
      intervalHours: data.intervalHours.present
          ? data.intervalHours.value
          : this.intervalHours,
      timesPerDay: data.timesPerDay.present
          ? data.timesPerDay.value
          : this.timesPerDay,
      timeWindow: data.timeWindow.present
          ? data.timeWindow.value
          : this.timeWindow,
      targetType: data.targetType.present
          ? data.targetType.value
          : this.targetType,
      targetValue: data.targetValue.present
          ? data.targetValue.value
          : this.targetValue,
      miniTargetValue: data.miniTargetValue.present
          ? data.miniTargetValue.value
          : this.miniTargetValue,
      eliteTargetValue: data.eliteTargetValue.present
          ? data.eliteTargetValue.value
          : this.eliteTargetValue,
      unit: data.unit.present ? data.unit.value : this.unit,
      pinned: data.pinned.present ? data.pinned.value : this.pinned,
      reminderTimes: data.reminderTimes.present
          ? data.reminderTimes.value
          : this.reminderTimes,
      motivationNotes: data.motivationNotes.present
          ? data.motivationNotes.value
          : this.motivationNotes,
      archived: data.archived.present ? data.archived.value : this.archived,
      promptReflection: data.promptReflection.present
          ? data.promptReflection.value
          : this.promptReflection,
      healthMetric: data.healthMetric.present
          ? data.healthMetric.value
          : this.healthMetric,
      healthSyncEnabled: data.healthSyncEnabled.present
          ? data.healthSyncEnabled.value
          : this.healthSyncEnabled,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HabitRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('color: $color, ')
          ..write('icon: $icon, ')
          ..write('categoryId: $categoryId, ')
          ..write('frequencyType: $frequencyType, ')
          ..write('targetDaysOfWeek: $targetDaysOfWeek, ')
          ..write('targetCountPerWeek: $targetCountPerWeek, ')
          ..write('intervalHours: $intervalHours, ')
          ..write('timesPerDay: $timesPerDay, ')
          ..write('timeWindow: $timeWindow, ')
          ..write('targetType: $targetType, ')
          ..write('targetValue: $targetValue, ')
          ..write('miniTargetValue: $miniTargetValue, ')
          ..write('eliteTargetValue: $eliteTargetValue, ')
          ..write('unit: $unit, ')
          ..write('pinned: $pinned, ')
          ..write('reminderTimes: $reminderTimes, ')
          ..write('motivationNotes: $motivationNotes, ')
          ..write('archived: $archived, ')
          ..write('promptReflection: $promptReflection, ')
          ..write('healthMetric: $healthMetric, ')
          ..write('healthSyncEnabled: $healthSyncEnabled, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    title,
    description,
    color,
    icon,
    categoryId,
    frequencyType,
    targetDaysOfWeek,
    targetCountPerWeek,
    intervalHours,
    timesPerDay,
    timeWindow,
    targetType,
    targetValue,
    miniTargetValue,
    eliteTargetValue,
    unit,
    pinned,
    reminderTimes,
    motivationNotes,
    archived,
    promptReflection,
    healthMetric,
    healthSyncEnabled,
    isDeleted,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HabitRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.color == this.color &&
          other.icon == this.icon &&
          other.categoryId == this.categoryId &&
          other.frequencyType == this.frequencyType &&
          other.targetDaysOfWeek == this.targetDaysOfWeek &&
          other.targetCountPerWeek == this.targetCountPerWeek &&
          other.intervalHours == this.intervalHours &&
          other.timesPerDay == this.timesPerDay &&
          other.timeWindow == this.timeWindow &&
          other.targetType == this.targetType &&
          other.targetValue == this.targetValue &&
          other.miniTargetValue == this.miniTargetValue &&
          other.eliteTargetValue == this.eliteTargetValue &&
          other.unit == this.unit &&
          other.pinned == this.pinned &&
          other.reminderTimes == this.reminderTimes &&
          other.motivationNotes == this.motivationNotes &&
          other.archived == this.archived &&
          other.promptReflection == this.promptReflection &&
          other.healthMetric == this.healthMetric &&
          other.healthSyncEnabled == this.healthSyncEnabled &&
          other.isDeleted == this.isDeleted &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class HabitsCompanion extends UpdateCompanion<HabitRow> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> description;
  final Value<String> color;
  final Value<String?> icon;
  final Value<String?> categoryId;
  final Value<HabitFrequencyType> frequencyType;
  final Value<List<int>?> targetDaysOfWeek;
  final Value<int?> targetCountPerWeek;
  final Value<int?> intervalHours;
  final Value<int?> timesPerDay;
  final Value<TimeWindow?> timeWindow;
  final Value<HabitTargetType> targetType;
  final Value<double?> targetValue;
  final Value<double?> miniTargetValue;
  final Value<double?> eliteTargetValue;
  final Value<String?> unit;
  final Value<bool> pinned;
  final Value<List<String>> reminderTimes;
  final Value<String?> motivationNotes;
  final Value<bool> archived;
  final Value<bool> promptReflection;
  final Value<HealthMetricType?> healthMetric;
  final Value<bool> healthSyncEnabled;
  final Value<bool> isDeleted;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const HabitsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.color = const Value.absent(),
    this.icon = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.frequencyType = const Value.absent(),
    this.targetDaysOfWeek = const Value.absent(),
    this.targetCountPerWeek = const Value.absent(),
    this.intervalHours = const Value.absent(),
    this.timesPerDay = const Value.absent(),
    this.timeWindow = const Value.absent(),
    this.targetType = const Value.absent(),
    this.targetValue = const Value.absent(),
    this.miniTargetValue = const Value.absent(),
    this.eliteTargetValue = const Value.absent(),
    this.unit = const Value.absent(),
    this.pinned = const Value.absent(),
    this.reminderTimes = const Value.absent(),
    this.motivationNotes = const Value.absent(),
    this.archived = const Value.absent(),
    this.promptReflection = const Value.absent(),
    this.healthMetric = const Value.absent(),
    this.healthSyncEnabled = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HabitsCompanion.insert({
    required String id,
    required String title,
    this.description = const Value.absent(),
    required String color,
    this.icon = const Value.absent(),
    this.categoryId = const Value.absent(),
    required HabitFrequencyType frequencyType,
    this.targetDaysOfWeek = const Value.absent(),
    this.targetCountPerWeek = const Value.absent(),
    this.intervalHours = const Value.absent(),
    this.timesPerDay = const Value.absent(),
    this.timeWindow = const Value.absent(),
    required HabitTargetType targetType,
    this.targetValue = const Value.absent(),
    this.miniTargetValue = const Value.absent(),
    this.eliteTargetValue = const Value.absent(),
    this.unit = const Value.absent(),
    this.pinned = const Value.absent(),
    this.reminderTimes = const Value.absent(),
    this.motivationNotes = const Value.absent(),
    this.archived = const Value.absent(),
    this.promptReflection = const Value.absent(),
    this.healthMetric = const Value.absent(),
    this.healthSyncEnabled = const Value.absent(),
    this.isDeleted = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       color = Value(color),
       frequencyType = Value(frequencyType),
       targetType = Value(targetType),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<HabitRow> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? color,
    Expression<String>? icon,
    Expression<String>? categoryId,
    Expression<String>? frequencyType,
    Expression<String>? targetDaysOfWeek,
    Expression<int>? targetCountPerWeek,
    Expression<int>? intervalHours,
    Expression<int>? timesPerDay,
    Expression<String>? timeWindow,
    Expression<String>? targetType,
    Expression<double>? targetValue,
    Expression<double>? miniTargetValue,
    Expression<double>? eliteTargetValue,
    Expression<String>? unit,
    Expression<bool>? pinned,
    Expression<String>? reminderTimes,
    Expression<String>? motivationNotes,
    Expression<bool>? archived,
    Expression<bool>? promptReflection,
    Expression<String>? healthMetric,
    Expression<bool>? healthSyncEnabled,
    Expression<bool>? isDeleted,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (color != null) 'color': color,
      if (icon != null) 'icon': icon,
      if (categoryId != null) 'category_id': categoryId,
      if (frequencyType != null) 'frequency_type': frequencyType,
      if (targetDaysOfWeek != null) 'target_days_of_week': targetDaysOfWeek,
      if (targetCountPerWeek != null)
        'target_count_per_week': targetCountPerWeek,
      if (intervalHours != null) 'interval_hours': intervalHours,
      if (timesPerDay != null) 'times_per_day': timesPerDay,
      if (timeWindow != null) 'time_window': timeWindow,
      if (targetType != null) 'target_type': targetType,
      if (targetValue != null) 'target_value': targetValue,
      if (miniTargetValue != null) 'mini_target_value': miniTargetValue,
      if (eliteTargetValue != null) 'elite_target_value': eliteTargetValue,
      if (unit != null) 'unit': unit,
      if (pinned != null) 'pinned': pinned,
      if (reminderTimes != null) 'reminder_times': reminderTimes,
      if (motivationNotes != null) 'motivation_notes': motivationNotes,
      if (archived != null) 'archived': archived,
      if (promptReflection != null) 'prompt_reflection': promptReflection,
      if (healthMetric != null) 'health_metric': healthMetric,
      if (healthSyncEnabled != null) 'health_sync_enabled': healthSyncEnabled,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HabitsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String?>? description,
    Value<String>? color,
    Value<String?>? icon,
    Value<String?>? categoryId,
    Value<HabitFrequencyType>? frequencyType,
    Value<List<int>?>? targetDaysOfWeek,
    Value<int?>? targetCountPerWeek,
    Value<int?>? intervalHours,
    Value<int?>? timesPerDay,
    Value<TimeWindow?>? timeWindow,
    Value<HabitTargetType>? targetType,
    Value<double?>? targetValue,
    Value<double?>? miniTargetValue,
    Value<double?>? eliteTargetValue,
    Value<String?>? unit,
    Value<bool>? pinned,
    Value<List<String>>? reminderTimes,
    Value<String?>? motivationNotes,
    Value<bool>? archived,
    Value<bool>? promptReflection,
    Value<HealthMetricType?>? healthMetric,
    Value<bool>? healthSyncEnabled,
    Value<bool>? isDeleted,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return HabitsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      categoryId: categoryId ?? this.categoryId,
      frequencyType: frequencyType ?? this.frequencyType,
      targetDaysOfWeek: targetDaysOfWeek ?? this.targetDaysOfWeek,
      targetCountPerWeek: targetCountPerWeek ?? this.targetCountPerWeek,
      intervalHours: intervalHours ?? this.intervalHours,
      timesPerDay: timesPerDay ?? this.timesPerDay,
      timeWindow: timeWindow ?? this.timeWindow,
      targetType: targetType ?? this.targetType,
      targetValue: targetValue ?? this.targetValue,
      miniTargetValue: miniTargetValue ?? this.miniTargetValue,
      eliteTargetValue: eliteTargetValue ?? this.eliteTargetValue,
      unit: unit ?? this.unit,
      pinned: pinned ?? this.pinned,
      reminderTimes: reminderTimes ?? this.reminderTimes,
      motivationNotes: motivationNotes ?? this.motivationNotes,
      archived: archived ?? this.archived,
      promptReflection: promptReflection ?? this.promptReflection,
      healthMetric: healthMetric ?? this.healthMetric,
      healthSyncEnabled: healthSyncEnabled ?? this.healthSyncEnabled,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (frequencyType.present) {
      map['frequency_type'] = Variable<String>(
        $HabitsTable.$converterfrequencyType.toSql(frequencyType.value),
      );
    }
    if (targetDaysOfWeek.present) {
      map['target_days_of_week'] = Variable<String>(
        $HabitsTable.$convertertargetDaysOfWeekn.toSql(targetDaysOfWeek.value),
      );
    }
    if (targetCountPerWeek.present) {
      map['target_count_per_week'] = Variable<int>(targetCountPerWeek.value);
    }
    if (intervalHours.present) {
      map['interval_hours'] = Variable<int>(intervalHours.value);
    }
    if (timesPerDay.present) {
      map['times_per_day'] = Variable<int>(timesPerDay.value);
    }
    if (timeWindow.present) {
      map['time_window'] = Variable<String>(
        $HabitsTable.$convertertimeWindown.toSql(timeWindow.value),
      );
    }
    if (targetType.present) {
      map['target_type'] = Variable<String>(
        $HabitsTable.$convertertargetType.toSql(targetType.value),
      );
    }
    if (targetValue.present) {
      map['target_value'] = Variable<double>(targetValue.value);
    }
    if (miniTargetValue.present) {
      map['mini_target_value'] = Variable<double>(miniTargetValue.value);
    }
    if (eliteTargetValue.present) {
      map['elite_target_value'] = Variable<double>(eliteTargetValue.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (pinned.present) {
      map['pinned'] = Variable<bool>(pinned.value);
    }
    if (reminderTimes.present) {
      map['reminder_times'] = Variable<String>(
        $HabitsTable.$converterreminderTimes.toSql(reminderTimes.value),
      );
    }
    if (motivationNotes.present) {
      map['motivation_notes'] = Variable<String>(motivationNotes.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (promptReflection.present) {
      map['prompt_reflection'] = Variable<bool>(promptReflection.value);
    }
    if (healthMetric.present) {
      map['health_metric'] = Variable<String>(
        $HabitsTable.$converterhealthMetric.toSql(healthMetric.value),
      );
    }
    if (healthSyncEnabled.present) {
      map['health_sync_enabled'] = Variable<bool>(healthSyncEnabled.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HabitsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('color: $color, ')
          ..write('icon: $icon, ')
          ..write('categoryId: $categoryId, ')
          ..write('frequencyType: $frequencyType, ')
          ..write('targetDaysOfWeek: $targetDaysOfWeek, ')
          ..write('targetCountPerWeek: $targetCountPerWeek, ')
          ..write('intervalHours: $intervalHours, ')
          ..write('timesPerDay: $timesPerDay, ')
          ..write('timeWindow: $timeWindow, ')
          ..write('targetType: $targetType, ')
          ..write('targetValue: $targetValue, ')
          ..write('miniTargetValue: $miniTargetValue, ')
          ..write('eliteTargetValue: $eliteTargetValue, ')
          ..write('unit: $unit, ')
          ..write('pinned: $pinned, ')
          ..write('reminderTimes: $reminderTimes, ')
          ..write('motivationNotes: $motivationNotes, ')
          ..write('archived: $archived, ')
          ..write('promptReflection: $promptReflection, ')
          ..write('healthMetric: $healthMetric, ')
          ..write('healthSyncEnabled: $healthSyncEnabled, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HabitLogsTable extends HabitLogs
    with TableInfo<$HabitLogsTable, HabitLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HabitLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _habitIdMeta = const VerificationMeta(
    'habitId',
  );
  @override
  late final GeneratedColumn<String> habitId = GeneratedColumn<String>(
    'habit_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES habits (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _intervalIndexMeta = const VerificationMeta(
    'intervalIndex',
  );
  @override
  late final GeneratedColumn<int> intervalIndex = GeneratedColumn<int>(
    'interval_index',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedMeta = const VerificationMeta(
    'completed',
  );
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
    'completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("completed" IN (0, 1))',
    ),
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
    'value',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<HabitTier?, String> targetTier =
      GeneratedColumn<String>(
        'target_tier',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<HabitTier?>($HabitLogsTable.$convertertargetTier);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _energyLevelMeta = const VerificationMeta(
    'energyLevel',
  );
  @override
  late final GeneratedColumn<int> energyLevel = GeneratedColumn<int>(
    'energy_level',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _moodMeta = const VerificationMeta('mood');
  @override
  late final GeneratedColumn<String> mood = GeneratedColumn<String>(
    'mood',
    aliasedName,
    true,
    type: DriftSqlType.string,
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
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    habitId,
    date,
    timestamp,
    intervalIndex,
    completed,
    value,
    durationSeconds,
    targetTier,
    note,
    energyLevel,
    mood,
    isDeleted,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'habit_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<HabitLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('habit_id')) {
      context.handle(
        _habitIdMeta,
        habitId.isAcceptableOrUnknown(data['habit_id']!, _habitIdMeta),
      );
    } else if (isInserting) {
      context.missing(_habitIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('interval_index')) {
      context.handle(
        _intervalIndexMeta,
        intervalIndex.isAcceptableOrUnknown(
          data['interval_index']!,
          _intervalIndexMeta,
        ),
      );
    }
    if (data.containsKey('completed')) {
      context.handle(
        _completedMeta,
        completed.isAcceptableOrUnknown(data['completed']!, _completedMeta),
      );
    } else if (isInserting) {
      context.missing(_completedMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('energy_level')) {
      context.handle(
        _energyLevelMeta,
        energyLevel.isAcceptableOrUnknown(
          data['energy_level']!,
          _energyLevelMeta,
        ),
      );
    }
    if (data.containsKey('mood')) {
      context.handle(
        _moodMeta,
        mood.isAcceptableOrUnknown(data['mood']!, _moodMeta),
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
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HabitLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HabitLogRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      habitId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}habit_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      intervalIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_index'],
      ),
      completed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}completed'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}value'],
      ),
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      ),
      targetTier: $HabitLogsTable.$convertertargetTier.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}target_tier'],
        ),
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      energyLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}energy_level'],
      ),
      mood: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mood'],
      ),
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $HabitLogsTable createAlias(String alias) {
    return $HabitLogsTable(attachedDatabase, alias);
  }

  static TypeConverter<HabitTier?, String?> $convertertargetTier =
      const HabitTierConverter();
}

class HabitLogRow extends DataClass implements Insertable<HabitLogRow> {
  final String id;
  final String habitId;
  final String date;
  final DateTime timestamp;
  final int? intervalIndex;
  final bool completed;
  final double? value;
  final int? durationSeconds;
  final HabitTier? targetTier;
  final String? note;
  final int? energyLevel;
  final String? mood;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  const HabitLogRow({
    required this.id,
    required this.habitId,
    required this.date,
    required this.timestamp,
    this.intervalIndex,
    required this.completed,
    this.value,
    this.durationSeconds,
    this.targetTier,
    this.note,
    this.energyLevel,
    this.mood,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['habit_id'] = Variable<String>(habitId);
    map['date'] = Variable<String>(date);
    map['timestamp'] = Variable<DateTime>(timestamp);
    if (!nullToAbsent || intervalIndex != null) {
      map['interval_index'] = Variable<int>(intervalIndex);
    }
    map['completed'] = Variable<bool>(completed);
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<double>(value);
    }
    if (!nullToAbsent || durationSeconds != null) {
      map['duration_seconds'] = Variable<int>(durationSeconds);
    }
    if (!nullToAbsent || targetTier != null) {
      map['target_tier'] = Variable<String>(
        $HabitLogsTable.$convertertargetTier.toSql(targetTier),
      );
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || energyLevel != null) {
      map['energy_level'] = Variable<int>(energyLevel);
    }
    if (!nullToAbsent || mood != null) {
      map['mood'] = Variable<String>(mood);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  HabitLogsCompanion toCompanion(bool nullToAbsent) {
    return HabitLogsCompanion(
      id: Value(id),
      habitId: Value(habitId),
      date: Value(date),
      timestamp: Value(timestamp),
      intervalIndex: intervalIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(intervalIndex),
      completed: Value(completed),
      value: value == null && nullToAbsent
          ? const Value.absent()
          : Value(value),
      durationSeconds: durationSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSeconds),
      targetTier: targetTier == null && nullToAbsent
          ? const Value.absent()
          : Value(targetTier),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      energyLevel: energyLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(energyLevel),
      mood: mood == null && nullToAbsent ? const Value.absent() : Value(mood),
      isDeleted: Value(isDeleted),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory HabitLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HabitLogRow(
      id: serializer.fromJson<String>(json['id']),
      habitId: serializer.fromJson<String>(json['habitId']),
      date: serializer.fromJson<String>(json['date']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      intervalIndex: serializer.fromJson<int?>(json['intervalIndex']),
      completed: serializer.fromJson<bool>(json['completed']),
      value: serializer.fromJson<double?>(json['value']),
      durationSeconds: serializer.fromJson<int?>(json['durationSeconds']),
      targetTier: serializer.fromJson<HabitTier?>(json['targetTier']),
      note: serializer.fromJson<String?>(json['note']),
      energyLevel: serializer.fromJson<int?>(json['energyLevel']),
      mood: serializer.fromJson<String?>(json['mood']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'habitId': serializer.toJson<String>(habitId),
      'date': serializer.toJson<String>(date),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'intervalIndex': serializer.toJson<int?>(intervalIndex),
      'completed': serializer.toJson<bool>(completed),
      'value': serializer.toJson<double?>(value),
      'durationSeconds': serializer.toJson<int?>(durationSeconds),
      'targetTier': serializer.toJson<HabitTier?>(targetTier),
      'note': serializer.toJson<String?>(note),
      'energyLevel': serializer.toJson<int?>(energyLevel),
      'mood': serializer.toJson<String?>(mood),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  HabitLogRow copyWith({
    String? id,
    String? habitId,
    String? date,
    DateTime? timestamp,
    Value<int?> intervalIndex = const Value.absent(),
    bool? completed,
    Value<double?> value = const Value.absent(),
    Value<int?> durationSeconds = const Value.absent(),
    Value<HabitTier?> targetTier = const Value.absent(),
    Value<String?> note = const Value.absent(),
    Value<int?> energyLevel = const Value.absent(),
    Value<String?> mood = const Value.absent(),
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => HabitLogRow(
    id: id ?? this.id,
    habitId: habitId ?? this.habitId,
    date: date ?? this.date,
    timestamp: timestamp ?? this.timestamp,
    intervalIndex: intervalIndex.present
        ? intervalIndex.value
        : this.intervalIndex,
    completed: completed ?? this.completed,
    value: value.present ? value.value : this.value,
    durationSeconds: durationSeconds.present
        ? durationSeconds.value
        : this.durationSeconds,
    targetTier: targetTier.present ? targetTier.value : this.targetTier,
    note: note.present ? note.value : this.note,
    energyLevel: energyLevel.present ? energyLevel.value : this.energyLevel,
    mood: mood.present ? mood.value : this.mood,
    isDeleted: isDeleted ?? this.isDeleted,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  HabitLogRow copyWithCompanion(HabitLogsCompanion data) {
    return HabitLogRow(
      id: data.id.present ? data.id.value : this.id,
      habitId: data.habitId.present ? data.habitId.value : this.habitId,
      date: data.date.present ? data.date.value : this.date,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      intervalIndex: data.intervalIndex.present
          ? data.intervalIndex.value
          : this.intervalIndex,
      completed: data.completed.present ? data.completed.value : this.completed,
      value: data.value.present ? data.value.value : this.value,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      targetTier: data.targetTier.present
          ? data.targetTier.value
          : this.targetTier,
      note: data.note.present ? data.note.value : this.note,
      energyLevel: data.energyLevel.present
          ? data.energyLevel.value
          : this.energyLevel,
      mood: data.mood.present ? data.mood.value : this.mood,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HabitLogRow(')
          ..write('id: $id, ')
          ..write('habitId: $habitId, ')
          ..write('date: $date, ')
          ..write('timestamp: $timestamp, ')
          ..write('intervalIndex: $intervalIndex, ')
          ..write('completed: $completed, ')
          ..write('value: $value, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('targetTier: $targetTier, ')
          ..write('note: $note, ')
          ..write('energyLevel: $energyLevel, ')
          ..write('mood: $mood, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    habitId,
    date,
    timestamp,
    intervalIndex,
    completed,
    value,
    durationSeconds,
    targetTier,
    note,
    energyLevel,
    mood,
    isDeleted,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HabitLogRow &&
          other.id == this.id &&
          other.habitId == this.habitId &&
          other.date == this.date &&
          other.timestamp == this.timestamp &&
          other.intervalIndex == this.intervalIndex &&
          other.completed == this.completed &&
          other.value == this.value &&
          other.durationSeconds == this.durationSeconds &&
          other.targetTier == this.targetTier &&
          other.note == this.note &&
          other.energyLevel == this.energyLevel &&
          other.mood == this.mood &&
          other.isDeleted == this.isDeleted &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class HabitLogsCompanion extends UpdateCompanion<HabitLogRow> {
  final Value<String> id;
  final Value<String> habitId;
  final Value<String> date;
  final Value<DateTime> timestamp;
  final Value<int?> intervalIndex;
  final Value<bool> completed;
  final Value<double?> value;
  final Value<int?> durationSeconds;
  final Value<HabitTier?> targetTier;
  final Value<String?> note;
  final Value<int?> energyLevel;
  final Value<String?> mood;
  final Value<bool> isDeleted;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const HabitLogsCompanion({
    this.id = const Value.absent(),
    this.habitId = const Value.absent(),
    this.date = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.intervalIndex = const Value.absent(),
    this.completed = const Value.absent(),
    this.value = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.targetTier = const Value.absent(),
    this.note = const Value.absent(),
    this.energyLevel = const Value.absent(),
    this.mood = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HabitLogsCompanion.insert({
    required String id,
    required String habitId,
    required String date,
    required DateTime timestamp,
    this.intervalIndex = const Value.absent(),
    required bool completed,
    this.value = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.targetTier = const Value.absent(),
    this.note = const Value.absent(),
    this.energyLevel = const Value.absent(),
    this.mood = const Value.absent(),
    this.isDeleted = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       habitId = Value(habitId),
       date = Value(date),
       timestamp = Value(timestamp),
       completed = Value(completed),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<HabitLogRow> custom({
    Expression<String>? id,
    Expression<String>? habitId,
    Expression<String>? date,
    Expression<DateTime>? timestamp,
    Expression<int>? intervalIndex,
    Expression<bool>? completed,
    Expression<double>? value,
    Expression<int>? durationSeconds,
    Expression<String>? targetTier,
    Expression<String>? note,
    Expression<int>? energyLevel,
    Expression<String>? mood,
    Expression<bool>? isDeleted,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (habitId != null) 'habit_id': habitId,
      if (date != null) 'date': date,
      if (timestamp != null) 'timestamp': timestamp,
      if (intervalIndex != null) 'interval_index': intervalIndex,
      if (completed != null) 'completed': completed,
      if (value != null) 'value': value,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (targetTier != null) 'target_tier': targetTier,
      if (note != null) 'note': note,
      if (energyLevel != null) 'energy_level': energyLevel,
      if (mood != null) 'mood': mood,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HabitLogsCompanion copyWith({
    Value<String>? id,
    Value<String>? habitId,
    Value<String>? date,
    Value<DateTime>? timestamp,
    Value<int?>? intervalIndex,
    Value<bool>? completed,
    Value<double?>? value,
    Value<int?>? durationSeconds,
    Value<HabitTier?>? targetTier,
    Value<String?>? note,
    Value<int?>? energyLevel,
    Value<String?>? mood,
    Value<bool>? isDeleted,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return HabitLogsCompanion(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      date: date ?? this.date,
      timestamp: timestamp ?? this.timestamp,
      intervalIndex: intervalIndex ?? this.intervalIndex,
      completed: completed ?? this.completed,
      value: value ?? this.value,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      targetTier: targetTier ?? this.targetTier,
      note: note ?? this.note,
      energyLevel: energyLevel ?? this.energyLevel,
      mood: mood ?? this.mood,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (habitId.present) {
      map['habit_id'] = Variable<String>(habitId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (intervalIndex.present) {
      map['interval_index'] = Variable<int>(intervalIndex.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (targetTier.present) {
      map['target_tier'] = Variable<String>(
        $HabitLogsTable.$convertertargetTier.toSql(targetTier.value),
      );
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (energyLevel.present) {
      map['energy_level'] = Variable<int>(energyLevel.value);
    }
    if (mood.present) {
      map['mood'] = Variable<String>(mood.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HabitLogsCompanion(')
          ..write('id: $id, ')
          ..write('habitId: $habitId, ')
          ..write('date: $date, ')
          ..write('timestamp: $timestamp, ')
          ..write('intervalIndex: $intervalIndex, ')
          ..write('completed: $completed, ')
          ..write('value: $value, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('targetTier: $targetTier, ')
          ..write('note: $note, ')
          ..write('energyLevel: $energyLevel, ')
          ..write('mood: $mood, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HabitShieldsTable extends HabitShields
    with TableInfo<$HabitShieldsTable, HabitShieldRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HabitShieldsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _habitIdMeta = const VerificationMeta(
    'habitId',
  );
  @override
  late final GeneratedColumn<String> habitId = GeneratedColumn<String>(
    'habit_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES habits (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _autoAppliedMeta = const VerificationMeta(
    'autoApplied',
  );
  @override
  late final GeneratedColumn<bool> autoApplied = GeneratedColumn<bool>(
    'auto_applied',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("auto_applied" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    habitId,
    date,
    autoApplied,
    isDeleted,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'habit_shields';
  @override
  VerificationContext validateIntegrity(
    Insertable<HabitShieldRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('habit_id')) {
      context.handle(
        _habitIdMeta,
        habitId.isAcceptableOrUnknown(data['habit_id']!, _habitIdMeta),
      );
    } else if (isInserting) {
      context.missing(_habitIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('auto_applied')) {
      context.handle(
        _autoAppliedMeta,
        autoApplied.isAcceptableOrUnknown(
          data['auto_applied']!,
          _autoAppliedMeta,
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
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HabitShieldRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HabitShieldRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      habitId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}habit_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      autoApplied: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto_applied'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $HabitShieldsTable createAlias(String alias) {
    return $HabitShieldsTable(attachedDatabase, alias);
  }
}

class HabitShieldRow extends DataClass implements Insertable<HabitShieldRow> {
  final String id;
  final String habitId;
  final String date;
  final bool autoApplied;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  const HabitShieldRow({
    required this.id,
    required this.habitId,
    required this.date,
    required this.autoApplied,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['habit_id'] = Variable<String>(habitId);
    map['date'] = Variable<String>(date);
    map['auto_applied'] = Variable<bool>(autoApplied);
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  HabitShieldsCompanion toCompanion(bool nullToAbsent) {
    return HabitShieldsCompanion(
      id: Value(id),
      habitId: Value(habitId),
      date: Value(date),
      autoApplied: Value(autoApplied),
      isDeleted: Value(isDeleted),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory HabitShieldRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HabitShieldRow(
      id: serializer.fromJson<String>(json['id']),
      habitId: serializer.fromJson<String>(json['habitId']),
      date: serializer.fromJson<String>(json['date']),
      autoApplied: serializer.fromJson<bool>(json['autoApplied']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'habitId': serializer.toJson<String>(habitId),
      'date': serializer.toJson<String>(date),
      'autoApplied': serializer.toJson<bool>(autoApplied),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  HabitShieldRow copyWith({
    String? id,
    String? habitId,
    String? date,
    bool? autoApplied,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => HabitShieldRow(
    id: id ?? this.id,
    habitId: habitId ?? this.habitId,
    date: date ?? this.date,
    autoApplied: autoApplied ?? this.autoApplied,
    isDeleted: isDeleted ?? this.isDeleted,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  HabitShieldRow copyWithCompanion(HabitShieldsCompanion data) {
    return HabitShieldRow(
      id: data.id.present ? data.id.value : this.id,
      habitId: data.habitId.present ? data.habitId.value : this.habitId,
      date: data.date.present ? data.date.value : this.date,
      autoApplied: data.autoApplied.present
          ? data.autoApplied.value
          : this.autoApplied,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HabitShieldRow(')
          ..write('id: $id, ')
          ..write('habitId: $habitId, ')
          ..write('date: $date, ')
          ..write('autoApplied: $autoApplied, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    habitId,
    date,
    autoApplied,
    isDeleted,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HabitShieldRow &&
          other.id == this.id &&
          other.habitId == this.habitId &&
          other.date == this.date &&
          other.autoApplied == this.autoApplied &&
          other.isDeleted == this.isDeleted &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class HabitShieldsCompanion extends UpdateCompanion<HabitShieldRow> {
  final Value<String> id;
  final Value<String> habitId;
  final Value<String> date;
  final Value<bool> autoApplied;
  final Value<bool> isDeleted;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const HabitShieldsCompanion({
    this.id = const Value.absent(),
    this.habitId = const Value.absent(),
    this.date = const Value.absent(),
    this.autoApplied = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HabitShieldsCompanion.insert({
    required String id,
    required String habitId,
    required String date,
    this.autoApplied = const Value.absent(),
    this.isDeleted = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       habitId = Value(habitId),
       date = Value(date),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<HabitShieldRow> custom({
    Expression<String>? id,
    Expression<String>? habitId,
    Expression<String>? date,
    Expression<bool>? autoApplied,
    Expression<bool>? isDeleted,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (habitId != null) 'habit_id': habitId,
      if (date != null) 'date': date,
      if (autoApplied != null) 'auto_applied': autoApplied,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HabitShieldsCompanion copyWith({
    Value<String>? id,
    Value<String>? habitId,
    Value<String>? date,
    Value<bool>? autoApplied,
    Value<bool>? isDeleted,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return HabitShieldsCompanion(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      date: date ?? this.date,
      autoApplied: autoApplied ?? this.autoApplied,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (habitId.present) {
      map['habit_id'] = Variable<String>(habitId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (autoApplied.present) {
      map['auto_applied'] = Variable<bool>(autoApplied.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HabitShieldsCompanion(')
          ..write('id: $id, ')
          ..write('habitId: $habitId, ')
          ..write('date: $date, ')
          ..write('autoApplied: $autoApplied, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HabitCategoriesTable extends HabitCategories
    with TableInfo<$HabitCategoriesTable, HabitCategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HabitCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
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
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    color,
    icon,
    isDeleted,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'habit_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<HabitCategoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    } else if (isInserting) {
      context.missing(_colorMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
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
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HabitCategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HabitCategoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      ),
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $HabitCategoriesTable createAlias(String alias) {
    return $HabitCategoriesTable(attachedDatabase, alias);
  }
}

class HabitCategoryRow extends DataClass
    implements Insertable<HabitCategoryRow> {
  final String id;
  final String name;
  final String color;
  final String? icon;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  const HabitCategoryRow({
    required this.id,
    required this.name,
    required this.color,
    this.icon,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['color'] = Variable<String>(color);
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  HabitCategoriesCompanion toCompanion(bool nullToAbsent) {
    return HabitCategoriesCompanion(
      id: Value(id),
      name: Value(name),
      color: Value(color),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      isDeleted: Value(isDeleted),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory HabitCategoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HabitCategoryRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<String>(json['color']),
      icon: serializer.fromJson<String?>(json['icon']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<String>(color),
      'icon': serializer.toJson<String?>(icon),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  HabitCategoryRow copyWith({
    String? id,
    String? name,
    String? color,
    Value<String?> icon = const Value.absent(),
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => HabitCategoryRow(
    id: id ?? this.id,
    name: name ?? this.name,
    color: color ?? this.color,
    icon: icon.present ? icon.value : this.icon,
    isDeleted: isDeleted ?? this.isDeleted,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  HabitCategoryRow copyWithCompanion(HabitCategoriesCompanion data) {
    return HabitCategoryRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
      icon: data.icon.present ? data.icon.value : this.icon,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HabitCategoryRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('icon: $icon, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, color, icon, isDeleted, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HabitCategoryRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.color == this.color &&
          other.icon == this.icon &&
          other.isDeleted == this.isDeleted &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class HabitCategoriesCompanion extends UpdateCompanion<HabitCategoryRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> color;
  final Value<String?> icon;
  final Value<bool> isDeleted;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const HabitCategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    this.icon = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HabitCategoriesCompanion.insert({
    required String id,
    required String name,
    required String color,
    this.icon = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       color = Value(color);
  static Insertable<HabitCategoryRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? color,
    Expression<String>? icon,
    Expression<bool>? isDeleted,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      if (icon != null) 'icon': icon,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HabitCategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? color,
    Value<String?>? icon,
    Value<bool>? isDeleted,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return HabitCategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HabitCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('icon: $icon, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserGamificationTable extends UserGamification
    with TableInfo<$UserGamificationTable, UserGamificationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserGamificationTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('user_gamification'),
  );
  static const VerificationMeta _totalXpMeta = const VerificationMeta(
    'totalXp',
  );
  @override
  late final GeneratedColumn<int> totalXp = GeneratedColumn<int>(
    'total_xp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _currentLevelMeta = const VerificationMeta(
    'currentLevel',
  );
  @override
  late final GeneratedColumn<int> currentLevel = GeneratedColumn<int>(
    'current_level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _lastCelebratedLevelMeta =
      const VerificationMeta('lastCelebratedLevel');
  @override
  late final GeneratedColumn<int> lastCelebratedLevel = GeneratedColumn<int>(
    'last_celebrated_level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _maxShieldsCapacityMeta =
      const VerificationMeta('maxShieldsCapacity');
  @override
  late final GeneratedColumn<int> maxShieldsCapacity = GeneratedColumn<int>(
    'max_shields_capacity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(3),
  );
  static const VerificationMeta _autoConsumeShieldsMeta =
      const VerificationMeta('autoConsumeShields');
  @override
  late final GeneratedColumn<bool> autoConsumeShields = GeneratedColumn<bool>(
    'auto_consume_shields',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("auto_consume_shields" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    totalXp,
    currentLevel,
    lastCelebratedLevel,
    maxShieldsCapacity,
    autoConsumeShields,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_gamification';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserGamificationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('total_xp')) {
      context.handle(
        _totalXpMeta,
        totalXp.isAcceptableOrUnknown(data['total_xp']!, _totalXpMeta),
      );
    }
    if (data.containsKey('current_level')) {
      context.handle(
        _currentLevelMeta,
        currentLevel.isAcceptableOrUnknown(
          data['current_level']!,
          _currentLevelMeta,
        ),
      );
    }
    if (data.containsKey('last_celebrated_level')) {
      context.handle(
        _lastCelebratedLevelMeta,
        lastCelebratedLevel.isAcceptableOrUnknown(
          data['last_celebrated_level']!,
          _lastCelebratedLevelMeta,
        ),
      );
    }
    if (data.containsKey('max_shields_capacity')) {
      context.handle(
        _maxShieldsCapacityMeta,
        maxShieldsCapacity.isAcceptableOrUnknown(
          data['max_shields_capacity']!,
          _maxShieldsCapacityMeta,
        ),
      );
    }
    if (data.containsKey('auto_consume_shields')) {
      context.handle(
        _autoConsumeShieldsMeta,
        autoConsumeShields.isAcceptableOrUnknown(
          data['auto_consume_shields']!,
          _autoConsumeShieldsMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserGamificationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserGamificationRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      totalXp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_xp'],
      )!,
      currentLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_level'],
      )!,
      lastCelebratedLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_celebrated_level'],
      )!,
      maxShieldsCapacity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_shields_capacity'],
      )!,
      autoConsumeShields: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto_consume_shields'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $UserGamificationTable createAlias(String alias) {
    return $UserGamificationTable(attachedDatabase, alias);
  }
}

class UserGamificationRow extends DataClass
    implements Insertable<UserGamificationRow> {
  final String id;
  final int totalXp;
  final int currentLevel;
  final int lastCelebratedLevel;
  final int maxShieldsCapacity;
  final bool autoConsumeShields;
  final DateTime updatedAt;
  const UserGamificationRow({
    required this.id,
    required this.totalXp,
    required this.currentLevel,
    required this.lastCelebratedLevel,
    required this.maxShieldsCapacity,
    required this.autoConsumeShields,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['total_xp'] = Variable<int>(totalXp);
    map['current_level'] = Variable<int>(currentLevel);
    map['last_celebrated_level'] = Variable<int>(lastCelebratedLevel);
    map['max_shields_capacity'] = Variable<int>(maxShieldsCapacity);
    map['auto_consume_shields'] = Variable<bool>(autoConsumeShields);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  UserGamificationCompanion toCompanion(bool nullToAbsent) {
    return UserGamificationCompanion(
      id: Value(id),
      totalXp: Value(totalXp),
      currentLevel: Value(currentLevel),
      lastCelebratedLevel: Value(lastCelebratedLevel),
      maxShieldsCapacity: Value(maxShieldsCapacity),
      autoConsumeShields: Value(autoConsumeShields),
      updatedAt: Value(updatedAt),
    );
  }

  factory UserGamificationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserGamificationRow(
      id: serializer.fromJson<String>(json['id']),
      totalXp: serializer.fromJson<int>(json['totalXp']),
      currentLevel: serializer.fromJson<int>(json['currentLevel']),
      lastCelebratedLevel: serializer.fromJson<int>(
        json['lastCelebratedLevel'],
      ),
      maxShieldsCapacity: serializer.fromJson<int>(json['maxShieldsCapacity']),
      autoConsumeShields: serializer.fromJson<bool>(json['autoConsumeShields']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'totalXp': serializer.toJson<int>(totalXp),
      'currentLevel': serializer.toJson<int>(currentLevel),
      'lastCelebratedLevel': serializer.toJson<int>(lastCelebratedLevel),
      'maxShieldsCapacity': serializer.toJson<int>(maxShieldsCapacity),
      'autoConsumeShields': serializer.toJson<bool>(autoConsumeShields),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  UserGamificationRow copyWith({
    String? id,
    int? totalXp,
    int? currentLevel,
    int? lastCelebratedLevel,
    int? maxShieldsCapacity,
    bool? autoConsumeShields,
    DateTime? updatedAt,
  }) => UserGamificationRow(
    id: id ?? this.id,
    totalXp: totalXp ?? this.totalXp,
    currentLevel: currentLevel ?? this.currentLevel,
    lastCelebratedLevel: lastCelebratedLevel ?? this.lastCelebratedLevel,
    maxShieldsCapacity: maxShieldsCapacity ?? this.maxShieldsCapacity,
    autoConsumeShields: autoConsumeShields ?? this.autoConsumeShields,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  UserGamificationRow copyWithCompanion(UserGamificationCompanion data) {
    return UserGamificationRow(
      id: data.id.present ? data.id.value : this.id,
      totalXp: data.totalXp.present ? data.totalXp.value : this.totalXp,
      currentLevel: data.currentLevel.present
          ? data.currentLevel.value
          : this.currentLevel,
      lastCelebratedLevel: data.lastCelebratedLevel.present
          ? data.lastCelebratedLevel.value
          : this.lastCelebratedLevel,
      maxShieldsCapacity: data.maxShieldsCapacity.present
          ? data.maxShieldsCapacity.value
          : this.maxShieldsCapacity,
      autoConsumeShields: data.autoConsumeShields.present
          ? data.autoConsumeShields.value
          : this.autoConsumeShields,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserGamificationRow(')
          ..write('id: $id, ')
          ..write('totalXp: $totalXp, ')
          ..write('currentLevel: $currentLevel, ')
          ..write('lastCelebratedLevel: $lastCelebratedLevel, ')
          ..write('maxShieldsCapacity: $maxShieldsCapacity, ')
          ..write('autoConsumeShields: $autoConsumeShields, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    totalXp,
    currentLevel,
    lastCelebratedLevel,
    maxShieldsCapacity,
    autoConsumeShields,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserGamificationRow &&
          other.id == this.id &&
          other.totalXp == this.totalXp &&
          other.currentLevel == this.currentLevel &&
          other.lastCelebratedLevel == this.lastCelebratedLevel &&
          other.maxShieldsCapacity == this.maxShieldsCapacity &&
          other.autoConsumeShields == this.autoConsumeShields &&
          other.updatedAt == this.updatedAt);
}

class UserGamificationCompanion extends UpdateCompanion<UserGamificationRow> {
  final Value<String> id;
  final Value<int> totalXp;
  final Value<int> currentLevel;
  final Value<int> lastCelebratedLevel;
  final Value<int> maxShieldsCapacity;
  final Value<bool> autoConsumeShields;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const UserGamificationCompanion({
    this.id = const Value.absent(),
    this.totalXp = const Value.absent(),
    this.currentLevel = const Value.absent(),
    this.lastCelebratedLevel = const Value.absent(),
    this.maxShieldsCapacity = const Value.absent(),
    this.autoConsumeShields = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserGamificationCompanion.insert({
    this.id = const Value.absent(),
    this.totalXp = const Value.absent(),
    this.currentLevel = const Value.absent(),
    this.lastCelebratedLevel = const Value.absent(),
    this.maxShieldsCapacity = const Value.absent(),
    this.autoConsumeShields = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : updatedAt = Value(updatedAt);
  static Insertable<UserGamificationRow> custom({
    Expression<String>? id,
    Expression<int>? totalXp,
    Expression<int>? currentLevel,
    Expression<int>? lastCelebratedLevel,
    Expression<int>? maxShieldsCapacity,
    Expression<bool>? autoConsumeShields,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (totalXp != null) 'total_xp': totalXp,
      if (currentLevel != null) 'current_level': currentLevel,
      if (lastCelebratedLevel != null)
        'last_celebrated_level': lastCelebratedLevel,
      if (maxShieldsCapacity != null)
        'max_shields_capacity': maxShieldsCapacity,
      if (autoConsumeShields != null)
        'auto_consume_shields': autoConsumeShields,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserGamificationCompanion copyWith({
    Value<String>? id,
    Value<int>? totalXp,
    Value<int>? currentLevel,
    Value<int>? lastCelebratedLevel,
    Value<int>? maxShieldsCapacity,
    Value<bool>? autoConsumeShields,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return UserGamificationCompanion(
      id: id ?? this.id,
      totalXp: totalXp ?? this.totalXp,
      currentLevel: currentLevel ?? this.currentLevel,
      lastCelebratedLevel: lastCelebratedLevel ?? this.lastCelebratedLevel,
      maxShieldsCapacity: maxShieldsCapacity ?? this.maxShieldsCapacity,
      autoConsumeShields: autoConsumeShields ?? this.autoConsumeShields,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (totalXp.present) {
      map['total_xp'] = Variable<int>(totalXp.value);
    }
    if (currentLevel.present) {
      map['current_level'] = Variable<int>(currentLevel.value);
    }
    if (lastCelebratedLevel.present) {
      map['last_celebrated_level'] = Variable<int>(lastCelebratedLevel.value);
    }
    if (maxShieldsCapacity.present) {
      map['max_shields_capacity'] = Variable<int>(maxShieldsCapacity.value);
    }
    if (autoConsumeShields.present) {
      map['auto_consume_shields'] = Variable<bool>(autoConsumeShields.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserGamificationCompanion(')
          ..write('id: $id, ')
          ..write('totalXp: $totalXp, ')
          ..write('currentLevel: $currentLevel, ')
          ..write('lastCelebratedLevel: $lastCelebratedLevel, ')
          ..write('maxShieldsCapacity: $maxShieldsCapacity, ')
          ..write('autoConsumeShields: $autoConsumeShields, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AchievementsTable extends Achievements
    with TableInfo<$AchievementsTable, AchievementRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AchievementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unlockedAtMeta = const VerificationMeta(
    'unlockedAt',
  );
  @override
  late final GeneratedColumn<DateTime> unlockedAt = GeneratedColumn<DateTime>(
    'unlocked_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _progressMeta = const VerificationMeta(
    'progress',
  );
  @override
  late final GeneratedColumn<int> progress = GeneratedColumn<int>(
    'progress',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notifiedMeta = const VerificationMeta(
    'notified',
  );
  @override
  late final GeneratedColumn<bool> notified = GeneratedColumn<bool>(
    'notified',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("notified" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    unlockedAt,
    progress,
    notified,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'achievements';
  @override
  VerificationContext validateIntegrity(
    Insertable<AchievementRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('unlocked_at')) {
      context.handle(
        _unlockedAtMeta,
        unlockedAt.isAcceptableOrUnknown(data['unlocked_at']!, _unlockedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_unlockedAtMeta);
    }
    if (data.containsKey('progress')) {
      context.handle(
        _progressMeta,
        progress.isAcceptableOrUnknown(data['progress']!, _progressMeta),
      );
    } else if (isInserting) {
      context.missing(_progressMeta);
    }
    if (data.containsKey('notified')) {
      context.handle(
        _notifiedMeta,
        notified.isAcceptableOrUnknown(data['notified']!, _notifiedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AchievementRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AchievementRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      unlockedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}unlocked_at'],
      )!,
      progress: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}progress'],
      )!,
      notified: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}notified'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AchievementsTable createAlias(String alias) {
    return $AchievementsTable(attachedDatabase, alias);
  }
}

class AchievementRow extends DataClass implements Insertable<AchievementRow> {
  final String id;
  final DateTime unlockedAt;
  final int progress;
  final bool notified;
  final DateTime createdAt;
  final DateTime updatedAt;
  const AchievementRow({
    required this.id,
    required this.unlockedAt,
    required this.progress,
    required this.notified,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['unlocked_at'] = Variable<DateTime>(unlockedAt);
    map['progress'] = Variable<int>(progress);
    map['notified'] = Variable<bool>(notified);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AchievementsCompanion toCompanion(bool nullToAbsent) {
    return AchievementsCompanion(
      id: Value(id),
      unlockedAt: Value(unlockedAt),
      progress: Value(progress),
      notified: Value(notified),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory AchievementRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AchievementRow(
      id: serializer.fromJson<String>(json['id']),
      unlockedAt: serializer.fromJson<DateTime>(json['unlockedAt']),
      progress: serializer.fromJson<int>(json['progress']),
      notified: serializer.fromJson<bool>(json['notified']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'unlockedAt': serializer.toJson<DateTime>(unlockedAt),
      'progress': serializer.toJson<int>(progress),
      'notified': serializer.toJson<bool>(notified),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AchievementRow copyWith({
    String? id,
    DateTime? unlockedAt,
    int? progress,
    bool? notified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => AchievementRow(
    id: id ?? this.id,
    unlockedAt: unlockedAt ?? this.unlockedAt,
    progress: progress ?? this.progress,
    notified: notified ?? this.notified,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AchievementRow copyWithCompanion(AchievementsCompanion data) {
    return AchievementRow(
      id: data.id.present ? data.id.value : this.id,
      unlockedAt: data.unlockedAt.present
          ? data.unlockedAt.value
          : this.unlockedAt,
      progress: data.progress.present ? data.progress.value : this.progress,
      notified: data.notified.present ? data.notified.value : this.notified,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AchievementRow(')
          ..write('id: $id, ')
          ..write('unlockedAt: $unlockedAt, ')
          ..write('progress: $progress, ')
          ..write('notified: $notified, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, unlockedAt, progress, notified, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AchievementRow &&
          other.id == this.id &&
          other.unlockedAt == this.unlockedAt &&
          other.progress == this.progress &&
          other.notified == this.notified &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AchievementsCompanion extends UpdateCompanion<AchievementRow> {
  final Value<String> id;
  final Value<DateTime> unlockedAt;
  final Value<int> progress;
  final Value<bool> notified;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AchievementsCompanion({
    this.id = const Value.absent(),
    this.unlockedAt = const Value.absent(),
    this.progress = const Value.absent(),
    this.notified = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AchievementsCompanion.insert({
    required String id,
    required DateTime unlockedAt,
    required int progress,
    this.notified = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       unlockedAt = Value(unlockedAt),
       progress = Value(progress);
  static Insertable<AchievementRow> custom({
    Expression<String>? id,
    Expression<DateTime>? unlockedAt,
    Expression<int>? progress,
    Expression<bool>? notified,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (unlockedAt != null) 'unlocked_at': unlockedAt,
      if (progress != null) 'progress': progress,
      if (notified != null) 'notified': notified,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AchievementsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? unlockedAt,
    Value<int>? progress,
    Value<bool>? notified,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return AchievementsCompanion(
      id: id ?? this.id,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      progress: progress ?? this.progress,
      notified: notified ?? this.notified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (unlockedAt.present) {
      map['unlocked_at'] = Variable<DateTime>(unlockedAt.value);
    }
    if (progress.present) {
      map['progress'] = Variable<int>(progress.value);
    }
    if (notified.present) {
      map['notified'] = Variable<bool>(notified.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AchievementsCompanion(')
          ..write('id: $id, ')
          ..write('unlockedAt: $unlockedAt, ')
          ..write('progress: $progress, ')
          ..write('notified: $notified, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $HabitsTable habits = $HabitsTable(this);
  late final $HabitLogsTable habitLogs = $HabitLogsTable(this);
  late final $HabitShieldsTable habitShields = $HabitShieldsTable(this);
  late final $HabitCategoriesTable habitCategories = $HabitCategoriesTable(
    this,
  );
  late final $UserGamificationTable userGamification = $UserGamificationTable(
    this,
  );
  late final $AchievementsTable achievements = $AchievementsTable(this);
  late final Index idxHabitLogsHabitId = Index(
    'idx_habit_logs_habit_id',
    'CREATE INDEX idx_habit_logs_habit_id ON habit_logs (habit_id)',
  );
  late final Index idxHabitLogsDate = Index(
    'idx_habit_logs_date',
    'CREATE INDEX idx_habit_logs_date ON habit_logs (date)',
  );
  late final Index idxHabitLogsHabitIdDate = Index(
    'idx_habit_logs_habit_id_date',
    'CREATE INDEX idx_habit_logs_habit_id_date ON habit_logs (habit_id, date)',
  );
  late final Index idxHabitLogsNaturalKey = Index(
    'idx_habit_logs_natural_key',
    'CREATE INDEX idx_habit_logs_natural_key ON habit_logs (habit_id, date, interval_index)',
  );
  late final Index idxHabitShieldsHabitId = Index(
    'idx_habit_shields_habit_id',
    'CREATE INDEX idx_habit_shields_habit_id ON habit_shields (habit_id)',
  );
  late final Index idxHabitShieldsDate = Index(
    'idx_habit_shields_date',
    'CREATE INDEX idx_habit_shields_date ON habit_shields (date)',
  );
  late final Index idxHabitShieldsHabitIdDate = Index(
    'idx_habit_shields_habit_id_date',
    'CREATE INDEX idx_habit_shields_habit_id_date ON habit_shields (habit_id, date)',
  );
  late final HabitDao habitDao = HabitDao(this as AppDatabase);
  late final HabitLogDao habitLogDao = HabitLogDao(this as AppDatabase);
  late final HabitShieldDao habitShieldDao = HabitShieldDao(
    this as AppDatabase,
  );
  late final HabitCategoryDao habitCategoryDao = HabitCategoryDao(
    this as AppDatabase,
  );
  late final GamificationDao gamificationDao = GamificationDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    habits,
    habitLogs,
    habitShields,
    habitCategories,
    userGamification,
    achievements,
    idxHabitLogsHabitId,
    idxHabitLogsDate,
    idxHabitLogsHabitIdDate,
    idxHabitLogsNaturalKey,
    idxHabitShieldsHabitId,
    idxHabitShieldsDate,
    idxHabitShieldsHabitIdDate,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'habits',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('habit_logs', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'habits',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('habit_shields', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$HabitsTableCreateCompanionBuilder = HabitsCompanion Function({
  required String id,
  required String title,
  Value<String?> description,
  required String color,
  Value<String?> icon,
  Value<String?> categoryId,
  required HabitFrequencyType frequencyType,
  Value<List<int>?> targetDaysOfWeek,
  Value<int?> targetCountPerWeek,
  Value<int?> intervalHours,
  Value<int?> timesPerDay,
  Value<TimeWindow?> timeWindow,
  required HabitTargetType targetType,
  Value<double?> targetValue,
  Value<double?> miniTargetValue,
  Value<double?> eliteTargetValue,
  Value<String?> unit,
  Value<bool> pinned,
  Value<List<String>> reminderTimes,
  Value<String?> motivationNotes,
  Value<bool> archived,
  Value<bool> promptReflection,
  Value<HealthMetricType?> healthMetric,
  Value<bool> healthSyncEnabled,
  Value<bool> isDeleted,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$HabitsTableUpdateCompanionBuilder = HabitsCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String?> description,
  Value<String> color,
  Value<String?> icon,
  Value<String?> categoryId,
  Value<HabitFrequencyType> frequencyType,
  Value<List<int>?> targetDaysOfWeek,
  Value<int?> targetCountPerWeek,
  Value<int?> intervalHours,
  Value<int?> timesPerDay,
  Value<TimeWindow?> timeWindow,
  Value<HabitTargetType> targetType,
  Value<double?> targetValue,
  Value<double?> miniTargetValue,
  Value<double?> eliteTargetValue,
  Value<String?> unit,
  Value<bool> pinned,
  Value<List<String>> reminderTimes,
  Value<String?> motivationNotes,
  Value<bool> archived,
  Value<bool> promptReflection,
  Value<HealthMetricType?> healthMetric,
  Value<bool> healthSyncEnabled,
  Value<bool> isDeleted,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$HabitsTableReferences
    extends BaseReferences<_$AppDatabase, $HabitsTable, HabitRow> {
  $$HabitsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$HabitLogsTable, List<HabitLogRow>>
  _habitLogsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.habitLogs,
    aliasName: 'habits__id__habit_logs__habit_id',
  );

  $$HabitLogsTableProcessedTableManager get habitLogsRefs {
    final manager = $$HabitLogsTableTableManager(
      $_db,
      $_db.habitLogs,
    ).filter((f) => f.habitId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_habitLogsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$HabitShieldsTable, List<HabitShieldRow>>
  _habitShieldsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.habitShields,
    aliasName: 'habits__id__habit_shields__habit_id',
  );

  $$HabitShieldsTableProcessedTableManager get habitShieldsRefs {
    final manager = $$HabitShieldsTableTableManager(
      $_db,
      $_db.habitShields,
    ).filter((f) => f.habitId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_habitShieldsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$HabitsTableFilterComposer
    extends Composer<_$AppDatabase, $HabitsTable> {
  $$HabitsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<HabitFrequencyType, HabitFrequencyType, String>
  get frequencyType => $composableBuilder(
    column: $table.frequencyType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<List<int>?, List<int>, String>
  get targetDaysOfWeek => $composableBuilder(
    column: $table.targetDaysOfWeek,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get targetCountPerWeek => $composableBuilder(
    column: $table.targetCountPerWeek,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervalHours => $composableBuilder(
    column: $table.intervalHours,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timesPerDay => $composableBuilder(
    column: $table.timesPerDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TimeWindow?, TimeWindow, String>
  get timeWindow => $composableBuilder(
    column: $table.timeWindow,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<HabitTargetType, HabitTargetType, String>
  get targetType => $composableBuilder(
    column: $table.targetType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<double> get targetValue => $composableBuilder(
    column: $table.targetValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get miniTargetValue => $composableBuilder(
    column: $table.miniTargetValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get eliteTargetValue => $composableBuilder(
    column: $table.eliteTargetValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pinned => $composableBuilder(
    column: $table.pinned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get reminderTimes => $composableBuilder(
    column: $table.reminderTimes,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get motivationNotes => $composableBuilder(
    column: $table.motivationNotes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get promptReflection => $composableBuilder(
    column: $table.promptReflection,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<HealthMetricType?, HealthMetricType, String>
  get healthMetric => $composableBuilder(
    column: $table.healthMetric,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get healthSyncEnabled => $composableBuilder(
    column: $table.healthSyncEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> habitLogsRefs(
    Expression<bool> Function($$HabitLogsTableFilterComposer f) f,
  ) {
    final $$HabitLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.habitLogs,
      getReferencedColumn: (t) => t.habitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitLogsTableFilterComposer(
            $db: $db,
            $table: $db.habitLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> habitShieldsRefs(
    Expression<bool> Function($$HabitShieldsTableFilterComposer f) f,
  ) {
    final $$HabitShieldsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.habitShields,
      getReferencedColumn: (t) => t.habitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitShieldsTableFilterComposer(
            $db: $db,
            $table: $db.habitShields,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$HabitsTableOrderingComposer
    extends Composer<_$AppDatabase, $HabitsTable> {
  $$HabitsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get frequencyType => $composableBuilder(
    column: $table.frequencyType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetDaysOfWeek => $composableBuilder(
    column: $table.targetDaysOfWeek,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetCountPerWeek => $composableBuilder(
    column: $table.targetCountPerWeek,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalHours => $composableBuilder(
    column: $table.intervalHours,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timesPerDay => $composableBuilder(
    column: $table.timesPerDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timeWindow => $composableBuilder(
    column: $table.timeWindow,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetType => $composableBuilder(
    column: $table.targetType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get targetValue => $composableBuilder(
    column: $table.targetValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get miniTargetValue => $composableBuilder(
    column: $table.miniTargetValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get eliteTargetValue => $composableBuilder(
    column: $table.eliteTargetValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pinned => $composableBuilder(
    column: $table.pinned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reminderTimes => $composableBuilder(
    column: $table.reminderTimes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get motivationNotes => $composableBuilder(
    column: $table.motivationNotes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get promptReflection => $composableBuilder(
    column: $table.promptReflection,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get healthMetric => $composableBuilder(
    column: $table.healthMetric,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get healthSyncEnabled => $composableBuilder(
    column: $table.healthSyncEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HabitsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HabitsTable> {
  $$HabitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<HabitFrequencyType, String>
  get frequencyType => $composableBuilder(
    column: $table.frequencyType,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<List<int>?, String> get targetDaysOfWeek =>
      $composableBuilder(
        column: $table.targetDaysOfWeek,
        builder: (column) => column,
      );

  GeneratedColumn<int> get targetCountPerWeek => $composableBuilder(
    column: $table.targetCountPerWeek,
    builder: (column) => column,
  );

  GeneratedColumn<int> get intervalHours => $composableBuilder(
    column: $table.intervalHours,
    builder: (column) => column,
  );

  GeneratedColumn<int> get timesPerDay => $composableBuilder(
    column: $table.timesPerDay,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<TimeWindow?, String> get timeWindow =>
      $composableBuilder(
        column: $table.timeWindow,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<HabitTargetType, String> get targetType =>
      $composableBuilder(
        column: $table.targetType,
        builder: (column) => column,
      );

  GeneratedColumn<double> get targetValue => $composableBuilder(
    column: $table.targetValue,
    builder: (column) => column,
  );

  GeneratedColumn<double> get miniTargetValue => $composableBuilder(
    column: $table.miniTargetValue,
    builder: (column) => column,
  );

  GeneratedColumn<double> get eliteTargetValue => $composableBuilder(
    column: $table.eliteTargetValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<bool> get pinned =>
      $composableBuilder(column: $table.pinned, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get reminderTimes =>
      $composableBuilder(
        column: $table.reminderTimes,
        builder: (column) => column,
      );

  GeneratedColumn<String> get motivationNotes => $composableBuilder(
    column: $table.motivationNotes,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<bool> get promptReflection => $composableBuilder(
    column: $table.promptReflection,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<HealthMetricType?, String>
  get healthMetric => $composableBuilder(
    column: $table.healthMetric,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get healthSyncEnabled => $composableBuilder(
    column: $table.healthSyncEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> habitLogsRefs<T extends Object>(
    Expression<T> Function($$HabitLogsTableAnnotationComposer a) f,
  ) {
    final $$HabitLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.habitLogs,
      getReferencedColumn: (t) => t.habitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.habitLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> habitShieldsRefs<T extends Object>(
    Expression<T> Function($$HabitShieldsTableAnnotationComposer a) f,
  ) {
    final $$HabitShieldsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.habitShields,
      getReferencedColumn: (t) => t.habitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitShieldsTableAnnotationComposer(
            $db: $db,
            $table: $db.habitShields,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$HabitsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HabitsTable,
          HabitRow,
          $$HabitsTableFilterComposer,
          $$HabitsTableOrderingComposer,
          $$HabitsTableAnnotationComposer,
          $$HabitsTableCreateCompanionBuilder,
          $$HabitsTableUpdateCompanionBuilder,
          (HabitRow, $$HabitsTableReferences),
          HabitRow,
          PrefetchHooks Function({bool habitLogsRefs, bool habitShieldsRefs})
        > {
  $$HabitsTableTableManager(_$AppDatabase db, $HabitsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HabitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HabitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HabitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> color = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<HabitFrequencyType> frequencyType = const Value.absent(),
                Value<List<int>?> targetDaysOfWeek = const Value.absent(),
                Value<int?> targetCountPerWeek = const Value.absent(),
                Value<int?> intervalHours = const Value.absent(),
                Value<int?> timesPerDay = const Value.absent(),
                Value<TimeWindow?> timeWindow = const Value.absent(),
                Value<HabitTargetType> targetType = const Value.absent(),
                Value<double?> targetValue = const Value.absent(),
                Value<double?> miniTargetValue = const Value.absent(),
                Value<double?> eliteTargetValue = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<bool> pinned = const Value.absent(),
                Value<List<String>> reminderTimes = const Value.absent(),
                Value<String?> motivationNotes = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<bool> promptReflection = const Value.absent(),
                Value<HealthMetricType?> healthMetric = const Value.absent(),
                Value<bool> healthSyncEnabled = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HabitsCompanion(
                id: id,
                title: title,
                description: description,
                color: color,
                icon: icon,
                categoryId: categoryId,
                frequencyType: frequencyType,
                targetDaysOfWeek: targetDaysOfWeek,
                targetCountPerWeek: targetCountPerWeek,
                intervalHours: intervalHours,
                timesPerDay: timesPerDay,
                timeWindow: timeWindow,
                targetType: targetType,
                targetValue: targetValue,
                miniTargetValue: miniTargetValue,
                eliteTargetValue: eliteTargetValue,
                unit: unit,
                pinned: pinned,
                reminderTimes: reminderTimes,
                motivationNotes: motivationNotes,
                archived: archived,
                promptReflection: promptReflection,
                healthMetric: healthMetric,
                healthSyncEnabled: healthSyncEnabled,
                isDeleted: isDeleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<String?> description = const Value.absent(),
                required String color,
                Value<String?> icon = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                required HabitFrequencyType frequencyType,
                Value<List<int>?> targetDaysOfWeek = const Value.absent(),
                Value<int?> targetCountPerWeek = const Value.absent(),
                Value<int?> intervalHours = const Value.absent(),
                Value<int?> timesPerDay = const Value.absent(),
                Value<TimeWindow?> timeWindow = const Value.absent(),
                required HabitTargetType targetType,
                Value<double?> targetValue = const Value.absent(),
                Value<double?> miniTargetValue = const Value.absent(),
                Value<double?> eliteTargetValue = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<bool> pinned = const Value.absent(),
                Value<List<String>> reminderTimes = const Value.absent(),
                Value<String?> motivationNotes = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<bool> promptReflection = const Value.absent(),
                Value<HealthMetricType?> healthMetric = const Value.absent(),
                Value<bool> healthSyncEnabled = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => HabitsCompanion.insert(
                id: id,
                title: title,
                description: description,
                color: color,
                icon: icon,
                categoryId: categoryId,
                frequencyType: frequencyType,
                targetDaysOfWeek: targetDaysOfWeek,
                targetCountPerWeek: targetCountPerWeek,
                intervalHours: intervalHours,
                timesPerDay: timesPerDay,
                timeWindow: timeWindow,
                targetType: targetType,
                targetValue: targetValue,
                miniTargetValue: miniTargetValue,
                eliteTargetValue: eliteTargetValue,
                unit: unit,
                pinned: pinned,
                reminderTimes: reminderTimes,
                motivationNotes: motivationNotes,
                archived: archived,
                promptReflection: promptReflection,
                healthMetric: healthMetric,
                healthSyncEnabled: healthSyncEnabled,
                isDeleted: isDeleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$HabitsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({habitLogsRefs = false, habitShieldsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (habitLogsRefs) db.habitLogs,
                    if (habitShieldsRefs) db.habitShields,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (habitLogsRefs)
                        await $_getPrefetchedData<
                          HabitRow,
                          $HabitsTable,
                          HabitLogRow
                        >(
                          currentTable: table,
                          referencedTable: $$HabitsTableReferences
                              ._habitLogsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$HabitsTableReferences(
                                db,
                                table,
                                p0,
                              ).habitLogsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.habitId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (habitShieldsRefs)
                        await $_getPrefetchedData<
                          HabitRow,
                          $HabitsTable,
                          HabitShieldRow
                        >(
                          currentTable: table,
                          referencedTable: $$HabitsTableReferences
                              ._habitShieldsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$HabitsTableReferences(
                                db,
                                table,
                                p0,
                              ).habitShieldsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.habitId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$HabitsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HabitsTable,
      HabitRow,
      $$HabitsTableFilterComposer,
      $$HabitsTableOrderingComposer,
      $$HabitsTableAnnotationComposer,
      $$HabitsTableCreateCompanionBuilder,
      $$HabitsTableUpdateCompanionBuilder,
      (HabitRow, $$HabitsTableReferences),
      HabitRow,
      PrefetchHooks Function({bool habitLogsRefs, bool habitShieldsRefs})
    >;
typedef $$HabitLogsTableCreateCompanionBuilder = HabitLogsCompanion Function({
  required String id,
  required String habitId,
  required String date,
  required DateTime timestamp,
  Value<int?> intervalIndex,
  required bool completed,
  Value<double?> value,
  Value<int?> durationSeconds,
  Value<HabitTier?> targetTier,
  Value<String?> note,
  Value<int?> energyLevel,
  Value<String?> mood,
  Value<bool> isDeleted,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$HabitLogsTableUpdateCompanionBuilder = HabitLogsCompanion Function({
  Value<String> id,
  Value<String> habitId,
  Value<String> date,
  Value<DateTime> timestamp,
  Value<int?> intervalIndex,
  Value<bool> completed,
  Value<double?> value,
  Value<int?> durationSeconds,
  Value<HabitTier?> targetTier,
  Value<String?> note,
  Value<int?> energyLevel,
  Value<String?> mood,
  Value<bool> isDeleted,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$HabitLogsTableReferences
    extends BaseReferences<_$AppDatabase, $HabitLogsTable, HabitLogRow> {
  $$HabitLogsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $HabitsTable _habitIdTable(_$AppDatabase db) =>
      db.habits.createAlias('habit_logs__habit_id__habits__id');

  $$HabitsTableProcessedTableManager get habitId {
    final $_column = $_itemColumn<String>('habit_id')!;

    final manager = $$HabitsTableTableManager(
      $_db,
      $_db.habits,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_habitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$HabitLogsTableFilterComposer
    extends Composer<_$AppDatabase, $HabitLogsTable> {
  $$HabitLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervalIndex => $composableBuilder(
    column: $table.intervalIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<HabitTier?, HabitTier, String>
  get targetTier => $composableBuilder(
    column: $table.targetTier,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get energyLevel => $composableBuilder(
    column: $table.energyLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mood => $composableBuilder(
    column: $table.mood,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$HabitsTableFilterComposer get habitId {
    final $$HabitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableFilterComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HabitLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $HabitLogsTable> {
  $$HabitLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalIndex => $composableBuilder(
    column: $table.intervalIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetTier => $composableBuilder(
    column: $table.targetTier,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get energyLevel => $composableBuilder(
    column: $table.energyLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mood => $composableBuilder(
    column: $table.mood,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$HabitsTableOrderingComposer get habitId {
    final $$HabitsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableOrderingComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HabitLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HabitLogsTable> {
  $$HabitLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<int> get intervalIndex => $composableBuilder(
    column: $table.intervalIndex,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);

  GeneratedColumn<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<HabitTier?, String> get targetTier =>
      $composableBuilder(
        column: $table.targetTier,
        builder: (column) => column,
      );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get energyLevel => $composableBuilder(
    column: $table.energyLevel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mood =>
      $composableBuilder(column: $table.mood, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$HabitsTableAnnotationComposer get habitId {
    final $$HabitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableAnnotationComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HabitLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HabitLogsTable,
          HabitLogRow,
          $$HabitLogsTableFilterComposer,
          $$HabitLogsTableOrderingComposer,
          $$HabitLogsTableAnnotationComposer,
          $$HabitLogsTableCreateCompanionBuilder,
          $$HabitLogsTableUpdateCompanionBuilder,
          (HabitLogRow, $$HabitLogsTableReferences),
          HabitLogRow,
          PrefetchHooks Function({bool habitId})
        > {
  $$HabitLogsTableTableManager(_$AppDatabase db, $HabitLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HabitLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HabitLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HabitLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> habitId = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<int?> intervalIndex = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<double?> value = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
                Value<HabitTier?> targetTier = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int?> energyLevel = const Value.absent(),
                Value<String?> mood = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HabitLogsCompanion(
                id: id,
                habitId: habitId,
                date: date,
                timestamp: timestamp,
                intervalIndex: intervalIndex,
                completed: completed,
                value: value,
                durationSeconds: durationSeconds,
                targetTier: targetTier,
                note: note,
                energyLevel: energyLevel,
                mood: mood,
                isDeleted: isDeleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String habitId,
                required String date,
                required DateTime timestamp,
                Value<int?> intervalIndex = const Value.absent(),
                required bool completed,
                Value<double?> value = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
                Value<HabitTier?> targetTier = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int?> energyLevel = const Value.absent(),
                Value<String?> mood = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => HabitLogsCompanion.insert(
                id: id,
                habitId: habitId,
                date: date,
                timestamp: timestamp,
                intervalIndex: intervalIndex,
                completed: completed,
                value: value,
                durationSeconds: durationSeconds,
                targetTier: targetTier,
                note: note,
                energyLevel: energyLevel,
                mood: mood,
                isDeleted: isDeleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$HabitLogsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({habitId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (habitId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.habitId,
                        referencedTable: $$HabitLogsTableReferences
                            ._habitIdTable(db),
                        referencedColumn: $$HabitLogsTableReferences
                            ._habitIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$HabitLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HabitLogsTable,
      HabitLogRow,
      $$HabitLogsTableFilterComposer,
      $$HabitLogsTableOrderingComposer,
      $$HabitLogsTableAnnotationComposer,
      $$HabitLogsTableCreateCompanionBuilder,
      $$HabitLogsTableUpdateCompanionBuilder,
      (HabitLogRow, $$HabitLogsTableReferences),
      HabitLogRow,
      PrefetchHooks Function({bool habitId})
    >;
typedef $$HabitShieldsTableCreateCompanionBuilder =
    HabitShieldsCompanion Function({
      required String id,
      required String habitId,
      required String date,
      Value<bool> autoApplied,
      Value<bool> isDeleted,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$HabitShieldsTableUpdateCompanionBuilder =
    HabitShieldsCompanion Function({
      Value<String> id,
      Value<String> habitId,
      Value<String> date,
      Value<bool> autoApplied,
      Value<bool> isDeleted,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$HabitShieldsTableReferences
    extends BaseReferences<_$AppDatabase, $HabitShieldsTable, HabitShieldRow> {
  $$HabitShieldsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $HabitsTable _habitIdTable(_$AppDatabase db) =>
      db.habits.createAlias('habit_shields__habit_id__habits__id');

  $$HabitsTableProcessedTableManager get habitId {
    final $_column = $_itemColumn<String>('habit_id')!;

    final manager = $$HabitsTableTableManager(
      $_db,
      $_db.habits,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_habitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$HabitShieldsTableFilterComposer
    extends Composer<_$AppDatabase, $HabitShieldsTable> {
  $$HabitShieldsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get autoApplied => $composableBuilder(
    column: $table.autoApplied,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$HabitsTableFilterComposer get habitId {
    final $$HabitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableFilterComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HabitShieldsTableOrderingComposer
    extends Composer<_$AppDatabase, $HabitShieldsTable> {
  $$HabitShieldsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get autoApplied => $composableBuilder(
    column: $table.autoApplied,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$HabitsTableOrderingComposer get habitId {
    final $$HabitsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableOrderingComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HabitShieldsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HabitShieldsTable> {
  $$HabitShieldsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<bool> get autoApplied => $composableBuilder(
    column: $table.autoApplied,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$HabitsTableAnnotationComposer get habitId {
    final $$HabitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableAnnotationComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HabitShieldsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HabitShieldsTable,
          HabitShieldRow,
          $$HabitShieldsTableFilterComposer,
          $$HabitShieldsTableOrderingComposer,
          $$HabitShieldsTableAnnotationComposer,
          $$HabitShieldsTableCreateCompanionBuilder,
          $$HabitShieldsTableUpdateCompanionBuilder,
          (HabitShieldRow, $$HabitShieldsTableReferences),
          HabitShieldRow,
          PrefetchHooks Function({bool habitId})
        > {
  $$HabitShieldsTableTableManager(_$AppDatabase db, $HabitShieldsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HabitShieldsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HabitShieldsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HabitShieldsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> habitId = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<bool> autoApplied = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HabitShieldsCompanion(
                id: id,
                habitId: habitId,
                date: date,
                autoApplied: autoApplied,
                isDeleted: isDeleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String habitId,
                required String date,
                Value<bool> autoApplied = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => HabitShieldsCompanion.insert(
                id: id,
                habitId: habitId,
                date: date,
                autoApplied: autoApplied,
                isDeleted: isDeleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$HabitShieldsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({habitId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (habitId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.habitId,
                        referencedTable: $$HabitShieldsTableReferences
                            ._habitIdTable(db),
                        referencedColumn: $$HabitShieldsTableReferences
                            ._habitIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$HabitShieldsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HabitShieldsTable,
      HabitShieldRow,
      $$HabitShieldsTableFilterComposer,
      $$HabitShieldsTableOrderingComposer,
      $$HabitShieldsTableAnnotationComposer,
      $$HabitShieldsTableCreateCompanionBuilder,
      $$HabitShieldsTableUpdateCompanionBuilder,
      (HabitShieldRow, $$HabitShieldsTableReferences),
      HabitShieldRow,
      PrefetchHooks Function({bool habitId})
    >;
typedef $$HabitCategoriesTableCreateCompanionBuilder =
    HabitCategoriesCompanion Function({
      required String id,
      required String name,
      required String color,
      Value<String?> icon,
      Value<bool> isDeleted,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$HabitCategoriesTableUpdateCompanionBuilder =
    HabitCategoriesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> color,
      Value<String?> icon,
      Value<bool> isDeleted,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$HabitCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $HabitCategoriesTable> {
  $$HabitCategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HabitCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $HabitCategoriesTable> {
  $$HabitCategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HabitCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $HabitCategoriesTable> {
  $$HabitCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$HabitCategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HabitCategoriesTable,
          HabitCategoryRow,
          $$HabitCategoriesTableFilterComposer,
          $$HabitCategoriesTableOrderingComposer,
          $$HabitCategoriesTableAnnotationComposer,
          $$HabitCategoriesTableCreateCompanionBuilder,
          $$HabitCategoriesTableUpdateCompanionBuilder,
          (
            HabitCategoryRow,
            BaseReferences<
              _$AppDatabase,
              $HabitCategoriesTable,
              HabitCategoryRow
            >,
          ),
          HabitCategoryRow,
          PrefetchHooks Function()
        > {
  $$HabitCategoriesTableTableManager(
    _$AppDatabase db,
    $HabitCategoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HabitCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HabitCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HabitCategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> color = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HabitCategoriesCompanion(
                id: id,
                name: name,
                color: color,
                icon: icon,
                isDeleted: isDeleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String color,
                Value<String?> icon = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HabitCategoriesCompanion.insert(
                id: id,
                name: name,
                color: color,
                icon: icon,
                isDeleted: isDeleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HabitCategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HabitCategoriesTable,
      HabitCategoryRow,
      $$HabitCategoriesTableFilterComposer,
      $$HabitCategoriesTableOrderingComposer,
      $$HabitCategoriesTableAnnotationComposer,
      $$HabitCategoriesTableCreateCompanionBuilder,
      $$HabitCategoriesTableUpdateCompanionBuilder,
      (
        HabitCategoryRow,
        BaseReferences<_$AppDatabase, $HabitCategoriesTable, HabitCategoryRow>,
      ),
      HabitCategoryRow,
      PrefetchHooks Function()
    >;
typedef $$UserGamificationTableCreateCompanionBuilder =
    UserGamificationCompanion Function({
      Value<String> id,
      Value<int> totalXp,
      Value<int> currentLevel,
      Value<int> lastCelebratedLevel,
      Value<int> maxShieldsCapacity,
      Value<bool> autoConsumeShields,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$UserGamificationTableUpdateCompanionBuilder =
    UserGamificationCompanion Function({
      Value<String> id,
      Value<int> totalXp,
      Value<int> currentLevel,
      Value<int> lastCelebratedLevel,
      Value<int> maxShieldsCapacity,
      Value<bool> autoConsumeShields,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$UserGamificationTableFilterComposer
    extends Composer<_$AppDatabase, $UserGamificationTable> {
  $$UserGamificationTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalXp => $composableBuilder(
    column: $table.totalXp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentLevel => $composableBuilder(
    column: $table.currentLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastCelebratedLevel => $composableBuilder(
    column: $table.lastCelebratedLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxShieldsCapacity => $composableBuilder(
    column: $table.maxShieldsCapacity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get autoConsumeShields => $composableBuilder(
    column: $table.autoConsumeShields,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserGamificationTableOrderingComposer
    extends Composer<_$AppDatabase, $UserGamificationTable> {
  $$UserGamificationTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalXp => $composableBuilder(
    column: $table.totalXp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentLevel => $composableBuilder(
    column: $table.currentLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastCelebratedLevel => $composableBuilder(
    column: $table.lastCelebratedLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxShieldsCapacity => $composableBuilder(
    column: $table.maxShieldsCapacity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get autoConsumeShields => $composableBuilder(
    column: $table.autoConsumeShields,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserGamificationTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserGamificationTable> {
  $$UserGamificationTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get totalXp =>
      $composableBuilder(column: $table.totalXp, builder: (column) => column);

  GeneratedColumn<int> get currentLevel => $composableBuilder(
    column: $table.currentLevel,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastCelebratedLevel => $composableBuilder(
    column: $table.lastCelebratedLevel,
    builder: (column) => column,
  );

  GeneratedColumn<int> get maxShieldsCapacity => $composableBuilder(
    column: $table.maxShieldsCapacity,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get autoConsumeShields => $composableBuilder(
    column: $table.autoConsumeShields,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$UserGamificationTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserGamificationTable,
          UserGamificationRow,
          $$UserGamificationTableFilterComposer,
          $$UserGamificationTableOrderingComposer,
          $$UserGamificationTableAnnotationComposer,
          $$UserGamificationTableCreateCompanionBuilder,
          $$UserGamificationTableUpdateCompanionBuilder,
          (
            UserGamificationRow,
            BaseReferences<
              _$AppDatabase,
              $UserGamificationTable,
              UserGamificationRow
            >,
          ),
          UserGamificationRow,
          PrefetchHooks Function()
        > {
  $$UserGamificationTableTableManager(
    _$AppDatabase db,
    $UserGamificationTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserGamificationTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserGamificationTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserGamificationTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> totalXp = const Value.absent(),
                Value<int> currentLevel = const Value.absent(),
                Value<int> lastCelebratedLevel = const Value.absent(),
                Value<int> maxShieldsCapacity = const Value.absent(),
                Value<bool> autoConsumeShields = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserGamificationCompanion(
                id: id,
                totalXp: totalXp,
                currentLevel: currentLevel,
                lastCelebratedLevel: lastCelebratedLevel,
                maxShieldsCapacity: maxShieldsCapacity,
                autoConsumeShields: autoConsumeShields,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> totalXp = const Value.absent(),
                Value<int> currentLevel = const Value.absent(),
                Value<int> lastCelebratedLevel = const Value.absent(),
                Value<int> maxShieldsCapacity = const Value.absent(),
                Value<bool> autoConsumeShields = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => UserGamificationCompanion.insert(
                id: id,
                totalXp: totalXp,
                currentLevel: currentLevel,
                lastCelebratedLevel: lastCelebratedLevel,
                maxShieldsCapacity: maxShieldsCapacity,
                autoConsumeShields: autoConsumeShields,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserGamificationTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserGamificationTable,
      UserGamificationRow,
      $$UserGamificationTableFilterComposer,
      $$UserGamificationTableOrderingComposer,
      $$UserGamificationTableAnnotationComposer,
      $$UserGamificationTableCreateCompanionBuilder,
      $$UserGamificationTableUpdateCompanionBuilder,
      (
        UserGamificationRow,
        BaseReferences<
          _$AppDatabase,
          $UserGamificationTable,
          UserGamificationRow
        >,
      ),
      UserGamificationRow,
      PrefetchHooks Function()
    >;
typedef $$AchievementsTableCreateCompanionBuilder =
    AchievementsCompanion Function({
      required String id,
      required DateTime unlockedAt,
      required int progress,
      Value<bool> notified,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$AchievementsTableUpdateCompanionBuilder =
    AchievementsCompanion Function({
      Value<String> id,
      Value<DateTime> unlockedAt,
      Value<int> progress,
      Value<bool> notified,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$AchievementsTableFilterComposer
    extends Composer<_$AppDatabase, $AchievementsTable> {
  $$AchievementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get unlockedAt => $composableBuilder(
    column: $table.unlockedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get notified => $composableBuilder(
    column: $table.notified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AchievementsTableOrderingComposer
    extends Composer<_$AppDatabase, $AchievementsTable> {
  $$AchievementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get unlockedAt => $composableBuilder(
    column: $table.unlockedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get notified => $composableBuilder(
    column: $table.notified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AchievementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AchievementsTable> {
  $$AchievementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get unlockedAt => $composableBuilder(
    column: $table.unlockedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get progress =>
      $composableBuilder(column: $table.progress, builder: (column) => column);

  GeneratedColumn<bool> get notified =>
      $composableBuilder(column: $table.notified, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AchievementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AchievementsTable,
          AchievementRow,
          $$AchievementsTableFilterComposer,
          $$AchievementsTableOrderingComposer,
          $$AchievementsTableAnnotationComposer,
          $$AchievementsTableCreateCompanionBuilder,
          $$AchievementsTableUpdateCompanionBuilder,
          (
            AchievementRow,
            BaseReferences<_$AppDatabase, $AchievementsTable, AchievementRow>,
          ),
          AchievementRow,
          PrefetchHooks Function()
        > {
  $$AchievementsTableTableManager(_$AppDatabase db, $AchievementsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AchievementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AchievementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AchievementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> unlockedAt = const Value.absent(),
                Value<int> progress = const Value.absent(),
                Value<bool> notified = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AchievementsCompanion(
                id: id,
                unlockedAt: unlockedAt,
                progress: progress,
                notified: notified,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime unlockedAt,
                required int progress,
                Value<bool> notified = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AchievementsCompanion.insert(
                id: id,
                unlockedAt: unlockedAt,
                progress: progress,
                notified: notified,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AchievementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AchievementsTable,
      AchievementRow,
      $$AchievementsTableFilterComposer,
      $$AchievementsTableOrderingComposer,
      $$AchievementsTableAnnotationComposer,
      $$AchievementsTableCreateCompanionBuilder,
      $$AchievementsTableUpdateCompanionBuilder,
      (
        AchievementRow,
        BaseReferences<_$AppDatabase, $AchievementsTable, AchievementRow>,
      ),
      AchievementRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$HabitsTableTableManager get habits =>
      $$HabitsTableTableManager(_db, _db.habits);
  $$HabitLogsTableTableManager get habitLogs =>
      $$HabitLogsTableTableManager(_db, _db.habitLogs);
  $$HabitShieldsTableTableManager get habitShields =>
      $$HabitShieldsTableTableManager(_db, _db.habitShields);
  $$HabitCategoriesTableTableManager get habitCategories =>
      $$HabitCategoriesTableTableManager(_db, _db.habitCategories);
  $$UserGamificationTableTableManager get userGamification =>
      $$UserGamificationTableTableManager(_db, _db.userGamification);
  $$AchievementsTableTableManager get achievements =>
      $$AchievementsTableTableManager(_db, _db.achievements);
}
