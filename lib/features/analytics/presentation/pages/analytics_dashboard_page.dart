import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/analytics_bloc.dart';
import '../bloc/analytics_event.dart';
import '../bloc/analytics_state.dart';
import '../widgets/quick_stats_card.dart';
import '../widgets/activity_heatmap_widget.dart';
import '../widgets/velocity_chart_widget.dart';
import '../widgets/benchmark_bar_widget.dart';
import '../widgets/time_period_selector.dart';
import '../widgets/learning_goals_widget.dart';
import '../../../../core/theme/app_colors.dart';

class AnalyticsDashboardPage extends StatefulWidget {
  final int userId;
  final int? courseId;

  const AnalyticsDashboardPage({
    super.key,
    required this.userId,
    this.courseId,
  });

  @override
  State<AnalyticsDashboardPage> createState() => _AnalyticsDashboardPageState();
}

class _AnalyticsDashboardPageState extends State<AnalyticsDashboardPage> {
  TimePeriod _selectedPeriod = TimePeriod.month;

  @override
  void initState() {
    super.initState();
    context.read<AnalyticsBloc>().add(
      LoadAnalyticsDashboard(userId: widget.userId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text(
          '📊 Analytics Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.share_rounded),
            tooltip: 'Chia sẻ kết quả',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đang chuẩn bị báo cáo...'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<AnalyticsBloc, AnalyticsState>(
        buildWhen: (prev, curr) =>
            prev.runtimeType != curr.runtimeType || prev != curr,
        builder: (context, state) {
          if (state is AnalyticsLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (state is AnalyticsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<AnalyticsBloc>().add(
                        LoadAnalyticsDashboard(userId: widget.userId),
                      );
                    },
                    icon: Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          if (state is AnalyticsDashboardLoaded) {
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                context.read<AnalyticsBloc>().add(
                  LoadAnalyticsDashboard(userId: widget.userId),
                );
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TimePeriodSelector(
                    selected: _selectedPeriod,
                    onChanged: (period) {
                      setState(() => _selectedPeriod = period);
                      context.read<AnalyticsBloc>().add(
                        LoadAnalyticsDashboard(userId: widget.userId),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  QuickStatsCard(summary: state.summary),
                  const SizedBox(height: 16),
                  const LearningGoalsWidget(
                    dailyMinutesTarget: 30,
                    dailyMinutesActual: 22,
                    weeklyLessonsTarget: 5,
                    weeklyLessonsActual: 3,
                    currentStreak: 7,
                  ),
                  const SizedBox(height: 16),
                  ActivityHeatmapWidget(entries: state.heatmap),
                  const SizedBox(height: 16),
                  if (widget.courseId != null) ...[
                    _VelocitySection(
                      userId: widget.userId,
                      courseId: widget.courseId!,
                    ),
                    const SizedBox(height: 16),
                    _BenchmarkSection(
                      userId: widget.userId,
                      courseId: widget.courseId!,
                    ),
                  ],
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _VelocitySection extends StatefulWidget {
  final int userId;
  final int courseId;

  const _VelocitySection({required this.userId, required this.courseId});

  @override
  State<_VelocitySection> createState() => _VelocitySectionState();
}

class _VelocitySectionState extends State<_VelocitySection> {
  @override
  void initState() {
    super.initState();
    context.read<AnalyticsBloc>().add(
      LoadVelocity(userId: widget.userId, courseId: widget.courseId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnalyticsBloc, AnalyticsState>(
      buildWhen: (prev, current) => current is VelocityLoaded,
      builder: (context, state) {
        if (state is VelocityLoaded) {
          return VelocityChartWidget(velocity: state.velocity);
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _BenchmarkSection extends StatefulWidget {
  final int userId;
  final int courseId;

  const _BenchmarkSection({required this.userId, required this.courseId});

  @override
  State<_BenchmarkSection> createState() => _BenchmarkSectionState();
}

class _BenchmarkSectionState extends State<_BenchmarkSection> {
  @override
  void initState() {
    super.initState();
    context.read<AnalyticsBloc>().add(
      LoadBenchmark(userId: widget.userId, courseId: widget.courseId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnalyticsBloc, AnalyticsState>(
      buildWhen: (prev, current) => current is BenchmarkLoaded,
      builder: (context, state) {
        if (state is BenchmarkLoaded) {
          return BenchmarkBarWidget(benchmark: state.benchmark);
        }
        return const SizedBox.shrink();
      },
    );
  }
}
