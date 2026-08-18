import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../di/providers.dart';
import '../../../domain/gamification/gamification_models.dart';
import '../../../domain/repositories/gamification_repository.dart';

class GamificationUiState {
  final PlayerProgression progression;
  final AchievementCategory selectedCategory;
  final List<AchievementStatus> allAchievements;
  final List<AchievementStatus> filteredAchievements;
  final LevelUpCelebration? pendingCelebration;
  final bool isLoading;

  const GamificationUiState({
    this.progression = const PlayerProgression(),
    this.selectedCategory = AchievementCategory.all,
    this.allAchievements = const [],
    this.filteredAchievements = const [],
    this.pendingCelebration,
    this.isLoading = false,
  });

  GamificationUiState copyWith({
    PlayerProgression? progression,
    AchievementCategory? selectedCategory,
    List<AchievementStatus>? allAchievements,
    List<AchievementStatus>? filteredAchievements,
    LevelUpCelebration? pendingCelebration,
    bool? isLoading,
    bool clearCelebration = false,
  }) {
    return GamificationUiState(
      progression: progression ?? this.progression,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      allAchievements: allAchievements ?? this.allAchievements,
      filteredAchievements:
          filteredAchievements ?? this.filteredAchievements,
      pendingCelebration: clearCelebration
          ? null
          : (pendingCelebration ?? this.pendingCelebration),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final gamificationControllerProvider = StateNotifierProvider.autoDispose<
    GamificationController, GamificationUiState>((ref) {
  final repository = ref.watch(gamificationRepositoryProvider);
  return GamificationController(repository);
});

class GamificationController extends StateNotifier<GamificationUiState> {
  final GamificationRepository _repository;

  AchievementCategory _selectedCategory = AchievementCategory.all;
  PlayerProgression _progression = const PlayerProgression();
  List<AchievementStatus> _achievements = [];
  LevelUpCelebration? _celebration;

  StreamSubscription? _progressionSub;
  StreamSubscription? _achievementsSub;
  StreamSubscription? _celebrationSub;

  GamificationController(this._repository)
      : super(const GamificationUiState(isLoading: true)) {
    _init();
  }

  void _init() {
    _progressionSub = _repository.getPlayerProgression().listen((prog) {
      _progression = prog;
      _recalculate();
    });

    _achievementsSub = _repository.getAchievements().listen((achs) {
      _achievements = achs;
      _recalculate();
    });

    _celebrationSub = _repository.getPendingCelebration().listen((cel) {
      _celebration = cel;
      _recalculate();
    });
  }

  AchievementCategory get selectedCategory => _selectedCategory;

  void _recalculate() {
    final filtered = _selectedCategory == AchievementCategory.all
        ? _achievements
        : _achievements
            .where((a) => a.definition.category == _selectedCategory)
            .toList();

    state = GamificationUiState(
      progression: _progression,
      selectedCategory: _selectedCategory,
      allAchievements: _achievements,
      filteredAchievements: filtered,
      pendingCelebration: _celebration,
      isLoading: false,
    );
  }

  void selectCategory(AchievementCategory category) {
    _selectedCategory = category;
    _recalculate();
  }

  Future<void> dismissCelebration(int level) async {
    await _repository.dismissCelebration(level);
  }

  @override
  void dispose() {
    _progressionSub?.cancel();
    _achievementsSub?.cancel();
    _celebrationSub?.cancel();
    super.dispose();
  }
}
