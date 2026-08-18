import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/domain/engines/shield_banking_engine.dart';
import 'package:habit_tracker/domain/gamification/gamification_models.dart';
import 'package:habit_tracker/domain/gamification/player_title.dart';
import 'package:habit_tracker/domain/repositories/gamification_repository.dart';
import 'package:habit_tracker/ui/gamification/controllers/gamification_controller.dart';

class FakeGamificationRepository implements GamificationRepository {
  final _progressionController =
      StreamController<PlayerProgression>.broadcast();
  final _achievementsController =
      StreamController<List<AchievementStatus>>.broadcast();
  final _celebrationController =
      StreamController<LevelUpCelebration?>.broadcast();

  PlayerProgression progression;
  List<AchievementStatus> achievements;
  LevelUpCelebration? celebration;

  int? dismissedLevel;

  FakeGamificationRepository({
    this.progression = const PlayerProgression(
      totalXp: 150,
      level: 2,
      title: PlayerTitle.novice,
      nextLevelTargetXp: 200,
    ),
    this.achievements = const [],
    this.celebration,
  });

  @override
  Stream<PlayerProgression> getPlayerProgression() async* {
    yield progression;
    yield* _progressionController.stream;
  }

  @override
  Stream<List<AchievementStatus>> getAchievements() async* {
    yield achievements;
    yield* _achievementsController.stream;
  }

  @override
  Stream<LevelUpCelebration?> getPendingCelebration() async* {
    yield celebration;
    yield* _celebrationController.stream;
  }

  @override
  Future<void> dismissCelebration(int level) async {
    dismissedLevel = level;
    celebration = null;
    _celebrationController.add(null);
  }

  @override
  Stream<ShieldBankState> getShieldBankState() => Stream.value(
        const ShieldBankState(
          totalShieldsEarned: 1,
          usedShieldsCount: 0,
          availableShields: 1,
          maxCapacity: 3,
          daysToNextShield: 14,
          progressToNextShield: 0.0,
          autoConsumeEnabled: true,
        ),
      );

  @override
  Future<void> updateShieldSettings({
    required int maxCapacity,
    required bool autoConsume,
  }) async {}

  void updateProgression(PlayerProgression newProgression) {
    progression = newProgression;
    _progressionController.add(newProgression);
  }

  void updateAchievements(List<AchievementStatus> newAchievements) {
    achievements = newAchievements;
    _achievementsController.add(newAchievements);
  }

  void setCelebration(LevelUpCelebration? newCelebration) {
    celebration = newCelebration;
    _celebrationController.add(newCelebration);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testAchievement = const AchievementStatus(
    definition: AchievementDefinition(
      id: 'streak_3',
      title: 'Getting Started',
      description: 'Reach a 3-day streak',
      category: AchievementCategory.streak,
      tier: AchievementTier.bronze,
      iconName: 'fire',
      xpReward: 50,
      targetValue: 3,
      unit: 'days',
    ),
    isUnlocked: true,
    currentProgress: 3,
    progressFraction: 1.0,
  );

  final volumeAchievement = const AchievementStatus(
    definition: AchievementDefinition(
      id: 'volume_10',
      title: 'Centurion',
      description: 'Complete 10 habits',
      category: AchievementCategory.volume,
      tier: AchievementTier.silver,
      iconName: 'trophy',
      xpReward: 100,
      targetValue: 10,
      unit: 'times',
    ),
    isUnlocked: false,
    currentProgress: 4,
    progressFraction: 0.4,
  );

  late FakeGamificationRepository fakeRepo;
  late GamificationController controller;

  setUp(() {
    fakeRepo = FakeGamificationRepository(
      achievements: [testAchievement, volumeAchievement],
      celebration: const LevelUpCelebration(
        newLevel: 2,
        previousLevel: 1,
        title: PlayerTitle.novice,
        titleChanged: false,
      ),
    );
    controller = GamificationController(fakeRepo);
  });

  tearDown(() {
    controller.dispose();
  });

  test('initial state loads progression, achievements, and celebration',
      () async {
    await Future.delayed(const Duration(milliseconds: 50));
    final state = controller.state;

    expect(state.isLoading, isFalse);
    expect(state.progression.level, 2);
    expect(state.progression.totalXp, 150);
    expect(state.allAchievements.length, 2);
    expect(state.filteredAchievements.length, 2);
    expect(state.pendingCelebration?.newLevel, 2);
  });

  test('selecting category filters achievements list', () async {
    await Future.delayed(const Duration(milliseconds: 50));

    controller.selectCategory(AchievementCategory.streak);
    await Future.delayed(const Duration(milliseconds: 50));

    expect(controller.state.selectedCategory, AchievementCategory.streak);
    expect(controller.state.filteredAchievements.length, 1);
    expect(
      controller.state.filteredAchievements.first.definition.id,
      'streak_3',
    );

    controller.selectCategory(AchievementCategory.all);
    expect(controller.state.filteredAchievements.length, 2);
  });

  test('dismissCelebration calls repository and clears celebration', () async {
    await Future.delayed(const Duration(milliseconds: 50));

    await controller.dismissCelebration(2);
    await Future.delayed(const Duration(milliseconds: 50));

    expect(fakeRepo.dismissedLevel, 2);
    expect(controller.state.pendingCelebration, isNull);
  });
}
