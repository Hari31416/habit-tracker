import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
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

  PlayerProgression _progression;
  List<AchievementStatus> _achievements;
  LevelUpCelebration? _celebration;

  int? dismissedLevel;

  FakeGamificationRepository({
    PlayerProgression progression = const PlayerProgression(
      totalXp: 150,
      level: 2,
      title: PlayerTitle.novice,
      nextLevelTargetXp: 200,
    ),
    List<AchievementStatus> achievements = const [],
    LevelUpCelebration? celebration,
  })  : _progression = progression,
        _achievements = achievements,
        _celebration = celebration;

  @override
  Stream<PlayerProgression> getPlayerProgression() async* {
    yield _progression;
    yield* _progressionController.stream;
  }

  @override
  Stream<List<AchievementStatus>> getAchievements() async* {
    yield _achievements;
    yield* _achievementsController.stream;
  }

  @override
  Stream<LevelUpCelebration?> getPendingCelebration() async* {
    yield _celebration;
    yield* _celebrationController.stream;
  }

  @override
  Future<void> dismissCelebration(int level) async {
    dismissedLevel = level;
    _celebration = null;
    _celebrationController.add(null);
  }

  void updateProgression(PlayerProgression progression) {
    _progression = progression;
    _progressionController.add(progression);
  }

  void updateAchievements(List<AchievementStatus> achievements) {
    _achievements = achievements;
    _achievementsController.add(achievements);
  }

  void setCelebration(LevelUpCelebration? celebration) {
    _celebration = celebration;
    _celebrationController.add(celebration);
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
